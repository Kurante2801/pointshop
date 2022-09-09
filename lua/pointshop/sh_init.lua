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
    AddSlider = function(this, panel, text, value, min, max, snap, callback)
        local slider = panel:Add("PS_HorizontalSlider")
        slider.TextArea:SetWide(80)
        slider:Dock(TOP)
        slider:DockMargin(0, 0, 0, 6)
        slider:SetText(text)
        slider:SetSnap(snap)
        slider:SetMinMax(min, max)
        slider:SetValue(value)
        slider:SetDefaultValue(0)
        slider.OnValueChanged = function(_, _value)
            callback(_value)
        end

        local button = slider:Add("PS_ButtonIcon")
        button:Dock(LEFT)
        button:DockMargin(0, 0, 6, 0)
        button:SetWide(32)
        button:SetIcon("lbg_pointshop/derma/reset.png", 20, 20)
        button.DoClick = function()
            slider:SetValue(slider:GetDefaultValue())
        end

        return slider
    end,
    AddBool = function(this, panel, text, noText, yesText, value, callback)
        local container = panel:Add("EditablePanel")
        container:Dock(TOP)
        container:DockMargin(0, 0, 0, 6)
        container:SetTall(32)

        container.Text = container:Add("PS_Button")
        container.Text:Dock(LEFT)
        container.Text:DockMargin(0, 0, 6, 0)
        container.Text:SetText(text)
        container.Text:SizeToContents()
        container.Text:SetWide(container.Text:GetWide() + 12)
        container.Text:SetMouseInputEnabled(false)
        container.Text:SetThemeMainColor("Foreground1Color")

        container.No = container:Add("PS_Button")
        container.No:Dock(LEFT)
        container.No:DockMargin(0, 0, 6, 0)
        container.No:SetText(noText)
        container.No:SizeToContents()
        container.No:SetWide(container.No:GetWide() + 12)
        container.No:SetupTransition("Selected", 6, function() return not value end)
        container.No.Paint = function(_this, w, h)
            draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground2Color"))
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 75 * _this.MouseHover))
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * _this.Selected))
        end
        container.No.DoClick = function()
            value = false
            callback(false)
        end

        container.Yes = container:Add("PS_Button")
        container.Yes:Dock(LEFT)
        container.Yes:DockMargin(0, 0, 6, 0)
        container.Yes:SetText(yesText)
        container.Yes:SizeToContents()
        container.Yes:SetWide(container.Yes:GetWide() + 12)
        container.Yes:SetupTransition("Selected", 6, function() return value end)
        container.Yes.Paint = function(_this, w, h)
            draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground2Color"))
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 75 * _this.MouseHover))
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * _this.Selected))
        end
        container.Yes.DoClick = function()
            value = true
            callback(true)
        end

        return container
    end,
    AddComboBox = function(this, panel, text, value, values, data, callback)
        local container = panel:Add("EditablePanel")
        container:Dock(TOP)
        container:DockMargin(0, 0, 0, 6)
        container:SetTall(32)

        container.Text = container:Add("PS_Button")
        container.Text:Dock(LEFT)
        container.Text:DockMargin(0, 0, 6, 0)
        container.Text:SetText(text)
        container.Text:SizeToContents()
        container.Text:SetWide(container.Text:GetWide() + 12)
        container.Text:SetMouseInputEnabled(false)
        container.Text:SetThemeMainColor("Foreground1Color")

        container.ComboBox = container:Add("PS_ComboBox")
        container.ComboBox:Dock(FILL)
        container.ComboBox:SetValue(value)
        container.ComboBox.OnSelect = function(_, i, v, d)
            callback(v, d)
        end

        for i, v in ipairs(values) do
            container.ComboBox:AddChoice(v, data[i])
        end

        return container
    end,
    AddSelector = function(this, panel, text, value, values, callback)
        local container = panel:Add("EditablePanel")
        container:Dock(TOP)
        container:DockMargin(0, 0, 0, 6)
        container:SetTall(32)

        container.header = container:Add("PS_Button")
        container.header:Dock(LEFT)
        container.header:DockMargin(0, 0, 6, 0)
        container.header:SetWide(180)
        container.header:SetText(text)
        container.header:SetMouseInputEnabled(false)
        container.header:SetThemeMainColor("Foreground1Color")

        container.grid = container:Add("DIconLayout")
        container.grid:Dock(TOP)
        container.grid:SetSpaceX(6)
        container.grid:SetSpaceY(6)

        container.buttons = {}
        for _, v in ipairs(values) do
            container.button = container.grid:Add("PS_Button")
            container.button:SetText(v)
            container.button:SetTall(32)
            container.button:SetupTransition("Selected", 6, function() return value == v end)
            container.button.Paint = function(_this, w, h)
                draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
                draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * _this.Selected))
            end
            container.button.DoClick = function()
                value = v
                callback(v)
            end
    
            table.insert(container.buttons, container.button)
        end

        container.grid:TDLib():On("PerformLayout", function(_this)
            container:SetTall(_this:GetTall())
        end)

        return container
    end
}

