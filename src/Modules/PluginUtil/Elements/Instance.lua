local fusion = require(script.Parent.Parent.getFusion)
local Types = require(script.Parent.Parent.Types)

local New = fusion.New;
local Children = fusion.Children;
local OnEvent = fusion.OnEvent;
local Value = fusion.Value;
local Computed = fusion.Computed;
local OnChange = fusion.OnChange;

local currentActive = Value{
    Value = nil,
    OnChange = nil
};

game.Selection.SelectionChanged:Connect(function()
    task.wait()
    if currentActive:get().Value and #game.Selection:Get() == 1 then
        currentActive:get().Value:set(game.Selection:Get()[1])
        if currentActive:get().OnChange then
            currentActive:get().OnChange(currentActive:get().Value:get())
        end

        currentActive:set{
            Value = nil,
            OnChange = nil
        }
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then

        currentActive:get().Value:set(game.Selection:Get()[1])
        if currentActive:get().OnChange then
            currentActive:get().OnChange(currentActive:get().Value:get())
        end

        currentActive:set{
            Value = nil,
            OnChange = nil
        }
    end
end)

local hasBound = false

return function(pluginUtil, i: number, elemData: Types.Property<Instance>)

    if not hasBound then

        hasBound = true

        pluginUtil:bindFnToClose(function()
            currentActive:set{
                Value = nil,
                OnChange = nil
            }
        end)

        pluginUtil:bindToPluginInputBegan(function(input)
            if (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape) or (input.UserInputType == Enum.UserInputType.MouseButton1) then
                currentActive:set{
                    Value = nil,
                    OnChange = nil
                }
            end
        end)
    end

    local startVal = elemData.DefaultValue;
    local cVal;
    if startVal and typeof(startVal) == "table" and startVal.get then
        cVal = startVal
    else
        cVal = Value(startVal);
    end

    if OnChange then
        elemData.OnChange(cVal:get());
    end;

    return New "Frame" {
        Name = i,
        LayoutOrder = i,
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        [ OnEvent "MouseEnter"] = function()
            pluginUtil.tooltip.hoverTip = elemData.Tooltip;
        end,
        [ OnEvent "MouseLeave"] = function()
            pluginUtil.tooltip.hoverTip = nil;
        end,
        [ Children ] = {
            New "UIStroke" {
                Color = Color3.fromRGB(150, 150, 150),
                Transparency = 0.5,
                Thickness = 1,
            },
            New "UICorner" {
                CornerRadius = UDim.new(0, 4)
            },
            New "TextLabel" {
                Name = "Label",
                BackgroundTransparency = 1,
                Text = elemData.Key,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                Size = UDim2.new(0.5, -2, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
            },
            New "TextButton" {
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0.5, -2, 0, 24),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = pluginUtil.CONFIG.accentColor,
                BorderSizePixel = 0,
                TextColor3 = Computed(function()
                    if (currentActive:get().Value == cVal) or (not cVal:get()) then
                        return Color3.fromRGB(200, 200, 200)
                    else
                        return Color3.fromRGB(255, 255, 255)
                    end
                end),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ClipsDescendants = true,
                Text = Computed(function()
                    if currentActive:get().Value == cVal then
                        return elemData.SelectingText or "Select instance"
                    end
                    local c = cVal:get()
                    if c then
                        return c.Name
                    else
                        return elemData.EmptyText or ""
                    end
                end),
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.Bold),
                [ Children ] = {
                    New "UICorner" {
                        CornerRadius = UDim.new(0, 4)
                    },
                    New "UIPadding" {
                        PaddingLeft = UDim.new(0, 4),
                        PaddingRight = UDim.new(0, 4)
                    }
                },
                [ OnEvent "Activated" ] = function()
                    if game.Selection:Get() and #game.Selection:Get() == 1 then
                        cVal:set(game.Selection:Get()[1]);
                        if elemData.OnChange then
                            elemData.OnChange(cVal:get());
                        end
                    else
                        currentActive:set{
                            Value = cVal,
                            OnChange = elemData.OnChange
                        }
                    end;
                end
            },
        }
    };
end