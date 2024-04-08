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

return function(pluginUtil, i: number, elemData: Types.Checklist)
	return New("Frame")({
		Name = i,
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 24),
		AutomaticSize = Enum.AutomaticSize.Y,
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
				Text = elemData.Header,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
				Size = UDim2.new(1, 0, 0, 24),
				Position = UDim2.new(0, 0, 0, 0),
				[Children] = {
					New("UIPadding")({
						PaddingLeft = UDim.new(0, 4),
					}),
				},
			}),
			New("Frame")({
				Name = "Checklist",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 24),
				AnchorPoint = Vector2.new(0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = {
					New("UIListLayout")({
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.Name,
						Padding = UDim.new(0, 4),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),
					New("UIPadding")({
						PaddingBottom = UDim.new(0, 4),
					}),
					Computed(function()
						local options = elemData.Options:get()
						local states = {}
						for _, v in pairs(options) do
							if elemData.DefaultValues then
								states[v] = Value(1)
							else
								states[v] = Value(0)
							end
						end

						local function updateValue()
							if elemData.OnChange then
								local returnData = {}
								for k, v in pairs(states) do
									returnData[k] = v:get() == 1
								end
								elemData.OnChange(returnData)
							end
						end

						updateValue()

						return ForPairs(states, function(opt, state)
							local spring = Spring(state, 20, 1)
							return opt,
								New("Frame")({
									Name = opt,
									BackgroundTransparency = 1,
									Size = UDim2.new(1, -8, 0, 24),
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
											Text = opt,
											TextColor3 = Color3.fromRGB(255, 255, 255),
											TextSize = 16,
											TextXAlignment = Enum.TextXAlignment.Left,
											FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
											Size = UDim2.new(1, -28, 1, 0),
											[Children] = {
												New("UIPadding")({
													PaddingLeft = UDim.new(0, 4),
												}),
											},
										}),
										New("TextButton")({
											Position = UDim2.new(1, 0, 0, 0),
											Size = UDim2.new(0, 24, 0, 24),
											AnchorPoint = Vector2.new(1, 0),
											BackgroundColor3 = pluginUtil.CONFIG.accentColor,
											BorderSizePixel = 0,
											[Children] = {
												New("UICorner")({
													CornerRadius = UDim.new(0, 4),
												}),
												New("Frame")({
													Size = Computed(function()
														local s = spring:get()
														return UDim2.new(0, 8 + 9 * (1 - s), 0, 4)
													end),
													Position = Computed(function()
														local s = spring:get()
														return UDim2.new(0.5 * (1 - s), 8 * s, 0.5 + 0.2 * s, 0)
													end),
													AnchorPoint = Vector2.new(0.5, 0.5),
													Rotation = 45,
													BackgroundColor3 = Color3.fromRGB(255, 255, 255),
													BorderSizePixel = 0,
												}),
												New("Frame")({
													Size = UDim2.new(0, 17, 0, 4),
													Position = Computed(function()
														local s = spring:get()
														return UDim2.new(0.5 * (1 - s), 16 * s, 0.5, 0)
													end),
													AnchorPoint = Vector2.new(0.5, 0.5),
													Rotation = -45,
													BackgroundColor3 = Color3.fromRGB(255, 255, 255),
													BorderSizePixel = 0,
												}),
											},
											[OnEvent("Activated")] = function()
												state:set(1 - state:get())
												updateValue()
											end,
										}),
									},
								})
						end, fusion.PairDestructor):get()
					end),
				},
			}),
		},
	})
end
