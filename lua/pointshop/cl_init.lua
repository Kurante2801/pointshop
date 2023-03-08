PS.ShopMenu = PS.ShopMenu or nil

PS_VIS_FIRSTPERSON, PS_VIS_OTHERTEAMS, PS_VIS_NONFRIENDS = 1, 2, 4
function PS.CanSeeItem(target, localVisibility, targetVisibility, isFirstPerson)
    local ply = LocalPlayer():GetViewEntity()
    if not IsValid(ply) or not ply:IsPlayer() then
        ply = LocalPlayer()
    end

    if target == ply then
        if isFirstPerson then
            return bit.band(localVisibility, PS_VIS_FIRSTPERSON) == PS_VIS_FIRSTPERSON
        else
            return true
        end
    end

    local status = target:GetFriendStatus()
    if status == "blocked" then return false end -- target is blocked on Steam

    -- Test for local visibility
    if bit.band(localVisibility, PS_VIS_OTHERTEAMS) ~= PS_VIS_OTHERTEAMS and ply:Team() ~= target:Team() then
        return false -- ply and target are on different team
    end

    if bit.band(localVisibility, PS_VIS_NONFRIENDS) ~= PS_VIS_NONFRIENDS and target:GetFriendStatus() ~= "friend" then
        return false -- ply and target are not friends
    end

    -- Test for target visibility
    if bit.band(targetVisibility, PS_VIS_OTHERTEAMS) ~= PS_VIS_OTHERTEAMS and ply:Team() ~= target:Team() then
        return false -- ply and target are on different team
    end

    if bit.band(targetVisibility, PS_VIS_NONFRIENDS) ~= PS_VIS_NONFRIENDS and target:GetFriendStatus() ~= "friend" then
        return false -- ply and target are not friends
    end

    return true
end

-- menu stuff
function PS:ToggleMenu()
    if IsValid(PS.ShopMenu) then
        PS.ShopMenu:SetVisible(not PS.ShopMenu:IsVisible())
    else
        PS.ShopMenu = vgui.Create("PS_Menu")
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
    local files, _ = file.Find("pointshop_webmaterials/*", "DATA")
    for _, filename in ipairs(files) do
        file.Delete("pointshop_webmaterials/" .. filename)
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