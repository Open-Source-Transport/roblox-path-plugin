local packages = script.Parent.Parent.Packages
local fusion = require(packages.fusion)
local Types = require(script.Parent.Types)
local highlightConfigs = require(script.highlightConfig)

return {

    highlights = {},

    addHighlight = function(self, id: string, instance: BasePart | Model | UnionOperation, highlightInfo: Types.HighlightInfo?)
        if self.highlights[id] then
            self:removeHighlight(id)
        end

        if not highlightInfo then
            highlightInfo = highlightConfigs[id] or highlightConfigs.Default
        end

        self.highlights[id] = fusion.New "Highlight" {
            Adornee = instance,
            FillColor = highlightInfo.fill or Color3.fromRGB(255, 0, 0),
            OutlineColor = highlightInfo.outline or Color3.fromRGB(255, 255, 255),
            FillTransparency = highlightInfo.fillTransparency or 0.5,
            DepthMode = highlightInfo.depthMode or Enum.HighlightDepthMode.AlwaysOnTop,
            Parent = workspace.CurrentCamera
        }
    end,

    removeHighlight = function(self, id: string)
        if not self.highlights[id] then
            return
        end

        self.highlights[id]:Destroy()
        self.highlights[id] = nil
    end,

    clearHighlights = function(self)
        for id, _ in pairs(self.highlights) do
            self:removeHighlight(id)
        end
    end
}