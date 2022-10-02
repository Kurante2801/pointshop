local BASE = {}
BASE.ID = "flashlight"
BASE.Material = "effects/flashlight001"
BASE.PlayerColorable = true
BASE.RainbowColorable = true
BASE.Modify = true

function BASE:OnEquip(ply, mods)
    if PS.GamemodeCheck(self) then return end

    ply:SetNWBool("PS_Flashlight", true)

    if ply:FlashlightIsOn() then
        ply:Flashlight(false)
    end
end

function BASE:OnHolster(ply, mods)
    if PS.GamemodeCheck(self) then return end

    ply:SetNWBool("PS_Flashlight", false)
end

function BASE:SanitizeTable(mods)
    if not self.Modify then return {} end

    if not self.PlayerColorable and mods.colorMode == "player" then
        mods.colorMode = "color"
    end

    if not self.RainbowColorable and mods.colorMode == "rainbow" then
        mods.colorMode = "color"
    end

    return {
        color = "#" .. PS.SanitizeHEX(mods.color, true),
        colorMode = mods.colorMode or "color",
    }
end

if SERVER then
    util.AddNetworkString("PS_FlashlightToggle")

    -- On certain gamemodes, flashlights are silent
    function PS.ShouldSoundFlashlight(ply)
        if GAMEMODE.FolderName == "hideandseek" then
            return ply:Team() == TEAM_SEEK
        end

        return true
    end

    -- Player pressed impulse 100
    net.Receive("PS_FlashlightToggle", function(_, ply)
        if not ply:Alive() or ply:PS_IsSpectator() or not ply.PS_Items then return end
        -- Do nothing if player doesn't have a PS item
        local found = false
        for id, item in pairs(ply.PS_Items) do
            local ITEM = PS.Items[id]
            if ITEM and item.Equipped and ITEM.Base == "flashlight" then
                found = true
                break
            end
        end

        if not found then return end

        if ply:FlashlightIsOn() then
            ply:Flashlight(false)
        end

        ply:SetNWBool("PS_Flashlight", not ply:GetNWBool("PS_Flashlight", false))
        if PS.ShouldSoundFlashlight(ply) then
            ply:EmitSound("items/flashlight1.wav")
        end
    end)

    -- Turn off flashlights
    hook.Add("Think", "PS_Flashlights", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("PS_Flashlight", false) and (not ply:Alive() or ply:PS_IsSpectator()) then
                ply:SetNWBool("PS_Flashlight", false)
            end
        end
    end)

    return PS:RegisterBase(BASE)
end

function BASE:OnCustomizeSetup(panel, mods)
    mods.color = mods.color or "#FFFFFFFF"
    mods.colorMode = mods.colorMode or "color"
    mods.colorSpeed = mods.colorSpeed or 7

    local values = { "Color" }
    local datas = { "color" }

    if self.PlayerColorable then
        table.insert(values, "Player Color")
        table.insert(datas, "player")
    end

    if self.RainbowColorable then
        table.insert(values, "Rainbow")
        table.insert(datas, "rainbow")
    end

    PS.AddColorModeSelector(panel, "Flashlight Color Mode", PS.HEXtoRGB(mods.color or ""), mods.colorSpeed, true, mods.colorMode, values, datas, function(v, d, c, s)
        PS:SendModification(self.ID, "colorMode", d)
        PS:SendModification(self.ID, "color", "#" .. PS.RGBtoHEX(c, true))
        PS:SendModification(self.ID, "colorSpeed", s)
    end)
end

local flash_up = 0
local flash_forward = 0
local flash_threshold = 140
local wallDist = flash_threshold * flash_threshold

PS.ProjectedTextures = PS.ProjectedTextures or {}
local projected = PS.ProjectedTextures

local function DeleteFlashlight(ply, id)
    if not projected[ply] or not projected[ply][id] or not IsValid(projected[ply][id]) then return end

    projected[ply][id]:Remove()
    projected[ply][id] = nil
end

local function GetFlashlight(ply, id, item)
    if not projected[ply] then
        projected[ply] = {}
    end

    if not projected[ply][id] and not IsValid(projected[ply][id]) then
        local ent = ProjectedTexture()
        projected[ply][id] = ent

        ent:SetTexture(Material(item.Material, "smooth"):GetTexture("$basetexture"):GetName())
        ent:SetNearZ(64)
        ent:SetFarZ(700)
        ent:SetFOV(62)

        item:OnFlashlightInitialized(ply, ply:PS_GetModifiers(id), ent)
    end

    return projected[ply][id]
