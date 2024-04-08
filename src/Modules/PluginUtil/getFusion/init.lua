local fusion: ModuleScript

local checkedBefore = {}

local p: Instance = script

while p and p.Parent do
    if checkedBefore[p] then p = p.Parent continue end;
    checkedBefore[p] = true
    fusion = p:FindFirstChild("fusion") or p:FindFirstChild("Fusion")
    if fusion then
        break
    else
        fusion = nil
        p = p:FindFirstChild("Packages") or p:FindFirstChild("Modules") or p.Parent
    end
end

if not fusion then
    error("[PluginUtil] Fusion not found in plugin installation")
end

local f = require(fusion)

if not script:FindFirstChild("FusionDestructors") then
    error("[PluginUtil] FusionDestructors not provided in PluginUtil/getFusion")
end

for _, k in pairs(script.FusionDestructors:GetChildren()) do
    f[k.Name] = require(k)
end

return f

