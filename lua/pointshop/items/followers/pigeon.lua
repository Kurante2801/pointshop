local ITEM = {}
ITEM.Base = "follower"

-- Example of a follower with an animation

ITEM.ID = "pigeon"
ITEM.Name = "Pigeon"
ITEM.Model = "models/pigeon.mdl"

function ITEM:OnModelThink(ply, ent, model)
    local sequence
    if ent.AngleWeight >= 1 and ent:GetVelocity().z < 0 then
        sequence = model:LookupSequence("Soar")
    else
        sequence = model:LookupSequence("Fly01")
    end

    model:SetPlaybackRate(1)
    model:ResetSequence(sequence)
end

function ITEM:OnPreModelDraw(ply, ent, model)
    model:FrameAdvance()
end

return PS:RegisterItem(ITEM)