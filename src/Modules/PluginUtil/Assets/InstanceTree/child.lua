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

return function(pluginUtil, child, parent, state, callback)
    New "TextButton" {
        Text = child.Name,
        Size = UDim2.new(1, 0, 0, 16),
        Parent = parent,
        BackgroundTransparency = Computed(function()
            if state:get() == child then
                return 0;
            else
                return 1;
            end;
        end),
        BackgroundColor3 = pluginUtil.CONFIG.accentColor,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        FontFace = Font.fromName("Montserrat", Enum.FontWeight.SemiBold),
        TextXAlignment = Enum.TextXAlignment.Left,
        [ OnEvent "Activated" ] = function()
            pluginUtil.data.currentUI:set(0);
            state:set(child);
            coroutine.wrap(function()
                repeat wait() until pluginUtil.data.UISpring:get() < 0.01;
                pluginUtil:cleanup();
            end)();
            if callback then
                local s, e = pcall(function()
                    callback(child);
                end);
                if not s then
                    warn("Error executing onChange function: " .. e);
                end;
            end;
        end,
        [ Children ] = {
            New "UIPadding" {
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingTop = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4)
            },
            New "UICorner" {
                CornerRadius = UDim.new(0, 4)
            },
            New "UIStroke" {
                Color = Color3.fromRGB(255, 255, 255),
                Thickness = 1,
                Transparency = 0.5,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            }
        }
    }
end