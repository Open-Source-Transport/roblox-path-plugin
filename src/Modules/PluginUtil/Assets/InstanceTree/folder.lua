local fusion = require(script.Parent.Parent.Parent.getFusion)

local New = fusion.New;
local Children = fusion.Children;
local OnEvent = fusion.OnEvent;
local Value = fusion.Value;
local Computed = fusion.Computed;
local ForPairs = fusion.ForPairs;
local ForValues = fusion.ForValues;
local Spring = fusion.Spring;
local OnChange = fusion.OnChange;

return function(pluginUtil, folder, parent, instanceType, resultValue, callback)
    local folderFrame;
    local state = Value(false);
    folderFrame = New "Frame" {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = parent,
        ClipsDescendants = true,
        [ Children ] = {
            New "TextButton" {
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                Text = folder.Name,
                TextSize = 14,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
                TextXAlignment = Enum.TextXAlignment.Left,
                [ OnEvent "Activated" ] = function()
                    state:set(not state:get())
                    if state:get() then
                        folderFrame:TweenSize(UDim2.new(1, 0, 0, 24 + (folderFrame.Children.UIListLayout.AbsoluteContentSize.Y)), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true)
                    else
                        folderFrame:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.2, true)
                    end
                end,
                [ Children ] = {
                    New "UIPadding" {
                        PaddingLeft = UDim.new(0, 22)
                    }
                }
            },
            New "ImageLabel" {
                Name = "Arrow",
                BackgroundTransparency = 1,
                Image = "rbxassetid://13642210590",
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(0, 10, 0, 8),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Rotation = Spring(
                    Computed(function()
                        if state:get() then
                            return 135
                        else
                            return 45
                        end
                    end),
                    20,
                    1
                )
            },
            New "Frame" {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Name = "Children",
                Position = UDim2.new(1, 0, 0, 20),
                Size = UDim2.new(1, -16, 0, 0),
                AnchorPoint = Vector2.new(1, 0),
                [ Children ] = {
                    New "UIListLayout" {
                        SortOrder = Enum.SortOrder.Name,
                        Padding = UDim.new(0, 4),
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    }
                }
            },
            New "UICorner" {
                CornerRadius = UDim.new(0, 4)
            },
            New "UIStroke" {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 1,
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            },
            New "UIPadding" {
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2)
            }
        }
    }

    folderFrame.Children.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if state:get() then
            folderFrame.Size = UDim2.new(1, 0, 0, 24 + (folderFrame.Children.UIListLayout.AbsoluteContentSize.Y))
        end;
    end)

    for _, c in pairs(folder:GetChildren()) do
        if c:IsA("Folder") then
            pluginUtil:processFolder(c, folderFrame.Children, instanceType, resultValue, callback);
        elseif c:IsA(instanceType) then
            pluginUtil:addChild(c, folderFrame.Children, resultValue, callback);
        end;
    end;
end