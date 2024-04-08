local fusion = require(script.Parent.Parent.Parent.getFusion)

local New = fusion.New
local Children = fusion.Children
local OnEvent = fusion.OnEvent
local Value = fusion.Value
local Computed = fusion.Computed
local ForPairs = fusion.ForPairs
local ForValues = fusion.ForValues
local Spring = fusion.Spring
local OnChange = fusion.OnChange

return function(pluginUtil)
	return New("Frame")({
		Name = "InstanceTree",
		Parent = pluginUtil.data.widget,
		Size = UDim2.new(1, 0, 1, 0),
		Position = Computed(function()
			local s = 1 - pluginUtil.data.UISpring:get()
			return UDim2.new(s, 10 * s, 0, 0)
		end),
		BackgroundTransparency = 1,
		[Children] = {
			New("UICorner")({
				CornerRadius = UDim.new(0, 4),
			}),
			New("UIPadding")({
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			New("TextLabel")({
				Name = "Header",
				BackgroundTransparency = 1,
				Text = "",
				TextSize = 18,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
				Size = UDim2.new(1, 0, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				[Children] = {
					New("UIPadding")({
						PaddingLeft = UDim.new(0, 28),
					}),
				},
			}),
			New("ImageButton")({
				Name = "Back",
				BackgroundTransparency = 1,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				Image = "rbxassetid://13642210590",
				Size = UDim2.new(0, 16, 0, 16),
				Position = UDim2.new(0, 12, 0, 12),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = 225,
				[OnEvent("Activated")] = function()
					pluginUtil.data.currentUI:set(0)
				end,
			}),
			New("TextLabel")({
				Name = "Source",
				BackgroundTransparency = 1,
				Text = "",
				TextSize = 14,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
				Size = UDim2.new(1, 4, 0, 18),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				Position = UDim2.new(0, 0, 0, 26),
				TextXAlignment = Enum.TextXAlignment.Left,
				[Children] = {
					New("UIPadding")({
						PaddingLeft = UDim.new(0, 4),
					}),
				},
			}),
			New("ScrollingFrame")({
				Name = "Scroll",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 0,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				Size = UDim2.new(1, 0, 1, -48),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				[Children] = {
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.Name,
						Padding = UDim.new(0, 8),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),
					New("UIPadding")({
						PaddingLeft = UDim.new(0, 2),
						PaddingRight = UDim.new(0, 2),
						PaddingTop = UDim.new(0, 2),
						PaddingBottom = UDim.new(0, 2),
					}),
				},
			}),
		},
	})
end
