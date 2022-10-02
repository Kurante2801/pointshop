PS_ITEM_EQUIP = 1
PS_ITEM_HOLSTER = 2
PS_ITEM_MODIFY = 3
local Player = FindMetaTable("Player")

function Player:PS_PlayerSpawn()
    if not self:PS_CanPerformAction() or self:PS_IsSpectator() then return end
    timer.Simple(0, function()
        if not IsValid(self) or not self:PS_CanPerformAction() or self:PS_IsSpectator() then return end

        for item_id, item in pairs(self.PS_Items or {}) do
            local ITEM = PS.Items[item_id]

            if item.Equipped then
                ITEM:OnSpawn(self, item.Modifiers)
            end
        end
    end)
end

function Player:PS_PlayerDeath()
    for item_id, item in pairs(self.PS_Items) do
        if item.Equipped then
            local ITEM = PS.Items[item_id]
            ITEM:OnDeath(self, item.Modifiers)
        end
    end
end

function Player:PS_PlayerInitialSpawn()
    self.PS_Points = 0
    self.PS_Items = {}
    self:PS_LoadData()
end

function Player:PS_NetReady()
    self:PS_SendPoints()
    self:PS_SendItems()
    self:PS_PlayerSpawn()

    if PS.Config.NotifyOnJoin then
        if PS.Config.ShopKey ~= "" then
            self:PS_Notify(string.format("Press %s to open PointShop!", PS.Config.ShopKey))
        end

        if PS.Config.ShopCommand ~= "" then
            self:PS_Notify(string.format("Type %s in console to open PointShop!", PS.Config.ShopCommand))
        end

        if PS.Config.ShopChatCommand ~= "" then
            self:PS_Notify(string.format("Type %s in chat to open PointShop!", PS.Config.ShopChatCommand))
        end

        self:PS_Notify(string.format("You have %s %s to spend!", self:PS_GetPoints(), PS.Config.PointsName))
    end

    if PS.Config.PointsOverTime then
        local name = "PS_PointsOverTime_" .. self:SteamID64()
        timer.Create(name, PS.Config.PointsOverTimeDelay * 60, 0, function()
            if not IsValid(self) then
                timer.Remove(name)
            else
                self:PS_GivePoints(PS.Config.PointsOverTimeAmount)
                self:PS_Notify(string.format("You've been given %s %s for playing on the server!", PS.Config.PointsOverTimeAmount, PS.Config.PointsName))
            end
        end)
    end
end

function Player:PS_PlayerDisconnected()
    timer.Remove("PS_PointsOverTime_" .. self:SteamID64())
end

function Player:PS_Save()
    PS:SetPlayerData(self, PS:ValidatePoints(self.PS_Points), self.PS_Items)
end

function Player:PS_LoadData()
    self.PS_Points = 0
    self.PS_Items = {}

    PS:GetPlayerData(self, function(points, items)
        self.PS_Points = PS:ValidatePoints(points)
        self.PS_Items = items
        -- Send data to other connected players
        self:PS_SendPoints()
        self:PS_SendItems()
    end)
end

function Player:PS_CanPerformAction(itemname)
    return true
end

-- points
function Player:PS_GivePoints(points)
    self.PS_Points = PS:ValidatePoints(self.PS_Points + points)
    PS:GivePlayerPoints(self, points)
    self:PS_SendPoints()
end

function Player:PS_TakePoints(points)
    self.PS_Points = PS:ValidatePoints(self.PS_Points - points)
    PS:TakePlayerPoints(self, points)
    self:PS_SendPoints()
end

function Player:PS_SetPoints(points)
    self.PS_Points = PS:ValidatePoints(self.PS_Points - points)
    PS:SetPlayerPoints(self, points)
    self:PS_SendPoints()
end

function Player:PS_GetPoints()
    return self.PS_Points and self.PS_Points or 0
end

function Player:PS_HasPoints(points)
    return self.PS_Points >= points
end

-- give/take items
function Player:PS_GiveItem(item_id)
    if not PS.Items[item_id] then return false end

    self.PS_Items[item_id] = {
        Modifiers = {},
        Equipped = false
    }

    PS:GivePlayerItem(self, item_id, self.PS_Items[item_id])
    self:PS_SendItems()

    return true
end

function Player:PS_TakeItem(item_id)
    if not PS.Items[item_id] then return false end
    if not self:PS_HasItem(item_id) then return false end
    self.PS_Items[item_id] = nil
    PS:TakePlayerItem(self, item_id)
    self:PS_SendItems()

    return true
end

