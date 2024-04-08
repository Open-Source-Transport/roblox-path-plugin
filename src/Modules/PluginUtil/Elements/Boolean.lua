local fusion = require(script.Parent.Parent.getFusion)
local Types = require(script.Parent.Parent.Types)

local New = fusion.New;
local Children = fusion.Children;
local OnEvent = fusion.OnEvent;
local Value = fusion.Value;
local Computed = fusion.Computed;
local ForPairs = fusion.ForPairs;
local ForValues = fusion.ForValues;
local Spring = fusion.Spring;
local OnChange = fusion.OnChange;

return function(pluginUtil, i: number, elemData: Types.Property<boolean>)
    local val = elemData.DefaultValue;
    local activeValue = Value(0);
    if val then activeValue:set(1) end;
    local spring = Spring(activeValue, 40, 1);
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
                Size = UDim2.new(1, -32, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                [ Children ] = {
                    New "UIPadding" {
                        PaddingLeft = UDim.new(0, 4)
                    }
                }
            },
            New "TextButton" {
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(0, 24, 0, 24),
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = pluginUtil.CONFIG.accentColor,
                BorderSizePixel = 0,
                [ Children ] = {
                    New "UICorner" {
                        CornerRadius = UDim.new(0, 4)
                    },
                    New "Frame" {
                        Size = Computed(function()
                            local s = spring:get()
                            return UDim2.new(0, 8 + 9 * (1 - s), 0, 4)
                        end),
                        Position = Computed(function()
                            local s = spring:get()
                            return UDim2.new(0.5 * (1 - s), 8 * (s), 0.5 + 0.2 * (s), 0);
                        end),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Rotation = 45,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                    };
                    New "Frame" {
                        Size = UDim2.new(0, 17, 0, 4),
                        Position = Computed(function()
                            local s = spring:get()
                            return UDim2.new(0.5 * (1 - s), 16 * (s), 0.5, 0)
                        end),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Rotation =   -45,
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BorderSizePixel = 0,
                    };
                },
                [ OnEvent "Activated" ] = function()
                    val = not val;
                    if val then activeValue:set(1) else activeValue:set(0) end;
                    elemData.OnChange(val);
                end
            },
        }
    };
end