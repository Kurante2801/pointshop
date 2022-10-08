local ITEM = {}
ITEM.Base = "model"
ITEM.ID = "turtlehat"

ITEM.Name = "Turtle Hat"
ITEM.Price = 100

ITEM.CameraData = {
    pos = Vector(50, 50, 70),
    target = Vector(0, 0, 70),
    fov = 25
}

ITEM.Props = {
    ["snowman"] = {
        model = "models/props/de_tides/Vending_turtle.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(0, 0, 6),
        ang = Angle(90, 240, 90),
        scale = Vector(1, 1, 1),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}


return PS:RegisterItem(ITEM)