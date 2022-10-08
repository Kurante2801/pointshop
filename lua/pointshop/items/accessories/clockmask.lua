local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "clockmask"

ITEM.Name = "Clock Mask"
ITEM.Price = 50

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["clock"] = {
        model = "models/props_c17/clock01.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 5, 4),
        ang = Angle(90, 0, 180),
        scale = Vector(1, 1, 1),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)