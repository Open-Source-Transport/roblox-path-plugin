-- Plugin.server.lua
-- The main script for the plugin
-- Authors: Anthony O'Brien, arandomollie

-- Services
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")
local PhysicsService = game:GetService("PhysicsService")

-- Constants
local MAX_GRADIENT = 2000

-- Modules
local modules = script.Parent.Modules
local packages = script.Parent.Packages
local Path = require(modules.Path)
local CreateAssets = require(modules.CreateAssets)
local pluginUtil = require(modules.PluginUtil)
local fusion = require(packages.fusion)
local _Types = require(modules.Types)
local highlights = require(modules.Highlights)

local Value = fusion.Value

-- Initialise plugin

pluginUtil:init(
	plugin:CreateToolbar(pluginUtil.CONFIG.toolbarName),
	plugin:CreateDockWidgetPluginGui(pluginUtil.CONFIG.pluginId, pluginUtil.CONFIG.widgetInfo)
)

local assets = CreateAssets()

if not PhysicsService:IsCollisionGroupRegistered("PathPluginPreview") then
	PhysicsService:RegisterCollisionGroup("PathPluginPreview")
	PhysicsService:CollisionGroupSetCollidable("PathPluginPreview", "Default", false)
end

local pathChanged
local controlPoint
local path
local isUpdatingControlPoint = false

local gradeVal = Value("Flat")
local segmentLength = Value(20)
local cantAngle = Value(0)
local template = Value()
local endpoint = Value()
local reversePath = Value(false)
local primaryAxis: "Z" | "X" = "Z"
local optimiseStraights = true
local templateConnection: RBXScriptConnection?
local endpointConnection: RBXScriptConnection?

-- Functions

local function getTemplateCf()
	local templateLength = path.template:IsA("BasePart") and path.template.Size[primaryAxis] or path.template:GetExtentsSize()[primaryAxis]
	local scalar = templateLength * (reversePath:get() and -1 or 1)
	local toEdge: CFrame
	if primaryAxis == "X" then
		toEdge = CFrame.new(Vector3.new(0.5 * scalar, 0, 0), Vector3.new(scalar * 2, 0, 0))
	else
		toEdge = CFrame.new(Vector3.new(0, 0, 0.5 * scalar), Vector3.new(0, 0, scalar * 2))
	end
	return path.template
		and (path.template:GetPivot():ToWorldSpace(toEdge))
end

