local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "skullhead"

ITEM.Name = "Skull Head"
ITEM.Price = 150

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["skull"] = {
        model = "models/Gibs/HGIBS.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 1.5, 4),
        ang = Angle(0, -90, 270),
        scale = Vector(1.5, 1.5, 1.5),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)