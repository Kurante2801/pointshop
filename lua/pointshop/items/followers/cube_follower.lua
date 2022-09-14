local ITEM = {}
ITEM.Base = "follower"
ITEM.ID = "cube_follower"

ITEM.Name = "Cube"
ITEM.Price = 1000
ITEM.Model = "models/hunter/blocks/cube025x025x025.mdl"

function ITEM:OnModelInitialize(ply, ent, model)
    model:SetModelScale(0.75, 0)
end

return PS:RegisterItem(ITEM)