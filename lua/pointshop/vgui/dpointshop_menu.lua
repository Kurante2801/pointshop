local COLOR_WHITE = Color(255, 255, 255)
local emptyfunc = function() end
local draw_RoundedBox = draw.RoundedBox
local draw_RoundedBoxEx = draw.RoundedBoxEx

PS.ActiveItem = nil
PS.ActiveTheme = cookie.GetString("PS_Theme", "default")
PS.Theme = table.Copy(PS.Config.Themes.default)

if PS.ActiveTheme ~= "default" and istable(PS.Config.Themes[PS.ActiveTheme]) then
    table.Merge(PS.Theme, PS.Config.Themes[PS.ActiveTheme])
end

function PS:GetThemeVar(element)
    return PS.Theme[element]
end

function PS.Mask(panel, x, y, w, h, callback)
    render.ClearStencil()
    render.SetStencilEnable(true)

    render.SetStencilWriteMask(1)
    render.SetStencilTestMask(1)

    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    render.SetStencilPassOperation(STENCILOPERATION_ZERO)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilReferenceValue(1)

    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawRect(x, y, w, h)

    render.SetStencilFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    render.SetStencilReferenceValue(1)

    callback()

    render.SetStencilEnable(false)
    render.ClearStencil()
end

local font = file.Exists("resource/fonts/rubik-semibold.ttf", "THIRDPARTY") and "Rubik SemiBold" or "Circular Std Medium"

surface.CreateFont("PS_Label", {
    size = 20,
    font = font, shadow = false, antialias = true,
})

surface.CreateFont("PS_Header", {
    size = 30,
    font = font, shadow = false, antialias = true,
})

surface.CreateFont("PS_LabelLarge", {
    size = 26,
    font = font, shadow = false, antialias = true,
})

surface.CreateFont("PS_LabelSmall", {
    size = 16,
    font = font, shadow = false, antialias = true,
})

function PS:FadeFunction(panel, transition, color_string, alpha, speed, round, func)
    panel:TDLib()
        :SetupTransition(transition, speed, func)
        :On("Paint", function(this, w, h)
            draw_RoundedBox(round, 0, 0, w, h, ColorAlpha(self:GetThemeVar(color_string), alpha * this[transition]))
        end)

    return panel
end

function PS:FadeHover(panel, color_string, alpha, speed, round)
    return self:FadeFunction(panel, "PS_FadeHover", color_string, alpha, speed, round, TDLibUtil.HoverFunc)
end

local activefunc = function(this) return this.Active end
local downfunc = function(this) return this:IsDown() end

function PS:FadeActive(panel, color_string, alpha, speed, round)
    return self:FadeFunction(panel, "PS_FadeActive", color_string, alpha, speed, round, activefunc)
end

-- https://github.com/Arizard/deathrun/blob/master/gamemode/cl_derma.lua#L57
local text_shadow = Color(0, 0, 0)
local draw_SimpleText = draw.SimpleText
PS.ShadowedText = function(text, font, x, y, color, alignx, aligny, blur)
    blur = blur or 1
    if blur ~= 0 then
        text_shadow.a = color.a * 0.25
        draw_SimpleText(text, font, x + blur * 2, y + blur * 2, text_shadow, alignx, aligny)
        text_shadow.a = color.a * 0.7
        draw_SimpleText(text, font, x + blur, y + blur, text_shadow, alignx, aligny)
    end

    return draw_SimpleText(text, font, x, y, color, alignx, aligny)
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

    surface.SetDrawColor(0, 0, 0, color.a * 0.7)
    surface.DrawTexturedRect(x + blur, y + blur, w, h)

    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawTexturedRect(x, y, w, h)
end

local foreground1func = function(panel, w, h)
    draw_RoundedBox(0, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local foreground1roundfunc = function(panel, w, h)
    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

function PS.AddSlider(panel, text, value, min, max, snap, callback)
    local slider = panel:Add("PS_HorizontalSlider")
    slider.TextArea:SetWide(80)
    slider:Dock(TOP)
    slider:DockMargin(0, 0, 0, 6)
    slider:SetText(text)
    slider:SetSnap(snap)
    slider:SetMinMax(min, max)
    slider:SetValue(value)
    slider:SetDefaultValue(0)
    slider.OnValueChanged = function(_, _value)
        callback(_value)
    end

    local button = slider:Add("PS_ButtonIcon")
    button:Dock(LEFT)
    button:DockMargin(0, 0, 6, 0)
    button:SetWide(32)
    button:SetIcon("lbg_pointshop/derma/reset.png", 20, 20)
    button.DoClick = function()
        slider:SetValue(slider:GetDefaultValue())
    end

    return slider
end

function PS.AddTextArea(panel, text)
    local container = panel:Add("EditablePanel")
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 6)
    container:SetTall(32)

    container.Text = container:Add("PS_Button")
    container.Text:Dock(LEFT)
    container.Text:DockMargin(0, 0, 6, 0)
    container.Text:SetText(text)
    container.Text:SizeToContents()
    container.Text:SetWide(container.Text:GetWide() + 12)
    container.Text:SetMouseInputEnabled(false)
    container.Text:SetThemeMainColor("Foreground1Color")

    return container
end

