local BASE = {}
BASE.ID = "playermodel"
BASE.IsPlayermodel = true
BASE.Modify = false -- set to true on ITEM when adding skins/bodygroups
BASE.Colorable = true

function BASE:OnEquip(ply, mods)
    if PS.GamemodeCheck(self) or ply:PS_IsSpectator() then return end

    if not ply.PS_OldModel then
        local old = ply:GetModel()
        if old ~= "models/player.mdl" and old ~= self.Model then
            ply.PS_OldModel = ply.PS_OldModel or old
        end
    end

    ply:SetModel(self.Model)
    self:SetBodygroups(ply, mods)
    ply:SetupHands()
end

function BASE:OnSpawn(ply, mods)
    if PS.GamemodeCheck(self) or ply:PS_IsSpectator() then return end

    local old = ply:GetModel()
    if old ~= "models/player.mdl" and old ~= self.Model then
        ply.PS_OldModel = ply.PS_OldModel or old
    end

    self:OnEquip(ply, mods)
end

function BASE:OnHolster(ply)
    if PS.GamemodeCheck(self) or ply:PS_IsSpectator() then return end

    if ply.PS_OldModel then
        ply:SetModel(ply.PS_OldModel)
    end
end

function BASE:OnModify(ply, mods)
    if PS.GamemodeCheck(self) or ply:PS_IsSpectator() then return end
    self:SetBodygroups(ply, mods)
end

local empty = {}
function BASE:OnPanelSetup(panel)
    panel.ModelPanel = panel:Add("DModelPanel")
    panel.ModelPanel:SetPos(6, 6)
    panel.ModelPanel:SetSize(128, 128)
    panel.ModelPanel:SetMouseInputEnabled(false)
    panel.ModelPanel:SetModel(self.Model)
    self:SetBodygroups(panel.ModelPanel.Entity, empty)

    local PrevMins, PrevMaxs = panel.ModelPanel.Entity:GetRenderBounds()
    panel.ModelPanel:SetCamPos(PrevMins:Distance(PrevMaxs) * Vector(0.5, 0.5, 0.5))
    panel.ModelPanel:SetLookAt((PrevMaxs + PrevMins) / 2)

    panel.ModelPanel.LayoutEntity = function(this, ent)
        if this:GetParent():IsHovered() then
            ent:SetAngles(Angle(0, ent:GetAngles().y + 1, 0))
        end

        ent.GetPlayerColor = function() return LocalPlayer():GetPlayerColor() end
    end
end

function BASE:OnPreviewDraw(w, h, panel)
    if panel:GetModel() ~= self.Model then
        panel:SetModel(self.Model)
        self:SetBodygroups(panel.Entity, empty)
    end
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
    if self.Skins and #self.Skins > 1 then
        PS.AddSelector(panel, "Skin", mods.skin or self.Skins[1], self.Skins, function(value)
            PS:SendModification(self.ID, "skin", value)
        end)
    end

    if self.Bodygroups then
        for _, group in ipairs(self.Bodygroups) do
            if #group.values > 1 then
                PS.AddSelector(panel, group.name, mods.bodygroups[group.id] or group.values[0], group.values, function(value)
                    mods.bodygroups[group.id] = value
                    PS:SendModification(self.ID, "bodygroups", mods.bodygroups)
                end)
            end
        end
    end
end

function BASE:ToString()
    return "[playermodel] " .. self.ID
end

-- Compat until I make new menu
function BASE:ModifyClientsideModel(ply, model, pos, ang)
    return model, pos, ang
end

return PS:RegisterBase(BASE)