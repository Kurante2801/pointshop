PS.Bases = PS.Bases or {}
PS.Items = PS.Items or {}
PS.Categories = PS.Categories or {}

-- validation
function PS:ValidateItems(items)
    if not istable(items) then return {} end

    -- Remove any items that no longer exist
    for item_id, item in pairs(items) do
        if not self.Items[item_id] then
            items[item_id] = nil
        end
    end

    return items
end

function PS:ValidatePoints(points)
    if not isnumber(points) then
        return 0
    end

    return math.Clamp(points, 0, 0xFFFFFFFF)
end

-- Utils
function PS:FindCategoryByName(cat_name)
    for id, cat in pairs(self.Categories) do
        if cat.Name == cat_name then return cat end
    end

    return false
end

-- Initialization
function PS:Initialize()
    if SERVER then
        self:LoadDataProvider()
    end

    self:LoadItems()
end

function PS:RegisterBase(base)
    if self.LoadingItems then
        return base
    elseif not base.ID then
        PS:LoadItems()
        return
    end

    PS:NewBase(base)
    PS:UpdateClient()
end

-- The base all bases base off
PS.MasterBase = {
    Name = "", Price = 0, AdminOnly = false,
    AllowedUserGroups = PS.UserGroups["user"],
    SingleUse = false, NoPreview = false, CanPlayerBuy = true,
    CanPlayerSell = true, CanPlayerEquip = true, CanPlayerHolster = true,
    ToString = function(this)
        return "[base] " .. this.ID
    end,
    SetupThinker = function(this, panel, mods_reference, mods_copy, compare_func, on_change)
        local thinker = panel:Add("EditablePanel")
        thinker:SetMouseInputEnabled(false)
        thinker.Mods = mods_copy
        thinker.LastSent = CurTime()
        thinker.Think = function(_this)
            if CurTime() - _this.LastSent < 0.5 then return end

            if compare_func(mods_reference, mods_copy) then
                _this.LastSent = CurTime()
                on_change(mods_reference, mods_copy)

                net.Start("PS_ModifyItem")
                net.WriteString(this.ID)
                net.WriteString(util.TableToJSON(mods_reference))
                net.SendToServer()
            end
        end
    end,
}

local emptyFunc = function() end
local emptyFuncs = {
    "OnBuy", "OnSell", "OnEquip", "OnHolster", "OnModify",
    "OnSpawn", "OnDeath", "OnLoadout", "OnThink", "OnMove", "OnDraw",
    "OnPreviewDraw"
}
for _, func in ipairs(emptyFuncs) do
    PS.MasterBase[func] = emptyFunc
end

function PS:RegisterCategory(category)
    if self.LoadingItems then
        return category
    elseif not category.ID then
        self:LoadItems() -- If category does not specify it's ID, we can't reload just that category
        return
    end

    local prev = PS.Categories[category.ID]
    if not prev then return end

    category.ID = prev.ID
    PS:NewCategory(category)
end

PS.BaseCategory = {
    Name = "", Icon = "", Order = 20,
    AllowedEquipped = -1, AllowedUserGroups = {},
    CanPlayerSee = function() return true end,
}

function PS:RegisterItem(item)
    if self.LoadingItems then
        return item
    elseif not item.ID then
        self:LoadItems()
        return
    end

    local prev = PS.Items[item.ID]
    if not prev then return end

    item.Category = prev.Category
    PS:NewItem(item)
    PS:UpdateClient()
end

-- Creation
function PS:NewBase(base)
    base.__index = function(this, key)
        -- First we try to get value from 'this'
        local value = rawget(this, key)
        if value ~= nil then return value end

        local meta = getmetatable(this)
        if this ~= meta then
            value = meta[key]
            if value ~= nil then return value end
        end
        -- Then we try to get the value from 'this.Base'
        local baseID = rawget(this, "Base")
        if baseID then return PS.Bases[baseID][key] end
        -- Finally we return the master base's value
        return PS.MasterBase[key]
    end

    base.__tostring = function(this)
        return this:ToString()
    end

    PS.Bases[base.ID] = setmetatable(base, base)
