local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "lampshadehat"

ITEM.Name = "Lampshade Hat"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["lamp"] = {
        model = "models/props_c17/lampShade001a.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, -1, 8),
        ang = Angle(-90, -70, 0),
        scale = Vector(0.75, 0.75, 0.75),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)