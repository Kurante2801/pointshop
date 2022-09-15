local BASE = {}
BASE.ID = "trail"
BASE.Material = "trails/laser"
BASE.Modify = true
BASE.Color = Color(255, 255, 255)
BASE.PlayerColorable = true -- Can trail color be the same as PLAYER:GetPlayerColor

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
    if self:GamemodeCheck() then return end
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
    if self:GamemodeCheck() then return end
    if not PS.Trails[ply] then return end
    SafeRemoveEntity(PS.Trails[ply][self.ID])
    PS.Trails[ply][self.ID] = nil
end

function BASE:OnModify(ply, mods)
    if self:GamemodeCheck() then return end
    if not PS.Trails[ply] or not PS.Trails[ply][self.ID] then return end
end

function BASE:OnThink(ply, mods)
    if self:GamemodeCheck() then return end
    if CLIENT or not PS.Trails[ply] or not PS.Trails[ply][self.ID] then return end

    if ply:PS_IsSpectator() then
        self:OnHolster(ply, mods)
    end
end

function BASE:OnCustomizeSetup(panel, mods)
    mods.color = mods.color or "#FFFFFF"

    self:SetupThinker(panel, mods, {
        colorMode = mods.colorMode, color = mods.color
    }, function(a, b)
        return not PS.TablesEqual(a, b)
    end, function(reference, copy)
        return table.Copy(reference)
    end)

    PS.AddColorSelector(panel, "Trail Color", mods.color, function(value)
        mods.color = value
    end)
end

function PS.AddColorSelector(panel, text, value, callback)
    local container = panel:Add("EditablePanel")
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 6)
    container:SetTall(32)

    container.header = container:Add("PS_Button")
    container.header:Dock(LEFT)
    container.header:DockMargin(0, 0, 6, 0)
    container.header:SetWide(180)
    container.header:SetText(text)
    container.header:SetMouseInputEnabled(false)
    container.header:SetThemeMainColor("Foreground1Color")
end

function BASE:SanitizeTable(mods)
    if not self.Modify or not mods.color or not isstring(mods.color) then return {} end

    local color = mods.color
    if color == "player" and not self.PlayerColorable then return {} end

    return { color = PS.SanitizeHEX(color, true) }
end

PS.TrailColorsCache = PS.TrailColorCache or {}

function BASE:ColorFunction(trail, ply)
    local mods = ply:PS_GetModifiers(self.ID)

    if not self.Modify or not isstring(mods.color) then
        surface.SetDrawColor(255, 255, 255, 255)
        return
    end

    if self.PlayerColorable and mods.color == "player" then
        local color = ply:GetPlayerColor() -- Not using :ToColor since I don't need a table here
        surface.SetDrawColor(color.x * 255, color.y * 255, color.z * 255)
        return
    end

    if not PS.TrailColorsCache[mods.color] then
        PS.TrailColorsCache = PS.HEXtoRGB(mods.color, true)
    end

    local color = PS.TrailColorsCache[mods.color]
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
end

return PS:RegisterBase(BASE)