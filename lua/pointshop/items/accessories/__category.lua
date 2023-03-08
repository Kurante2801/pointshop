local CATEGORY = {}

CATEGORY.ID = "accessories"
CATEGORY.Material = "pointshop/derma/tie.png"
CATEGORY.Name = "Accessories"
CATEGORY.Description = ""
CATEGORY.Order = 1

-- Description supports multi-line!
CATEGORY.Subcategories = {}

CATEGORY.Subcategories["user"] = {
    Name = "User Accessories",
    Description = "Accessories for all users",
    Order = 1,
    Default = true
}

CATEGORY.Subcategories["admin"] = {
    Name = "Admin Accessories",
    Description = "Accessories for admins",
    Order = 2,
}

return PS:RegisterCategory(CATEGORY)