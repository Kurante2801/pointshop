local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "headcrabhat"

ITEM.Name = "Headcrab Hat"
ITEM.Price = 100
ITEM.AllowedUserGroups = PS.UserGroups["admin"]
ITEM.Subcategory = "admin"

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["headcrab"] = {
        model = "models/headcrabclassic.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 5, 6),
        ang = Angle(-90, -50, 0),
        scale = Vector(0.75, 0.75, 0.75),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)