end

local function ShouldDraw(ply)
    if not ply:Alive() or ply:PS_IsSpectator() then return false end
    local on = ply:GetNWBool("PS_Flashlight")

    if GAMEMODE.FolderName == "hideandseek" and ply:Team() == TEAM_HIDE then
        return on and LocalPlayer():Team() == TEAM_HIDE
    end

    return on
end

local function GetTraceLine(ply)
    return util.TraceLine({
        start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * flash_threshold,
        mask = MASK_SOLID_BRUSHONLY
    })
end

function BASE:OnThink(ply, mods, isLocal)
    if PS.GamemodeCheck(self) then return end

    if not ShouldDraw(ply) then
        DeleteFlashlight(ply, self.ID)
        return
    end

    self:UpdateEntity(ply, mods, GetFlashlight(ply, self.ID, self), isLocal)
end

local ang, tr
function BASE:UpdateEntity(ply, mods, ent, isLocal)
    ang = ply:EyeAngles()
    ent:SetAngles(ang)
    ent:SetColor(self:ColorFunction(ply, mods, ent))
    ent:SetNearZ(isLocal and 40 or 64)

    -- GetEyeTrace is cached, so it's not expensive to call here
    tr = ply:GetEyeTrace()
    if tr.Hit and tr.HitPos:DistToSqr(ply:EyePos()) <= wallDist then
        -- This next trace only targets the world (walls, floor, etc)
        tr = GetTraceLine(ply)
        if tr.Hit and tr.HitPos:DistToSqr(ply:EyePos()) <= wallDist then
            ent:SetPos(tr.HitPos  - ang:Up() * flash_up + ang:Forward() * flash_forward - ang:Forward() * flash_threshold)
            ent:Update()
            return
        end
    end

    ent:SetPos(ply:EyePos() - ang:Up() * flash_up + ang:Forward() * flash_forward)
    ent:Update()
end

function BASE:OnFlashlightInitialized(ply, mods, ent)
    -- Override
end

function BASE:OnPreFlashlightUpdated(ply, mods, ent)
    -- Override
end

local COLOR_WHITE = Color(255, 255, 255)
PS.FlashlightsColorsCache = PS.FlashlightsColorCache or {}
local colorCache = PS.FlashlightsColorsCache
function BASE:ColorFunction(ply, mods, ent)
    if not self.Modify then
        return COLOR_WHITE
    end

    if not isstring(mods.colorMode) then
        mods.colorMode = "color"
    end

    if not isstring(mods.color) and mods.colorMode == "color" then
        return COLOR_WHITE
    end

    if self.PlayerColorable and mods.colorMode == "player" then
        return ply:GetPlayerColor():ToColor()
    end

    if not isnumber(mods.colorSpeed) then
        mods.colorSpeed = 7
    end

    if self.PlayerColorable and mods.colorMode == "rainbow" then
        return HSVToColor(RealTime() * (10 * mods.colorSpeed) % 360, 1, 1)
    end

    if not colorCache[mods.color] then
        colorCache[mods.color] = PS.HEXtoRGB(mods.color, true)
    end

    return colorCache[mods.color]
end

-- Local player's flashlights, no other hook works as well as CalcView
hook.Add("CalcView", "PS_Flashlight_LocalPlayer", function(ply)
    if not ply.PS_Items then return end

    for id, item in pairs(ply.PS_Items) do
        local ITEM = PS.Items[id]
        if ITEM and item.Equipped and ITEM.Base == "flashlight" then
            ITEM:OnThink(ply, item.Modifiers, true)
        end
    end
end)

-- Cleanup for disconnected players
local valid
hook.Add("Think", "PS_Flashlights_Cleanup", function()
    for ply, flashlights in pairs(projected) do
        valid = IsValid(ply)

        for id, ent in pairs(flashlights) do
            if not valid or not ply:PS_HasItemEquipped(id) then
                if IsValid(ent) then
                    ent:Remove()
                end
                projected[ply][id] = nil
            end
        end

        if not valid then
            projected[ply] = nil
        end
    end
end)

hook.Add("PlayerBindPress", "PS_FlashlightPress", function(ply, bind, pressed, code)
    if bind ~= "impulse 100" or not pressed or not ply.PS_Items then return end

    for id, item in pairs(ply.PS_Items) do
        local ITEM = PS.Items[id]
        if ITEM and item.Equipped and ITEM.Base == "flashlight" then
            net.Start("PS_FlashlightToggle")
            net.SendToServer()
            return true
        end
    end
end)

return PS:RegisterBase(BASE)