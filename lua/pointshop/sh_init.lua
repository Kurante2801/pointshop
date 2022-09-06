--[[
	pointshop/sh_init.lua
	first file included on both states.
]]
--
PS = PS or {}
PS.__index = PS
PS.Bases = PS.Bases or {}
PS.Items = PS.Items or {}
PS.Categories = PS.Categories or {}
PS.ClientsideModels = {}
include("sh_config.lua")
include("sh_player_extension.lua")

-- validation
function PS:ValidateItems(items)
    if type(items) ~= "table" then return {} end

    -- Remove any items that no longer exist
    for item_id, item in pairs(items) do
        if not self.Items[item_id] then
            items[item_id] = nil
        end
    end

    return items
end

function PS:ValidatePoints(points)
    if type(points) ~= "number" then return 0 end

    return points >= 0 and points or 0
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

    if SERVER and self.Config.CheckVersion then
        self:CheckVersion()
    end

    self:LoadItems()
end

function PS:RegisterBase(base)
    if self.LoadingItems then
        return base
    else
        PS:LoadItems()
    end
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
    GamemodeCheck = function(this)
        if this.GamemodesWhitelistIndex then
            return not this.GamemodesWhitelistIndex[GAMEMODE.FolderName]
        elseif this.GamemodesBlacklistIndex then
            return this.GamemodesBlacklistIndex[GAMEMODE.FolderName]
        end
    end
}

local emptyFunc = function() end
local emptyFuncs = {
    "OnBuy", "OnSell", "OnEquip", "OnHolster", "OnModify",
    "OnSpawn", "OnDeath", "OnLoadout", "Think", "Move", "Draw",
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
    Name = "", Icon = "", Order = 0,
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

    PS.Items[item.ID] = setmetatable(item, item)

    if item.Model then
        util.PrecacheModel(item.Model)
    end

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
    -- For now does nothing
end

-- Hooks
hook.Add("PostGamemodeLoaded", "PS_Initialize", function()
    PS:Initialize()
end)