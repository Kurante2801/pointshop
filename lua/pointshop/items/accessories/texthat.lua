local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "texthat"

ITEM.Name = "Text Hat"
ITEM.Price = 500
ITEM.CharLimit = 32

ITEM.PlayerColorable = true -- Can trail color be the same as PLAYER:GetPlayerColor
ITEM.RainbowColorable = true -- Can trail color be a rainbow

function ITEM:SanitizeTable(mods)
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
        colorSpeed = isnumber(mods.colorSpeed) and math.Clamp(mods.colorSpeed, 1, 14) or 7,
        text = isstring(mods.text) and string.sub(mods.text, 1, self.CharLimit) or nil
    }
end

if not CLIENT then
    return PS:RegisterItem(ITEM)
end

if file.Exists("resource/fonts/rubik-semibold.ttf", "THIRDPARTY") then
    surface.CreateFont("PS_TextHat", {
        font = "Rubik SemiBold",
        size = 32, shadow = false, antialias = true,
    })
else
    surface.CreateFont("PS_TextHat", {
        font = "Circular Std Medium",
        size = 32, shadow = false, antialias = true,
    })
end

ITEM.Props = {
    ["bubble"] = {
        model = "models/extras/info_speech.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(15, 0, 0),
        ang = Angle(90, 90, 0),
        scale = Vector(0.425, 0.425, 0.425),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}

ITEM.CameraData = {
    pos = Vector(60, 60, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

local COLOR_WHITE = Color(255, 255, 255)
local draw_ShadowedText = PS.ShadowedText
function ITEM:OnPlayerDraw(ply, flags, ent, mods)
    if PS.GamemodeCheck(self) or not PS:CanSeeAccessory(ply) then return end
    ent = ent or ply

    local pos, ang = self:GetBonePosAng(ent, "ValveBiped.Bip01_Head1")
    if not pos or not ang then return end

    ang:RotateAroundAxis(ang:Right(), 90)
    ang:RotateAroundAxis(ang:Forward(), -90)
    pos = pos + ang:Right() * -12

    cam.Start3D2D(pos, ang, 0.1)
        draw_ShadowedText(mods.text or ply:Name(), "PS_TextHat", 0, 0, self:ColorFunction(ply, mods, ent), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    ang:RotateAroundAxis(ang:Right(), 180)
    cam.Start3D2D(pos, ang, 0.1)
        draw_ShadowedText(mods.text or ply:Name(), "PS_TextHat", 0, 0, self:ColorFunction(ply, mods, ent), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ITEM:OnPreviewDraw(w, h, panel)
end

function ITEM:OnCustomizeSetup(panel, mods)
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

    PS.AddColorModeSelector(panel, "Text Color Mode", PS.HEXtoRGB(mods.color or ""), mods.colorSpeed, true, mods.colorMode, values, datas, function(v, d, c, s)
        PS:SendModification(self.ID, "colorMode", d)
        PS:SendModification(self.ID, "color", "#" .. PS.RGBtoHEX(c, true))
        PS:SendModification(self.ID, "colorSpeed", s)
    end)

    PS.AddTextEntry(panel, "Text", mods.text or "", self.CharLimit, function(value)
        PS:SendModification(self.ID, "text", value)
    end)
end

PS.TextHatColorsCache = PS.TextHatColorsCache or {}
local colorCache = PS.TextHatColorsCache
function ITEM:ColorFunction(ply, mods, ent)
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

return PS:RegisterItem(ITEM)