local function getGradientValue(curve)
	curve = curve:GetChildren()
	local length = 0
	for i, v in pairs(curve) do
		if v:IsA("BasePart") then
			length = length + v.Size.Z
		elseif v:IsA("Model") then
			local _, size = v:GetBoundingBox()
			length = length + size.Z
		end
	end
	local startSegment, endSegment = curve[1], curve[#curve]
	if
		(startSegment:IsA("Model") or startSegment:IsA("BasePart"))
		and (endSegment:IsA("Model") or endSegment:IsA("BasePart"))
	then
		local startCf, startSize
		local endCf, endSize

		if startSegment:IsA("Model") then
			startCf, startSize = startSegment:GetBoundingBox()
		else
			startCf, startSize = startSegment.CFrame, startSegment.Size
		end

		if endSegment:IsA("Model") then
			endCf, endSize = endSegment:GetBoundingBox()
		else
			endCf, endSize = endSegment.CFrame, endSegment.Size
		end
		startCf = startCf * CFrame.new(0, 0, 0.5 * startSize.Z)
		endCf = endCf * CFrame.new(0, 0, -0.5 * endSize.Z)
		local y0 = startCf.Position.Y
		local y1 = endCf.Position.Y
		if y0 ~= y1 then
			local gradient = math.floor(length / (y1 - y0) + 0.5)
			return math.abs(gradient) <= MAX_GRADIENT and gradient or 0
		end
	end
	return 0
end

-- Previews the path given, call with no arguments to clear
local function previewPath(path)
	if workspace.CurrentCamera:FindFirstChild("PathPreview") then
		workspace.CurrentCamera.PathPreview:Destroy()
	end
	if path and path.template and controlPoint then
		local preview = path:draw(getTemplateCf(), controlPoint.CFrame)
		local grade = getGradientValue(preview)
		if grade == 0 then
			grade = "Flat"
		elseif grade > 0 then
			grade = "Incline: 1 in " .. tostring(grade)
		else
			grade = "Decline: 1 in " .. tostring(-grade)
		end
		gradeVal:set(grade)
		if preview then
			for _, v in pairs(preview:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("Decal") then
					v.LocalTransparencyModifier = 0.5
					if v:IsA("BasePart") then
						v.Locked = true
						v.CollisionGroup = "PathPluginPreview"
					end
				end
			end
			preview.Name = "PathPreview"
			preview.Parent = workspace.CurrentCamera
		end
	else
		gradeVal:set("")
	end
end

-- Resets the plugin
local function resetPlugin()
	highlights:clearHighlights()
	for _, c in pairs(workspace.CurrentCamera:GetChildren()) do
		if c.Name == "PathPreview" or c.Name == "ControlPoint" or c.Name == "Highlight" then
			c:Destroy()
		end
	end
	controlPoint = nil
	gradeVal:set("")
	
	if templateConnection then
		templateConnection:Disconnect()
		templateConnection = nil
	end
	if endpointConnection then
		endpointConnection:Disconnect()
		endpointConnection = nil
	end
end

resetPlugin()

local function setEndpoint(value: (BasePart | Model)?, sign: number?)
	highlights:removeHighlight("Endpoint")
	if endpointConnection then
		endpointConnection:Disconnect()
		endpointConnection = nil
	end
	if (not (value and controlPoint)) or (value == controlPoint) then
		endpoint:set()
		return
	end
	local addConnection = value == endpoint:get()
	local p: BasePart
	isUpdatingControlPoint = true
	if value:IsA("Model") then
		local maxSize = 0
		for _, c in pairs(value:GetDescendants()) do
			if c:IsA("BasePart") and c.Size[primaryAxis] > maxSize then
				p = c
				maxSize = c.Size[primaryAxis]
				break
			end
		end
		if maxSize == 0 then
			endpoint:set()
			return
		end
	elseif value:IsA("BasePart") then
		p = value
	else
		endpoint:set()
		return
	end

	highlights:addHighlight("Endpoint", value)

	if not sign then
		local mouse = UserInputService:GetMouseLocation()
		local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
		local rayParams = RaycastParams.new()
		rayParams.CollisionGroup = "StudioSelectable"
		local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)

		if not (result and ((result.Instance == value) or (result.Instance:IsDescendantOf(value)))) then
			if template:get() then
				result = template:get():GetPivot()
			else
				return
			end
		end

		local pos = (value:GetPivot():PointToObjectSpace(result.Position))
		sign = math.sign(pos[primaryAxis])
	end
	if not sign then
		return
	end

	endpoint:set(value)

	local s = p.Size[primaryAxis]
	local relPos = sign * (s) / 2

	local relCF = CFrame.new(Vector3.new(if primaryAxis == "X" then relPos else 0, 0, if primaryAxis == "Z" then relPos else 0), Vector3.new())

	controlPoint.CFrame = value:GetPivot():ToWorldSpace(relCF)

	isUpdatingControlPoint = false

	if addConnection then
		endpointConnection = p:GetPropertyChangedSignal("CFrame"):Connect(function()
			setEndpoint(value, sign)
		end)
	end
end

local isDraggingControlPoint = false

UserInputService.InputBegan:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and controlPoint then
		local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)
		local result = workspace:Raycast(ray.Origin, ray.Direction * 500)
		if result and result.Instance == controlPoint then
			isDraggingControlPoint = true
		end
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and isDraggingControlPoint then
		isDraggingControlPoint = false
	end
