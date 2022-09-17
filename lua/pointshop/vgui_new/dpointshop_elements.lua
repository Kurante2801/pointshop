local COLOR_WHITE = Color(255, 255, 255)
local draw_RoundedBox = draw.RoundedBox
local draw_RoundedBoxEx = draw.RoundedBoxEx

local emptyfunc = function() end
local activefunc = function(this) return this.Active end
local downfunc = function(this) return this:IsDown() end
local foreground1func = function(panel, w, h)
    draw_RoundedBox(0, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local foreground1roundfunc = function(panel, w, h)
    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local PANEL = {}
AccessorFunc(PANEL, "_color", "ThemeColor", FORCE_STRING)
AccessorFunc(PANEL, "_hovertext", "HoverText")
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
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._main))
    else
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._dis))
    end
    draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(self._hover), self._hoverA * self.MouseHover))
    draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(self._down), self._downA * self.ButtonDown))
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

PANEL = {}
AccessorFunc(PANEL, "._text", "Text", FORCE_STRING)
AccessorFunc(PANEL, "._font", "Font", FORCE_STRING)
PANEL.AlignX = TEXT_ALIGN_CENTER
PANEL.AlignY = TEXT_ALIGN_CENTER

function PANEL:Init()
    self:SetText("Label")
    self:SetFont("PS_Label")
    self:SetContentAlignment(5)
    self:DockPadding(6, 6, 6, 6)
end

function PANEL:PaintOver(w, h)
    local l, t, r, b = self:GetDockPadding()

    local mat = self.IconMaterial
    local mat_w, mat_h = self.IconWidth, self.IconHeight

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

    w = PS.ShadowedText(self:GetText(), self:GetFont(), x, y, COLOR_WHITE, self.AlignX, self.AlignY)

    if mat ~= nil then
        if self.AlignX == TEXT_ALIGN_CENTER then
            w = w * 0.5
        elseif self.AlignX == TEXT_ALIGN_LEFT then
            w = 0
        end

        PS.ShadowedImage(mat, x - mat_w - w, y, mat_w, mat_h, COLOR_WHITE, TEXT_ALIGN_CENTER, self.AlignY)
    end
end

function PANEL:SetContentAlignmentOverride(align)
    self.AlignX = alignsX[align]
    self.AlignY = alignsY[align]
end

function PANEL:SetIcon(path, w, h)
    self.IconWidth = w
    self.IconHeight = h

    self.IconMaterial = Material(path, "noclamp smooth")
end

vgui.Register("PS_Label", PANEL, "EditablePanel")

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

PANEL = {}

-- TODO: Use default model or equipped model when spectating
function PANEL:Init()
    self:SetModel(LocalPlayer():GetModel())

    local mins, maxs = self.Entity:GetRenderBounds()
    self:SetCamPos(mins:Distance(maxs) * Vector(0.30, 0.30, 0.25) + Vector(0, 8, 15))
    self:SetLookAt((maxs + mins) / 2 + Vector(0, -4, 0))

    self.Angles = Angle(0, 0, 0)
    self.LastPress = 0
end

