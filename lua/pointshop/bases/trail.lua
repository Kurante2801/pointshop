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

PS.Trails = PS.Trails or {}
local trails = PS.Trails

BASE.VisibilitySettings = {
    VisibilityText = "Who can see your Trails?",
    DisplayText = "Display Trails from: ",
    CVarSuffix = "trail",
    FirstPersonOptional = false
}

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
    trails[ply] = trails[ply] or {}
    self:OnHolster(ply, mods)
    if ply:PS_IsSpectator(ply) then return end
    local color = self.Color

    trails[ply] = trails[ply] or {}
    SafeRemoveEntity(trails[ply][self.ID])
    trails[ply][self.ID] = PS:SpriteTrail(ply, color, self.StartWidth, self.EndWidth, self.LifeTime, self.Material)

    local ent = trails[ply][self.ID]
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
    if not trails[ply] then return end
    SafeRemoveEntity(trails[ply][self.ID])
    trails[ply][self.ID] = nil
end

function BASE:OnModify(ply, mods)
    if PS.GamemodeCheck(self) then return end
    if not trails[ply] or not trails[ply][self.ID] then return end
end

function BASE:OnThink(ply, mods)
    if PS.GamemodeCheck(self) then return end
    if CLIENT or not trails[ply] or not trails[ply][self.ID] then return end

    if ply:PS_IsSpectator() then
        self:OnHolster(ply, mods)
    end
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

    PS.AddColorModeSelector(panel, "Trail Color Mode", PS.HEXtoRGB(mods.color or ""), mods.colorSpeed, true, mods.colorMode, values, datas, function(v, d, c, s)
        PS:SendModification(self.ID, "colorMode", d)
        PS:SendModification(self.ID, "color", "#" .. PS.RGBtoHEX(c, true))
        PS:SendModification(self.ID, "colorSpeed", s)
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
        colorSpeed = isnumber(mods.colorSpeed) and math.Clamp(mods.colorSpeed, 1, 14) or 7
    }
end

PS.TrailColorsCache = PS.TrailColorCache or {}
local colorCache = PS.TrailColorsCache
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

    if not isnumber(mods.colorSpeed) then
        mods.colorSpeed = 7
    end

    if self.PlayerColorable and mods.colorMode == "player" then
        trail.Color = ply:GetPlayerColor():ToColor()
        return
    end

    if self.PlayerColorable and mods.colorMode == "rainbow" then
        trail.Color = HSVToColor(RealTime() * (10 * mods.colorSpeed) % 360, 1, 1)
        return
    end

    if not colorCache[mods.color] then
        colorCache[mods.color] = PS.HEXtoRGB(mods.color, true)
    end

    trail.Color = colorCache[mods.color]
end

function BASE:OnPanelSetup(panel)
    panel.Mat = Material(self.Material, "smooth")
    panel.FrameTime = 0
 end

 function BASE:OnPanelPaint(panel, w, h)
    PS.Mask(panel, 6, 6, w - 12, w - 12, function()
        surface.SetMaterial(panel.Mat)
        surface.SetDrawColor(255, 255, 255, 255)
        -- Scrolling down
        if panel:IsHovered() then
            panel.FrameTime = panel.FrameTime + 0.5
        end
        local y = math.Round(panel.FrameTime % 128)
        surface.DrawTexturedRect(6, 6 + y - 128, 128, 128)
        surface.DrawTexturedRect(6, 6 + y, 128, 128)
    end)
 end

return PS:RegisterBase(BASE)