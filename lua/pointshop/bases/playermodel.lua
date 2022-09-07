local BASE = {}
BASE.ID = "playermodel"
BASE.IsPlayermodel = true
BASE.Modify = false -- set to true on ITEM when adding skins/bodygroups
BASE.Colorable = true

function BASE:OnEquip(ply, mods)
    if self:GamemodeCheck() or ply:PS_IsSpectator() then return end

    if not ply.PS_OldModel then
        local old = ply:GetModel()
        if old ~= "models/player.mdl" and old ~= self.Model then
            ply.PS_OldModel = ply.PS_OldModel or old
        end
    end

    ply:SetModel(self.Model)
    ply:SetupHands()
end

function BASE:OnSpawn(ply, mods)
    if self:GamemodeCheck() or ply:PS_IsSpectator() then return end

    local old = ply:GetModel()
    if old ~= "models/player.mdl" and old ~= self.Model then
        ply.PS_OldModel = ply.PS_OldModel or old
    end

    self:OnEquip(ply, mods)
    self:SetBodygroups(ply, mods)
end

function BASE:OnHolster(ply)
    if self:GamemodeCheck() or ply:PS_IsSpectator() then return end

    if ply.PS_OldModel then
        ply:SetModel(ply.PS_OldModel)
    end
end

function BASE:OnModify(ply, mods)
    if self:GamemodeCheck() or ply:PS_IsSpectator() then return end
    self:SetBodygroups(ply, mods)
end

function BASE:SetBodygroups(ply, mods)
    if self.Skins then
        if #self.Skins == 1 or not mods.skin or not table.HasValue(self.Skins, mods.skin) then
            ply:SetSkin(self.Skins[1])
        else
            ply:SetSkin(mods.skin)
        end
    end

    if not self.Bodygroups then
        for _, group in ipairs(ply:GetBodyGroups()) do
            ply:SetBodygroup(group.id, 0)
        end
    else
        for _, group in ipairs(self.Bodygroups) do
            if #group.values == 1 or not mods.bodygroups or not mods.bodygroups[group.id] then
                ply:SetBodygroup(group.id, group.values[1])
            else
                ply:SetBodygroup(group.id, mods.bodygroups[group.id])
            end
        end
    end
end

function BASE:SanitizeTable(mods)
    if self.Colorable and isstring(mods.color) then
        mods.color = PS.SanitizeHEX(mods.color)
    else
        mods.color = nil
    end

    if not self.Skins then
        mods.skin = nil
    else
        mods.skin = tonumber(mods.skin)
        if mods.skin and not table.HasValue(self.Skins, mods.skin) then
            mods.skin = nil
        end
    end

    if not self.Bodygroups then
        mods.bodygroups = nil
    end

    mods.bodygroups = mods.bodygroups or {}
    local ids = {}

    for _, group in ipairs(self.Bodygroups or {}) do
        local mod = tonumber(mods.bodygroups[group.id])
        if not mod or #group.values == 1 or not table.HasValue(group.values, mod) then
            ids[group.id] = group.values[1]
        else
            ids[group.id] = mod
        end
    end

    return {
        skin = mods.skin, bodygroups = ids, color = mods.color
    }
end

function BASE:OnCustomizeSetup(panel, mods)
    self:SetupThinker(panel, mods, {
        skin = mods.skin, bodygroups = table.Copy(mods.bodygroups)
    }, function(a, b)
        if a.skin ~= b.skin then return true end

        for _, group in ipairs(self.Bodygroups or {}) do
            if a.bodygroups[group.id] ~= b.bodygroups[group.id] then
                return true
            end
        end

        return false
    end, function(reference, copy)
        copy.skin = reference.skin
        copy.bodygroups = reference.bodygroups and table.Copy(reference.bodygroups) or nil
    end)

    if self.Skins and #self.Skins > 1 then
        self:AddSelector(panel, "Skin", mods.skin or self.Skins[1], self.Skins, function(value)
            mods.skin = value
        end)
    end

    if self.Bodygroups then
        for _, group in ipairs(self.Bodygroups) do
            if #group.values > 1 then
                self:AddSelector(panel, group.name, mods.bodygroups[group.id] or group.values[0], group.values, function(value)
                    mods.bodygroups[group.id] = value
                end)
            end
        end
    end
end

function BASE:AddSelector(panel, text, value, values, callback)
    local container = panel:Add("EditablePanel")
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 6)
    container:SetTall(32)

    local header = container:Add("PS_Button")
    header:Dock(LEFT)
    header:DockMargin(0, 0, 6, 0)
    header:SetWide(180)
    header:SetText(text)
    header:SetMouseInputEnabled(false)
    header:SetThemeMainColor("Foreground1Color")

    local grid = container:Add("DIconLayout")
    grid:Dock(TOP)
    grid:SetSpaceX(6)
    grid:SetSpaceY(6)

    for _, v in ipairs(values) do
        local button = grid:Add("PS_Button")
        button:SetText(v)
        button:SetTall(32)
        button:SetupTransition("Selected", 6, function() return value == v end)
        button.Paint = function(this, w, h)
            draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * this.Selected))
        end
        button.DoClick = function()
            value = v
            callback(v)
        end
    end

    grid:TDLib():On("PerformLayout", function(this)
        container:SetTall(this:GetTall())
    end)
end

function BASE:ToString()
    return "[playermodel] " .. self.ID
end

-- Compat until I make new menu
function BASE:ModifyClientsideModel(ply, model, pos, ang)
    return model, pos, ang
end

return PS:RegisterBase(BASE)