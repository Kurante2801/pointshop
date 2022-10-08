local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "snowmanhead"

ITEM.Name = "Snowman Head"
ITEM.Price = 200

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["snowman"] = {
        model = "models/props/cs_office/Snowman_face.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 2, 4),
        ang = Angle(0, -90, 180),
        scale = Vector(1.25, 1.25, 1.25),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)