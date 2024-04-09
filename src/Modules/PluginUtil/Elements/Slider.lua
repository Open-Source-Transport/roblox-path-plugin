local fusion = require(script.Parent.Parent.getFusion)
local Types = require(script.Parent.Parent.Types)

local New = fusion.New
local Children = fusion.Children
local OnEvent = fusion.OnEvent
local Value = fusion.Value
local Computed = fusion.Computed

return function(pluginUtil, i: number, elemData: Types.Property<number>)
	if not (elemData.Maximum and elemData.Minimum) then
		return
	end
	local val
	if elemData.DefaultValue and typeof(elemData.DefaultValue) == "table" and elemData.DefaultValue.get then
		val = elemData.DefaultValue
	else
		val = Value(elemData.DefaultValue or 0)
	end

	if val:get() < elemData.Minimum or val:get() > elemData.Maximum then
		warn("Default value for property " .. elemData.Key .. " is out of range")
		return
	end

	local textbox = nil
	local f: Frame

	f = New("Frame")({
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		[OnEvent("MouseEnter")] = function()
			pluginUtil.tooltip.hoverTip = elemData.Tooltip
		end,
		[OnEvent("MouseLeave")] = function()
			pluginUtil.tooltip.hoverTip = nil
			pluginUtil.data.mouseDown = false
		end,
		[OnEvent("InputBegan")] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				pluginUtil.data.mouseDown = true
			end
		end,
		[OnEvent("InputEnded")] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				pluginUtil.data.mouseDown = false
			end
		end,
		[OnEvent("InputChanged")] = function(input)
			if (input.UserInputType == Enum.UserInputType.MouseMovement) and pluginUtil.data.mouseDown then
				local x = input.Position.X
				local pos = f.AbsolutePosition
				local size = f.AbsoluteSize
				local relX = math.clamp((x - pos.X - 8) / (size.X - 16), 0, 1)
				val:set(elemData.Minimum + (elemData.Maximum - elemData.Minimum) * relX)
				if elemData.OnChange then
					elemData.OnChange(val:get())
				end
			end
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
				Font = Enum.Font.GothamBold,
				Size = UDim2.new(0.6, -2, 0, 24),
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
				Font = Enum.Font.GothamBold,
				Size = UDim2.new(0.4, -2, 0, 20),
				Position = UDim2.new(1, -2, 0, 2),
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
			New("Frame")({
				Name = "Slider",
				BackgroundColor3 = pluginUtil.CONFIG.accentColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, -16, 0, 4),
				Position = UDim2.new(0.5, 0, 0, 34),
				AnchorPoint = Vector2.new(0.5, 0.5),
				[Children] = {
					New("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),
					New("Frame")({
						Name = "Fill",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.new(0, 8, 0, 8),
						Position = Computed(function()
							return UDim2.new(
								(val:get() - elemData.Minimum) / (elemData.Maximum - elemData.Minimum),
								0,
								0.5,
								0
							)
						end),
						[Children] = {
							New("UICorner")({
								CornerRadius = UDim.new(1, 0),
							}),
						},
					}),
				},
			}),
		},
	})
	textbox = f:FindFirstChild("Box")
	return f
end
