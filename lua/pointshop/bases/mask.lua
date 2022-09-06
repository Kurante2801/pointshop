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


local materials = {}
function BASE:OnPlayerDraw(ply)
    if self:GamemodeCheck() then return end

    if not materials[self.Material] then
        materials[self.Material] = Material(self.Material, "noclamp smooth")
    end

    local mat = materials[self.Material]

    local attach_id = ply:LookupAttachment("eyes")
    if not attach_id then return end

    local attachment = ply:GetAttachment(attach_id)
    if not attachment then return end

    local pos = attachment.Pos
    local ang = attachment.Ang
    -- Front
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), -90)
    cam.Start3D2D(pos - (ang:Forward() * (5 * self.Scale)) + (ang:Right() * (-5 * self.Scale)) + (ang:Up() * 2.5), ang, self.Scale)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(0, 0, 10, 10)
    cam.End3D2D()
    -- Back
    ang:RotateAroundAxis(ang:Right(), 180)
    cam.Start3D2D(pos - (ang:Forward() * (5 * self.Scale)) + (ang:Right() * (-5 * self.Scale)) + (ang:Up() * -2.5), ang, self.Scale)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(0, 0, 10, 10)
    cam.End3D2D()
end

return PS:RegisterBase(BASE)