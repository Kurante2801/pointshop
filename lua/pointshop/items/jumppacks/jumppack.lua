local ITEM = {}
ITEM.ID = "jumppack"
ITEM.Base = "jumppack"

ITEM.Name = "Classic Jump Pack"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 55),
    target = Vector(0, 0, 55),
    angle = Angle(0, -115, 0),
    fov = 35
}

ITEM.Props = {
    ["jetstream_sam"] = {
        model = "models/xqm/jetengine.mdl",
        bone = "ValveBiped.Bip01_Spine2",
        pos = Vector(5, -9.75, 0),
        ang = Angle(0, -9.5, 0),
        scale = Vector(0.5, 0.5, 0.5),
    },
}

return PS:RegisterItem(ITEM)