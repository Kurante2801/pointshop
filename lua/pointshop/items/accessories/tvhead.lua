local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "tvhead"

ITEM.Name = "TV Head"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["snowman"] = {
        model = "models/props_c17/tv_monitor01.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(-1.5, 0, 2),
        ang = Angle(0, -90, -90),
        scale = Vector(1, 1, 1),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)