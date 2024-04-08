-- Plugin.server.lua
-- The main script for the plugin
-- Authors: Anthony O'Brien

-- Services
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local PluginGuiService = game:GetService("PluginGuiService")
local Selection = game:GetService("Selection")

-- Constants
local PREVIEW_REFRESH_RATE = 1/15
local MAX_GRADIENT = 2000
local TOOLBAR_NAME = "anthony0br/roblox-path-plugin"

-- Modules
local modules = script.Parent.Modules
local Path = require(modules.Classes.Path)
local CreateAssets = require(modules.CreateAssets)

-- Initialise plugin
local plugin = plugin -- fix intellisense
local pluginGui = PluginGuiService:FindFirstChild("anthony0br/roblox-path-plugin") or
	plugin:CreateDockWidgetPluginGui(
		"anthony0br/roblox-path-plugin",
		DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 260, 280, 260, 280)
	)
pluginGui.Title = "anthony0br/roblox-path-plugin"
pluginGui.Name = "anthony0br/roblox-path-plugin"
local assets = CreateAssets()
assets.Parent = script.Parent
if not pluginGui:FindFirstChild("Gui") then
	assets.Gui:Clone().Parent = pluginGui
end
local gui = pluginGui.Gui
local pathChanged
local controlPoint
local path

-- Functions

local function getTemplateCf()
	local templateLength = path.template:IsA("BasePart") and path.template.Size.Z or path.template:GetExtentsSize().Z
	local toEdge = CFrame.new(0, 0, -0.5 * templateLength)
	return path.template and (path.template:IsA("BasePart") and path.template.CFrame * toEdge 
		or path.template:GetBoundingBox() * toEdge)
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
	if (startSegment:IsA("Model") or startSegment:IsA("BasePart")) 
	and (endSegment:IsA("Model") or endSegment:IsA("BasePart")) then
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
	if workspace.CurrentCamera:FindFirstChild("TrackPreview") then
		workspace.CurrentCamera.TrackPreview:Destroy()
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
		gui.Gradient.Text = grade
		if preview then
			for i, v in pairs(preview:GetDescendants()) do
				if v:IsA("BasePart") or v:IsA("Decal") then
					v.LocalTransparencyModifier = 0.5
					if v:IsA("BasePart") then
						v.Locked = true
					end
				end
			end
			preview.Name = "TrackPreview"
			preview.Parent = workspace.CurrentCamera
		end
	end
end

-- Resets the plugin
local function resetPlugin()
	if controlPoint then
		controlPoint:Destroy()
	end
	gui.Gradient.Text = "Flat"
end

local function setTemplate(template)
	ChangeHistoryService:SetWaypoint("Set template")
	local newSelection = template
	if path and not newSelection or newSelection:IsA("BasePart") or newSelection:IsA("Model") then
		gui.CurrentSelection.Text = newSelection and "Selected: " .. newSelection.Name or "Selected: None"
		path.template = newSelection
		if controlPoint then
			controlPoint:Destroy()
		end
		controlPoint = assets.ControlPoint:Clone()
		controlPoint.Parent = workspace.Camera
		controlPoint.CFrame = getTemplateCf()
		* (path.length and CFrame.new(0, 0, -path.length) or CFrame.new(0, 0, -10)) 
		
		-- Reset when deleted
		controlPoint.AncestryChanged:Connect(function()
			if not controlPoint:IsDescendantOf(game) and path then
				controlPoint = nil
				gui.CurrentSelection.Text = "Selected: None"
				previewPath()
			end
		end)
		
		-- Tell plugin to update path on changed
		controlPoint.Changed:Connect(function()
			pathChanged = true
		end)
		
		-- Preview path
		previewPath(newSelection and path)
	end
end

-- Create toolbar button and open PluginGui on click
plugin:CreateToolbar(TOOLBAR_NAME):CreateButton("Track Placer", "Lay some track", "").Click:Connect(function()
	pluginGui.Enabled = true
	path = Path.new()
	path.length = gui.Length.TextBox.Text
	path.canting = gui.Canting.TextBox.Text
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
pluginGui:BindToClose(function()
	pluginGui.Enabled = false
	resetPlugin()
end)

-- Gui events
do
	-- CreateButton clicked
	gui.CreateButton.MouseButton1Down:Connect(function()
		if controlPoint and path.template then
			ChangeHistoryService:SetWaypoint("Create track")
			previewPath()
			local folder = path:draw(getTemplateCf(), controlPoint.CFrame, true)
			path.template = nil
			resetPlugin()
			path = Path.new()
			path.length = gui.Length.TextBox.Text
			path.canting = gui.Canting.TextBox.Text
			local tracks = folder:GetChildren()
			setTemplate(tracks[#tracks])
		end
	end)
	
	-- Update TextBoxes on FocusLost
	gui.Length.TextBox.FocusLost:Connect(function()
		path.length = gui.Length.TextBox.Text
		previewPath(path)
	end)
	gui.Canting.TextBox.FocusLost:Connect(function()
		path.canting = gui.Canting.TextBox.Text
		previewPath(path)
	end)
	
	-- Update template
	gui.SetTemplateButton.MouseButton1Down:Connect(function()
		setTemplate(Selection:Get()[1])
	end)
end
