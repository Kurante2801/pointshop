--[[
	pointshop/cl_init.lua
	first file included clientside.
]]
--
include"sh_init.lua"
include"cl_player_extension.lua"
include"vgui/DPointShopMenu.lua"
include"vgui/DPointShopItem.lua"
include"vgui/DPointShopPreview.lua"
include"vgui/DPointShopColorChooser.lua"
include"vgui/DPointShopGivePoints.lua"

include"vgui_new/fdermalib.lua"
include"vgui_new/tdlib.lua"

include"vgui_new/dpointshop_menu.lua"
include"vgui_new/dpointshop_elements.lua"

PS.ShopMenu = nil
PS.ClientsideModels = PS.ClientsideModels or {}
PS.HoverModel = nil
PS.HoverModelClientsideModel = nil
local invalidplayeritems = {}

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

function PS:SetHoverItem(item_id)
    local ITEM = PS.Items[item_id]

    if ITEM.Model then
        self.HoverModel = item_id
        self.HoverModelClientsideModel = ClientsideModel(ITEM.Model, RENDERGROUP_OPAQUE)
        self.HoverModelClientsideModel:SetNoDraw(true)
    end
end

function PS:RemoveHoverItem()
    self.HoverModel = nil
    self.HoverModelClientsideModel = nil
end

-- modification stuff
function PS:ShowColorChooser(item, modifications)
    -- TODO: Do this
    local chooser = vgui.Create('DPointShopColorChooser')
    chooser:SetColor(modifications.color)

    chooser.OnChoose = function(color)
        modifications.color = color
        self:SendModifications(item.ID, modifications)
    end
end

function PS:SendModifications(item_id, modifications)
    net.Start('PS_ModifyItem')
    net.WriteString(item_id)
    net.WriteTable(modifications)
    net.SendToServer()
end

-- net hooks
net.Receive('PS_ToggleMenu', function(length)
    PS:ToggleMenu()
end)

net.Receive('PS_Items', function(length)
    local ply = net.ReadEntity()
    local items = net.ReadTable()
    ply.PS_Items = PS:ValidateItems(items)

    -- Update buttons
    if IsValid(PS.ShopMenu) then
        local item = PS.ShopMenu.Buy.Item

        PS.ShopMenu.Buy:SetItem(item)
        PS.ShopMenu.Customize:SetItem(item)
        PS.ShopMenu.Equip:SetItem(item)
    end
end)

net.Receive('PS_Points', function(length)
    local ply = net.ReadEntity()
    local points = net.ReadInt(32)
    ply.PS_Points = PS:ValidatePoints(points)
end)

net.Receive('PS_AddClientsideModel', function(length)
    local ply = net.ReadEntity()
    local item_id = net.ReadString()

    if not IsValid(ply) then
        if not invalidplayeritems[ply] then
            invalidplayeritems[ply] = {}
        end

        table.insert(invalidplayeritems[ply], item_id)

        return
    end

    ply:PS_AddClientsideModel(item_id)
end)

net.Receive('PS_RemoveClientsideModel', function(length)
    local ply = net.ReadEntity()
    local item_id = net.ReadString()
    if not ply or not IsValid(ply) or not ply:IsPlayer() then return end
    ply:PS_RemoveClientsideModel(item_id)
end)

net.Receive('PS_SendClientsideModels', function(length)
    local itms = net.ReadTable()

    for ply, items in pairs(itms) do
        -- skip if the player isn't valid yet and add them to the table to sort out later
        if not IsValid(ply) then
            invalidplayeritems[ply] = items
            continue
        end

        for _, item_id in pairs(items) do
            if PS.Items[item_id] then
                ply:PS_AddClientsideModel(item_id)
            end
        end
    end
end)

net.Receive('PS_SendNotification', function(length)
    local str = net.ReadString()
    notification.AddLegacy(str, NOTIFY_GENERIC, 5)
end)

-- hooks
hook.Add('Think', 'PS_Think', function()
    for ply, items in pairs(invalidplayeritems) do
        if IsValid(ply) then
            for _, item_id in pairs(items) do
                if PS.Items[item_id] then
                    ply:PS_AddClientsideModel(item_id)
                end
            end

            invalidplayeritems[ply] = nil
        end
    end
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