end

function PS:NewCategory(category)
    category.__index = function(this, key)
        -- First we try to get value from 'this'
        local value = rawget(this, key)
        if value ~= nil then return value end

        local meta = getmetatable(this)
        if this ~= meta then
            value = meta[key]
            if value ~= nil then return value end
        end

        -- Then we return the base category's value
        return PS.BaseCategory[key]
    end

    if not isstring(category.Name) then
        categoryName = tostring(category.Name)
    end

    PS.Categories[category.ID] = setmetatable(category, category)
end

function PS:NewItem(item)
    item.__index = function(this, key)
        -- First we try to get value from 'this'
        local value = rawget(this, key)
        if value ~= nil then return value end

        local meta = getmetatable(this)
        if this ~= meta then
            value = meta[key]
            if value ~= nil then return value end
        end

        -- Then we try to get the value from 'this.Base'
        local baseID = rawget(this, "Base")
        if baseID then return PS.Bases[baseID][key] end
        -- Finally we return the master base's value
        return PS.MasterBase[key]
    end

    -- GamemodesWhitelist and GamemodesBlacklist are tables of strings
    -- To make GamemodeCheck faster, we create index tables
    if item.GamemodesWhitelist then
        item.GamemodesWhitelistIndex = {}
        for _, gm in ipairs(item.GamemodesWhitelist) do
            item.GamemodesWhitelistIndex[gm] = true
        end
    elseif item.GamemodesBlacklist then
        item. GamemodesBlacklistIndex = {}
        for _, gm in ipairs(item.GamemodesBlacklist) do
            item.GamemodesBlacklistIndex[gm] = true
        end
    end

    if item.Model then
        util.PrecacheModel(item.Model)
    end

    PS.Items[item.ID] = setmetatable(item, item)
    return item
end

-- Loading
function PS:LoadItems()
    self.LoadingItems = true -- Prevents infinite loops
    -- First load bases
    local bases = file.Find("pointshop/bases/*.lua", "LUA")

    for _, id in ipairs(bases) do
        AddCSLuaFile("pointshop/bases/" .. id)
        local base = include("pointshop/bases/" .. id)
        if not base then continue end
        base.ID = id:lower():StripExtension()

        PS:NewBase(base)
    end

    -- Then we load categories
    local _, cats = file.Find("pointshop/items/*", "LUA")
    local loaded = {}

    for i = 1, #cats do
        local id = cats[i]
        local filename = string.format("pointshop/items/%s/__category.lua", id)
        if not file.Exists(filename, "LUA") then continue end

        CATEGORY = {} -- To support Pointshop 1 categories
        AddCSLuaFile(filename)
        local category = include(filename) or CATEGORY
        if not category or table.Count(category) <= 0 then
            CATEGORY = nil
            continue
        end

        category = table.Copy(category)
        category.ID = id:lower()
        CATEGORY = nil

        table.insert(loaded, category.ID)
        PS:NewCategory(category)
    end

    -- Finally, load items
    for _, category in ipairs(loaded) do
        local items = file.Find(string.format("pointshop/items/%s/*.lua", category), "LUA")

        for _, id in ipairs(items) do
            if id == "__category.lua" then continue end
            local filename = string.format("pointshop/items/%s/%s", category, id)
            ITEM = {} -- To support Pointshop 1 items
            AddCSLuaFile(filename)
            local item = include(filename) or ITEM
            if not item or table.Count(item) <= 0 then
                ITEM = nil
                continue
            end

            item = table.Copy(item)
            ITEM = nil

            item.ID = id:lower():StripExtension()
            item.Category = category

            PS:NewItem(item)
        end
    end

    PS:UpdateClient()
    self.LoadingItems = false
end

