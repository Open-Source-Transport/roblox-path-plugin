local fusion = require(script.Parent.Parent.getFusion)
local Types = require(script.Parent.Parent.Types)

local New = fusion.New
local Children = fusion.Children
local OnEvent = fusion.OnEvent
local Value = fusion.Value
local Computed = fusion.Computed
local ForPairs = fusion.ForPairs
local ForValues = fusion.ForValues
local Spring = fusion.Spring
local OnChange = fusion.OnChange

return function(pluginUtil, i: number, elemData: Types.ToggleButton)
	if elemData.Deactivate then
		table.insert(pluginUtil.data.onDeactivate, elemData.Deactivate)
	end
	return New("TextButton")({
		Name = i,
		LayoutOrder = i,
		BackgroundColor3 = Computed(function()
			if pluginUtil.data.activeToggle:get() == elemData.Text then
				local h, s, v = pluginUtil.CONFIG.accentColor:ToHSV()
				return Color3.fromHSV(h, s, v - 0.25)
			else
				return pluginUtil.CONFIG.accentColor
			end
		end),
		BorderSizePixel = 0,
		Text = elemData.Text or "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
		Size = UDim2.new(1, 0, 0, 24),
		[OnEvent("MouseEnter")] = function()
			pluginUtil.hoverTip = elemData.Tooltip
		end,
		[OnEvent("MouseLeave")] = function()
			pluginUtil.hoverTip = nil
		end,
		[OnEvent("Activated")] = function()
			if pluginUtil.data.activeToggle:get() == elemData.Text then
				if pluginUtil.data.deactivateFn then
					pluginUtil.data.deactivateFn()
				end
				pluginUtil.data.activeToggle:set()
				return
			end
			script.Parent.Parent.ActivatePlugin:Fire()
			pluginUtil.data.activeToggle:set(elemData.Text)
			if pluginUtil.data.deactivateFn then
				pluginUtil.data.deactivateFn()
			end
			if elemData.Activate then
				elemData.Activate()
			end
			pluginUtil.data.deactivateFn = elemData.Deactivate
		end,
		[Children] = {
			New("UIStroke")({
				Color = Color3.fromRGB(150, 150, 150),
				Transparency = 0.5,
				Thickness = 1,
			}),
			New("UICorner")({
				CornerRadius = UDim.new(0, 4),
			}),
		},
	})
end
