PS.Config = {}
-- Edit below
PS.Config.CommunityName = "My Community"
PS.Config.DataProvider = "sql"
PS.Config.ShopKey = "F3" -- Any Uppercase key or blank to disable
PS.Config.ShopCommand = "ps_shop" -- Console command to open the shop, set to blank to disable
PS.Config.ShopChatCommand = "!shop" -- Chat command to open the shop, set to blank to disable
PS.Config.NotifyOnJoin = true -- Should players be notified about opening the shop when they spawn?
PS.Config.PointsOverTime = true -- Should players be given points over time?
PS.Config.PointsOverTimeDelay = 1 -- If so, how many minutes apart?
PS.Config.AdminCanAccessAdminTab = false -- Can Admins access the Admin tab?
PS.Config.SuperAdminCanAccessAdminTab = true -- Can SuperAdmins access the Admin tab?
PS.Config.CanPlayersGivePoints = true -- Can players give points away to other players?
PS.Config.DisplayPreviewInMenu = true -- Can players see the preview of their items in the menu?
PS.Config.PointsName = "Points" -- What are the points called?
PS.Config.SortItemsBy = "Name" -- How are items sorted? Set to 'Price' to sort by price.
-- Edit below if you know what you're doing
PS.Config.CalculateBuyPrice = function(ply, item) return item.Price end -- You can do different calculations here to return how much an item should cost to buy. -- There are a few examples below, uncomment them to use them. -- Everything half price for admins: -- if ply:IsAdmin() then return math.Round(item.Price * 0.5) end -- 25% off for the 'donators' group -- if ply:IsUserGroup('donators') then return math.Round(item.Price * 0.75) end
PS.Config.CalculateSellPrice = function(ply, item) return math.Round(item.Price * 0.75) end -- 75% or 3/4 (rounded) of the original item price
PS.Config.GetDefaultPlayermodel = function()
    return "models/player/group01/male_02.mdl"
end
PS.Config.GetPointsOverTime = function(ply)
    if ply:IsUserGroup("premium") or ply:IsAdmin() then
        return 25
    end

    return 10
end


PS.Config.DefaultTheme = "default"
PS.Config.Themes = {}

PS.Config.Themes["default"] = {
    MainColor = Color(200, 0, 0), -- Top bar, buttons, etc
    SecondaryColor = Color(0, 125, 200), -- Top bar, buttons, etc
    BackgroundColor = Color(0, 0, 0),
    Foreground1Color = Color(25, 25, 25), -- Scroll bars, deselected buttons, etc
    Foreground2Color = Color(50, 50, 50), -- Dropdowns, input fields, etc
    ErrorColor = Color(225, 50, 50),
    SuccessColor = Color(50, 225, 175),
}

PS.UserGroups = {
    ["user"] = { "superadmin", "admin", "premium", "member", "user" },
    ["member"] = { "superadmin", "admin", "premium", "member" },
    ["premium"] = { "superadmin", "admin", "premium" },
    ["admin"] = { "superadmin", "admin" },
    ["superadmin"] = { "superadmin" },
}
