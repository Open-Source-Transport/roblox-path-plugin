--PluginUtil.lua
--A utility to make working with plugins easier, providing standardised UI elements
--Author: roblox: @ARandomAtom github: @arandomollie

local RUS = game:GetService("RunService")

--Fusion functions
local fusion = require(script.getFusion)

local Types = require(script.Types)

local Value = fusion.Value
local Spring = fusion.Spring

return {

	data = {
		RSFunctions = {},
		closeFunctions = {},
		activeTab = nil,
		toolbar = nil,
		widget = nil,
		activeToggle = Value(nil),
		deactivateFn = nil,
		onDeactivate = {},
		onActivate = {},
		mouseDown = false,
		frame = nil,
	},

	CONFIG = require(script.CONFIG),

	cleanup = function(self)
		for _, f in pairs(self.data.closeFunctions) do
			f()
		end
		RUS:UnbindFromRenderStep(self.CONFIG.pluginId .. "RSUpdates")
		--[[for _, c in pairs(game.CoreGui:GetChildren()) do
            if c.Name == "TrackPlugin" then
                c:Destroy()
            end
        end]]
	end,

	bindFnToClose = function(self, fn)
		table.insert(self.data.closeFunctions, fn)
	end,

	deactivate = function(self)
		for _, f in pairs(self.data.onDeactivate) do
			f()
		end
		RUS:UnbindFromRenderStep(self.CONFIG.pluginId .. "RSUpdates")
	end,

	bindToActivate = function(self, fn)
		table.insert(self.data.onActivate, fn)
		if self.data.widget and self.data.widget.Enabled then
			fn()
		end
	end,

	bindToPluginInputBegan = function(self, fn)
		if self.data.frame then
			self.data.frame.InputBegan:Connect(fn)
		end
	end,

	bindToPluginInputChanged = function(self, fn)
		if self.data.frame then
			self.data.frame.InputChanged:Connect(fn)
		end
	end,

	bindToPluginInputEnded = function(self, fn)
		if self.data.frame then
			self.data.frame.InputEnded:Connect(fn)
		end
	end,

	init = function(self, toolbar, widget)
		self:cleanup()
		
		self:bindToActivate(function()
			RUS:BindToRenderStep(self.CONFIG.pluginId .. "RSUpdates", 151, function(step)
				for i = #self.data.RSFunctions, 1, -1 do
					local s, e = pcall(self.data.RSFunctions[i], step)
					if not s then
						warn("[PluginUtil] Error executing RenderStepped update: " .. e)
						table.remove(self.data.RSFunctions, i)
					end
				end
			end)
		end)

		self.data.toolbar = toolbar

		local toolbarButton = self.data.toolbar:CreateButton(
			self.CONFIG.toolbarButton.Name,
			self.CONFIG.toolbarButton.Tooltip,
			self.CONFIG.toolbarButton.Image,
			self.CONFIG.toolbarButton.Text
		)

		toolbarButton.Click:Connect(function()
			widget.Enabled = not widget.Enabled
		end)

		self.data.currentUI = Value(0)

		self.data.UISpring = Spring(self.data.currentUI, 20, 1)

		toolbarButton:SetActive(widget.Enabled)

		do
			local function widgetEnabledUpdate()
				toolbarButton:SetActive(widget.Enabled)
				self.data.currentUI:set(0)
				if not widget.Enabled then
					for _, f in pairs(self.data.closeFunctions) do
						f()
					end
				else
					for _, f in pairs(self.data.onActivate) do
						f()
					end
				end
			end

			widget:GetPropertyChangedSignal("Enabled"):Connect(widgetEnabledUpdate)

			widgetEnabledUpdate()
		end

		widget.Title = self.CONFIG.widgetTitle

		self.data.widget = widget

		self.data.frame = require(script.Assets.base)(self)

		self.instanceTree.frame = require(script.Assets.InstanceTree.base)(self)

		self.instanceTree.data = self.data

		self.tooltip.data = self.data

		self.instanceTree.frame.Source:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			self.instanceTree.frame.Scroll.Size =
				UDim2.new(1, 0, 1, -(30 + self.instanceTree.frame.Source.AbsoluteSize.Y))
		end)

		self:bindToRenderStep(function()
			self.tooltip:tooltipRenderStepUpdate()
		end)

		table.insert(self.data.onDeactivate, function()
			self.data.activeToggle:set()
		end)
	end,

	bindToRenderStep = function(self, fn)
		table.insert(self.data.RSFunctions, fn)
	end,

	instanceTree = {

		data = {},

		CONFIG = require(script.CONFIG),

		frame = nil,

		addChild = require(script.Assets.InstanceTree.child),

		processFolder = require(script.Assets.InstanceTree.folder),

		hydrate = function(self, title, source, instanceType, recursive, state, callback)
			self:cleanup()

			self.frame.Header.Text = title

			do
				local parents = {}

				local cParent = source

				while cParent and (cParent ~= game) do
					table.insert(parents, 1, cParent.Name)
					cParent = cParent.Parent
				end

				self.frame.Source.Text = table.concat(parents, " / ")
			end

			for _, c in pairs(source:GetChildren()) do
				if c:IsA("Folder") then
					if recursive then
						self:processFolder(c, self.frame.Scroll, instanceType, state, callback)
					end
				elseif c:IsA(instanceType) then
					self:addChild(c, self.frame.Scroll, state, callback)
				end
			end
		end,

		cleanup = function(self)
			for _, c in pairs(self.frame.Scroll:GetChildren()) do
				if c:IsA("Frame") or c:IsA("TextButton") then
					c:Destroy()
				end
			end

			self.frame.Header.Text = ""
			self.frame.Source.Text = ""
		end,
	},

	tooltip = {

		data = {},

		hoverTip = nil,

		tooltip = nil,

		displayTooltip = function(self)
			if not self.hoverTip then
				return
			end

			self:cleanup()

			local position = self.data.widget:GetRelativeMousePosition()

			self.tooltip = require(script.Assets.tooltip)(self, position)
		end,

		lastMousePos = Vector2.new(),

		lastMouseMove = tick(),

		tooltipRenderStepUpdate = function(self)
			local pos = self.data.widget:GetRelativeMousePosition()
			local size = self.data.widget.AbsoluteSize
			if
				((pos - self.lastMousePos).Magnitude < 5)
				and (pos.X > 0 and pos.Y > 0 and pos.X < size.X and pos.Y < size.Y)
			then
				if not self.tooltip and (tick() - self.lastMouseMove) > 1 then
					self:displayTooltip()
				end
			else
				self.lastMouseMove = tick()
				self.lastMousePos = pos
				self:cleanup()
			end
		end,

		cleanup = function(self)
			if self.tooltip then
				self.tooltip:Destroy()
				self.tooltip = nil
			end
		end,
	},

	addSectionToWidget = function(self, SectionLayout: Types.SectionLayout, index: number?)
		local children = {}

		for i, elemData in pairs(SectionLayout.Contents) do
			if script.Elements:FindFirstChild(elemData.Type) then
				table.insert(children, require(script.Elements:FindFirstChild(elemData.Type))(self, i, elemData))
			end
		end

		if #children == 0 then
			warn("No children for section " .. SectionLayout.Name .. ": not rendering")
		end

		return require(script.Assets.section)(self, index or #self.data.frame:GetChildren(), SectionLayout, children)
	end,

	addElementToWidget = function(self, elemData: Types.Element, index: number?)
		if script.Elements:FindFirstChild(elemData.Type) then
			local f = require(script.Elements:FindFirstChild(elemData.Type))(
				self,
				index or #self.data.frame:GetChildren(),
				elemData
			)
			f.Parent = self.data.frame
			return f
		else
			warn("No element for type " .. elemData.Type .. ": not rendering")
			return
		end
	end,
}
