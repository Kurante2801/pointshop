local BASE = {}

BASE.ID = "jumppack"
BASE.Base = "model"

function BASE:OnMove(ply, mods, data)
    if PS.GamemodeCheck(self) then return end

    local buttons = data:GetButtons()
    if bit.band(buttons, IN_JUMP) > 0 then
        data:SetVelocity(data:GetVelocity() + Vector(0, 0, 100) * FrameTime())
    end
end

return PS:RegisterBase(BASE)