function PANEL:Paint(w, h)
    if not IsValid(self.Entity) then return end
    local x, y = self:LocalToScreen(0, 0)
    local ang = self.aLookAngle or (self.vLookatPos - self.vCamPos):Angle()
    self:LayoutEntity(self.Entity)

    cam.Start3D(self.vCamPos, ang, self.fFOV, x, y, w, h, 5, 4096)
    cam.IgnoreZ(true)
    render.SuppressEngineLighting(true)
    render.SetLightingOrigin(self.Entity:GetPos())
    render.ResetModelLighting(self.colAmbientLight.r / 255, self.colAmbientLight.g / 255, self.colAmbientLight.b / 255)
    render.SetColorModulation(self.colColor.r / 255, self.colColor.g / 255, self.colColor.b / 255)
    render.SetBlend(self.colColor.a / 255)

    for i = 0, 6 do
        local col = self.DirectionalLight[i]

        if (col) then
            render.SetModelLighting(i, col.r / 255, col.g / 255, col.b / 255)
        end
    end

    self.Entity:DrawModel()

    -- Either draw models in preview or the local player
    local should, item = false, nil, nil
    if PS.ActiveItem then
        item = PS.Items[PS.ActiveItem]
        if item and (item.IsPlayermodel or item.Props) then
            should = true
        end
    end

    if should then
        for _, model in pairs(self.Models) do
            model:DrawModel()
            local pos
            pos, ang = item:GetBonePosAng(self.Entity, model.prop.bone)
            if not pos or not ang then continue end

            -- Offset
            pos = pos + ang:Forward() * model.prop.pos.x - ang:Right() * model.prop.pos.y + ang:Up() * model.prop.pos.z
            ang:RotateAroundAxis(ang:Forward(), model.prop.ang.p)
            ang:RotateAroundAxis(ang:Right(), -model.prop.ang.y)
            ang:RotateAroundAxis(ang:Up(), -model.prop.ang.r)

            model, pos, ang = item:ModifyClientsideModel(LocalPlayer(), model, pos, ang)

            model:SetPos(pos)
            model:SetAngles(ang)
            model:SetRenderOrigin(pos)
            model:SetRenderAngles(ang)
            model:SetupBones()

            if model.prop.colorabletype == "playercolor" then
                local color = LocalPlayer():GetPlayerColor()
                render.SetBlend(1)
                render.SetColorModulation(color.x, color.y, color.z)
            elseif model.prop.colorabletype == "rainbow" then
                local color = HSVToColor(RealTime() * (model.prop.speed or 70) % 360, 1, 1)
                render.SetBlend(1)
                render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
            else
                render.SetBlend(model.alpha or 1)
                render.SetColorModulation(model.Color.x, model.Color.y, model.Color.z)
            end

            model:DrawModel()
            if model.prop.animated then
                model:FrameAdvance((RealTime() - model.LastPaint) * (model.data.animspeed or 1))
            end

            model:SetRenderOrigin()
            model:SetRenderAngles()
            render.SetBlend(1)
            render.SetColorModulation(1, 1, 1)
        end
    else
        PS.PlayerDraw(LocalPlayer(), 0, self.Entity)
    end

    render.SuppressEngineLighting(false)
    cam.IgnoreZ(false)
    cam.End3D()
end

function PANEL:GetPlayerColor()
    return LocalPlayer():GetPlayerColor()
end

function PANEL:LayoutEntity(ent)
    ent.GetPlayerColor = self.GetPlayerColor

    if self.Pressed then
        local mx = input.GetCursorPos()
        self.Angles.y = self.Angles.y - ((self.PressX or mx) - mx)
        self.PressX, self.PressY = input.GetCursorPos()

        ent:SetAngles(self.Angles)
    end

    if not PS.ActiveItem then
        local ply = LocalPlayer()
        if ent.Skin ~= ply:GetSkin() then
            ent:SetSkin(ply:GetSkin())
        end

        for _, group in ipairs(ply:GetBodyGroups()) do
            if ent:GetBodygroup(group.id) ~= ply:GetBodygroup(group.id) then
                ent:SetBodygroup(group.id, ply:GetBodygroup(group.id))
            end
        end
    end
end

function PANEL:OnRemove()
    SafeRemoveEntity(self.Entity)
end

function PANEL:OnMouseWheeled(delta)
    if not IsValid(self.Entity) then return end

    self:SetFOV(math.Clamp(self:GetFOV() - delta * 2, 10, 90))
end

function PANEL:DragMousePress()
    self.PressX, self.PressY = input.GetCursorPos()
    self.Pressed = true
end

function PANEL:DragMouseRelease()
    self.Pressed = false
end

vgui.Register("PS_Preview", PANEL, "DModelPanel")

PANEL = {}

function PANEL:Init()
    self:SetSize(140, 158)
    self:DockMargin(6, 6, 6, 6)
    self:DockPadding(6, 6, 6, 24)
    self:SetText("")
    self.FrameTime = 0

    self.OwnedMat = Material("lbg_pointshop/derma/sell.png")
    self.EquippedMat = Material("lbg_pointshop/derma/checkroom.png")

    self:TDLib()
        :SetupTransition("MouseHover", 12, TDLibUtil.HoverFunc)
        :SetupTransition("ItemActive", 12, function(this) return PS.ActiveItem == this.Item.ID or PS.ActiveItem == this.Item end)
end

