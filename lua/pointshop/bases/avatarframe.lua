local BASE = {}
BASE.ID = "avatarframe"

function BASE:OnEquip(ply, mods)
    if self:GamemodeCheck() then return end
    ply:SetNWString("LBG_AvatarFrame", self.ID)
end

function BASE:OnHolster(ply)
    if self:GamemodeCheck() then return end
    ply:SetNWString("LBG_AvatarFrame", "")
end

function BASE:OnPreDrawFrame(ply, w, h)
    surface.SetDrawColor(255, 255, 255, 255)
end

if SERVER then
    return PS:RegisterBase(BASE)
end

function BASE:OnPanelSetup(panel)
    panel.Avatar = panel:Add("AvatarImage")
    panel.Avatar:SetPos(18, 18)
    panel.Avatar:SetSize(105, 105)
    panel.Avatar:SetMouseInputEnabled(false)
    panel.Avatar:SetPaintedManually(true)
    panel.Avatar:SetPlayer(LocalPlayer(), 128)

    panel.MaskMat = Material(self.Material, "noclamp smooth")
 end

function BASE:OnPanelPaint(panel, w, h)
    panel.Avatar:PaintManual()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(panel.MaskMat)
    surface.DrawTexturedRect(6, 6, 128, 128)
 end

-- Steam IDs
BASE.Frames = {}

-- Avatar Frame
local PANEL = {}

function PANEL:Paint(w, h)
    if self.Item and self.Material then
        self.Item:OnPreDrawFrame(self.Player, w, h)
    elseif self.Material then
        surface.SetDrawColor(255, 255, 255, 255)
    else
        return
    end

    surface.SetMaterial(self.Material)
    surface.DrawTexturedRect(0, 0, w, h)
end

function PANEL:Think()
    if not IsValid(self.Player) or self.CustomMaterial then return end

    if self.Player:GetNWString("LBG_AvatarFrame", "") ~= self.AvatarFrame then
        self:SetItem(self.Player:GetNWString("LBG_AvatarFrame", ""))
    end

    if self.Item or self.AttemptedSteam then return end
    self:RequestSteamFrame()
end

function PANEL:SetItem(id)
    self.AvatarFrame = id
    local item = PS.Items[id]

    if not item or not item.Material then
        self.Item = nil
        self.AttemptedSteam = false
        self.Material = nil
        return
    end

    self.Item = item
    self.Material = Material(item.Material)
end

function PANEL:SetMaterial(material)
    self.Material = material
    self.CustomMaterial = true
end

function PANEL:AutoLayout()
    local x, y = self:GetPos()
    local size = math.Round(self:GetWide() * 1.22)
    local padding = math.Round(size * 0.089)

    self:SetPos(x - padding, y - padding)
    self:SetSize(size, size)
end

function PANEL:RequestSteamFrame()
    self.AttemptedSteam = true
    local ply = self.Player
    if ply:IsBot() then return end

    if BASE.Frames[ply:SteamID64()] then
        local name = BASE.Frames[ply:SteamID64()]
        if file.Exists(string.format("materials/steam_avatarframes/%s.vtf", name), "GAME") then
            self.Material = Material("steam_avatarframes/" .. name)
        else
            self.Material = Material(string.format("data/lbg_steam_avatarframes/%s.png", name), "noclamp smooth")
        end
        return
    end

    -- Get frame filename from steam profile
    http.Fetch("https://steamcommunity.com/profiles/" .. ply:SteamID64(), function(body)
        if not IsValid(self) or not IsValid(ply) then return end

        local _, _, url = string.find(body, [[<div class="profile_avatar_frame">%s*<img src="(.-)">]])
        -- Frame not found
        if not url then
            BASE.Frames[ply:SteamID64()] = false
            return
        end

        local _, _, name = string.find(url, [[/([%a%d]+)%.png]])
        if not name then return end
        -- Frame yes found
        BASE.Frames[ply:SteamID64()] = name

        -- We check if there are any manually created VTF material
        if file.Exists(string.format("materials/steam_avatarframes/%s.vtf", name), "GAME") then
            self.Material = Material("steam_avatarframes/" .. name)
            return
        end

        -- We download and create the frame
        -- since GMod can't animate APNGs, the frame will not be animated
        http.Fetch(url, function(src)
            if not IsValid(self) or not IsValid(ply) then return end

            if not file.Exists("lbg_steam_avatarframes", "DATA") then
                file.CreateDir("lbg_steam_avatarframes")
            end

            local path = string.format("lbg_steam_avatarframes/%s.png", name)
            if not file.Exists(path, "DATA") then
                file.Write(path, src)
            end

            self.Material = Material(string.format("data/lbg_steam_avatarframes/%s.png", name), "noclamp smooth")
        end)
    end, function(err) print(err) end)
end

function PANEL:SetPlayer(ply)
    self.Player = ply
end

vgui.Register("HNS.AvatarFrame", PANEL, "DPanel")
vgui.Register("PS_AvatarFrame", PANEL, "DPanel")

return PS:RegisterBase(BASE)