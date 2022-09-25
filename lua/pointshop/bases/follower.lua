local BASE = {}
BASE.ID = "follower"

BASE.Model = "models/Gibs/HGIBS.mdl"

function BASE:CreateEnt(ply, mods)
    local ent = ents.Create("lbg_follower")
    ent:SetOwner(ply)
    ent:SetPos(ply:EyePos())
    ent:Spawn()
    ent:SetItemID(self.ID)

    return ent
end

function BASE:OnEquip(ply, mods)
    PS.Followers = PS.Followers or {}
    PS.Followers[ply] = PS.Followers[ply] or {}

    self:OnHolster(ply)
    if PS.GamemodeCheck(self) or not ply:Alive() or ply:PS_IsSpectator() then return end

    PS.Followers[ply][self.ID] = self:CreateEnt(ply, mods)
end

function BASE:OnHolster(ply)
    if PS.GamemodeCheck(self) or not PS.Followers or not PS.Followers[ply] then return end

    SafeRemoveEntity(PS.Followers[ply][self.ID])
    PS.Followers[ply][self.ID] = nil
end

function BASE:OnSpawn(ply, mods)
    self:OnEquip(ply, mods)
end

function BASE:OnDeath(ply)
    self:OnHolster(ply)
end

function BASE:ModifyClientsideModel(ply, model, pos, ang)
    return pos, ang
end

function BASE:OnModelInitialize(ply, ent, model)
end

function BASE:OnModelThink(ply, ent, model)
end

function BASE:OnPreModelDraw(ply, ent, model)
end

return PS:RegisterBase(BASE)