function PANEL:Paint(w, h)
    local owned = false
    self._back = "Foreground2Color"

    if self.Item then
        owned = LocalPlayer():PS_HasItem(self.Item.ID)
        self._back = owned and "Foreground2Color" or "Foreground1Color"
    end

    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._back))
    draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 125 * self.MouseHover))
    draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * self.ItemActive))
    draw_RoundedBox(6, 6, 6, w - 12, w - 12, PS:GetThemeVar("BackgroundColor"))

    if not self.Item then return end

    if self.Item.OnPanelPaint then
        self.Item:OnPanelPaint(self, w, h)
    elseif self.Mat then
        PS.Mask(self, 6, 6, w - 12, w - 12, function()
            surface.SetMaterial(self.Mat)
            surface.SetDrawColor(255, 255, 255, 255)
            -- Scrolling down
            if self:IsHovered() then
                self.FrameTime = self.FrameTime + 0.5
            end

            surface.DrawTexturedRect(6, 6 + self.FrameTime % 128 - 128, 128, 128)
            surface.DrawTexturedRect(6, 6 + self.FrameTime % 128, 128, 128)
        end)
    end

    PS.ShadowedText(self:IsHovered() and self.SetHoverText or (self.Item.Name or self.Item.ID), "PS_LabelSmall", w * 0.5, h - 4, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

    if owned then
        PS.ShadowedImage(self.OwnedMat, 10, 10, 16, 16, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        if LocalPlayer():PS_HasItemEquipped(self.Item.ID) then
            PS.ShadowedImage(self.EquippedMat, 30, 10, 18, 18, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
end

function PANEL:OnCursorEntered()
    local ply = LocalPlayer()
    if ply:PS_HasItem(self.Item.ID) then
        self.SetHoverText = "+" .. PS.Config.CalculateSellPrice(ply, self.Item)
    else
        self.SetHoverText = "-" .. PS.Config.CalculateBuyPrice(ply, self.Item)
    end
end

function PANEL:SetData(item)
    self.Item = item
    if item.OnPanelSetup then
        item:OnPanelSetup(self)
        return
    end

    if not item.OnPanelPaint then
        if item.Material then
            self.Mat = Material(item.Material, "noclamp smooth")
        elseif item.Model then
            self.ModelPanel = self:Add("DModelPanel")
            self.ModelPanel:SetModel(item.Model)
            self.ModelPanel:SetPos(6, 6)
            self.ModelPanel:SetSize(128, 128)
            self.ModelPanel:SetMouseInputEnabled(false)

            if item.Skin then
                self.ModelPanel:SetSkin(item.Skin)
            end

            local PrevMins, PrevMaxs = self.ModelPanel.Entity:GetRenderBounds()
            self.ModelPanel:SetCamPos(PrevMins:Distance(PrevMaxs) * Vector(0.5, 0.5, 0.5))
            self.ModelPanel:SetLookAt((PrevMaxs + PrevMins) / 2)

            self.ModelPanel.LayoutEntity = function(this, ent)
                if this:GetParent():IsHovered() then
                    ent:SetAngles(Angle(0, ent:GetAngles().y + 1, 0))
                end

                if self.Item.ModifyClientsideModel then
                    self.Item:ModifyClientsideModel(LocalPlayer(), ent, Vector(), Angle())
                end

                ent.GetPlayerColor = function() return LocalPlayer():GetPlayerColor() end
            end
        end
    end
end

function PANEL:DoClick()
    if self.Item then
        self:OnItemSelected(self.Item)
    end
end

function PANEL:OnItemSelected(item) end

vgui.Register("PS_Item", PANEL, "DButton")

PANEL = {}

function PANEL:Init()
    self.VBar:SetWide(22)
    self.VBar:SetHideButtons(true)
    self.VBar:TDLib():SetupTransition("MouseHover", 6, function(this) return self:IsHovered() or this:IsHovered() or this.btnGrip:IsHovered() or this.btnGrip.Depressed end)
    self.VBar.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("Foreground2Color"), 255 * this.MouseHover))
    end

    self.VBar.btnGrip:TDLib()
        :SetupTransition("MouseHover", 12, TDLibUtil.HoverFunc)
        :SetupTransition("ButtonDown", 6, function(this) return this.Depressed end)
    self.VBar.btnGrip.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("MainColor"))
        draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("Foreground1Color"), 200 * this.ButtonDown))
        draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("Foreground1Color"), 125 * this.MouseHover))
    end