function PS:UpdateClient()
    for id, item in pairs(PS.Items) do
        if item.WebMaterial then
            local path = string.format("lbg_pointshop_webmaterials/%s.png", id)
            item.Material = "data/" .. path

            if CLIENT then
                http.Fetch(item.WebMaterial, function(data)
                    file.Write(path, data)
                end)
            end
        end
    end

    for id, category in pairs(PS.Categories) do
        if category.WebMaterial then
            local path = string.format("lbg_pointshop_webmaterials/category_%s.png", id)
            category.Material = "data/" .. path

            if CLIENT then
                http.Fetch(category.WebMaterial, function(data)
                    file.Write(path, data)
                end)
            end
        end
    end

    if not CLIENT then return end

    -- Download materials
    if not file.Exists("lbg_pointshop_webmaterials", "DATA") then
        file.CreateDir("lbg_pointshop_webmaterials")
    end
end

function PS.GamemodeCheck(item)
    if item.GamemodesWhitelistIndex then
        return not item.GamemodesWhitelistIndex[GAMEMODE.FolderName]
    elseif item.GamemodesBlacklistIndex then
        return item.GamemodesBlacklistIndex[GAMEMODE.FolderName]
    end
end

-- Hooks
hook.Add("PostGamemodeLoaded", "PS_Initialize", function()
    PS:Initialize()
end)

-- For simple and short tables
function PS.WriteTable(tbl)
    net.WriteString(util.TableToJSON(tbl))
end

function PS.ReadTable()
    return util.JSONToTable(net.ReadString())
end

hook.Add("Think", "PS_Think", function()
    for _, ply in ipairs(player.GetAll()) do
        ply:PS_Think()
    end
end)

hook.Add("Move", "PS_Move", function(ply, data)
    ply:PS_Move(data)
end)

-- Color utils
PS.ValidHEX = { ["0"] = true, ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = true, ["7"] = true, ["8"] = true, ["9"] = true, ["A"] = true, ["B"] = true, ["C"] = true, ["D"] = true, ["E"] = true, ["F"] = true, }

PS.SanitizeHEX = function(hex, parseAlpha)
    -- If given invalid, return white
    if not hex or not isstring(hex) then return parseAlpha and "FFFFFFFF" or "FFFFFF" end
    -- Remove # if it has one and make all uppercase
    hex = string.upper(string.Replace(hex, "#", ""))

    local length = parseAlpha and 8 or 6
    -- Now we check if the string is using an unvalid char.
    for i = 1, length do
        -- We are checking if the character is on the ValidHex table. Otherwise replace with an F
        if not PS.ValidHEX[hex[i]] then
            -- Strings in lua are inmutable, so we do some fuckery to create a new one
            hex = string.format("%s%s%s", string.sub(hex, 1, i - 1), "F", string.sub(hex, i + 1))
        end
    end
    -- Limit to 6 or 8 chars
    if #hex > length then
        hex = string.sub(hex, 1, length)
    end

    return hex
end

PS.HEXtoRGB = function(hex, parseAlpha)
    hex = PS.SanitizeHEX(hex, parseAlpha)
    -- Separate RRGGBB
    local r, g, b, a = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6), parseAlpha and string.sub(hex, 7, 8) or "FF"
    -- Turn those into numbers and return them as a Color
    return Color(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16))
end

local indices = { "r", "g", "b", "a" }
PS.RGBtoHEX = function(colorTable, parseAlpha)
    local hexadecimal = "" -- End result

    for i = 1, (parseAlpha and 4 or 3) do
        local color

        color = colorTable[indices[i]]
        local hex = ""

        -- Get RRGGBB
        while color > 0 do
            local e = color % 16 + 1
            color = math.floor(color / 16)
            hex = string.sub("0123456789ABCDEF", e, e) .. hex
        end

        -- If number is below 10, fix
        if string.len(hex) == 1 then
            hex = "0" .. hex
        elseif string.len(hex) == 0 then
            hex = "00"
        end

        hexadecimal = hexadecimal .. hex
    end

    return hexadecimal
end

function PS.TablesEqual(a, b)
    for key, value in pairs(a) do
        if b[key] ~= value then
            return false
        end
    end

    return true
end