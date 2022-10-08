local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "conehat"

ITEM.Name = "Cone Hat"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["cone"] = {
        model = "models/props_junk/TrafficCone001a.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0.25, -4, 16),
        ang = Angle(-90, -70, 0),
        scale = Vector(0.8, 0.8, 0.8),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)