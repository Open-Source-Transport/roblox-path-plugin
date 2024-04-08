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

return function(pluginUtil, i: number, elemData: Types.InstanceTree)
    local startVal = elemData.DefaultValue;
    local cVal;
    if startVal and typeof(startVal) == "table" and startVal.get then
        if not startVal:get() then
            for _, p in pairs(elemData.Source:GetChildren()) do
                if p:IsA(elemData.InstanceType) then
                    startVal:set(p);
                    break;
                end;
            end;
            if not startVal:get() then
                for _, p in pairs(elemData.Source:GetDescendants()) do
                    if p:IsA(elemData.InstanceType) then
                        startVal:set(p);
                        break;
                    end;
                end;
            end;
            if not startVal:get() then
                warn("No instances of type " .. elemData.InstanceType .. " found in " .. elemData.Source:GetFullName());
                return;
            end;
        end
        cVal = startVal
    else
        if not startVal then
            for _, p in pairs(elemData.Source:GetChildren()) do
                if p:IsA(elemData.InstanceType) then
                    startVal = p;
                    break;
                end;
            end;
            if not startVal then
                for _, p in pairs(elemData.Source:GetDescendants()) do
                    if p:IsA(elemData.InstanceType) then
                        startVal = p;
                        break;
                    end;
                end;
            end;
            if not startVal then
                warn("No instances of type " .. elemData.InstanceType .. " found in " .. elemData.Source:GetFullName());
                return;
            end;
        end;
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
                Text = elemData.Header,
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
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ClipsDescendants = true,
                Text = Computed(function()
                    local c = cVal:get()
                    if c then
                        return c.Name
                    else
                        return ""
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
                    pluginUtil.instanceTree:hydrate(elemData.Header, elemData.Source, elemData.InstanceType, elemData.Recursive, cVal, elemData.OnChange);
                    pluginUtil.data.currentUI:set(1);
                end
            },
        }
    };
end