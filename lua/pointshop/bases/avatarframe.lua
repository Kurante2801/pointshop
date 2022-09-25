local BASE = {}
BASE.ID = "avatarframe"

function BASE:OnEquip(ply, mods)
    if PS.GamemodeCheck(self) then return end
    ply:SetNWString("LBG_AvatarFrame", self.ID)
end

function BASE:OnHolster(ply)
    if PS.GamemodeCheck(self) then return end
    ply:SetNWString("LBG_AvatarFrame", "")
end

-- OnEquip is not called when joining the server
function BASE:OnSpawn(ply, mods)
    self:OnEquip(ply, mods)
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

-- [SteamID64] = id.png
PS.AvatarFrames = PS.AvatarFrames or {}

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
    self.Material = Material(item.Material, "noclamp smooth")
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

function PANEL:RequestFrame()
    -- HNS compatibility
end

function PANEL:RequestSteamFrame()
    self.AttemptedSteam = true
    local ply = self.Player
    if ply:IsBot() then return end

    local name = PS.AvatarFrames[ply:SteamID64()]
    if name then
        if string.EndsWith(name, ".png") then
            self.Material = Material("data/lbg_steam_avatarframes/" .. name, "noclamp smooth")
            print(CurTime())
        else
            self.Material = Material("steam_avatarframes/" .. name)
        end
        return
    end

    -- Get frame filename from steam profile
    http.Fetch("https://steamcommunity.com/profiles/" .. ply:SteamID64(), function(body)
        if not IsValid(self) or not IsValid(ply) then return end

        local _, _, url = string.find(body, [[<div class="profile_avatar_frame">%s*<img src="(.-)">]])
        -- Frame not found
        if not url then
            PS.AvatarFrames[ply:SteamID64()] = false
            return
        end

        _, _, name = string.find(url, [[/([%a%d]+)%.png]])
        if not name then return end

        -- We check if there are any manually created VTF material
        if file.Exists(string.format("materials/steam_avatarframes/%s.vtf", name), "GAME") then
            PS.AvatarFrames[ply:SteamID64()] = name
            self.Material = Material("steam_avatarframes/" .. name)
            return
        end

        name = name .. ".png"
        PS.AvatarFrames[ply:SteamID64()] = name

        -- We download and create the frame
        -- since GMod can't animate APNGs, the frame will not be animated
        http.Fetch(url, function(src)
            if not IsValid(self) or not IsValid(ply) then return end

            if not file.Exists("lbg_steam_avatarframes", "DATA") then
                file.CreateDir("lbg_steam_avatarframes")
            end

            local path = "lbg_steam_avatarframes/" .. name
            if not file.Exists(path, "DATA") then
                file.Write(path, src)
            end

            self.Material = Material("data/" .. path, "noclamp smooth")
        end)
    end, function(err) print(err) end)
end

function PANEL:SetPlayer(ply)
    self.Player = ply
end

vgui.Register("HNS.AvatarFrame", PANEL, "DPanel")
vgui.Register("PS_AvatarFrame", PANEL, "DPanel")

PANEL = {}
PANEL.PaddingMultiplier = 1.22

function PANEL:Init()
    self.Avatar = self:Add("AvatarImage")
    self.Avatar:Dock(FILL)
    self.Avatar:SetPaintedManually(true)
end

function PANEL:Paint(w, h)
    self.Avatar:PaintManual()

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

function PANEL:PerformLayout(w, h)
    self.PaddingX = (w - w / self.PaddingMultiplier) * 0.5
    self.PaddingY = (h - h / self.PaddingMultiplier) * 0.5
    self:DockPadding(self.PaddingX, self.PaddingY,self.PaddingX, self.PaddingY)
end

function PANEL:SetPlayer(ply, size)
    self.Avatar:SetPlayer(ply, size)
    self.Player = ply
end

function PANEL:RequestFrame()
    -- HNS compatibility
end

vgui.Register("HNS.Avatar", PANEL, "PS_AvatarFrame")

return PS:RegisterBase(BASE)