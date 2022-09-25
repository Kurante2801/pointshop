local BASE = {}
BASE.ID = "mask"
BASE.Material = "pointshop/masks/gman_alyx.png"
BASE.Scale = 1

function BASE:OnPanelSetup(panel)
   panel.MaskMat = Material(self.Material, "noclamp smooth")
end

function BASE:OnPanelPaint(panel, w, h)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(panel.MaskMat)
    surface.DrawTexturedRect(6, 6, 128, 128)
end

function BASE:OnPlayerDraw(ply, flags, ent, mods)
    if PS.GamemodeCheck(self) or not PS:CanSeeAccessory(ply) then return end

    self:DrawMask(ent or ply)
end

function BASE:OnPreviewDraw(w, h, panel)
    self:DrawMask(panel.Entity)
end

local v1, v2, v3, v4 = Vector(), Vector(), Vector(), Vector()
function BASE:DrawQuad(pos, ang, w, h, color)
    w = w * 0.5
    h = h * 0.5

    v1 = pos + ang:Up() * h + ang:Right() * w
    v2 = pos + ang:Up() * h - ang:Right() * w

    v3 = pos - ang:Up() * h - ang:Right() * w
    v4 = pos - ang:Up() * h + ang:Right() * w

    render.DrawQuad(v1, v2, v3, v4, color)
end

local materials = {}
local COLOR_WHITE = Color(255, 255, 255)

function BASE:DrawMask(ent)
    if not materials[self.Material] then
        materials[self.Material] = Material(self.Material, "smooth")
    end

    local mat = materials[self.Material]

    local attach_id = ent:LookupAttachment("eyes")
    if not attach_id then return end

    local attachment = ent:GetAttachment(attach_id)
    if not attachment then return end

    local pos = attachment.Pos
    local ang = attachment.Ang

    pos = pos + ang:Forward() * 2.5 * self.Scale
    render.SetMaterial(mat)
    self:DrawQuad(pos, ang, 10, 10, COLOR_WHITE)
    ang:RotateAroundAxis(ang:Up(), 180)
    self:DrawQuad(pos, ang, 10, 10, COLOR_WHITE)
end

return PS:RegisterBase(BASE)