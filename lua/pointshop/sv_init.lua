--[[
	pointshop/sv_init.lua
	first file included serverside.
]]
--
resource.AddWorkshop("2860434667")

-- Make code a bit more bearable
local function NetMessage(msg, callback)
    util.AddNetworkString(msg)
    net.Receive(msg, callback)
end

NetMessage("PS_BuyItem", function(_, ply) ply:PS_BuyItem(net.ReadString()) end)
NetMessage("PS_SellItem", function(_, ply) ply:PS_SellItem(net.ReadString()) end)
NetMessage("PS_EquipItem", function(_, ply) ply:PS_EquipItem(net.ReadString()) end)
NetMessage("PS_HolsterItem", function(_, ply) ply:PS_HolsterItem(net.ReadString()) end)
NetMessage("PS_ModifyItem", function(_, ply) ply:PS_ModifyItem(net.ReadString(), PS.ReadTable()) end)
NetMessage("PS_ModQueue", function(_, ply)
    local tbl = util.JSONToTable(net.ReadString())
    if not tbl then return end

    for id, new_mods in pairs(tbl) do
        local mods = ply:PS_GetModifiers(id)
        table.Merge(mods, new_mods)
        ply:PS_ModifyItem(id, mods, true)
    end
end)
NetMessage("PS_SetNetworkVisibility", function(_, ply)
    ply:SetNWInt("ps_accessoryvisibility", ply:GetInfoNum("ps_accessoryvisibility", 1))
    ply:SetNWInt("ps_trailvisibility", ply:GetInfoNum("ps_trailvisibility", 1))
    ply:SetNWInt("ps_followervisibility", ply:GetInfoNum("ps_followervisibility", 1))
end)
-- Points from player to player
NetMessage("PS_SendPoints", function(_, ply)
    if not PS.Config.CanPlayersGivePoints then return end

    local other net.ReadEntity()
    local points = PS:ValidatePoints(net.ReadUInt(32))
    if points == 0 then return end
    if not IsValid(other) or not other:IsPlayer() then return end

    if ply.PS_LastGavePoints and CurTime() - ply.PS_LastGavePoints < 5 then
        ply:PS_Notify("Slow down! You can't give away points that fast.")
        return
    end
    ply.PS_LastGavePoints = CurTime()

    ply:PS_TakePoints(points)
    ply:PS_Notify("You gave ", other:Nick(), " ", points, " of your ", PS.Config.PointsName, ".")
    other:PS_GivePoints(points)
    other:PS_Notify(ply:Nick(), " gave you ", points, " of their ", PS.Config.PointsName, ".")
end)
-- Points from admin to player
NetMessage("PS_GivePoints", function(_, ply)
    if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

    local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
    local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()
    if not admin_allowed and not super_admin_allowed then return end

    local other = net.ReadEntity()
    local points = PS:ValidatePoints(net.ReadUInt(32))
    if IsValid(other) and other:IsPlayer() then
        other:PS_GivePoints(points)
        other:PS_Notify(string.format("%s gave you %s %s.", ply:Name(), points, PS.Config.PointsName))
    end
end)
NetMessage("PS_TakePoints", function(_, ply)
    if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

    local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
    local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()
    if not admin_allowed and not super_admin_allowed then return end

    local other = net.ReadEntity()
    local points = PS:ValidatePoints(net.ReadUInt(32))
    if IsValid(other) and other:IsPlayer() then
        other:PS_TakePoints(points)
        other:PS_Notify(string.format("%s took %s %s from you.", ply:Name(), points, PS.Config.PointsName))
    end
end)
NetMessage("PS_SetPoints", function(_, ply)
    if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

    local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
    local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()
    if not admin_allowed and not super_admin_allowed then return end

    local other = net.ReadEntity()
    local points = PS:ValidatePoints(net.ReadUInt(32))
    if IsValid(other) and other:IsPlayer() then
        other:PS_SetPoints(points)
        other:PS_Notify(string.format("%s set your %s to %s.", ply:Name(), PS.Config.PointsName, points))
    end
end)