function PS.AddBool(panel, text, noText, yesText, value, callback)
    local container = PS.AddTextArea(panel, text)

    container.No = container:Add("PS_Button")
    container.No:Dock(LEFT)
    container.No:DockMargin(0, 0, 6, 0)
    container.No:SetText(noText)
    container.No:SizeToContents()
    container.No:SetWide(container.No:GetWide() + 12)
    container.No:SetupTransition("Selected", 6, function() return not value end)
    container.No.Paint = function(_this, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground2Color"))
        draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 75 * _this.MouseHover))
        draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * _this.Selected))
    end
    container.No.DoClick = function()
        value = false
        callback(false)
    end

    container.Yes = container:Add("PS_Button")
    container.Yes:Dock(LEFT)
    container.Yes:DockMargin(0, 0, 6, 0)
    container.Yes:SetText(yesText)
    container.Yes:SizeToContents()
    container.Yes:SetWide(container.Yes:GetWide() + 12)
    container.Yes:SetupTransition("Selected", 6, function() return value end)
    container.Yes.Paint = function(_this, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground2Color"))
        draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 75 * _this.MouseHover))
        draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * _this.Selected))
    end
    container.Yes.DoClick = function()
        value = true
        callback(true)
    end

    return container
end

function PS.AddComboBox(panel, text, value, values, data, callback)
    local container = PS.AddTextArea(panel, text)

    container.ComboBox = container:Add("PS_ComboBox")
    container.ComboBox:Dock(FILL)

    for i, v in ipairs(values) do
        container.ComboBox:AddChoice(v, data[i], value == data[i])
    end

    container.ComboBox.OnSelect = function(_, i, v, d)
        callback(v, d)
    end

    return container
end

function PS.AddSelector(panel, text, value, values, callback)
    local container = PS.AddTextArea(panel, text)

    container.grid = container:Add("DIconLayout")
    container.grid:Dock(TOP)
    container.grid:SetSpaceX(6)
    container.grid:SetSpaceY(6)

    container.buttons = {}
    for _, v in ipairs(values) do
        local button = container.grid:Add("PS_Button")
        button:SetText(v)
        button:SetTall(32)
        button:SetupTransition("Selected", 6, function() return value == v end)
        button.Paint = function(_this, w, h)
            draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
            draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("MainColor"), 255 * _this.Selected))
        end
        button.DoClick = function()
            value = v
            callback(v)
        end

        table.insert(container.buttons, button)
    end

    container.grid:TDLib():On("PerformLayout", function(_this)
        container:SetTall(_this:GetTall())
    end)

    return container
end

function PS.AddColorSelector(panel, text, value, callback)
    local container = PS.AddTextArea(panel, text)

    container.picker = container:Add("PS_ColorPicker")
    container.picker:Dock(LEFT)
    container.picker:DockMargin(0, 0, 6, 0)
    container.picker:SetWide(180)
    container.picker:SetValue(value)
    container.picker.OnValueChanged = function(this, _value)
        callback(_value)
    end
end

function PS.AddColorModeSelector(panel, text, color, speed, allowAlpha, value, values, data, callback)
    local picker = nil
    local slider = nil
    local container = PS.AddComboBox(panel, text, value, values, data, function(v, d)
        picker:SetVisible(d == "color")
        slider:SetVisible(d == "rainbow")
        callback(v, d, picker:GetValue())
    end)
    container.ComboBox:Dock(LEFT)
    container.ComboBox:DockMargin(6, 0, 6, 0)
    container.ComboBox:SetWide(200)

    picker = container:Add("PS_ColorPicker")
    picker:SetVisible(value == "color")
    picker:SetValue(color, allowAlpha)
    picker:Dock(LEFT)
    picker.OnValueChanged = function(this, _color)
        local id = container.ComboBox:GetSelectedID()
        callback(container.ComboBox:GetOptionText(id), container.ComboBox:GetOptionData(id), _color, slider:GetValue())
    end
    container.picker = picker

    slider = container:Add("PS_HorizontalSlider")
    slider.Label:SetVisible(false)
    slider:SetVisible(value == "rainbow")
    slider:SetMinMax(1, 14)
    slider:SetDecimals(0)
    slider:SetSnap(1)
    slider:SetValue(speed)
    slider:Dock(FILL)
    slider.OnValueChanged = function(this, _value)
        local id = container.ComboBox:GetSelectedID()
        callback(container.ComboBox:GetOptionText(id), container.ComboBox:GetOptionData(id), picker:GetValue(), _value)
    end

    return container
end

