return {
    pluginId = "BRSoundPlugin",
    toolbarName = "BR Plugins",
    widgetTitle = "BR Sound Preview",
    toolbarButton = {
        Name = "BRSoundPlugin",
        Text = "Preview sounds",
        Image = "",
        Tooltip = "BR Sound Tool"
    },
    widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float,
        false,
        false,
        200,
        300,
        200,
        300
    ),
    accentColor = Color3.fromRGB(110, 136, 232),
    lengthResolution = 0.025
}