-- buy/sell items
function Player:PS_BuyItem(item_id)
    local ITEM = PS.Items[item_id]
    if not ITEM then return false end
    --if self:PS_HasItem(item_id) then return end

    local points = PS.Config.CalculateBuyPrice(self, ITEM)
    if not self:PS_HasPoints(points) then return false end
    if not self:PS_CanPerformAction(item_id) then return end

    if ITEM.AdminOnly and not self:IsAdmin() then
        self:PS_Notify("This item is Admin only!")

        return false
    end

    if ITEM.AllowedUserGroups and #ITEM.AllowedUserGroups > 0 and not table.HasValue(ITEM.AllowedUserGroups, self:PS_GetUsergroup()) then
        self:PS_Notify("You're not in the right group to buy this item!")
        return false
    end

    local CATEGORY = PS.Categories[ITEM.Category]

    if CATEGORY.AllowedUserGroups and #CATEGORY.AllowedUserGroups > 0 and not table.HasValue(CATEGORY.AllowedUserGroups, self:PS_GetUsergroup()) then
        self:PS_Notify("You're not in the right group to buy this item!")
        return false
    end

    if CATEGORY.CanPlayerSee and not CATEGORY:CanPlayerSee(self) then
        self:PS_Notify("You\'re not allowed to buy this item!")
        return false
    end

    -- should exist but we'll check anyway
    if ITEM.CanPlayerBuy then
        local allowed, message

        if (type(ITEM.CanPlayerBuy) == "function") then
            allowed, message = ITEM:CanPlayerBuy(self)
        elseif (type(ITEM.CanPlayerBuy) == "boolean") then
            allowed = ITEM.CanPlayerBuy
        end

        if not allowed then
            self:PS_Notify(message or "You're not allowed to buy this item!")

            return false
        end
    end

    self:PS_TakePoints(points)
    self:PS_Notify(string.format("Bought %s for %s %s", ITEM.Name, points, PS.Config.PointsName))
    ITEM:OnBuy(self)
    hook.Call("PS_ItemPurchased", nil, self, item_id)

    if ITEM.SingleUse then
        self:PS_Notify("Single use item. You'll have to buy this item again next time!")

        return
    end

    self:PS_GiveItem(item_id)
    self:PS_EquipItem(item_id)
end

function Player:PS_SellItem(item_id)
    if not PS.Items[item_id] then return false end
    if not self:PS_HasItem(item_id) then return false end
    local ITEM = PS.Items[item_id]

    -- should exist but we'll check anyway
    if ITEM.CanPlayerSell then
        local allowed, message

        if (type(ITEM.CanPlayerSell) == "function") then
            allowed, message = ITEM:CanPlayerSell(self)
        elseif (type(ITEM.CanPlayerSell) == "boolean") then
            allowed = ITEM.CanPlayerSell
        end

        if not allowed then
            self:PS_Notify(message or "You're not allowed to sell this item!")

            return false
        end
    end

    local points = PS.Config.CalculateSellPrice(self, ITEM)
    self:PS_GivePoints(points)
    ITEM:OnHolster(self)
    ITEM:OnSell(self)
    hook.Call("PS_ItemSold", nil, self, item_id)
    self:PS_Notify(string.format("Sold %s for %s %s", ITEM.Name, points, PS.Config.PointsName))

    return self:PS_TakeItem(item_id)
end

function Player:PS_HasItem(item_id)
    return self.PS_Items[item_id] or false
end

function Player:PS_HasItemEquipped(item_id)
    if not self:PS_HasItem(item_id) then return false end

    return self.PS_Items[item_id].Equipped or false
end

function Player:PS_NumItemsEquippedFromCategory(cat_name)
    local count = 0

    for item_id, item in pairs(self.PS_Items) do
        local ITEM = PS.Items[item_id]

        if ITEM.Category == cat_name and item.Equipped then
            count = count + 1
        end
    end

    return count
end

-- used as a default if an item is missing the SanitizeTable function. Catches colors/text
local function Sanitize(modifications)
    local out = {}

    if isstring(modifications.text) then
        out.text = modifications.text
    end

    if modifications.color then
        out.color = Color(modifications.color.r or 255, modifications.color.g or 255, modifications.color.b or 255)
    end

    return out
end

