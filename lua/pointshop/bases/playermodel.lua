local BASE = {}
BASE.ID = "playermodel"
BASE.IsPlayermodel = true

function BASE:OnEquip(ply, mods)
    if self:GamemodeCheck() or PS:IsSpectator(ply) then return end

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
    if self:GamemodeCheck() or PS:IsSpectator(ply) then return end

    local old = ply:GetModel()
    if old ~= "models/player.mdl" and old ~= self.Model then
        ply.PS_OldModel = ply.PS_OldModel or old
    end

    self:OnEquip(ply, mods)
end

function BASE:OnHolster(ply)
    if self:GamemodeCheck() or PS:IsSpectator(ply) then return end

    if ply.PS_OldModel then
        ply:SetModel(ply.PS_OldModel)
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