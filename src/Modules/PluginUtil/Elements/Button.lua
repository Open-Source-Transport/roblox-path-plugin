local fusion = require(script.Parent.Parent.getFusion)
local Types = require(script.Parent.Parent.Types)

local New = fusion.New
local Children = fusion.Children
local OnEvent = fusion.OnEvent

return function(pluginUtil, i: number, elemData: Types.Button)
	return New("TextButton")({
		Name = i,
		LayoutOrder = i,
		BackgroundColor3 = pluginUtil.CONFIG.accentColor,
		BorderSizePixel = 0,
		Text = elemData.Text or "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 16,
		FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
		Size = UDim2.new(1, 0, 0, 24),
		[OnEvent("MouseEnter")] = function()
			pluginUtil.tooltip.hoverTip = elemData.Tooltip
		end,
		[OnEvent("MouseLeave")] = function()
			pluginUtil.tooltip.hoverTip = nil
		end,
		[OnEvent("Activated")] = elemData.OnClick,
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
