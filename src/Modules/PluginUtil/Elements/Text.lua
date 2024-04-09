local fusion = require(script.Parent.Parent.getFusion)
local Types = require(script.Parent.Parent.Types)

local New = fusion.New
local Children = fusion.Children
local OnEvent = fusion.OnEvent
local Value = fusion.Value
local Computed = fusion.Computed

return function(pluginUtil, i: number, elemData: Types.Text)
	local val

	if not elemData.Text then
		return
	end

	if typeof(elemData.Text) == "table" and elemData.Text.get then
		val = elemData.Text
	elseif typeof(elemData.Text) == "string" then
		val = Value(elemData.Text)
	end

	if elemData.Key then
		return New("Frame")({
			Name = i,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			[OnEvent("MouseEnter")] = function()
				pluginUtil.tooltip.hoverTip = elemData.Tooltip
			end,
			[OnEvent("MouseLeave")] = function()
				pluginUtil.tooltip.hoverTip = nil
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
				New("TextLabel")({
					Name = "Label",
					BackgroundTransparency = 1,
					Text = elemData.Key,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
					Size = UDim2.new(0.6, -2, 1, 0),
					[Children] = {
						New("UIPadding")({
							PaddingLeft = UDim.new(0, 4),
						}),
					},
				}),
				New("UISizeConstraint")({
					MinSize = Vector2.new(0, 24),
				}),
				New("TextLabel")({
					BackgroundColor3 = pluginUtil.CONFIG.accentColor,
					BorderSizePixel = 0,
					Text = Computed(function()
						return val:get()
					end),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 16,
					FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
					Size = UDim2.new(0.4, -2, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					[Children] = {
						New("UIPadding")({
							PaddingLeft = UDim.new(0, 8),
						}),
						New("UICorner")({
							CornerRadius = UDim.new(0, 4),
						}),
					},
				}),
			},
		})
	else
		return New("TextLabel")({
			Name = i,
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = Computed(function()
				return val:get()
			end),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
			[OnEvent("MouseEnter")] = function()
				pluginUtil.tooltip.hoverTip = elemData.Tooltip
			end,
			[OnEvent("MouseLeave")] = function()
				pluginUtil.tooltip.hoverTip = nil
			end,
			[Children] = {
				New("UIPadding")({
					PaddingLeft = UDim.new(0, 8),
				}),
			},
		})
	end
end
