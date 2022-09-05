local COLOR_WHITE = Color(255, 255, 255)
local emptyfunc = function() end
local activefunc = function(this) return this.Active end
local downfunc = function(this) return this:IsDown() end
local foreground1func = function(panel, w, h)
    draw.RoundedBox(0, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local foreground1roundfunc = function(panel, w, h)
    draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local PANEL = {}
AccessorFunc(PANEL, "_color", "ThemeColor", FORCE_STRING)
AccessorFunc(PANEL, "_hovertext", "HoverText", FORCE_STRING)

PANEL.AlignX = TEXT_ALIGN_CENTER
PANEL.AlignY = TEXT_ALIGN_CENTER

function PANEL:Init()
    self.SetTextOriginal = self.SetText
    self.SetText = self.SetTextOverride

    self.SetContentAlignmentOriginal = self.SetContentAlignment
    self.SetContentAlignment = self.SetContentAlignmentOverride

    self:SetFont("PS_Label")
    self:SetText("Label")
    self:SetContentAlignment(5)
    self:SetThemePressedColor("Foreground1Color")
    self:SetThemeHoverColor("Foreground1Color")
    self:DockPadding(6, 6, 6, 6)

    self:TDLib()
        :SetupTransition("ButtonDown", 6, downfunc)
        :SetupTransition("MouseHover", 6, TDLibUtil.HoverFunc)
end

function PANEL:Paint(w, h)
    draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("MainColor"))
    draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(self._down), self._downA * self.ButtonDown))
    draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(self._hover), self._hoverA * self.MouseHover))
end

function PANEL:PaintOver(w, h)
    local l, t, r, b = self:GetDockPadding()

    local text = self._text
    local mat = self.IconMaterial
    local mat_w, mat_h = self.IconWidth, self.IconHeight

    if self:IsHovered() then
        if self._hovertext ~= nil then
            text = self._hovertext
        end

        if self.HoverIconMaterial ~= nil and self.HoverIconMaterial ~= "" then
            if not self.HoverIconMaterial then
                mat = nil
            else
                mat = self.HoverIconMaterial
                mat_w, mat_h = self.HoverIconWidth, self.HoverIconHeight
            end
        end
    end

    local x = 0
    if self.AlignX == TEXT_ALIGN_LEFT then
        x = l
    elseif self.AlignX == TEXT_ALIGN_CENTER then
        x = w * 0.5
    elseif self.AlignX == TEXT_ALIGN_RIGHT then
        x = w - r
    end

    local y = 0
    if self.AlignY == TEXT_ALIGN_TOP then
        y = t
    elseif self.AlignY == TEXT_ALIGN_CENTER then
        y = h * 0.5
    elseif self.AlignY == TEXT_ALIGN_BOTTOM then
        y = h - b
    end

    if mat ~= nil then
        if self.AlignX == TEXT_ALIGN_LEFT then
            x = x + mat_w + 18
        elseif self.AlignX == TEXT_ALIGN_CENTER then
            x = x + mat_w * 0.5 + 3
        end
    end

    w = PS.ShadowedText(text, self:GetFont(), x, y, COLOR_WHITE, self.AlignX, self.AlignY)

    if mat ~= nil then
        if self.AlignX == TEXT_ALIGN_CENTER then
            w = w * 0.5
        elseif self.AlignX == TEXT_ALIGN_LEFT then
            w = 0
        end

        PS.ShadowedImage(mat, x - mat_w - w, y, mat_w, mat_h, COLOR_WHITE, TEXT_ALIGN_CENTER, self.AlignY)
    end
end

function PANEL:SetTextOverride(text)
    self:SetTextOriginal(text)
    self:SetTextColor(Color(0, 0, 0, 0))
    self._text = text
end

local alignsX = { TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, TEXT_ALIGN_RIGHT }
local alignsY = { TEXT_ALIGN_BOTTOM, TEXT_ALIGN_BOTTOM, TEXT_ALIGN_BOTTOM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, TEXT_ALIGN_TOP, TEXT_ALIGN_TOP }
function PANEL:SetContentAlignmentOverride(align)
    self:SetContentAlignmentOriginal(align)
    self.AlignX = alignsX[align]
    self.AlignY = alignsY[align]
end

function PANEL:SetIcon(path, w, h)
    self.IconWidth = w
    self.IconHeight = h

    self.IconMaterial = Material(path, "noclamp smooth")
end

function PANEL:SetHoverIcon(path, w, h)
    if path == "" or not path then
        self.HoverIconMaterial = path
        return
    end

    self.HoverIconWidth = w
    self.HoverIconHeight = h

    self.HoverIconMaterial = Material(path, "noclamp smooth")
end

function PANEL:SetThemePressedColor(color_string, alpha)
    self._down = color_string
    self._downA = alpha or 200
end

function PANEL:SetThemeHoverColor(color_string, alpha)
    self._hover = color_string
    self._hoverA = alpha or 125
end

vgui.Register("PS_Button", PANEL, "DButton")