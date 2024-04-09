local Types = require(script.Parent.Parent.Types)

local configs: {[string]: Types.HighlightInfo} = {
    ["Default"] = {
        outline = Color3.fromRGB(255, 166, 0),
        fill = Color3.fromRGB(255, 255, 255),
        fillTransparency = 0.5,
        depthMode = Enum.HighlightDepthMode.Occluded
    },
    ["Startpoint"] = {
        outline = Color3.fromRGB(255, 166, 0),
        fill = Color3.fromRGB(255, 255, 255),
        fillTransparency = 1,
        depthMode = Enum.HighlightDepthMode.AlwaysOnTop
    },
    ["Endpoint"] = {
        outline = Color3.fromRGB(255, 166, 0),
        fill = Color3.fromRGB(255, 255, 255),
        fillTransparency = 1,
        depthMode = Enum.HighlightDepthMode.AlwaysOnTop
    },
}

return configs