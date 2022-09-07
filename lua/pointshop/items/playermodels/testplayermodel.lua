local ITEM = {}
ITEM.ID = "testplayermodel"
ITEM.Base = "playermodel"
ITEM.Name = "Casual Girl"
ITEM.Description = ""
ITEM.Model = "models/casualgirl_compressed/tda_kenzie.mdl"
ITEM.Price = 7500

ITEM.Modify = true
ITEM.Skins = { 0, 1 }
ITEM.Bodygroups = {
    {
        name = "Hair",
        id = 2,
        values = { 0, 1, 2, 3, 4, 5, 6, 7 },
    },
}

return PS:RegisterItem(ITEM)