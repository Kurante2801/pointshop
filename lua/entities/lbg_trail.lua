AddCSLuaFile()
ENT.Type = "anim"

ENT.PrintName = "LBG Trail"
ENT.Spawnable = true
ENT.DisableDuplicator = true
ENT.DisablePhysGun = true

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:DrawShadow(false)
    self:SetSolid(SOLID_NONE)
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)

    if CLIENT then
        self.LastSegmentTime = CurTime()
        self.Segments = {}
        self.TexturePos = 0
        self.ColorCache = "#FFFFFF"
        self.MaterialPath = "vgui/white"
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "MaterialPath")
    self:NetworkVar("String", 1, "ItemID")
    self:NetworkVar("Float", 0, "StartWidth")
    self:NetworkVar("Float", 1, "EndWidth")
    self:NetworkVar("Float", 2, "LifeTime")
end

function ENT:SpawnFunction(ply, tr, class)
    local ent = ents.Create(class)
    ent:SetParent(ply)
    ent:SetOwner(ply)
    ent:Spawn()

    return ent
end

function ENT:Think()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetPos(owner:GetPos())

    if SERVER then return end

    if owner:Team() == TEAM_SPECTATOR or IsValid(owner:GetObserverTarget()) then
        self.ShouldDraw = false
    elseif owner == LocalPlayer() then
        self.ShouldDraw = true
    else
        self.ShouldDraw = PS:CanSeeTrail(owner)
    end

    if not self.ShouldDraw then return end

    local time = CurTime()

    -- Add new segments
    if time - self.LastSegmentTime > 0.0125 then
        self.LastSegmentTime = time
        local len = #self.Segments

        local seg = {
            time = time,
            pos = owner:GetPos(),
            x = 0
        }
        -- Don't add another one if we didn't move
        if len > 1 then
            local dist = self.Segments[len - 1].pos:Distance(seg.pos)
            -- Shift texture
            if dist > 0.1 then
                self.TexturePos = self.TexturePos + dist * 0.062
                seg.x = self.TexturePos % self.Material:Width()
                table.insert(self.Segments, seg)
            end
        else
            table.insert(self.Segments, seg)
        end
    end

    -- Delete old segments
    for i, seg in ipairs(self.Segments) do
        if time - seg.time > self:GetLifeTime() then
            table.remove(self.Segments, i)
        end
    end

    -- Update color
    if self:GetItemID() ~= "" then
        PS.Items[self:GetItemID()]:ColorFunction(self, owner)
    else
        self:ColorFunction(owner)
    end

    -- Update material
    if self.MaterialPath ~= self:GetMaterialPath() then
        self.MaterialPath = self:GetMaterialPath()
        self.Material = Material(self.MaterialPath, "alphatest noclamp smooth")
    end
end

local mins, maxs = Vector(0, 0, 0), Vector(0, 0, 0)
function ENT:DrawTranslucent()
    if not self.ShouldDraw then return end

    local len = #self.Segments
    if len < 2 then return end

    render.SetMaterial(self.Material)
    render.StartBeam(len)

    local time = CurTime()

    for i, seg in ipairs(self.Segments) do
        if i < 2 or i > len then continue end

        local last = self.Segments[i - 1]
        if not last then continue end

        local difference = time - seg.time

        local w = self:WidthFunction(difference)

        render.AddBeam(seg.pos, w, seg.x, self.Color)

        -- Update render box
        mins.x = math.min(mins.x, seg.pos.x, last.pos.x)
        mins.y = math.min(mins.y, seg.pos.y, last.pos.y)
        mins.z = math.min(mins.z, seg.pos.z, last.pos.z)

        maxs.x = math.max(maxs.x, seg.pos.x, last.pos.x)
        maxs.y = math.max(maxs.y, seg.pos.y, last.pos.y)
        maxs.z = math.max(maxs.z, seg.pos.z, last.pos.z)
    end

    render.EndBeam()

    self:SetRenderBoundsWS(mins, maxs)
end

function ENT:WidthFunction(x)
    local startW = self:GetStartWidth()
    local endW = self:GetEndWidth()

    if startW == endW then
        return startW
    elseif startW > endW then
        return math.Clamp(startW - x * (startW - endW) / self:GetLifeTime() + endW, endW, startW)
    else
        return math.Clamp(startW + x * (endW - startW) / self:GetLifeTime() + startW, startW, endW)
    end
end

function ENT:AlphaFunction(x)
    return 255 - x * 255 / self:GetLifeTime()
end

function ENT:ColorFunction(owner)
    return Color(0, 0, 255) -- This shouldn't be called normally
end