NetMessage("PS_TakeItem", function(_, ply)
    if not PS.Config.AdminCanAccessAdminTab and not PS.Config.SuperAdminCanAccessAdminTab then return end

    local admin_allowed = PS.Config.AdminCanAccessAdminTab and ply:IsAdmin()
    local super_admin_allowed = PS.Config.SuperAdminCanAccessAdminTab and ply:IsSuperAdmin()
    if not admin_allowed and not super_admin_allowed then return end

    local other = net.ReadEntity()
    local item_id = net.ReadString()
    if PS.Items[item_id] and IsValid(other) and other:IsPlayer() and other:PS_HasItem(item_id) then
        -- holster it first without notificaiton
        other.PS_Items[item_id].Equipped = false
        local ITEM = PS.Items[item_id]
        ITEM:OnHolster(other)
        other:PS_TakeItem(item_id)
    end
end)

-- hooks
hook.Add("PlayerButtonDown", "PS_ToggleKey", function(ply, btn)
    if PS.Config.ShopKey and PS.Config.ShopKey ~= "" then
        local psButton = _G["KEY_" .. string.upper(PS.Config.ShopKey)]

        if psButton and psButton == btn then
            ply:PS_ToggleMenu()
        end
    end
end)

hook.Add("PlayerSpawn", "PS_PlayerSpawn", function(ply)
    ply:PS_PlayerSpawn()
end)

hook.Add("PlayerDeath", "PS_PlayerDeath", function(ply)
    ply:PS_PlayerDeath()
end)

hook.Add("PlayerInitialSpawn", "FullLoadSetup", function(ply)
    hook.Add("SetupMove", ply, function(this, _ply, _, cmd)
        if this == _ply and not cmd:IsForced() then
            hook.Remove("SetupMove", this)
            hook.Run("PlayerFullLoad", this)
        end
    end)
end)

hook.Add("PlayerInitialSpawn", "PS_PlayerInitialSpawn", function(ply)
    ply:PS_PlayerInitialSpawn()
end)

hook.Add("PlayerFullLoad", "PS_NetReady", function(ply)
    ply:PS_NetReady()
end)

hook.Add("PlayerDisconnected", "PS_PlayerDisconnected", function(ply)
    ply:PS_PlayerDisconnected()
end)

hook.Add("PlayerSay", "PS_PlayerSay", function(ply, text)
    if PS.Config.ShopChatCommand and #PS.Config.ShopChatCommand > 0 and string.lower(text) == string.lower(PS.Config.ShopChatCommand) then
        ply:PS_ToggleMenu()
        return ""
    end
end)

util.AddNetworkString("PS_Items")
util.AddNetworkString("PS_Points")
util.AddNetworkString("PS_SendNotification")
util.AddNetworkString("PS_ToggleMenu")

-- console commands
concommand.Add(PS.Config.ShopCommand, function(ply, cmd, args)
    ply:PS_ToggleMenu()
end)

-- data providers
function PS:LoadDataProvider()
    local path = "pointshop/providers/" .. self.Config.DataProvider .. ".lua"

    if not file.Exists(path, "LUA") then
        error("Pointshop data provider not found. " .. path)
    end

    PROVIDER = {}
    PROVIDER.__index = {}
    PROVIDER.ID = self.Config.DataProvider
    include(path)
    self.DataProvider = PROVIDER
    PROVIDER = nil
end

function PS:GetPlayerData(ply, callback)
    self.DataProvider:GetData(ply, function(points, items)
        callback(PS:ValidatePoints(tonumber(points)), PS:ValidateItems(items))
    end)
end

function PS:SetPlayerData(ply, points, items)
    self.DataProvider:SetData(ply, points, items)
end

function PS:SetPlayerPoints(ply, points)
    self.DataProvider:SetPoints(ply, points)
end

function PS:GivePlayerPoints(ply, points)
    self.DataProvider:GivePoints(ply, points, items)
end

function PS:TakePlayerPoints(ply, points)
    self.DataProvider:TakePoints(ply, points)
end

function PS:SavePlayerItem(ply, item_id, data)
    self.DataProvider:SaveItem(ply, item_id, data)
end

function PS:GivePlayerItem(ply, item_id, data)
    self.DataProvider:GiveItem(ply, item_id, data)
end

function PS:TakePlayerItem(ply, item_id)
    self.DataProvider:TakeItem(ply, item_id)
end