-- equip/hoster items
function Player:PS_EquipItem(item_id)
    if not PS.Items[item_id] then return false end
    if not self:PS_HasItem(item_id) then return false end
    if not self:PS_CanPerformAction(item_id) then return false end
    local ITEM = PS.Items[item_id]

    if isfunction(ITEM.CanPlayerEquip) then
        allowed, message = ITEM:CanPlayerEquip(self)
    elseif isbool(ITEM.CanPlayerEquip) then
        allowed = ITEM.CanPlayerEquip
    end

    if not allowed then
        self:PS_Notify(message or "You're not allowed to equip this item!")

        return false
    end

    local CATEGORY = PS.Categories[ITEM.Category]

    -- Unequip old when 1 allowed equipped
    if CATEGORY and CATEGORY.AllowedEquipped == 1 then
        for id, _ in pairs(self:PS_GetItemsEquippedFromCategory(ITEM.Category)) do
            self:PS_HolsterItem(id)
        end
    elseif CATEGORY and CATEGORY.AllowedEquipped and CATEGORY.AllowedEquipped > -1 then
        if self:PS_NumItemsEquippedFromCategory(ITEM.Category) >= CATEGORY.AllowedEquipped then
            self:PS_Notify(string.format("Only %s %s from this category allowed.", CATEGORY.AllowedEquipped, CATEGORY.AllowedEquipped == 1 and "item" or "items"))
            return false
        end
    end

    if PS.Items[item_id].Slot then
        for id, item in pairs(self.PS_Items) do
            if item_id ~= id and PS.Items[id].Slot and PS.Items[id].Slot == PS.Items[item_id].Slot and self.PS_Items[id].Equipped then
                self:PS_HolsterItem(id)
            end
        end
    end

    self.PS_Items[item_id].Equipped = true
    local mods = self.PS_Items[item_id].Modifiers or {}

    if ITEM.SanitizeTable then
        mods = ITEM:SanitizeTable(mods)
    else
        mods = Sanitize(mods)
    end

    self.PS_Items[item_id].Modifiers = mods

    ITEM:OnEquip(self, mods)
    self:PS_Notify("Equipped ", ITEM.Name, ".")
    hook.Call("PS_ItemUpdated", nil, self, item_id, PS_ITEM_EQUIP)
    PS:SavePlayerItem(self, item_id, self.PS_Items[item_id])
    self:PS_SendItems()
end

function Player:PS_HolsterItem(item_id)
    if not PS.Items[item_id] then return false end
    if not self:PS_HasItem(item_id) then return false end
    if not self:PS_CanPerformAction(item_id) then return false end
    self.PS_Items[item_id].Equipped = false
    local ITEM = PS.Items[item_id]

    if isfunction(ITEM.CanPlayerHolster) then
        allowed, message = ITEM:CanPlayerHolster(self)
    elseif isbool(ITEM.CanPlayerHolster) then
        allowed = ITEM.CanPlayerHolster
    end

    if not allowed then
        self:PS_Notify(message or "You're not allowed to holster this item!")

        return false
    end

    ITEM:OnHolster(self)
    self:PS_Notify("Holstered ", ITEM.Name, ".")
    hook.Call("PS_ItemUpdated", nil, self, item_id, PS_ITEM_HOLSTER)
    PS:SavePlayerItem(self, item_id, self.PS_Items[item_id])
    self:PS_SendItems()
end

function Player:PS_ModifyItem(item_id, modifications, fromQueue)
    if not PS.Items[item_id] then return false end
    if not self:PS_HasItem(item_id) then return false end
    if not istable(modifications) then return false end
    if not self:PS_CanPerformAction(item_id) then return false end
    local ITEM = PS.Items[item_id]

    -- This if block helps prevent someone from sending a table full of random junk that will fill up the server's RAM, be networked to every player, and be stored in the database
    if ITEM.SanitizeTable then
        modifications = ITEM:SanitizeTable(modifications)
    else
        modifications = Sanitize(modifications)
    end

    table.Empty(self.PS_Items[item_id].Modifiers)
    for key, value in pairs(modifications) do
        self.PS_Items[item_id].Modifiers[key] = value
    end

    ITEM:OnModify(self, self.PS_Items[item_id].Modifiers)
    hook.Call("PS_ItemUpdated", nil, self, item_id, PS_ITEM_MODIFY, modifications)
    PS:SavePlayerItem(self, item_id, self.PS_Items[item_id])

    if fromQueue then
        local targets = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply ~= self then
                table.insert(targets, ply)
            end
        end

        self:PS_SendItems(targets)
    else
        self:PS_SendItems()
    end
end

-- menu stuff
function Player:PS_ToggleMenu(show)
    net.Start("PS_ToggleMenu")
    net.Send(self)
end

-- send stuff
function Player:PS_SendPoints()
    net.Start("PS_Points")
    net.WriteEntity(self)
    net.WriteUInt(self.PS_Points, 32)
    net.Broadcast()
end

-- Yogpod taught me this
function Player:PS_SendItems(target)
    local items = util.TableToJSON(self.PS_Items)
    local compressed = util.Compress(items) or items
    local len = string.len(compressed)
    local send_size = 60000
    local parts = math.ceil(len / send_size)
    local start = 0

    for i = 1, parts do
        local endbyte = math.min(start + send_size, len)
        local size = endbyte - start
        net.Start("PS_Items")
        net.WriteEntity(self)
        net.WriteBool(i == parts)
        net.WriteUInt(size, 16)
        net.WriteData(compressed:sub(start + 1, endbyte + 1), size)

        if target then
            net.Send(target)
        else
            net.Broadcast()
        end
    end
end

-- notifications
function Player:PS_Notify(...)
    local str = table.concat({...}, '')

    net.Start('PS_SendNotification')
    net.WriteString(str)
    net.Send(self)
end