end

vgui.Register("PS_ScrollPanel", PANEL, "DScrollPanel")

PANEL = {}
AccessorFunc(PANEL, "_snap", "Snap", FORCE_NUMBER)

function PANEL:Init()
    self:SetSnap(0.5)

    self.Label:Remove()
    self.Label = self:Add("PS_Label")
    self.Label:Dock(LEFT)
    self.Label:DockMargin(0, 0, 6, 0)
    self.Label:SetMouseInputEnabled(true)
    self.Label:DockPadding(0, 0, 0, 0)
    self.Label:TDLib():SetupTransition("ScratchHover", 6, function() return self.Scratch:IsHovered() end)
    self.Label.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * this.ScratchHover))
    end

    self.Scratch = self.Label:Add("DNumberScratch")
    self.Scratch:SetImageVisible(false)
    self.Scratch:Dock(FILL)
    self.Scratch:Hide()
    self.Scratch:SetValue(self:GetValue())
    self.Scratch.OnValueChanged = function() self:ValueChanged(self.Scratch:GetFloatValue()) end
    self.Wang = self.Scratch

    self.TextArea:SetTextColor(COLOR_WHITE)
    self.TextArea:SetCursorColor(COLOR_WHITE)
    self.TextArea:DockMargin(6, 0, 0, 0)

    self.TextArea:SetFont("PS_Label")
    self.TextArea:SetWide(80)
    self.TextArea:SetContentAlignment(5)
    self.TextArea.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        derma.SkinHook("Paint", "TextEntry", this, w, h)
    end

    self.Slider.Paint = function(this, w, h)
        draw_RoundedBox(3, 10, h * 0.5 - 3, w - 20, 6, PS:GetThemeVar("Foreground1Color"))
        draw_RoundedBox(3, 10, h * 0.5 - 3, (w - 20) * self.Scratch:GetFraction(), 6, PS:GetThemeVar(this._fill))
    end

    self.Slider.Knob:SetSize(18, 18)
    self.Slider.Knob.Mat = Material("lbg_pointshop/derma/slider_knob.png", "noclamp smooth")
    self.Slider.Knob.Paint = function(this, w, h)
        PS.ShadowedImage(this.Mat, 0, 0, w, h, PS:GetThemeVar(this._color))
    end

    self:SetFillThemeColor("MainColor")
    self:SetMinMax(0, 5)
    self:SetValue(2.5)
end

function PANEL:ApplySchemeSettings()
end

function PANEL:ValueChanged(value)
    local desired = tonumber(value)
    desired = math.Round(self:GetSnap() * math.Round(desired / self:GetSnap()), self:GetDecimals())
    desired = math.Clamp(desired, self:GetMin(), self:GetMax())

    if desired ~= value then
        self:SetValue(desired)
        return
    end

    if self.TextArea ~= vgui.GetKeyboardFocus() then
        self.TextArea:SetValue(self.Scratch:GetTextValue())
    end

    self.Slider:SetSlideX(self.Scratch:GetFraction(desired))
    self:OnValueChanged(desired)
end

function PANEL:SetFillThemeColor(color_string)
    self.Slider._fill = color_string
    self.Slider.Knob._color = color_string
end

vgui.Register("PS_HorizontalSlider", PANEL, "DNumSlider")

PANEL = {}
AccessorFunc(PANEL, "_border", "ThemeBorderColor", FORCE_STRING)
AccessorFunc(PANEL, "_borderSize", "BorderSize", FORCE_NUMBER)
AccessorFunc(PANEL, "m_bDoSort", "SortItems", FORCE_BOOL)

