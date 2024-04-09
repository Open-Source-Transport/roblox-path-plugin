-- Plugin.server.lua
-- The main script for the plugin
-- Authors: Anthony O'Brien

-- Services
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")
local UserInputService = game:GetService("UserInputService")

-- Constants
local PREVIEW_REFRESH_RATE = 1 / 15
local MAX_GRADIENT = 2000
local TOOLBAR_NAME = "anthony0br/roblox-path-plugin"

-- Modules
local modules = script.Parent.Modules
local packages = script.Parent.Packages
local Path = require(modules.Path)
local CreateAssets = require(modules.CreateAssets)
local pluginUtil = require(modules.PluginUtil)
local fusion = require(packages.fusion)
local Types = require(modules.Types)
local highlights = require(modules.Highlights)

local Value = fusion.Value

-- Initialise plugin

pluginUtil:init(plugin:CreateToolbar(pluginUtil.CONFIG.toolbarName), plugin:CreateDockWidgetPluginGui(pluginUtil.CONFIG.pluginId, pluginUtil.CONFIG.widgetInfo))

plugin.Deactivation:Connect(function()
	pluginUtil:deactivate()
end)

plugin.Unloading:Connect(function()
	pluginUtil:deactivate()
end)

local assets = CreateAssets()

local pathChanged
local controlPoint
local path
local isUpdatingControlPoint = false

local gradeVal = Value("Flat")
local segmentLength = Value(20)
local cantAngle = Value(0)
local template = Value()
local endpoint = Value()
local endpointConnection: RBXScriptConnection

-- Functions

local function getTemplateCf()
	local templateLength = path.template:IsA("BasePart") and path.template.Size.Z or path.template:GetExtentsSize().Z
	local toEdge = CFrame.new(0, 0, -0.5 * templateLength)
	return path.template
		and (path.template:IsA("BasePart") and path.template.CFrame * toEdge or path.template:GetBoundingBox() * toEdge)
end

local function getGradientValue(curve)
	curve = curve:GetChildren()
	local length = 0
	for i, v in pairs(curve) do
		if v:IsA("BasePart") then
			length = length + v.Size.Z
		elseif v:IsA("Model") then
			local cf, size = v:GetBoundingBox()
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
			for i, v in pairs(preview:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("Decal") then
					v.LocalTransparencyModifier = 0.5
					if v:IsA("BasePart") then
						v.Locked = true
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
end

resetPlugin()

local function setEndpoint(value: Instance, sign: number?)
	highlights:removeHighlight("Endpoint")
	if endpointConnection then
		endpointConnection:Disconnect()
	end
	if not (value and controlPoint) then endpoint:set() return end
	local addConnection = value == endpoint:get()
	local p: nil
	isUpdatingControlPoint = true
	if value:IsA("Model") then
		local maxSize = 0
		for _, c in pairs(value:GetDescendants()) do
			if c:IsA("BasePart") and c.Size.Z > maxSize then
				p = c
				maxSize = c.Size.Z
				break
			end
		end
		if maxSize == 0 then endpoint:set() return end
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

		sign = math.sign(value:GetPivot():PointToObjectSpace(result.Position).Z)
	end

	local relPos = sign * p.Size.Z / 2

	local relCF = CFrame.new(Vector3.new(0, 0, relPos), Vector3.new())
	
	controlPoint.CFrame = value:GetPivot():ToWorldSpace(relCF)

	isUpdatingControlPoint = false

	if addConnection then
		endpointConnection = p:GetPropertyChangedSignal("CFrame"):Connect(function()
			setEndpoint(value, sign)
		end)
	end
end

local function setTemplate()
	ChangeHistoryService:SetWaypoint("Set template")
	local newSelection = template:get()
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
					if not controlPoint:IsDescendantOf(game) and path then
						controlPoint = nil
						template:set(nil)
						previewPath()
					end
				end)

				-- Tell plugin to update path on changed
				controlPoint.Changed:Connect(function()
					pathChanged = true
					if not isUpdatingControlPoint then
						setEndpoint()
					end
				end)
			end

			-- Preview path
			previewPath(newSelection and path)
		else
			highlights:removeHighlight("Startpoint")
			template:set(nil)
		end
	else
		highlights:removeHighlight("Startpoint")
		template:set(nil)
	end
end

--Plugin activation / deactivation

pluginUtil:bindToActivate(function()
	path = Path.new()
	path.length = segmentLength:get()
	path.canting = cantAngle:get()

	spawn(function()
		while path do
			if pathChanged then
				previewPath(path)
				pathChanged = false
			end
			wait(PREVIEW_REFRESH_RATE)
		end
	end)
end)

-- Cleanup before PluginGui closed
pluginUtil:bindFnToClose(function()
	resetPlugin()
end)

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
	end
})

pluginUtil:addSectionToWidget({
	Name = "Settings",
	Contents = {
		{
			Type = "Slider",
			Key = "Segment Length",
			Minimum = 1,
			Maximum = 100,
			DefaultValue = 20,
			Unit = "Studs",
			OnChange = function(value)
				path.length = value
				segmentLength:set(value)
				pathChanged = true
			end,
		},
		{
			Type = "Slider",
			Key = "Bank Angle",
			Minimum = 0,
			Maximum = 20,
			DefaultValue = 0,
			Unit = "Degrees",
			OnChange = function(value)
				path.canting = value
				cantAngle:set(value)
				pathChanged = true
			end,
		},
		{
			Type = "Text",
			Text = gradeVal,
		},
	},
})

pluginUtil:addElementToWidget({
	Type = "Button",
	Text = "Render Path",
	OnClick = function()
		if controlPoint and path.template then
			ChangeHistoryService:SetWaypoint("Render Path")
			previewPath()
			local folder = path:draw(getTemplateCf(), controlPoint.CFrame, true)
			path.template = nil
			local prevEndpoint = endpoint:get()
			resetPlugin()
			path = Path.new()
			path.length = segmentLength:get()
			path.canting = cantAngle:get()
			if prevEndpoint then
				template:set(prevEndpoint)
			else
				local tracks = folder:GetChildren()
				template:set(tracks[#tracks])
			end
			setEndpoint()
			setTemplate()
			ChangeHistoryService:SetWaypoint("Render Path")
		end
	end,
})