end)

local function setTemplate()
	ChangeHistoryService:SetWaypoint("Set template")
	local newSelection = template:get()
	if templateConnection then
		templateConnection:Disconnect()
		templateConnection = nil
	end
	if path and newSelection then
		if newSelection:IsA("BasePart") or newSelection:IsA("Model") then
			path.template = newSelection
			template:set(newSelection)
			highlights:addHighlight("Startpoint", newSelection)

			if not endpoint:get() then
				if controlPoint then
					controlPoint:Destroy()
				end
				controlPoint = assets.ControlPoint:Clone()
				controlPoint.Parent = workspace.Camera
				controlPoint.CFrame = getTemplateCf()
					* (path.length and CFrame.new(0, 0, -path.length) or CFrame.new(0, 0, -10))

				-- Reset when deleted
				controlPoint.AncestryChanged:Connect(function()
					if not controlPoint then
						return
					end
					isDraggingControlPoint = false
					if not controlPoint:IsDescendantOf(game) and path then
						controlPoint = nil
						previewPath()
					end
				end)

				-- Tell plugin to update path on changed

				controlPoint.Changed:Connect(function()
					if isDraggingControlPoint then
						return
					end
					pathChanged = true
					if not isUpdatingControlPoint then
						setEndpoint()
					end
				end)
			end

			templateConnection = newSelection.Changed:Connect(function()
				pathChanged = true
			end)

			-- Preview path
			previewPath(newSelection and path)
		else
			highlights:removeHighlight("Startpoint")
			template:set()
		end
	else
		highlights:removeHighlight("Startpoint")
		template:set()
	end
end

--Plugin activation and RenderStep update - update preview if any changes
do
	local lastUpdate = tick()

	local previewRefreshDelta = 0

	local MIN_STEP = 1 / 60

	local dragRayParams = RaycastParams.new()
	dragRayParams.FilterType = Enum.RaycastFilterType.Exclude
	dragRayParams.FilterDescendantsInstances = { workspace.CurrentCamera }

	pluginUtil:bindToActivate(function()
		path = Path.new()
		path.length = segmentLength:get()
		path.canting = cantAngle:get()
		path.primaryAxis = primaryAxis
		path.optimiseStraights = optimiseStraights
		path.swapEnd = reversePath:get()
	end)

	pluginUtil:bindToRenderStep(function(step: number)
		local s = tick()

		if tick() - lastUpdate < previewRefreshDelta then
			return
		end

		lastUpdate = s

		if template:get() and not template:get().Parent then
			template:set()
			setTemplate()
			resetPlugin()
		end

		if isDraggingControlPoint and controlPoint then --override default studio dragger to avoid any collisions with preview
			local ray = workspace.CurrentCamera:ScreenPointToRay(
				UserInputService:GetMouseLocation().X,
				UserInputService:GetMouseLocation().Y
			)
			local result = workspace:Raycast(ray.Origin, ray.Direction * 500, dragRayParams)
			if result then
				controlPoint.CFrame = controlPoint.CFrame
					+ result.Position
					- controlPoint.Position
					+ controlPoint.Size * result.Normal / 2
			end
			endpoint:set()
			pathChanged = true
		end

		if path and pathChanged then
			previewPath(path)
			pathChanged = false
		end

		local delta = tick() - s

		if delta * 4 > MIN_STEP then --Taking too long to run - decrease refresh rate
			previewRefreshDelta = delta * 8
		else
			previewRefreshDelta = 0
		end
	end)

	-- Cleanup on close
	pluginUtil:bindFnToClose(function()
		resetPlugin()
		template:set()
		setTemplate()
	end)

	plugin.Deactivation:Connect(function()
		pluginUtil:deactivate()
		template:set()
		setTemplate()
		resetPlugin()
	end)

	plugin.Unloading:Connect(function()
		pluginUtil:deactivate()
		template:set()
		setTemplate()
		resetPlugin()
	end)
