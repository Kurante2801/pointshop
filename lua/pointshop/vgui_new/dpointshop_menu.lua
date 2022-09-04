local COLOR_WHITE = Color(255, 255, 255)

function PS:GetThemeVar(element)
    return self.Config.Themes[self.Config.DefaultTheme][element] or self.Config.Themes.default[element]
end

surface.CreateFont("PS_Header", {
    font = "Rubik SemiBold",
    size = 30, shadow = false, antialias = true,
})

-- https://github.com/Arizard/deathrun/blob/master/gamemode/cl_derma.lua#L57
local text_shadow = Color(0, 0, 0)
PS.ShadowedText = function(text, font, x, y, color, alignx, aligny, blur)
    blur = blur or 1
    if blur ~= 0 then
        text_shadow.a = color.a * 0.25
        draw.SimpleText(text, font, x + blur * 2, y + blur * 2, text_shadow, alignx, aligny)
        text_shadow.a = color.a * 0.5
        draw.SimpleText(text, font, x + blur, y + blur, text_shadow, alignx, aligny)
    end

    draw.SimpleText(text, font, x, y, color, alignx, aligny)
end


PS.ShadowedImage = function(material, x, y, w, h, color, alignx, aligny, blur)
    color = color or COLOR_WHITE
    alignx = alignx or TEXT_ALIGN_LEFT
    aligny = aligny or TEXT_ALIGN_TOP
    blur = blur or 1

    if alignx == TEXT_ALIGN_CENTER then
        x = x - w / 2
    elseif alignx == TEXT_ALIGN_RIGHT then
        x = x - w
    end

    if aligny == TEXT_ALIGN_CENTER then
        y = y - h / 2
    elseif aligny == TEXT_ALIGN_BOTTOM then
        y = y - h
    end

    surface.SetMaterial(material)

    surface.SetDrawColor(0, 0, 0, color.a * 0.25)
    surface.DrawTexturedRect(x + blur * 2, y + blur * 2, w, h)

    surface.SetDrawColor(0, 0, 0, color.a * 0.5)
    surface.DrawTexturedRect(x + blur, y + blur, w, h)

    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawTexturedRect(x, y, w, h)
end

local PANEL = {}
PANEL.BarHeight = 34

function PANEL:Init()
    self:SetSize(math.Clamp(1024, 0, ScrW()), math.Clamp(768, 0, ScrH()))
    self:Center()
    self:MakePopup()
    self:SetDraggable(false)
    self:SetTitle("")

    self.btnMaxim:SetVisible(false)
    self.btnMinim:SetVisible(false)
    self.btnClose.Mat = Material("lbg_pointshop/derma/close.png", "noclamp smooth")
    self.btnClose:TDLib()
        :ClearPaint()
        :On("PaintOver", function(this, w, h) PS.ShadowedImage(this.Mat, 0, 0, w, h) end)
        :FadeHover(ColorAlpha(PS:GetThemeVar("Foreground1Color"), 125), 6, 6)

    self.Settings = self:Add("DButton")
    self.Settings.Mat = Material("lbg_pointshop/derma/settings.png", "noclamp smooth")
    self.Settings:TDLib():ClearPaint()
        :Text("")
        :On("PaintOver", function(this, w, h) PS.ShadowedImage(this.Mat, 0, 0, w, h) end)
        :FadeHover(ColorAlpha(PS:GetThemeVar("Foreground1Color"), 125), 6, 6)

    self.Initialized = true
end

function PANEL:PerformLayout()
    local w = self:GetWide()

    self.btnClose:SetPos(w - self.BarHeight, 0)
    self.btnClose:SetSize(self.BarHeight, self.BarHeight)

    if not self.Initialized then return end

    self.Settings:SetPos(w - self.BarHeight * 2, 0)
    self.Settings:SetSize(self.BarHeight, self.BarHeight)
end

function PANEL:Paint(w, h)
    local main = PS:GetThemeVar("MainColor")
    local back = PS:GetThemeVar("BackgroundColor")

    draw.RoundedBoxEx(6, 0, self.BarHeight - 6, w, h - self.BarHeight + 6, back, false, false, true, true)
    draw.RoundedBox(6, 0, 0, w, self.BarHeight, main)

    PS.ShadowedText(PS.Config.CommunityName, "PS_Header", 6, self.BarHeight * 0.5, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("PS_Menu", PANEL, "DFrame")
vgui.Create("PS_Menu")