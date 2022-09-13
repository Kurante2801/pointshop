local ITEM = {}
ITEM.Base = "follower"
ITEM.ID = "skull_follower"

ITEM.Name = "Flaming Skull"
ITEM.Price = 1000
ITEM.Model = "models/Gibs/HGIBS.mdl"
ITEM.Particles = "follower_flames"

ITEM.Subcategory = "admin"
ITEM.AllowedUserGroups = PS.UserGroups["admin"]

return PS:RegisterItem(ITEM)