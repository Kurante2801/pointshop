local ITEM = {}
ITEM.Base = "follower"
ITEM.ID = "cube_follower"

ITEM.Name = "Cube"
ITEM.Price = 1000
ITEM.Model = "models/hunter/blocks/cube025x025x025.mdl"

function ITEM:ModifyClientsideModel(ply, model, pos, ang)
    model:SetModelScale(0.75, 0)
    return pos, ang
end

return PS:RegisterItem(ITEM)