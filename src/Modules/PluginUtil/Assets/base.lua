local fusion = require(script.Parent.Parent.getFusion)

local New = fusion.New;
local Children = fusion.Children;
local OnEvent = fusion.OnEvent;
local Value = fusion.Value;
local Computed = fusion.Computed;
local ForPairs = fusion.ForPairs;
local ForValues = fusion.ForValues;
local Spring = fusion.Spring;
local OnChange = fusion.OnChange;

return function(pluginUtil)
    New "UIPadding" {
        Parent = pluginUtil.data.widget,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
    };

    

    return New "ScrollingFrame" {
        Name = "Scroll",
        Parent = pluginUtil.data.widget,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Position = Computed(function()
            local s = pluginUtil.data.UISpring:get()
            return UDim2.new(s * -1, -10 * s, 0, 0)
        end),
        [ Children ] = {
            New "UIListLayout" {
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.Name,
                Padding = UDim.new(0, 8),
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                VerticalAlignment = Enum.VerticalAlignment.Top
            },
            New "UIPadding" {
                PaddingLeft = UDim.new(0, 2),
                PaddingRight = UDim.new(0, 2),
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 2),
            };
        }
    }
end