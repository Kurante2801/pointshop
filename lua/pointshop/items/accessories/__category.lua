local CATEGORY = {}

CATEGORY.ID = "accessories"
CATEGORY.Material = "lbg_pointshop/derma/tie.png"
CATEGORY.Name = "Accessories"
CATEGORY.Description = ""
CATEGORY.Order = 1

CATEGORY.Subcategories = {}

CATEGORY.Subcategories["user"] = {
    Name = "User Accessories",
    Description = "Accessories for all users",
    Order = 1,
    Default = true
}

CATEGORY.Subcategories["admin"] = {
    Name = "Admin Accessories",
    Description = "Accessories for admins, this should support multiline in theory, IN THEORY communism works, in theory",
    Order = 2,
}

return PS:RegisterCategory(CATEGORY)