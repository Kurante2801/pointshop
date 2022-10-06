local ITEM = {}
ITEM.ID = "backpack"
ITEM.Base = "model"

ITEM.Name = "Backpack"
ITEM.Description = "It's actually a briefcase."
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 55),
    target = Vector(0, 0, 55),
    angle = Angle(0, -115, 0),
    fov = 35
}

ITEM.Props = {
    ["briefcase"] = {
        model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
        bone = "ValveBiped.Bip01_Spine2",
        pos = Vector(7.5, 5, -1.2),
        ang = Angle(0, 0, 0),
        scale = Vector(0.8, 0.8, 0.8),
    },
}

return PS:RegisterItem(ITEM)