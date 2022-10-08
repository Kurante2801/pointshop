local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "melonhead"

ITEM.Name = "Melon Head"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["melon"] = {
        model = "models/props_junk/watermelon01.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 0, 2),
        ang = Angle(90, 0, 0),
        scale = Vector(1, 1, 1),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)