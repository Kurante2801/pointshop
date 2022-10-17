function EFFECT:Init(data)
    local ent = data:GetEntity()
    if not IsValid(ent) then return end
    self:SetOwner(ent)
    self.Emitter = ParticleEmitter(ent:GetPos())
end

function EFFECT:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then
        if IsValid(self.Emitter) then
            self.Emitter:Finish()
        end

        return false
    end

    local ply = owner:GetOwner()
    local isFirstPerson = false
    if ply == LocalPlayer():GetViewEntity() then
        isFirstPerson = not ply:ShouldDrawLocalPlayer()
    end
    if not IsValid(ply) or not ply:PS_CanSeeItem("skull_follower", isFirstPerson) then return true end

    local pos = owner:GetPos()
    self.Emitter:SetPos(pos)
    local particle = self.Emitter:Add("particles/flamelet3", pos)
    if not particle then return true end

    particle:SetVelocity(Vector(0, 0, 0))
    particle:SetLifeTime(0)
    particle:SetDieTime(0.5)
    particle:SetStartAlpha(255)
    particle:SetEndAlpha(0)
    particle:SetStartSize(7)
    particle:SetEndSize(3)
    particle:SetAngles(Angle(0, 0, 0))
    particle:SetAngleVelocity(Angle(0, 0, 0))
    particle:SetRoll(math.Rand(0, 360))

    local val = math.random(150, 255)
    particle:SetColor(255, val, val, 150)
    particle:SetGravity(Vector(math.random(0, 5), math.random(0, 5), 100))
    particle:SetAirResistance(0)
    particle:SetCollide(false)
    particle:SetBounce(0)

    return true
end

function EFFECT:Render()
end