function PANEL:Init()
    self:SetThemeMainColor("Foreground1Color")
    self:SetThemeHoverColor("MainColor", 255)
    self:SetThemeBorderColor("MainColor")
    self:SetBorderSize(3)
    self:SetContentAlignment(4)
    self:SetSortItems(true)

    self:Clear()

    self.ArrowMat = Material("lbg_pointshop/derma/expand_more.png", "noclamp smooth")
    self:TDLib():On("PaintOver", function(this, w, h)
        PS.ShadowedImage(this.ArrowMat, w - 8, h * 0.5, 20, 20, COLOR_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end)
end

function PANEL:Paint(w, h)
    if self:IsEnabled() then
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._border))
        draw_RoundedBox(self._borderSize, self._borderSize, self._borderSize, w - self._borderSize * 2, h - self._borderSize * 2, PS:GetThemeVar(self._main))
    else
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(self._dis))
    end
    draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(self._hover), self._hoverA * self.MouseHover))
    draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(self._down), self._downA * self.ButtonDown))
end

function PANEL:Clear()
    self:SetText("")
    self.Choices = {}
    self.Data = {}
    self.ChoiceIcons = {}
    self.Spacers = {}
    self.selected = nil

    if IsValid(self.Menu) then
        self.Menu:Remove()
    end
end

function PANEL:GetOptionText(id)
    return self.Choices[id]
end

function PANEL:GetOptionData(id)
    return self.Data[id]
end

function PANEL:GetOptionTextByData(data)
    for id, dat in pairs(self.Data) do
        if dat == data then
            return self:GetOptionText(id)
        end
    end

    -- Try interpreting it as a number
    for id, dat in pairs(self.Data) do
        if dat == tonumber(data) then
        return self:GetOptionText(id)
        end
    end

    -- In case we fail
    return data
end

function PANEL:ChooseOption(value, index)
    if IsValid(self.Menu) then
        self.Menu:Remove()
    end

    self:SetText(value)
    self.selected = index

    self:OnSelect(index, value, self:GetOptionData(index))
end

function PANEL:ChooseOptionID(index)
    local value = self:GetOptionText(index)
    self:ChooseOption(value, index)
end

function PANEL:OnSelect(index, value, data)
    -- For override
end

function PANEL:OnMenuOpened(menu)
    -- For override
end