function PS.AddTextEntry(panel, text, value, charLimit, callback)
    local container = PS.AddTextArea(panel, text)

    container.entry = container:Add("DTextEntry")
    container.entry:Dock(FILL)
    container.entry:SetFont("PS_Label")
    container.entry:SetValue(value)
    container.entry:SetTextColor(COLOR_WHITE)
    container.entry:SetCursorColor(COLOR_WHITE)
    container.entry:SetPaintBackground(false)
    container.entry:SetUpdateOnType(true)
    container.entry.AllowInput = function(this, char)
        return #this:GetValue() >= charLimit
    end
    container.entry.OnValueChange = function(this, _value)
        callback(string.sub(_value or "", 1, charLimit))
    end
    container.entry.Paint = function(this, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        derma.SkinHook("Paint", "TextEntry", this, w, h)
    end
end

function PS.AddFlagsSelector(panel, text, value, flags, trueTexts, falseTexts, callback)
    local container = PS.AddTextArea(panel, text)

    container.grid = container:Add("DIconLayout")
    container.grid:Dock(TOP)
    container.grid:SetSpaceX(6)
    container.grid:SetSpaceY(6)

    container.buttons = {}
    for i, flag in ipairs(flags) do
        local button = container.grid:Add("PS_ButtonBool")
        button:SetTrueText(trueTexts[i])
        button:SetFalseText(falseTexts[i])
        button:SetValue(bit.band(value, flag) == flag)
        button:SizeToContents()
        button:SetTall(32)

        button.OnValueChanged = function(this, bool)
            if bool then
                value = bit.bor(value, flag)
            else
                value = bit.bxor(value, flag)
            end

            callback(value)
        end

        table.insert(container.buttons, button)
    end

    container.grid:TDLib():On("PerformLayout", function(_this)
        container:SetTall(_this:GetTall())
    end)

    return container
end

local PANEL = {}
PANEL.BarHeight = 34

function PANEL:Init()
    self:SetSize(math.Clamp(1090, 0, ScrW()), math.Clamp(768, 0, ScrH()))
    self:Center()
    self:MakePopup(true)
    self:SetDraggable(false)
    self:SetTitle("")
    self:DockPadding(0, self.BarHeight, 0, 0)

    self.btnMaxim:SetVisible(false)
    self.btnMinim:SetVisible(false)
    self.btnClose.Mat = Material("lbg_pointshop/derma/close.png", "noclamp smooth")
    self.btnClose.DoClick = function(this)
        PS:ToggleMenu()
    end
    self.btnClose.DoRightClick = function(this)
        self:Remove()
        gui.EnableScreenClicker(false)
    end
    self.btnClose:TDLib()
        :ClearPaint()
        :On("PaintOver", function(this, w, h)
            PS.ShadowedImage(this.Mat, 0, 0, w, h)
        end)
        PS:FadeHover(self.btnClose, "Foreground1Color", 125, 6, 6)

    self.Settings = self:Add("PS_ButtonIcon")
    self.Settings:SetIcon("lbg_pointshop/derma/settings.png", self.BarHeight, self.BarHeight)
    self.Settings.DoClick = function(this)
        if this.Panel:IsVisible() then return end

        self:OnItemSelected(PS.ActiveItem)
        self:HidePanels()
        self.Settings.Panel:Show()
        self:SetDataText("Settings", "")
    end

    -- Left bar
    self.Left = self:Add("DPanel")
    self.Left:Dock(LEFT)
    self.Left.Active = cookie.GetString("PS_SideBar", 0) == "1"
    self.Left:SetWide(self.Left.Active and 46 or 186)
    self.Left.Paint = foreground1func

    self.SideBarToggle = self.Left:Add("DButton")
    self.SideBarToggle:Dock(TOP)
    self.SideBarToggle:SetTall(46)
    self.SideBarToggle.Mat = Material("lbg_pointshop/derma/menu.png", "noclamp smooth")
    self.SideBarToggle:TDLib()
        :ClearPaint()
        :Text("")
        :On("PaintOver", function(this, w, h)
            PS.ShadowedImage(this.Mat, 0, 0, h, h)
        end)
        :On("DoClick", function(this)
            if self.Left.Animating then return end
            self.Left.Animating = true

            local active = not self.Left.Active
            self.Left.Active = active
            cookie.Set("PS_SideBar", active and "1" or "0")

            self.Left:SizeTo(active and 46 or 186, -1, 0.5, 0, 0.4, function()
                self.Left.Animating = false
            end)
        end)
        PS:FadeHover(self.SideBarToggle, "Foreground2Color", 125, 6, 6)

    self.CategoriesContainer = self.Left:Add("DScrollPanel")
    self.CategoriesContainer:Dock(FILL)
    self.CategoriesContainer.Paint = emptyfunc

    -- Right bar
    self.Right = self:Add("DPanel")
    self.Right:Dock(RIGHT)
    self.Right:SetWide(264)
    self.Right:DockPadding(12, 12, 12, 12)
    self.Right.Paint = emptyfunc

    self.Controls = self.Right:Add("DPanel")
    self.Controls:Dock(BOTTOM)
    self.Controls:SetTall(82)
    self.Controls:DockPadding(6, 6, 6, 6)
    self.Controls.Paint = foreground1roundfunc

    -- Buy button
    self.Buy = self.Controls:Add("PS_Button")
    self.Buy:Dock(BOTTOM)
    self.Buy:SetTall(32)
    self.Buy:SetText("Purchase")
    self.Buy:SetIcon("lbg_pointshop/derma/shopping_cart.png", 18, 18)
    self.Buy:SetHoverText(nil)
    self.Buy:SetHoverIcon("lbg_pointshop/derma/shopping_cart.png", 18, 18)
    self.Buy.DoClick = function(this)
        if not this.Item then return end
        local ply = LocalPlayer()
        -- Require a double click
        if ply:PS_HasItem(this.Item.ID) then
            if this.PressedOnce then
                ply:PS_SellItem(this.Item.ID)
            else
                this.PressedOnce = true
                this:SetHoverText("Click again to confirm")
                this:SetHoverIcon("lbg_pointshop/derma/warning.png", 18, 18)
                this:SetThemeHoverColor("ErrorColor", 255)
            end
        else
            ply:PS_BuyItem(this.Item.ID)
        end
    end
    self.Buy:TDLib()
        :ClearPaint()
        :SetupTransition("ButtonDown", 6, downfunc)
        :SetupTransition("MouseHover", 6, TDLibUtil.HoverFunc)
        :On("Paint", function(this, w, h)
            if this:IsEnabled() then
                if this.PressedOnce then
                    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("ErrorColor"))
                else
                    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(this._main))
                end
            else
                draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(this._dis))
            end

            draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(this._down), this._downA * this.ButtonDown))
            draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(this._hover), this._hoverA * this.MouseHover))
        end)
        :On("Think", function(this)
            if this.PressedOnce and not this:IsHovered() then
                this:SetItem(this.Item)
            end
        end)

    self.Buy.SetItem = function(this, item)
        this.Item = item
        this.PressedOnce = false
        this:SetThemeHoverColor("Foreground1Color")

        if not item then
            this:SetText("Purchase")
            this:SetHoverText(nil)
            this:SetHoverIcon(nil)
            this:SetEnabled(false)
            return
        end

        local ply = LocalPlayer()

        if ply:PS_HasItem(item.ID) then
            this:SetText("Sell")
            this:SetHoverIcon("lbg_pointshop/derma/sell.png", 18, 18)
            this:SetHoverText("+" .. PS.Config.CalculateSellPrice(ply, item))
            this:SetEnabled(true)
        else
            local price = PS.Config.CalculateBuyPrice(ply, item)

            if not ply:PS_HasPoints(price) then
                this:SetText("Cannot Affort")
                this:SetHoverIcon("")
                this:SetHoverText("Short by: " .. (price - ply:PS_GetPoints()))
                this:SetEnabled(false)
            else
                this:SetText("Purchase")
                this:SetHoverIcon("lbg_pointshop/derma/sell.png", 18, 18)
                this:SetHoverText("-" .. PS.Config.CalculateBuyPrice(ply, item))
                this:SetEnabled(true)
            end
        end
    end

    -- Top buttons
    self.ControlsTop = self.Controls:Add("DPanel")
    self.ControlsTop:Dock(TOP)
    self.ControlsTop:SetTall(32)
    self.ControlsTop.Paint = emptyfunc

    -- Customize button
    self.Customize = self.ControlsTop:Add("PS_Button")
    self.Customize:Dock(LEFT)
    self.Customize:SetWide(111)
    self.Customize:SetText("Customize")
    self.Customize:SetEnabled(false)
    self.Customize.SetItem = function(this, item)
        this.Item = item

        if not item or not LocalPlayer():PS_HasItemEquipped(item.ID) then
            this:SetEnabled(false)
            this:SetHoverText("Customize")
            return
        end

        if item.Modify and not PS:GamemodeCheck(item) then
            this:SetEnabled(true)
            this:SetHoverText("Customize")
        else
            this:SetEnabled(false)
            this:SetHoverText("Unavailable")
        end
    end
    self.Customize.DoClick = function(this)
        if not this.Item then return end

        if isfunction(this.Item.Modify) then
            this.Item:Modify(this.Item, LocalPlayer():PS_GetModifiers(this.ID))
            return
        end

        self:HidePanels()
        self.CustomizePanel:Clear()
        self.CustomizePanel:SetupTopBar(this.Item)
        self.CustomizePanel:Show()
        this.Item:OnCustomizeSetup(self.CustomizePanel, LocalPlayer():PS_GetModifiers(this.Item.ID))
        self:OnItemSelected(PS.ActiveItem)
    end

    self.CustomizePanel = self:Add("EditablePanel")
    self.CustomizePanel:Dock(FILL)
    self.CustomizePanel:DockMargin(6, 12, 0, 12)
    self.CustomizePanel:Hide()
    self.CustomizePanel.SetupTopBar = function(this, item)
        local container = this:Add("EditablePanel")
        container:Dock(TOP)
        container:SetTall(32)
        container:DockMargin(0, 0, 0, 6)

        local button = container:Add("PS_Button")
        button:Dock(LEFT)
        button:SetWide(120)
        button:SetText("Return")
        button:SetIcon("lbg_pointshop/derma/arrow_back.png", 20, 20)
        button.Item = item
        button.DoClick = function(_this)
            for _, _button in ipairs(self.Categories) do
                if _button.Category.ID == _this.Item.Category then
                    _button:DoClick()
                    self:OnItemSelected(_this.Item)
                end
            end
        end

        local header = container:Add("PS_Button")
        header:Dock(FILL)
        header:DockMargin(6, 0, 0, 0)
        header:SetText("Customizing " .. item.Name or item.ID)
        header:SetEnabled(false)
        header:SetThemeDisabledColor("Foreground1Color")
        header:SetMouseInputEnabled(false)
    end

    -- Equip button
    self.Equip = self.ControlsTop:Add("PS_Button")
    self.Equip:Dock(RIGHT)
    self.Equip:SetWide(111)
    self.Equip:SetText("Equip")
    self.Equip.HasItemEquipped = function(this) return this.Item and LocalPlayer():PS_HasItemEquipped(this.Item.ID) end
    self.Equip:TDLib()
        :ClearPaint()
        :On("Paint", function(this, w, h)
            if this:IsEnabled() then
                if this:HasItemEquipped() then
                    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("SecondaryColor"))
                else
                    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(this._main))
                end
            else
                draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(this._dis))
            end

            draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(this._down), this._downA * this.ButtonDown))
            draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(this._hover), this._hoverA * this.MouseHover))
        end)

        self.Equip.DoClick = function(this)
        if not this.Item then return end

        local ply = LocalPlayer()
        if not ply:PS_HasItemEquipped(this.Item.ID) then
            ply:PS_EquipItem(this.Item.ID)
        else
            ply:PS_HolsterItem(this.Item.ID)
        end
    end
    self.Equip.SetItem = function(this, item)
        this.Item = item
        local ply = LocalPlayer()

        if not item or not ply:PS_HasItem(item.ID) then
            this:SetText("Equip")
            this:SetEnabled(false)
            return
        end

        this:SetEnabled(true)
        this:SetText(ply:PS_HasItemEquipped(item.ID) and "Holster" or "Equip")
    end

    -- Description and name
    self.DataContainer = self.Right:Add("DPanel")
    self.DataContainer:Dock(BOTTOM)
    self.DataContainer:SetTall(82)
    self.DataContainer:DockMargin(0, 0, 0, 12)
    self.DataContainer:DockPadding(6, 6, 6, 6)
    self.DataContainer.Paint = foreground1roundfunc

    self.ItemDesc = self.DataContainer:Add("DPanel")
    self.ItemDesc:Dock(BOTTOM)
    self.ItemDesc:DockMargin(0, 6, 0, 0)
    self.ItemDesc.Paint = emptyfunc

    self.ItemTitle = self.DataContainer:Add("DLabel")
    self.ItemTitle:Dock(BOTTOM)
    self.ItemTitle:SetColor(COLOR_WHITE)
    self.ItemTitle:SetFont("PS_LabelLarge")
    self.ItemTitle:SetContentAlignment(5)

    self.ModelPanel = self.Right:Add("EditablePanel")
    self.ModelPanel:Dock(FILL)
    self.ModelPanel:DockMargin(0, 0, 0, 12)
    self.ModelPanel.Paint = foreground1roundfunc

    self.MDL = self.ModelPanel:Add("PS_Preview")
    self.MDL:Dock(FILL)
    self.MDL.Models = {}

    self.ModelHeight = self.ModelPanel:Add("PS_VerticalSlider")
    self.ModelHeight:SetMinMax(-10, 70)
    self.ModelHeight:SetValue(30)
    self.ModelHeight:SetDefaultValue(30)
    self.ModelHeight.OnValueChanged = function(this, value)
        value = 60 - value

        local cam = self.MDL:GetCamPos()
        local at = self.MDL:GetLookAt()

        cam.z = value
        at.z = value

        self.MDL:SetCamPos(cam)
        self.MDL:SetLookAt(at)
    end
    self.ModelHeight.Slider.Knob.Mat = Material("lbg_pointshop/derma/unfold_more.png", "noclamp smooth")
    self.ModelHeight.Slider.Knob:TDLib()
        :ClearPaint()
        :SetupTransition("MouseHover", 6, TDLibUtil.HoverFunc)
        :On("Paint", function(this, w, h)
            draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("MainColor"))
            draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("Foreground1Color"), 125 * this.MouseHover))
            PS.ShadowedImage(this.Mat, w * 0.5, h * 0.5, 16, 16, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)

        :SetSize(24, 24)

    self.ModelReset = self.ModelPanel:Add("PS_ButtonIcon")
    self.ModelReset:SetIcon("lbg_pointshop/derma/reset.png", 20, 20)
    self.ModelReset.DoClick = function()
        self.ModelHeight:ResetToDefaultValue()
        local mins, maxs = self.MDL.Entity:GetRenderBounds()
        self.MDL:SetCamPos(mins:Distance(maxs) * Vector(0.30, 0.30, 0.25) + Vector(0, 0, 15))
        self.MDL:SetLookAt((maxs + mins) / 2 + Vector(0, -4, 0))
        self.MDL.Angles = Angle(0, 0, 0)
        self.MDL.LastPress = 0
        self.MDL:SetFOV(70)
        self.MDL.Entity:SetAngles(Angle(0, 0, 0))
    end

    self.ModelPanel.PerformLayout = function(this)
        local w, h = this:GetSize()

        self.ModelHeight:SetPos(w - self.ModelHeight:GetWide(), 6)
        self.ModelHeight:SetSize(32, h - 12)

        self.ModelReset:SetPos(6, h - 34)
        self.ModelReset:SetSize(28, 28)
    end

    self.PlayerInfo = self.Right:Add("DPanel")
    self.PlayerInfo:Dock(TOP)
    self.PlayerInfo:SetTall(64)
    self.PlayerInfo:DockMargin(0, 0, 0, 12)
    self.PlayerInfo.Mat = Material("lbg_pointshop/derma/attach_money.png", "noclamp smooth")
    self.PlayerInfo.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        PS.ShadowedText(LocalPlayer():Name(), "PS_Label", w * 0.5 + 32, 17, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        PS.ShadowedText("$  " .. LocalPlayer():PS_GetPoints(), "PS_Label", w * 0.5 + 32, h - 16, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    self.Avatar = self.PlayerInfo:Add("AvatarImage")
    self.Avatar:SetSize(64, 64)
    self.Avatar:SetPlayer(LocalPlayer(), 64)

    self.AvatarFrame = self.PlayerInfo:Add("PS_AvatarFrame")
    self.AvatarFrame:SetPos(0, 0)
    self.AvatarFrame:SetSize(64, 64)
    self.AvatarFrame:AutoLayout()
    self.AvatarFrame:SetPlayer(LocalPlayer())
    self.AvatarFrame:NoClipping(true)

    -- Center
    self.Container = self:Add("EditablePanel")
    self.Container:Dock(FILL)
    self.Container:MoveToBack()
    self.Container.Paint = emptyfunc

    self:PopulateCategories()

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

    draw_RoundedBoxEx(6, 0, self.BarHeight - 6, w, h - self.BarHeight + 6, back, false, false, true, true)
    draw_RoundedBox(6, 0, 0, w, self.BarHeight, main)

    PS.ShadowedText(PS.Config.CommunityName, "PS_Header", 6, self.BarHeight * 0.5, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local animationTime = 1.5 -- seconds
function PANEL:Think()
    if not self.ThemeTransitionStart or SysTime() - self.ThemeTransitionStart > animationTime then return end

    local frac = math.min((SysTime() - self.ThemeTransitionStart) / animationTime, 1)

    -- Color transition
    for key, value in pairs(PS.Config.Themes[PS.ActiveTheme] or PS.Config.Themes.default) do
        if IsColor(value) then
            PS.Theme[key] = TDLibUtil.LerpColor(frac, PS.Theme[key], value)
        end
    end
end

function PANEL:SetTheme(theme)
    PS.ActiveTheme = theme
    self.ThemeTransitionStart = SysTime()
end

function PANEL:PopulateCategories()
    for _, button in ipairs(self.Categories or {}) do
        button:Remove()
    end

    self.Container:Clear()

    local cats = {}
    for _, cat in pairs(PS.Categories) do
        table.insert(cats, cat)
    end
    table.sort(cats, function(a, b)
        a.Order = a.Order or 0
        b.Order = b.Order or 0

        return a.Order < b.Order
    end)

    self.Categories = {}
    for i, cat in ipairs(cats) do
        -- Create Button
        local button = self.CategoriesContainer:Add("PS_SidebarButton")
        table.insert(self.Categories, button)

        button.Category = cat
        button:SetZPos(i)
        button:SetText(cat.Name)

        if cat.Material then
            button:SetIcon(cat.Material)
        elseif cat.Icon then
            button:SetIcon(string.format("icon16/%s.png", cat.Icon))
            button:SetIcon16(true)
        end

        button.DoClick = function(this)
            if not IsValid(this.Panel) or this.Panel:IsVisible() then return end

            self:HidePanels()
            this.Panel:SetVisible(true)

            -- Disable item buttons and set bottom right texts to be the category's text
            PS.ActiveCategory = cat
            self:OnItemSelected(nil)
            self:SetDataText(cat.Name or cat.ID, cat.Description or "")

            this.Panel:Show()
        end

        local custom = hook.Run("PS_CustomCategoryTab", cat)
        if IsValid(custom) then
            button.Panel = custom
            custom:SetParent(self.Container)
            custom:Dock(FILL)
            custom:Hide()
        else
            if cat.Subcategories then
                self:MakeSubcategories(button, cat)
            else
                self:MakeCategory(button, cat)
            end
        end
    end

    self.AdminButton = self.Left:Add("PS_SidebarButton")
    self.AdminButton:Dock(BOTTOM)
    self.AdminButton:SetText("Admin Panel")
    self.AdminButton:SetIcon("lbg_pointshop/derma/admin_panel_settings.png")

    self.PointsButton = self.Left:Add("PS_SidebarButton")
    self.PointsButton:Dock(BOTTOM)
    self.PointsButton:SetText("Give Points")
    self.PointsButton:SetIcon("lbg_pointshop/derma/payments.png")
    self.PointsButton:SetVisible(PS.Config.CanPlayersGivePoints)

    self.AdminButton.Panel = self.Container:Add("DPanel")
    self:MakeAdminPanel(self.AdminButton.Panel)
    self.AdminButton.Panel:SetVisible(false)

    self.PointsButton.Panel = self.Container:Add("DPanel")
    self:MakePointsPanel(self.PointsButton.Panel)
    self.PointsButton.Panel:SetVisible(false)

    self.AdminButton.DoClick = function(this)
        if this.Panel:IsVisible() then return end

        self:OnItemSelected(PS.ActiveItem)
        self:HidePanels()
        this.Panel:Show()
        self:SetDataText(this:GetText(), "")
    end

    self.PointsButton.DoClick = function(this)
        self.AdminButton.DoClick(this)
    end

    self.Settings.Panel = self.Container:Add("DPanel")
    self:MakeSettingsPanel(self.Settings.Panel)
    self.Settings.Panel:SetVisible()


    self.Categories[1]:DoClick()
end

function PANEL:HidePanels()
    for _, button in ipairs(self.Categories) do
        button.Panel:SetVisible(false)
    end
    self.CustomizePanel:Clear()
    self.CustomizePanel:SetVisible(false)

    self.AdminButton.Panel:SetVisible(false)
    self.Settings.Panel:SetVisible(false)
    self.PointsButton.Panel:SetVisible(false)
end

function PANEL:SetDataText(title, desc)
    self.ItemTitle:SetText(title)
    self.ItemTitle:SizeToContents()

    self.ItemDesc:Clear()

    if not desc or desc == "" then
        self.ItemDesc:Hide()
        self:InvalidateLayout(true)
        self.DataContainer:SetTall(self.ItemTitle:GetTall() + 12)
        return
    end

    self.ItemDesc:Show()
    -- Super hack to support multiline text
    local parsed = markup.Parse(string.format("<font=%s>%s</font>", "PS_Label", desc), 230)

    for ii, block in ipairs(parsed.blocks) do
        local text = self.ItemDesc:Add("EditablePanel")
        text:Dock(BOTTOM)
        text:SetTall(18)
        text:SetZPos(-ii)
        text._text = block.text
        text:TDLib()
            :On("Paint", function(this, w, h)
                PS.ShadowedText(this._text, "PS_Label", w * 0.5, h * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end)
    end

    self.ItemDesc:SetTall(#parsed.blocks * 18)

    self:InvalidateLayout(true)
    self.DataContainer:SetTall(self.ItemTitle:GetTall() + #parsed.blocks * 18 + 16)
end

-- Category without subcategories
function PANEL:MakeCategory(button, category)
    button.Panel = self.Container:Add("PS_ScrollPanel")
    button.Panel:Dock(FILL)
    button.Panel:DockMargin(12, 12, 0, 12)
    button.Panel:Hide()

    button.Grid = button.Panel:Add("DIconLayout")
    button.Grid:Dock(FILL)
    button.Grid:SetSpaceX(12)
    button.Grid:SetSpaceY(12)

    for id, item in SortedPairsByMemberValue(PS.Items, "Name") do
        if item.Category ~= category.ID and item.Category ~= category.Name then continue end

        local itembutton = button.Grid:Add("PS_Item")
        itembutton:SetData(item)
        itembutton.OnItemSelected = function(this)
            self:OnItemSelected(this.Item)
        end
    end
end

-- Category with subcategories
function PANEL:MakeSubcategories(button, category)
    button.Panel = self.Container:Add("PS_ScrollPanel")
    button.Panel:Dock(FILL)
    button.Panel:DockMargin(12, 12, 0, 12)
    button.Panel:Hide()

    button.SubcategoryGrids = {}

    for id, subcategory in SortedPairsByMemberValue(category.Subcategories, "Order") do
        local panel = button.Panel
        local tall = 32

        local header = panel:Add("DPanel")
        header:Dock(TOP)
        header:DockMargin(0, 0, 0, 6)
        header:DockPadding(0, tall, 0, 0)
        header:SetZPos(subcategory.Order * 2)
        header.Text = subcategory.Name
        header.Paint = function(this, w, h)
            draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
            PS.ShadowedText(this.Text, "PS_LabelLarge", w * 0.5, 17, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local wide = self:GetWide() - 186 - self.Right:GetWide() - 24
       -- Super hack to support multiline text
        local parsed = markup.Parse(string.format("<font=%s>%s</font>", "PS_Label", subcategory.Description or ""), wide)

        for ii, block in ipairs(parsed.blocks) do
            local text = header:Add("EditablePanel")
            text:Dock(TOP)
            text:SetTall(18)
            text:SetZPos(ii)
            text._text = block.text
            text:TDLib()
                :On("Paint", function(this, w, h)
                    PS.ShadowedText(this._text, "PS_Label", w * 0.5, h * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end)
        end

        tall = tall + #parsed.blocks * 18 + 4
        header:SetTall(tall)
        tall = tall + 6

        local grid = panel:Add("DIconLayout")
        grid:Dock(TOP)
        grid:DockMargin(0, 0, 0, 12)
        grid:SetSpaceX(6)
        grid:SetSpaceY(6)
        grid:SetZPos(subcategory.Order * 2 + 1)

        button.SubcategoryGrids[id] = grid
    end

    local default
    for id, subcat in pairs(category.Subcategories) do
        if subcat.Default then
            default = id
            break
        end
    end

    -- Add items
    for id, item in SortedPairs(PS.Items) do
        if item.Category ~= category.ID then continue end

        if not item.Subcategory or not button.SubcategoryGrids[item.Subcategory] then
            if not default then continue end
            item.Subcategory = default
        end

        local itembutton = button.SubcategoryGrids[item.Subcategory]:Add("PS_Item")
        itembutton:SetData(item)
        itembutton.OnItemSelected = function(this)
            self:OnItemSelected(this.Item)
        end
    end
end

function PANEL:MakeSettingsPanel(panel)
    panel:Dock(FILL)
    panel:DockMargin(12, 12, 0, 12)
    panel.Paint = emptyfunc

    for _, base_id in pairs(PS.BaseVisibilities) do
        local base = PS.Bases[base_id]
        if not base then continue end

        if base.VisibilitySettings then
            -- Visibility
            local flags = { PS_VIS_NONFRIENDS, PS_VIS_OTHERTEAMS }
            local yTexts = { "Everyone", "All Teams", "First Person" }
            local fTexts = { "Friends Only", "Same Teams Only", "Third Person Only" }

            local vis = GetConVar("ps_visibility_" .. base.VisibilitySettings.CVarSuffix)
            PS.AddFlagsSelector(panel, base.VisibilitySettings.VisibilityText, vis:GetInt(), flags, yTexts, fTexts, function(value)
                vis:SetInt(value)
            end)

            -- Display
            if base.VisibilitySettings.FirstPersonOptional then
                table.insert(flags, PS_VIS_FIRSTPERSON)
            end
            local dis = GetConVar("ps_display_" .. base.VisibilitySettings.CVarSuffix)
            PS.AddFlagsSelector(panel, base.VisibilitySettings.DisplayText, dis:GetInt(), flags, yTexts, fTexts, function(value)
                dis:SetInt(value)
            end):DockMargin(0, 0, 0, 18)
        end
    end

    hook.Run("PS_SettingsPanel", panel)
end

local id_text, id_func
if PS.Config.DataProvider == "sql" then
    id_text = "SID64"
    id_func = function(ply) return ply:SteamID64() end
elseif PS.Config.DataProvider == "json" then
    id_text = "SID"
    id_func = function(ply) return ply:SteamID() end
elseif PS.Config.DataProvider == "sql" or PS.Config.DataProvider == "flatfile" then
    id_text = "SID"
    id_func = function(ply) return string.Replace(ply:SteamID(), ':', '_') end
else
    id_text = "UID"
    id_func = function(ply) return ply:UniqueID() end
end

function PANEL:MakeAdminPanel(panel)
    panel:Dock(FILL)
    panel:DockMargin(12, 12, 0, 12)
    panel.Paint = emptyfunc

    panel.Player = nil

    local playerContainer = panel:Add("EditablePanel")
    playerContainer:Dock(TOP)
    playerContainer:SetTall(128)

    local avatar = playerContainer:Add("AvatarImage")
    avatar:Dock(LEFT)
    avatar:DockMargin(0, 0, 16, 0)
    avatar:SetWide(128)

    local selector = playerContainer:Add("PS_ComboBox")
    selector:Dock(TOP)
    selector:SetTall(32)
    selector:DockMargin(0, 0, 0, 16)
    selector.DoClick = function(this)
        local value = this:GetOptionText(this:GetSelectedID())
        this:Clear()
        this:SetValue(value or "")

        for _, ply in ipairs(player.GetAll()) do
            this:AddChoice(string.format("%s (%s: %s)", ply:Name(), id_text, id_func(ply) or "90071996842377216 + ?"), ply)
        end
        if this:IsMenuOpen() then
            this:CloseMenu()
        else
            this:OpenMenu()
        end
    end

    local points = playerContainer:Add("PS_Button")
    points:Dock(TOP)
    points:DockMargin(0, 0, 0, 16)
    points:SetThemeMainColor("Foreground1Color")
    points:SetTall(32)
    points:SetMouseInputEnabled(false)
    points:SetContentAlignment(4)
    points:SetText("Points: ???")
    points.Think = function(this)
        if panel.Player then
            this:SetText("Points: " .. panel.Player:PS_GetPoints())
        end
    end

    local pointsContainer = playerContainer:Add("EditablePanel")
    pointsContainer:Dock(TOP)
    pointsContainer:SetTall(32)

    local setPoints = pointsContainer:Add("PS_Button")
    setPoints:Dock(LEFT)
    setPoints:SetWide(120)
    setPoints:SetText("Set Points: ")

    local entry = pointsContainer:Add("DNumberWang")
    entry:SetKeyboardInputEnabled(true)
    entry:Dock(FILL)
    entry:DockMargin(6, 0, 0, 0)
    entry:SetTextColor(COLOR_WHITE)
    entry:SetCursorColor(COLOR_WHITE)
    entry:SetPaintBackground(false)
    entry:SetFont("PS_Label")
    entry:SetMinMax(0, 2147483647)
    entry.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        derma.SkinHook("Paint", "TextEntry", this, w, h)
    end

    selector.OnSelect = function(this, id, text, ply)
        panel.Player = ply
        avatar:SetPlayer(ply, 128)
        entry:SetValue(ply:PS_GetPoints())
    end

    setPoints.DoClick = function(this)
        local value = tonumber(entry:GetValue())
        if not value or not IsValid(panel.Player) then return end

        net.Start("PS_SetPoints")
        net.WriteEntity(panel.Player)
        net.WriteUInt(value, 32)
        net.SendToServer()
    end
end

function PANEL:MakePointsPanel(panel)
    panel:Dock(FILL)
    panel:DockMargin(12, 12, 0, 12)
    panel.Paint = emptyfunc

    panel.Player = nil

    local playerContainer = panel:Add("EditablePanel")
    playerContainer:Dock(TOP)
    playerContainer:SetTall(128)

    local avatar = playerContainer:Add("AvatarImage")
    avatar:Dock(LEFT)
    avatar:DockMargin(0, 0, 16, 0)
    avatar:SetWide(128)

    local selector = playerContainer:Add("PS_ComboBox")
    selector:Dock(TOP)
    selector:SetTall(32)
    selector:DockMargin(0, 0, 0, 16)
    selector.DoClick = function(this)
        local value = this:GetOptionText(this:GetSelectedID())
        this:Clear()
        this:SetValue(value or "")

        for _, ply in ipairs(player.GetAll()) do
            if ply ~= LocalPlayer() then
                this:AddChoice(string.format("%s (%s: %s)", ply:Name(), id_text, id_func(ply) or "90071996842377216 + ?"), ply)
            end
        end
        if this:IsMenuOpen() then
            this:CloseMenu()
        else
            this:OpenMenu()
        end
    end

    local points = playerContainer:Add("PS_Button")
    points:Dock(TOP)
    points:DockMargin(0, 0, 0, 16)
    points:SetThemeMainColor("Foreground1Color")
    points:SetTall(32)
    points:SetMouseInputEnabled(false)
    points:SetContentAlignment(4)
    points:SetText("Points: ???")
    points.Think = function(this)
        if panel.Player then
            this:SetText("Points: " .. panel.Player:PS_GetPoints())
        end
    end

    local pointsContainer = playerContainer:Add("EditablePanel")
    pointsContainer:Dock(TOP)
    pointsContainer:SetTall(32)

    local givePoints = pointsContainer:Add("PS_Button")
    givePoints:Dock(LEFT)
    givePoints:SetWide(120)
    givePoints:SetText("Give Points: ")

    local entry = pointsContainer:Add("DNumberWang")
    entry:Dock(FILL)
    entry:DockMargin(6, 0, 0, 0)
    entry:SetTextColor(COLOR_WHITE)
    entry:SetCursorColor(COLOR_WHITE)
    entry:SetPaintBackground(false)
    entry:SetFont("PS_Label")
    entry:SetMinMax(0, 2147483647)
    entry.Paint = function(this, w, h)
        draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
        derma.SkinHook("Paint", "TextEntry", this, w, h)
    end

    selector.OnSelect = function(this, id, text, ply)
        panel.Player = ply
        avatar:SetPlayer(ply, 128)
    end

    givePoints.DoClick = function(this)
        local value = tonumber(entry:GetValue())
        if not value or not IsValid(panel.Player) then return end

        net.Start("PS_SendPoints")
        net.WriteEntity(panel.Player)
        net.WriteUInt(value, 32)
        net.SendToServer()
    end
end

function PANEL:OnItemSelected(item)
    if isstring(item) then
        item = PS.Items[item]
    end

    local ply = LocalPlayer()

    local ang = self.MDL.Entity:GetAngles()
    self.MDL:SetModel(ply:GetModel())
    self.MDL.Entity:SetAngles(ang)
    self.MDL.Entity:SetSkin(ply:GetSkin())

    for _, group in ipairs(ply:GetBodyGroups()) do
        self.MDL.Entity:SetBodygroup(group.id, ply:GetBodygroup(group.id))
    end

    for _, mdl in ipairs(self.MDL.Models) do
        SafeRemoveEntity(mdl)
    end
    self.MDL.Models = {}

    if not item or PS.ActiveItem == item.ID then
        PS.ActiveItem = nil

        self.Buy:SetItem(nil)
        self.Customize:SetItem(nil)
        self.Equip:SetItem(nil)

        if PS.ActiveCategory then
            self:SetDataText(PS.ActiveCategory.Name or PS.ActiveCategory.ID, PS.ActiveCategory.Description or "")
        end
        return
    end

    self:SetDataText(item.Name or item.ID, item.Description or "")
    self.Buy:SetItem(item)
    self.Customize:SetItem(item)
    self.Equip:SetItem(item)

    PS.ActiveItem = item.ID
end

vgui.Register("PS_Menu", PANEL, "DFrame")