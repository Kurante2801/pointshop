local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "afro"

ITEM.Name = "Afro"
ITEM.Price = 200

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["afro"] = {
        model = "models/dav0r/hoverball.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, -3, 8),
        ang = Angle(0, 180, -45),
        scale = Vector(1.25, 1.25, 1.25),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = "models/weapons/v_stunbaton/w_shaft01a"
    }
}


return PS:RegisterItem(ITEM)