function PANEL:AddSpacer()
    self.Spacers[#self.Choices] = true
end

function PANEL:AddChoice(value, data, select, icon)
    local i = table.insert(self.Choices, value)
    self.Data[i] = data
    self.ChoiceIcons[i] = icon

    if select then
        self:ChooseOption(value, i)
    end

    return i
end

function PANEL:IsMenuOpen()
    return IsValid(self.Menu)
end

function PANEL:OpenMenu(pControlOpener)
    if pControlOpener and pControlOpener == self.TextEntry then
        return
    end

    if #self.Choices == 0 then return end

    if IsValid(self.Menu) then
        self.Menu:Remove()
    end

    local parent = self
    while IsValid(parent) and not parent:IsModal() do
        parent = parent:GetParent()
    end

    if not IsValid(parent) then
        parent = self
    end

    self.Menu = parent:Add("PS_DermaMenu")

    local sorted = {}

    for k, v in pairs(self.Choices) do
        table.insert(sorted, { id = k, data = self.Data[k], label = tostring(v) } )
    end

    local func = self:GetSortItems() and SortedPairsByMemberValue or pairs
    for k, v in func(sorted, "label") do
        local option = self.Menu:AddOption(v.label, function()
            self:ChooseOption(v.label or "", v.id)
        end)

        if self.ChoiceIcons[v.id] then
            option:SetIcon(self.ChoiceIcons[v.id])
        end

        if self.Spacers[v.id] then
            self.Menu:AddSpacer()
        end
    end

    local x, y = self:LocalToScreen(0, self:GetTall())
    self.Menu:SetMinimumWidth(self:GetWide())
    self.Menu:Open(x, y, false, self)

    self:OnMenuOpened(self.Menu)
end

function PANEL:CloseMenu()
    if IsValid(self.Menu) then
        self.Menu:Remove()
    end
end

function PANEL:SetValue(strValue)
    self:SetText(strValue)
end

function PANEL:DoClick()
    if self:IsMenuOpen() then
        self:CloseMenu()
    else
        self:OpenMenu()
    end
end

function PANEL:GetSelectedID()
    return self.selected
end

vgui.Register("PS_ComboBox", PANEL, "PS_Button")

PANEL = {}

function PANEL:Paint(w, h)
    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

function PANEL:AddOption(text, callback)
    local button = self:Add("PS_Button")
    button:SetText(text)
    button:SetTall(32)
    button:SetContentAlignment(4)
    button.DoClick = callback

    button:SetThemeMainColor("Foreground2Color")
    button:SetThemeHoverColor("MainColor", 255)

    self:AddPanel(button)
    return button
end

vgui.Register("PS_DermaMenu", PANEL, "DMenu")

PANEL = {}
AccessorFunc(PANEL, "_alpha", "AlphaAllowed", FORCE_BOOL)

function PANEL:Init()
    self:SetWide(150)

    self.Button = self:Add("DButton")
    self.Button:TDLib()
        :ClearPaint()
        :Text("")
        :On("Paint", function(this, w, h)
            -- Outline
            if self:IsDark() then
                surface.SetDrawColor(255, 255, 255, 255)
            else
                surface.SetDrawColor(0, 0, 0, 255)
            end
            surface.DrawRect(0, 0, w, h)

            -- Transparency things
            local half_w, half_h = w * 0.5, h * 0.5
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawRect(2, 2, half_w - 2, half_h - 2)
            surface.DrawRect(half_w, half_w, half_w - 2, half_h - 2)
            surface.SetDrawColor(200, 200, 200)
            surface.DrawRect(half_w, 2, half_w - 2, half_h - 2)
            surface.DrawRect(2, half_h, half_w - 2, half_h - 2)

            -- Color
            local color = self:GetValue()
            surface.SetDrawColor(color.r, color.g, color.b, color.a)
            surface.DrawRect(2, 2, w - 4, h - 4)
        end)
        :On("DoClick", function(this)
            local picker = vgui.Create("PS_ColorModal")
            picker:Open()
            picker:SetValue(self:GetValue(), self:GetAlphaAllowed())
            picker.OnValueChanged = function(_, value)
                self:SetValue(value, self:GetAlphaAllowed())
                self:OnValueChanged(self:GetValue())
            end
        end)

    self.TextArea = self:Add("DTextEntry")
    self.TextArea:SetFont("PS_Label")
    self.TextArea:SetTextColor(COLOR_WHITE)
    self.TextArea:SetCursorColor(COLOR_WHITE)
    self.TextArea:SetPaintBackground(false)
    self.TextArea.OnValueChange = function(this, value)
        self:SetValue(PS.HEXtoRGB(value, self:GetAlphaAllowed()), self:GetAlphaAllowed())
        self:OnValueChanged(self:GetValue())
    end

    self:SetValue(Color(0, 255, 255, 255), true)
end

function PANEL:Paint(w, h)
    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

function PANEL:PerformLayout(w, h)
    self.Button:SetSize(h - 8, h - 8)
    self.Button:SetPos(4, h * 0.5 - self.Button:GetTall() * 0.5)

    local wide = self.Button:GetWide() + 8
    self.TextArea:SetSize(w - wide, h)
    self.TextArea:SetPos(wide, 0)
end

function PANEL:SetValue(color, allowAlpha)
    if not allowAlpha then
        color.a = 255
    end

    self:SetAlphaAllowed(allowAlpha)
    self._color = color
    self._dark = self:GetDark(color)

    self.TextArea:SetText("##" .. PS.RGBtoHEX(color, allowAlpha))
end

function PANEL:GetValue(color)
    if not self._alpha then
        self._color.a = 255
    end

    return self._color
end

function PANEL:GetDark(color)
    local _, _, v = Color(color.r, color.g, color.b):ToHSV()
    return v < 0.5
end

function PANEL:IsDark(color)
    return self._dark
end

function PANEL:OnValueChanged(value)
end

vgui.Register("PS_ColorPicker", PANEL, "EditablePanel")

PANEL = {}
AccessorFunc(PANEL, "m_UpdateOnChange", "UpdateOnChange", FORCE_BOOL)
AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu")
AccessorFunc(PANEL, "m_bDeleteSelf", "DeleteSelf")
AccessorFunc(PANEL, "_alpha", "AlphaAllowed")

PANEL:SetIsMenu(true)
PANEL:SetDeleteSelf(true)
PANEL:SetAlphaAllowed(true)

function PANEL:Init()
    RegisterDermaMenuForClose(self)
    self:DockPadding(6, 6, 6, 6)

    self.Mixer = self:Add("DColorMixer")
    self.Mixer:Dock(FILL)
    self.Mixer:SetPalette(false)
    self.Mixer.WangsPanel:SetWide(76)
    self.Mixer.ValueChanged = function(this, color)
        if this.notuserchange then return end

        self:SetValue(color, self:GetAlphaAllowed())
    end

    local keys = { "txtR", "txtG", "txtB", "txtA" }
    for i, key in ipairs(keys) do
        local wang = self.Mixer[key]
        wang.m_bIsMenuComponent = true
        wang:DockMargin(24, 0, 0, 6)
        wang:SetPaintBackground(false)
        wang:SetFont("PS_Label")
        wang:SetTall(24)
        wang:SetTextColor(COLOR_WHITE)
        wang:SetCursorColor(COLOR_WHITE)
        wang.Paint = function(this, w, h)
            draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
            derma.SkinHook("Paint", "TextEntry", this, w, h)
        end
    end

    self.Accept = self.Mixer.WangsPanel:Add("PS_Button")
    self.Accept:Dock(BOTTOM)
    self.Accept:DockMargin(8, 8, 8, 8)
    self.Accept:SetTall(60)
    self.Accept:SetText("")
    self.Accept:SetThemeMainColor("Foreground1Color")
    self.Accept:SetThemeHoverColor("MainColor", 255)
    self.Accept:On("Paint", function(this, w, h)
        -- Outline
        if self:IsDark() then
            surface.SetDrawColor(255, 255, 255, 255)
        else
            surface.SetDrawColor(0, 0, 0, 255)
        end
        surface.DrawRect(6, 6, w - 12, h - 12)

        -- Transparency things
        local half_w, half_h = w * 0.5, h * 0.5
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(8, 8, half_w - 8, half_h - 8)
        surface.DrawRect(half_w, half_w, half_w - 8, half_h - 8)
        surface.SetDrawColor(200, 200, 200)
        surface.DrawRect(half_w, 8, half_w - 8, half_h - 8)
        surface.DrawRect(8, half_h, half_w - 8, half_h - 8)

        -- Color
        local color = self:GetValue()
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawRect(8, 8, w - 16, h - 16)
    end):On("DoClick", function()
        self:OnValueChanged(self:GetValue())
        CloseDermaMenus()
    end)
end

local red = Color(255, 0, 0)
local green = Color(0, 255, 0)
local blue = Color(0, 0, 255)

function PANEL:Paint(w, h)
    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground2Color"))

    PS.ShadowedText("R", "PS_Label", w - 80, 8, red)
    PS.ShadowedText("G", "PS_Label", w - 80, 38, green)
    PS.ShadowedText("B", "PS_Label", w - 80, 68, blue)

    if self:GetAlphaAllowed() then
        PS.ShadowedText("A", "PS_Label", w - 80, 98, COLOR_WHITE)
    end

    draw_RoundedBox(0, w - 71, 133, 50, 50, Color(255, 0, 0))
end

function PANEL:Open(x, y)
    local w, h = self:GetSize()

    if not x then
        x, y = input.GetCursorPos()
    end

    x = math.Clamp(x, 1, ScrW() - w)
    y = math.Clamp(y, 1, ScrH() - h)

    self:SetPos(x, y)
    self:MakePopup()
    self:MoveToFront()
end

function PANEL:SetValue(color, allowAlpha)
    if not allowAlpha then
        color.a = 255
    end

    self:SetAlphaAllowed(allowAlpha)
    self._color = color
    self._dark = self:GetDark(color)

    self.Mixer.txtA:SetVisible(allowAlpha)
    self.Mixer.Alpha:SetVisible(allowAlpha)

    self.Mixer.notuserchange = true
    self.Mixer:SetColor(color)
    self.Mixer.notuserchange = nil

    self:SetSize(allowAlpha and 340 or 310, 200)
end

function PANEL:GetValue(color)
    if not self._alpha then
        self._color.a = 255
    end

    return self._color
end

function PANEL:GetDark(color)
    local _, _, v = Color(color.r, color.g, color.b):ToHSV()
    return v < 0.5
end

function PANEL:IsDark(color)
    return self._dark
end

function PANEL:OnValueChanged(color)
end

vgui.Register("PS_ColorModal", PANEL, "EditablePanel")