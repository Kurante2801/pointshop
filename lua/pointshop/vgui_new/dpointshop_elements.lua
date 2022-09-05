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
AccessorFunc(PANEL, "_dis", "ThemeDisabledColor", FORCE_STRING)
AccessorFunc(PANEL, "_main", "ThemeMainColor", FORCE_STRING)

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
    self:SetThemeMainColor("MainColor")
    self:SetThemeDisabledColor("Foreground2Color")
    self:SetThemePressedColor("Foreground1Color")
    self:SetThemeHoverColor("Foreground1Color")
    self:DockPadding(6, 6, 6, 6)

    self:TDLib()
        :SetupTransition("ButtonDown", 6, downfunc)
        :SetupTransition("MouseHover", 6, TDLibUtil.HoverFunc)
end

function PANEL:Paint(w, h)
    if self:IsEnabled() then
        draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._main))
    else
        draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._dis))
    end
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

function PANEL:Set(color_string)
    self._dis = color_string
end

vgui.Register("PS_Button", PANEL, "DButton")

PANEL = {}

function PANEL:Init()
    self:SetText("")

end

function PANEL:PaintOver(w, h)
    local l, t, r, b = self:GetDockPadding()
    local mat = self.IconMaterial
    local mat_w, mat_h = self.IconWidth, self.IconHeight

    if self:IsHovered() and self.HoverIconMaterial ~= nil and self.HoverIconMaterial ~= "" then
        if not self.HoverIconMaterial then
            mat = nil
        else
            mat = self.HoverIconMaterial
            mat_w, mat_h = self.HoverIconWidth, self.HoverIconHeight
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
        PS.ShadowedImage(mat, x, y, mat_w, mat_h, COLOR_WHITE, self.AlignX, self.AlignY)
    end
end

vgui.Register("PS_ButtonIcon", PANEL, "PS_Button")


-- Bro why is this not on base GMod
PANEL = {}
AccessorFunc(PANEL, "_min", "Min", FORCE_NUMBER)
AccessorFunc(PANEL, "_max", "Max", FORCE_NUMBER)
AccessorFunc(PANEL, "_def", "DefaultValue", FORCE_NUMBER)
AccessorFunc(PANEL, "_value", "FloatValue", FORCE_NUMBER)
AccessorFunc(PANEL, "_decimals", "Decimals", FORCE_NUMBER)

function PANEL:Init()
    self:SetMouseInputEnabled(true)

    self.Slider = self:Add("DSlider")
    self.Slider:SetLockX(0.5)
    self.Slider:SetLockY(nil)
    self.Slider.TranslateValues  = function(this, x, y) return self:TranslateSliderValues(x, y) end
    self.Slider:SetTrapInside(true)
    self.Slider:Dock(FILL)
    self.Slider:SetWide(24)
    self.Slider.Knob.OnMousePressed = function(this, mcode)
        if mcode == MOUSE_MIDDLE then
            self:ResetToRefaultValue()
        else
            self.Slider:OnMousePressed(mcode)
        end
    end

    self:SetMin(0)
    self:SetMax(1)
    self:SetDecimals(2)
    self:SetValue(0.5)
end

function PANEL:SetMinMax(min, max)
    self:SetMin(min)
    self:SetMax(max)
end

function PANEL:GetRange()
    return self:GetMax() - self:GetMin()
end

function PANEL:ResetToDefaultValue()
    if not self:GetDefaultValue() then return end
    self:SetValue(self:GetDefaultValue())
end

function PANEL:SetValue(value)
    value = math.Clamp(tonumber(value) or 0, self:GetMin(), self:GetMax())
    if self:GetValue() == value then return end
    self:SetFloatValue(value)
    self:ValueChanged(value)
end

function PANEL:GetValue()
    return self:GetFloatValue()
end

function PANEL:IsEditing()
    return self.Slider:IsEditing()
end

function PANEL:IsHovered()
    return self.Slider:IsHovered()
end

function PANEL:GetFraction()
    return (self:GetFloatValue() - self:GetMin()) / self:GetRange()
end

function PANEL:ValueChanged(value)
    value = math.Clamp(tonumber(value) or 0, self:GetMin(), self:GetMax())
    self.Slider:SetSlideY(self:GetFraction())
    self:OnValueChanged(value)
end

function PANEL:OnValueChanged(value) end

function PANEL:TranslateSliderValues(x, y)
    self:SetValue(self:GetMin() + (y * self:GetRange()))
    return x, self:GetFraction()
end

function PANEL:SetEnabled(enabled)
    self.Slider:SetEnabled(enabled)
    FindMetaTable("Panel").SetEnabled(self, enabled)
end


vgui.Register("PS_VerticalSlider", PANEL, "EditablePanel")