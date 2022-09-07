local BASE = {}
BASE.ID = "trail"
BASE.Material = "trails/laser"
BASE.Modify = true
BASE.Color = Color(255, 255, 255)
BASE.Colorable = true

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
    if PS:IsSpectator(ply) then return end
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

function BASE:ColorFunction(trail, ply)
    local mods = ply:PS_GetModifiers(self.ID)

end

return PS:RegisterBase(BASE)