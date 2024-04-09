local fusion = require(script.Parent.Parent.getFusion)

local New = fusion.New
local Children = fusion.Children

return function(pluginUtil, position)
	return New("TextLabel")({
		Parent = pluginUtil.data.widget,
		Name = "Tooltip",
		ZIndex = 5,
		BackgroundColor3 = Color3.fromRGB(100, 100, 100),
		BorderSizePixel = 0,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		TextWrapped = true,
		Text = pluginUtil.hoverTip,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
		Position = UDim2.new(0, position.X, 0, position.Y + 8),
		AnchorPoint = Vector2.new(0.5, 0),
		ClipsDescendants = true,
		[Children] = {
			New("UIPadding")({
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			New("UICorner")({
				CornerRadius = UDim.new(0, 4),
			}),
			New("UISizeConstraint")({
				MaxSize = Vector2.new(150, 60),
			}),
			New("Frame")({
				Name = "Arrow",
				BackgroundColor3 = Color3.fromRGB(100, 100, 100),
				BorderSizePixel = 0,
				Size = UDim2.new(0, 12, 0, 12),
				Position = UDim2.new(0.5, 0, 0, -4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = 45,
			}),
		},
	})
end
