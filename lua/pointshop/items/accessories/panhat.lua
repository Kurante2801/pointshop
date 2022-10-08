local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "panhat"

ITEM.Name = "Pan Hat"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["pan"] = {
        model = "models/props_interiors/pot02a.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(-6, 0, 6),
        ang = Angle(90, 70, 0),
        scale = Vector(1.2, 1.2, 1.2),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)