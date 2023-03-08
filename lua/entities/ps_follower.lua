AddCSLuaFile()

-- Based off: https://steamcommunity.com/sharedfiles/filedetails/?id=340516399

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.PrintName = "PS Follower"
ENT.Spawnable = true
ENT.DisableDuplicator = true
ENT.DisablePhysGun = true

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:DrawShadow(false)

    self.AngleWeight = 0
end

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "ItemID")
end

function ENT:SpawnFunction(ply, tr, class)
    local ent = ents.Create(class)
    ent:SetOwner(ply)
    ent:SetPos(ply:EyePos())
    ent:Spawn()

    return ent
end

function ENT:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then
        if SERVER then
            SafeRemoveEntity(self)
        end
        return
    end

    -- Cache ITEM
    if not self.Item then
        self.Item = PS.Items[self:GetItemID()]
        if not self.Item then return end
    end

    -- Position
    local ang = Angle(0, owner:GetAngles().y, 0)
    local origin = owner:GetPos() + Vector(0, 0, owner:Crouching() and 32 or 60)
    local targetPos = origin + ang:Right() * -20 + ang:Up() * 10 + ang:Forward() * -10

    local tr = util.TraceLine({
        start = origin,
        endpos = targetPos,
        filter = owner
    })

    targetPos = tr.HitPos + Vector(0, 0, 1) * math.sin(CurTime() * 1.5) * 4
    local pos = targetPos - self:GetPos()
    local velocity = math.Clamp(pos:Length(), 0, 150)
    pos:Normalize()
    self:SetLocalVelocity(pos * velocity * 3) -- Speed Multiplier

    -- Angles
    velocity = self:GetVelocity()
    local speed = velocity:LengthSqr() * 0.0005
    self.AngleWeight = math.Approach(self.AngleWeight, speed > 1.5 and 1 or 0, FrameTime() * (speed > 2.5 and 3 or 2.5))

    local move = Angle(0, velocity:Angle().y, 0)
    local stop = Angle(0, owner:GetAngles().y, 0)
    self:SetAngles(LerpAngle(self.AngleWeight, stop, move))

    if not CLIENT then return end

    -- Draw CS Model
    if not IsValid(self.CSModel) then
        self.CSModel = ClientsideModel(self.Item.Model, RENDERGROUP_BOTH)
        self.CSModel:SetParent(self)
        self.CSModel:SetNoDraw(true)
        self.CSModel:DrawShadow(false)
        self.CSModel:DestroyShadow()
        self.Item:OnModelInitialize(owner, self, self.CSModel)
    end

    pos, ang = self.Item:ModifyClientsideModel(owner, self.CSModel, self:GetPos(), self:GetAngles())
    self.CSModel:SetPos(pos)
    self.CSModel:SetAngles(ang)
    self.Item:OnModelThink(owner, self, self.CSModel)

    -- Particle System
    if self.Item.Particles and not self.Effect then
        self.Effect = true

        local data = EffectData()
        data:SetStart(pos)
        data:SetOrigin(pos)
        data:SetEntity(self)
        data:SetScale(1)
        util.Effect(self.Item.Particles, data)
    end

    if owner == LocalPlayer() then
        self:NextThink(CurTime())
        return true
    end
end

function ENT:OnRemove()
    SafeRemoveEntity(self.CSModel)
end

function ENT:Draw()
    local owner = self:GetOwner()
    local isFirstPerson = false

    if owner == LocalPlayer():GetViewEntity() then
        isFirstPerson = not owner:ShouldDrawLocalPlayer()
    end
    if not IsValid(owner) or not self.Item or not IsValid(self.CSModel) or not owner:PS_CanSeeItem(self.Item.ID, isFirstPerson) then return end

    self.Item:OnPreModelDraw(owner, self, self.CSModel)
    self.CSModel:DrawModel()
end