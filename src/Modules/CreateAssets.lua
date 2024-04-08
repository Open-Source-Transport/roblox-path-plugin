-- Creates the Assets folder
-- Generated by Codify from Anthony O'Brien's original plugin

return function(): Folder
	local Assets = Instance.new("Folder")
	Assets.Name = "Assets"

	local ControlPoint = Instance.new("Part")
	ControlPoint.Name = "ControlPoint"
	ControlPoint.Anchored = true
	ControlPoint.BottomSurface = Enum.SurfaceType.Smooth
	ControlPoint.BrickColor = BrickColor.new("Really red")
	ControlPoint.CFrame = CFrame.new(-3034.70312, 6.30002689, 7350.29688, 1, 0, 0, 0, 1, 0, 0, 0, 1)
	ControlPoint.CastShadow = false
	ControlPoint.Color = Color3.fromRGB(255, 0, 0)
	ControlPoint.Material = Enum.Material.SmoothPlastic
	ControlPoint.Size = Vector3.new(6, 2, 2)
	ControlPoint.TopSurface = Enum.SurfaceType.Smooth

	local Gui = Instance.new("BillboardGui")
	Gui.Name = "Gui"
	Gui.Active = true
	Gui.AlwaysOnTop = true
	Gui.ClipsDescendants = true
	Gui.LightInfluence = 1
	Gui.Size = UDim2.fromScale(3, 3)
	Gui.StudsOffset = Vector3.new(0, 3, 0)
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local Number = Instance.new("TextLabel")
	Number.Name = "Number"
	Number.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	Number.Text = "Control Point"
	Number.TextColor3 = Color3.fromRGB(240, 240, 240)
	Number.TextScaled = true
	Number.TextSize = 14
	Number.TextStrokeTransparency = 0
	Number.TextWrapped = true
	Number.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Number.BackgroundTransparency = 1
	Number.BorderSizePixel = 0
	Number.Size = UDim2.fromScale(1, 1)
	Number.Parent = Gui

	Gui.Parent = ControlPoint

	local UpArrow = Instance.new("Decal")
	UpArrow.Name = "Up Arrow"
	UpArrow.Texture = "http://www.roblox.com/asset/?id=29563813"
	UpArrow.Face = Enum.NormalId.Back
	UpArrow.Parent = ControlPoint

	local DownArrow = Instance.new("Decal")
	DownArrow.Name = "Down Arrow"
	DownArrow.Texture = "http://www.roblox.com/asset/?id=29563831"
	DownArrow.Face = Enum.NormalId.Top
	DownArrow.Parent = ControlPoint

	ControlPoint.Parent = Assets

	return Assets
end
