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

return function(pluginUtil, i: number, elemData: Types.Property<number>)
	if not elemData.Maximum then
		elemData.Maximum = math.huge
	end
	if not elemData.Minimum then
		elemData.Minimum = -math.huge
	end
	if elemData.DefaultValue < elemData.Minimum or elemData.DefaultValue > elemData.Maximum then
		warn("Default value for property " .. elemData.Key .. " is out of range")
		return
	end
	local val = Value(elemData.DefaultValue)

	local textbox = nil

	local f = New("Frame")({
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
			New("TextBox")({
				Name = "Box",
				BackgroundColor3 = pluginUtil.CONFIG.accentColor,
				BorderSizePixel = 0,
				Text = Computed(function()
					return string.format(elemData.FormatString or "%.2f", val:get())
				end),
				PlaceholderText = elemData.Unit or tostring(elemData.DefaultValue),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 16,
				FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
				Size = UDim2.new(0.4, -2, 1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				[OnEvent("FocusLost")] = function(enterPresed)
					if enterPresed then
						local newVal = tonumber(textbox.Text)
						if newVal and (newVal ~= val:get()) then
							if newVal < elemData.Minimum then
								val:set(elemData.Minimum)
							elseif newVal > elemData.Maximum then
								val:set(elemData.Maximum)
							else
								val:set(newVal)
							end
							if elemData.OnChange then
								elemData.OnChange(val:get())
							end
						else
							textbox.Text = string.format(elemData.FormatString or "%.2f", val:get())
						end
					else
						textbox.Text = string.format(elemData.FormatString or "%.2f", val:get())
					end
				end,
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
	textbox = f.Box
	return f
end
