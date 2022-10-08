local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "buckethat"

ITEM.Name = "Bucket Hat"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["bucket"] = {
        model = "models/props_junk/MetalBucket01a.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, -2, 8),
        ang = Angle(90, 60, 0),
        scale = Vector(0.65, 0.65, 0.65),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)