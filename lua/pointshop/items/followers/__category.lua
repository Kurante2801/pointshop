local CATEGORY = {}

CATEGORY.ID = "followers"
CATEGORY.Material = "lbg_pointshop/derma/mood.png"
CATEGORY.Name = "Followers"
CATEGORY.Description = "Models that follow you around"
CATEGORY.Order = 8
CATEGORY.AllowedEquipped = 1

CATEGORY.Subcategories = {}

CATEGORY.Subcategories["user"] = {
    Name = "User Followers",
    Description = "Followers for all users",
    Order = 1,
    Default = true
}

CATEGORY.Subcategories["admin"] = {
    Name = "Admin Followers",
    Description = "Followers for admins",
    Order = 2,
}

return PS:RegisterCategory(CATEGORY)