end

-- Gui

pluginUtil:addElementToWidget({
	Type = "Instance",
	Key = "Track",
	DefaultValue = template,
	SelectingText = "Select Track Model",
	EmptyText = "No Track Selected",
	OnChange = function()
		Selection:Set({})
		setTemplate()
	end,
})

pluginUtil:addElementToWidget({
	Type = "Instance",
	Key = "Endpoint",
	DefaultValue = endpoint,
	SelectingText = "Select endpoint",
	EmptyText = "ControlPoint",
	OnChange = function(value) --When endpoint selected, set control point to endpoint
		Selection:Set({})
		setEndpoint(value)
	end,
})

pluginUtil:addSectionToWidget({
	Name = "Settings",
	Contents = {
		{
			Type = "Slider",
			Key = "Segment Length",
			Minimum = 1,
			Maximum = 100,
			DefaultValue = segmentLength,
			Unit = "Studs",
			OnChange = function(value)
				path.length = value
				pathChanged = true
			end,
		},
		{
			Type = "Slider",
			Key = "Bank Angle",
			Minimum = 0,
			Maximum = 20,
			DefaultValue = cantAngle,
			Unit = "Degrees",
			OnChange = function(value)
				path.canting = value
				pathChanged = true
			end,
		},
		{
			Type = "Boolean",
			Key = "Swap End",
			DefaultValue = reversePath,
			OnChange = function(value)
				pathChanged = true
				path.swapEnd = value
				if endpoint:get() then
					setEndpoint(endpoint:get())
					return
				end;
				controlPoint.CFrame = getTemplateCf():ToWorldSpace((path.length and CFrame.new(0, 0, -path.length) or CFrame.new(0, 0, -10)))
			end,
		},
		{
			Type = "Boolean",
			Key = "Use X Axis",
			DefaultValue = false,
			OnChange = function(value)
				pathChanged = true

				primaryAxis = if value then "X" else "Z"
				path.primaryAxis = primaryAxis
				if endpoint:get() then
					setEndpoint(endpoint:get())
					return
				end;
				controlPoint.CFrame = getTemplateCf():ToWorldSpace((path.length and CFrame.new(0, 0, -path.length) or CFrame.new(0, 0, -10)))
			end,
		},
		{
			Type = "Boolean",
			Key = "Optimise Straights",
			DefaultValue = optimiseStraights,
			OnChange = function(value)
				optimiseStraights = value
				path.optimiseStraights = value
				pathChanged = true
			end,
		},
		{
			Type = "Text",
			Text = gradeVal,
		}
	},
})

pluginUtil:addElementToWidget({
	Type = "Button",
	Text = "Select Control Point",
	OnClick = function()
		if controlPoint then
			Selection:Set({controlPoint})
		end
	end,
})

pluginUtil:addElementToWidget({
	Type = "Button",
	Text = "Render Path",
	OnClick = function()
		if controlPoint and path.template then
			isUpdatingControlPoint = true
			ChangeHistoryService:SetWaypoint("Render Path")
			previewPath()
			local folder = path:draw(getTemplateCf(), controlPoint.CFrame, true)
			local prevEndpoint = endpoint:get()
			local hadSelectedControlPoint = game.Selection:Get()[1] == controlPoint
			resetPlugin()
			path = Path.new()
			path.length = segmentLength:get()
			path.canting = cantAngle:get()
			path.optimiseStraights = optimiseStraights
			path.primaryAxis = primaryAxis
			path.swapEnd = reversePath:get()
			if prevEndpoint then
				template:set(prevEndpoint)
			else
				local tracks = folder:GetChildren()
				template:set(tracks[#tracks])
			end
			setEndpoint()
			isUpdatingControlPoint = false
			setTemplate()
			if hadSelectedControlPoint and controlPoint then
				Selection:Set({controlPoint})
			end
			ChangeHistoryService:SetWaypoint("Render Path")
		end
	end,
})
