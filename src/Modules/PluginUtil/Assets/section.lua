local fusion = require(script.Parent.Parent.getFusion)

local New = fusion.New
local Children = fusion.Children
local OnEvent = fusion.OnEvent
local Value = fusion.Value
local Computed = fusion.Computed
local Spring = fusion.Spring
local OnChange = fusion.OnChange

return function(self, index, SectionLayout, children)
	local isSectionActive = Value(0)
	local sectionSpring = Spring(isSectionActive, 40, 1)
	local contentSize = Value(20)

	return New("Frame")({
		Parent = self.data.widget.Scroll,
		LayoutOrder = index,
		Name = "Section" .. tostring(index),
		BackgroundTransparency = 1,
		Size = Computed(function()
			return UDim2.new(1, 0, 0, 28 + sectionSpring:get() * (contentSize:get() - 20))
		end),
		ClipsDescendants = true,
		[Children] = {
			New("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Top,
				[OnChange("AbsoluteContentSize")] = function(size)
					contentSize:set(size.Y + 0.5)
				end,
			}),
			New("UICorner")({
				CornerRadius = UDim.new(0, 4),
			}),
			New("UIPadding")({
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			New("UIStroke")({
				Color = Color3.fromRGB(150, 150, 150),
				Transparency = 0.5,
				Thickness = 1,
			}),
			New("TextButton")({
				Name = "Header",
				BackgroundTransparency = 1,
				Text = SectionLayout.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
				Size = UDim2.new(1, 0, 0, 20),
				[Children] = {
					New("ImageLabel")({
						Name = "ExpandedTriangle",
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 12, 0, 12),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0, -12, 0.5, 0),
						ClipsDescendants = true,
						ImageColor3 = Color3.fromRGB(255, 255, 255),
						Image = "rbxassetid://13642210590",
						Rotation = Computed(function()
							return 45 + sectionSpring:get() * 90
						end),
					}),
					New("UIPadding")({
						PaddingLeft = UDim.new(0, 24),
					}),
				},
				[OnEvent("Activated")] = function()
					isSectionActive:set(1 - isSectionActive:get())
				end,
			}),
			children,
		},
	})
end
