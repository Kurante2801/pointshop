local ITEM = {}
ITEM.Base = "model"

-- Bones: https://wiki.facepunch.com/gmod/ValveBiped_Bones

ITEM.Name = "Bomb Head"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["bomb"] = {
        model = "models/Combine_Helicopter/helicopter_bomb01.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(3, -2.427, 0),
        ang = Angle(0, -160, 180),
        scale = Vector(0.425, 0.425, 0.425),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)