local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "noentrymask"

ITEM.Name = "No Entry Mask"
ITEM.Price = 50

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["sign"] = {
        model = "models/props_c17/streetsign004f.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 6, 4),
        ang = Angle(-90, 100, 90),
        scale = Vector(0.7, 0.7, 0.7),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)