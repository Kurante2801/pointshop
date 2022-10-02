PS.ShopMenu = PS.ShopMenu or nil

PS.AccessoryVisibility = CreateClientConVar("ps_accessoryvisibility", "1", true, true, "Who can see your accessories? 1 = Everyone; 2 = Same Team Only; 3 = Friends Only", 1, 3)
PS.AccessoryEnabled = CreateClientConVar("ps_accessoryenabled", "1", true, true, "What accessories can you see? 1 = Everyone; 2 = Same Team Only; 3 = Friends Only", 1, 3)

PS.TrailVisibility = CreateClientConVar("ps_trailvisibility", "1", true, true, "Who can see your trails? 1 = Everyone; 2 = Same Team Only; 3 = Friends Only", 1, 3)
PS.TrailEnabled = CreateClientConVar("ps_trailenabled", "1", true, true, "What trails can you see? 1 = Everyone; 2 = Same Team Only; 3 = Friends Only", 1, 3)

PS.FollowerVisibility = CreateClientConVar("ps_followervisibility", "1", true, true, "Who can see your followers? 1 = Everyone; 2 = Same Team Only; 3 = Friends Only", 1, 3)
PS.FollowerEnabled = CreateClientConVar("ps_followerenabled", "1", true, true, "What followers can you see? 1 = Everyone; 2 = Same Team Only; 3 = Friends Only", 1, 3)

local enabled, visibility
function PS:CanSeeAccessory(target)
    local ply = LocalPlayer()
    if target == ply then return true end

    enabled = self.AccessoryEnabled:GetInt()
    if enabled == 2 and ply:Team() ~= target:Team() then
        return false
    elseif enabled == 3 and target:GetFriendStatus() ~= "friend" then
        return false
    end

    visibility = target:GetNWInt("ps_accessoryvisibility", 3)
    if visibility == 2 and ply:Team() ~= target:Team() then
        return false
    elseif visibility == 3 and target:GetFriendStatus() ~= "friend" then
        return false
    end

    return true
end

function PS:CanSeeTrail(target)
    local ply = LocalPlayer()
    if target == ply then return true end

    enabled = self.TrailEnabled:GetInt()
    if enabled == 2 and ply:Team() ~= target:Team() then
        return false
    elseif enabled == 3 and target:GetFriendStatus() ~= "friend" then
        return false
    end

    visibility = target:GetNWInt("ps_trailvisibility", 3)
    if visibility == 2 and ply:Team() ~= target:Team() then
        return false
    elseif visibility == 3 and target:GetFriendStatus() ~= "friend" then
        return false
    end

    return true
end

function PS:CanSeeFollower(target)
    local ply = LocalPlayer()
    if target == ply then return true end

    enabled = self.FollowerEnabled:GetInt()
    if enabled == 2 and ply:Team() ~= target:Team() then
        return false
    elseif enabled == 3 and target:GetFriendStatus() ~= "friend" then
        return false
    end

    visibility = target:GetNWInt("ps_followervisibility", 3)
    if visibility == 2 and ply:Team() ~= target:Team() then
        return false
    elseif visibility == 3 and target:GetFriendStatus() ~= "friend" then
        return false
    end

    return true
end

-- menu stuff
function PS:ToggleMenu()
    if not IsValid(PS.ShopMenu) then
        PS.ShopMenu = vgui.Create("PS_Menu")
        PS.ShopMenu:SetVisible(false)
    end

    if PS.ShopMenu:IsVisible() then
        PS.ShopMenu:Hide()
        gui.EnableScreenClicker(false)
    else
        PS.ShopMenu:Show()
        gui.EnableScreenClicker(true)
    end
end

function PS:SendModifications(item_id, modifications)
    net.Start("PS_ModifyItem")
    net.WriteString(item_id)
    PS.WriteTable(modifications)
    net.SendToServer()
end

PS.ModQueue = PS.ModQueue or {}
function PS:SendModification(id, key, value)
    self.ModQueue[id] = self.ModQueue[id] or {}
    self.ModQueue[id][key] = value
    -- Change values on local player instantly
    LocalPlayer():PS_GetModifiers(id)[key] = value
end

-- net hooks
net.Receive("PS_ToggleMenu", function(_)
    PS:ToggleMenu()
end)

local buffers = {}
net.Receive("PS_Items", function()
    local ply = net.ReadEntity()
    local done = net.ReadBool()
    local length = net.ReadUInt(16)
    local data = net.ReadData(length)
    buffers[ply] = (buffers[ply] or "") .. data
    if not done then return end
    local uncompressed = util.Decompress(buffers[ply])
    buffers[ply] = ""

    if not uncompressed then
        PS:Msg("Received items but couldn't decompres!")

        return
    end

    local items = util.JSONToTable(uncompressed) or {}
    ply.PS_Items = PS:ValidateItems(items)

    -- Update buttons
    if IsValid(PS.ShopMenu) then
        local item = PS.ShopMenu.Buy.Item

        PS.ShopMenu.Buy:SetItem(item)
        PS.ShopMenu.Customize:SetItem(item)
        PS.ShopMenu.Equip:SetItem(item)
    end
end)

net.Receive("PS_Points", function(length)
    local ply = net.ReadEntity()
    local points = net.ReadUInt(32)
    ply.PS_Points = PS:ValidatePoints(points)
end)

net.Receive("PS_SendNotification", function(length)
    local str = net.ReadString()
    notification.AddLegacy(str, NOTIFY_GENERIC, 5)
end)

function PS.PlayerDraw(ply, flags, ent)
    if not ply.PS_Items then return end

    for id, item in pairs(ply.PS_Items) do
        local ITEM = PS.Items[id]
        if ITEM and item.Equipped and ITEM.OnPlayerDraw then
            ITEM:OnPlayerDraw(ply, flags, ent, item.Modifiers)
        end
    end
end

hook.Add("PostPlayerDraw", "PS_PlayerDraw", PS.PlayerDraw)
hook.Add("PostDrawTranslucentRenderables", "PS_PlayerDraw", function(_, skybox)
    if skybox then return end
    -- Draw player items in ragdoll
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() then continue end

        local ragdoll = ply:GetRagdollEntity()
        if not IsValid(ragdoll) then continue end

        PS.PlayerDraw(ply, 0, ragdoll)
    end
end)

hook.Add("ShutDown", "PS_WebMaterialsCleanup", function()
    local files, _ = file.Find("lbg_pointshop_webmaterials/*", "DATA")
    for _, filename in ipairs(files) do
        file.Delete("lbg_pointshop_webmaterials/" .. filename)
    end
end)

hook.Add("InitPostEntity", "PS_VisibilityNetwork", function()
    net.Start("PS_SetNetworkVisibility")
    net.SendToServer()
end)

hook.Add("Think", "PS_ModQueue", function()
    if table.IsEmpty(PS.ModQueue) or (PS.LastSentMods and CurTime() - PS.LastSentMods < 1) then return end
    PS.LastSentMods = CurTime()

    net.Start("PS_ModQueue")
    net.WriteString(util.TableToJSON(PS.ModQueue))
    net.SendToServer()

    table.Empty(PS.ModQueue)
end)

cvars.AddChangeCallback("ps_accessoryvisibility", function()
    net.Start("PS_SetNetworkVisibility")
    net.SendToServer()
end)

cvars.AddChangeCallback("ps_trailvisibility", function()
    net.Start("PS_SetNetworkVisibility")
    net.SendToServer()
end)

cvars.AddChangeCallback("ps_followervisibility", function()
    net.Start("PS_SetNetworkVisibility")
    net.SendToServer()
end)