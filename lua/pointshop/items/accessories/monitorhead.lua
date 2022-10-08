local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "monitorhead"

ITEM.Name = "Monitor Head"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["monitor"] = {
        model = "models/props_lab/monitor02.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 0, -4),
        ang = Angle(0, -90, -90),
        scale = Vector(0.75, 0.75, 0.75),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)