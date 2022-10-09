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
    ["jetengine"] = {
        model = "models/xqm/jetengine.mdl",
        bone = "ValveBiped.Bip01_Spine2",
        pos = Vector(0, 9.75, 5),
        ang = Angle(0, 0, 0),
        scale = Vector(0.5, 0.5, 0.5),
        colorabletype = "mods"
    },
}

return PS:RegisterItem(ITEM)