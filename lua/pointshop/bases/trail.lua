local BASE = {}
BASE.ID = "trail"
BASE.Material = "trails/laser"
BASE.Modify = true
BASE.Color = Color(255, 255, 255)
BASE.PlayerColorable = true -- Can trail color be the same as PLAYER:GetPlayerColor
BASE.RainbowColorable = true -- Can trail color be a rainbow

BASE.StartWidth = 15
BASE.EndWidth = 0
BASE.LifeTime = 4.25

function PS:SpriteTrail(ply, color, startW, endW, lifeT, mat)
    local ent = ents.Create("lbg_trail")
    ent:SetColor(color)
    ent:SetStartWidth(startW)
    ent:SetEndWidth(endW)
    ent:SetLifeTime(lifeT)
    ent:SetOwner(ply)
    ent:Spawn()
    ent:SetMaterialPath(mat)
    return ent
end

function BASE:OnEquip(ply, mods)
    if PS.GamemodeCheck(self) then return end
    PS.Trails[ply] = PS.Trails[ply] or {}
    self:OnHolster(ply, mods)
    if ply:PS_IsSpectator(ply) then return end
    local color = self.Color

    PS.Trails[ply] = PS.Trails[ply] or {}
    SafeRemoveEntity(PS.Trails[ply][self.ID])
    PS.Trails[ply][self.ID] = PS:SpriteTrail(ply, color, self.StartWidth, self.EndWidth, self.LifeTime, self.Material)

    local ent = PS.Trails[ply][self.ID]
    ent:SetItemID(self.ID)
end

function BASE:OnSpawn(ply, mods)
    if ply:PS_IsSpectator() then return end
    self:OnEquip(ply, mods)
end

function BASE:OnSpawn(ply, mods)
    self:OnEquip(ply, mods)
end

function BASE:OnDeath(ply, mods)
    self:OnHolster(ply, mods)
end

function BASE:OnHolster(ply, mods)
    if PS.GamemodeCheck(self) then return end
    if not PS.Trails[ply] then return end
    SafeRemoveEntity(PS.Trails[ply][self.ID])
    PS.Trails[ply][self.ID] = nil
end

function BASE:OnModify(ply, mods)
    if PS.GamemodeCheck(self) then return end
    if not PS.Trails[ply] or not PS.Trails[ply][self.ID] then return end
end

function BASE:OnThink(ply, mods)
    if PS.GamemodeCheck(self) then return end
    if CLIENT or not PS.Trails[ply] or not PS.Trails[ply][self.ID] then return end

    if ply:PS_IsSpectator() then
        self:OnHolster(ply, mods)
    end
end

function BASE:OnCustomizeSetup(panel, mods)
    mods.color = mods.color or "#FFFFFFFF"
    mods.colorMode = mods.colorMode or "color"

    self:SetupThinker(panel, mods, {
        colorMode = mods.colorMode, color = mods.color
    }, function(a, b)
        return not PS.TablesEqual(a, b)
    end, function(reference, copy)
        return table.Copy(reference)
    end)

    local values = { "Color", "Player Color", "Rainbow" }
    local datas = { "color", "player", "rainbow" }

    PS.AddColorModeSelector(panel, "Trail Color Mode", PS.HEXtoRGB(mods.color or ""), true, values[table.KeyFromValue(datas, mods.colorMode) or 1], values, datas, function(v, d, c)
        mods.colorMode = d
        mods.color = "#" .. PS.RGBtoHEX(c, true)
    end)
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

PS.TrailColorsCache = PS.TrailColorCache or {}
local COLOR_WHITE = Color(255, 255, 255)

function BASE:ColorFunction(trail, ply)
    local mods = ply:PS_GetModifiers(self.ID)

    if not self.Modify then
        trail.Color = COLOR_WHITE
        return
    end

    if not isstring(mods.colorMode) then
        mods.colorMode = "color"
    end

    if not isstring(mods.color) and mods.colorMode == "color" then
        trail.Color = COLOR_WHITE
        return
    end

    if self.PlayerColorable and mods.colorMode == "player" then
        trail.Color = ply:GetPlayerColor():ToColor()
        return
    end

    if self.PlayerColorable and mods.colorMode == "rainbow" then
        trail.Color = HSVToColor(RealTime() * 70 % 360, 1, 1)
        return
    end

    if not PS.TrailColorsCache[mods.color] then
        PS.TrailColorsCache[mods.color] = PS.HEXtoRGB(mods.color, true)
    end

    trail.Color = PS.TrailColorsCache[mods.color]
end

return PS:RegisterBase(BASE)