local emptyFunc = function() end
local emptyFuncs = {
    "OnBuy", "OnSell", "OnEquip", "OnHolster", "OnModify",
    "OnSpawn", "OnDeath", "OnLoadout", "OnThink", "OnMove", "OnDraw",
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

    for ply, items in pairs(PS.ClientsideModels) do
        for id, _ in pairs(items) do
            ply:PS_AddClientsideModel(id)
        end
    end

    -- Download materials
    if not file.Exists("lbg_pointshop_webmaterials", "DATA") then
        file.CreateDir("lbg_pointshop_webmaterials")
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
PS.ValidHEX = {
    ["0"] = true,
    ["A"] = true,
    ["1"] = true,
    ["B"] = true,
    ["2"] = true,
    ["C"] = true,
    ["3"] = true,
    ["D"] = true,
    ["4"] = true,
    ["E"] = true,
    ["5"] = true,
    ["F"] = true,
    ["6"] = true,
    ["7"] = true,
    ["8"] = true,
    ["9"] = true,
}

PS.SanitizeHEX = function(hex)
    -- If given invalid, return white
    if not hex or not isstring(hex) then return "FFFFFF" end
    -- Remove # if it has one and make all uppercase
    hex = string.Replace(hex, "#", "")
    hex = string.upper(hex)

    -- Now we check if the string is using an unvalid char.
    for i = 1, 6 do
        -- We are checking if the character is on the ValidHex table. Otherwise replace with an F
        if not PS.ValidHEX[hex[i]] then
            -- Strings in lua are inmutable, so we do some fuckery to create a new one
            hex = string.format("%s%s%s", string.sub(hex, 1, i - 1), "F", string.sub(hex, i + 1))
        end
    end

    -- Limit to 6 chars
    if #hex > 6 then
        hex = string.sub(hex, 1, 6)
    end

    return hex
end

-- Returns a valid HEX string
PS.SanitizeHEX = function(hex)
    -- If given invalid, return white
    if not hex or not isstring(hex) then return "FFFFFF" end
    -- Remove # if it has one and make all uppercase
    hex = string.Replace(hex, "#", "")
    hex = string.upper(hex)

    -- Now we check if the string is using an unvalid char.
    for i = 1, 6 do
        -- We are checking if the character is on the ValidHex table. Otherwise replace with an F
        if not PS.ValidHEX[hex[i]] then
            -- Strings in lua are inmutable, so we do some fuckery to create a new one
            hex = string.format("%s%s%s", string.sub(hex, 1, i - 1), "F", string.sub(hex, i + 1))
        end
    end

    -- Limit to 6 chars
    if #hex > 6 then
        hex = string.sub(hex, 1, 6)
    end

    return hex
end

PS.HEXtoRGB = function(hex)
    hex = PS.SanitizeHEX(hex)
    -- Separate RRGGBB
    local r, g, b = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6)

    -- Turn those into numbers and return them as a Color
    return Color(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

PS.RGBtoHEX = function(colorTable)
    local hexadecimal = "" -- End result

    for i = 1, 3 do
        local color

        if i == 1 then
            color = colorTable.r
        elseif i == 2 then
            color = colorTable.g
        else
            color = colorTable.b
        end

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