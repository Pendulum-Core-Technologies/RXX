-- hi my name is nexus
local httpService = game:GetService("HttpService")

local properties = {
    "Position", "Size", "CFrame", "Color", "Transparency", 
    "Reflectance", "Anchored", "CanCollide", "Material",
    "CastShadow", "MeshId", "TextureID", "Text", "TextColor3",
    "MaxActivationDistance", "HoldDuration", "ActionText", "ObjectText", 
    "Enabled", "Source", "Disabled", "Face", "Texture", "ZIndex", "Color3", 
    "BrickColor", "Neutral", "TeamColor", "FormFactor", 
    "Shape", "BackSurface", "BottomSurface", "FrontSurface", 
    "TopSurface", "LeftSurface", "RightSurface", "Part0", "Part1", 
    "Archivable", "Value", "OffsetStudsU", "OffsetStudsV", 
    "StudsPerTileU", "StudsPerTileV", "MeshType", 
    "Offset", "Scale", "Visible", "TextureId", "VertexColor", 
    "OverlayTextureId", "BodyPart", "BaseTextureId", 
    "AnimationId", "Active", "Adornee", "AlwaysOnTop", 
    "HeadColor", "TorsoColor", "RightLegColor", "RightArmColor", 
    "LeftLegColor", "LeftArmColor", "ConversationDistance", "GoodbyeDialog", 
    "InUse", "InitialPrompt", "Purpose", "Tone", "ResponseDialog", 
    "UserDialog", "Heat", "SecondaryColor", "Font", 
    "PantsTemplate", "ShirtTemplate", "LightEmission", "ZOffset", 
    "Lifetime", "Rate", "RotSpeed", "Rotation", "Orientation", 
    "Speed", "SpreadAngle", "Range", "Brightness", "Shadows", 
    "CartoonFactor", "Target", "TargetOffset", "TargetRadius", 
    "MaxSpeed", "MaxThrust", "ThrustD", "ThrustP", "TurnD", 
    "TurnP", "Opacity", "RiseVelocity", "SoundId", 
    "Playing", "Looped", "Volume", "Pitch", "PlayOnRemove", 
    "Locked", "BrickColor", "Fog", "Health", "MaxHealth", 
    "WalkSpeed", "Sit", "PlatformStand", "FallenPartsDestroyHeight",
    "FogColor", "FogEnd", "FogStart", "TeamColor"
}
-- huge ass table ^^

local total = #workspace:GetDescendants()
local proc = 0
local yield = os.clock()
local pcount = 0

local function parsev(v)
    local t = typeof(v)
    if t == "Vector3" then
        return {"V3", v.X, v.Y, v.Z}
    elseif t == "Color3" then
        return {"C3", v.R, v.G, v.B}
    elseif t == "CFrame" then
        return {"CF", {v:GetComponents()}}
    elseif t == "EnumItem" then
        return {"Enum", tostring(v)}
    elseif t == "boolean" or t == "number" or t == "string" then
        return v
    end
    return nil
end

local function read(inst, prop)
    return inst[prop]
end

local function readattributes(inst)
    return inst:GetAttributes()
end

local function serialize(obj)
    proc = proc + 1

    if proc - pcount >= 5 or proc == total then
        print(proc .. "/" .. total)
        pcount = proc
    end

    if os.clock() - yield > 0.09 then
        task.wait()
        yield = os.clock()
    end

    local data = {
        Class = obj.ClassName,
        Name = obj.Name,
        Props = {},
        Attrs = {},
        Children = {}
    }

    for i = 1, #properties do
        local prop = properties[i]
        local ok, val = pcall(read, obj, prop)
        if ok and val ~= nil then
            data.Props[prop] = parsev(val)
        end
    end

    local okAttrs, attrs = pcall(readattributes, obj)
    if okAttrs and attrs then
        for name, val in pairs(attrs) do
            data.Attrs[name] = parsev(val)
        end
    end

    local children = obj:GetChildren()
    for i = 1, #children do
        local child = children[i]
        if not child:IsA("Player") and not child:IsA("Camera") then
            table.insert(data.Children, serialize(child))
        end
    end

    return data
end

local dump = {}
local wc = workspace:GetChildren()

for i = 1, #wc do
    local item = wc[i]
    if not item:IsA("Camera") and not item:IsA("Terrain") then
        table.insert(dump, serialize(item))
    end
end

print("encoding")
local raw = httpService:JSONEncode(dump)

if writefile then
    writefile("game.raw", raw)
    print("saved")
-- i think it compiles the retrostudio ui too but idgaf
end
