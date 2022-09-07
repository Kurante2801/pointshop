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

if file.Exists("resource/fonts/rubik-semibold.ttf", "THIRDPARTY") then
    surface.CreateFont("PS_Label", {
        font = "Rubik SemiBold",
        size = 20, shadow = false, antialias = true,
    })

    surface.CreateFont("PS_Header", {
        font = "Rubik SemiBold",
        size = 30, shadow = false, antialias = true,
    })

    surface.CreateFont("PS_LabelLarge", {
        font = "Rubik SemiBold",
        size = 26, shadow = false, antialias = true,
    })

    surface.CreateFont("PS_LabelSmall", {
        font = "Rubik SemiBold",
        size = 16, shadow = false, antialias = true,
    })
else
    surface.CreateFont("PS_Label", {
        font = "Circular Std Medium",
        size = 20, shadow = false, antialias = true,
    })

    surface.CreateFont("PS_Header", {
        font = "Circular Std Medium",
        size = 30, shadow = false, antialias = true,
    })

    surface.CreateFont("PS_LabelLarge", {
        font = "Circular Std Medium",
        size = 26, shadow = false, antialias = true,
    })

    surface.CreateFont("PS_LabelSmall", {
        font = "Circular Std Medium",
        size = 16, shadow = false, antialias = true,
    })
end

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
        text_shadow.a = color.a * 0.5
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

    surface.SetDrawColor(0, 0, 0, color.a * 0.5)
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

local PANEL = {}
PANEL.BarHeight = 34

function PANEL:Init()
    self:SetSize(math.Clamp(1090, 0, ScrW()), math.Clamp(768, 0, ScrH()))
    self:Center()
    self:MakePopup()
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

    self.Settings = self:Add("DButton")
    self.Settings.Mat = Material("lbg_pointshop/derma/settings.png", "noclamp smooth")
    self.Settings:TDLib()
        :ClearPaint()
        :Text("")
        :On("PaintOver", function(this, w, h) PS.ShadowedImage(this.Mat, 0, 0, w, h) end)
        :On("DoClick", function(this)
            self:SetTheme(PS.ActiveTheme == "default" and "dark" or "default")
        end)
    PS:FadeHover(self.Settings, "Foreground1Color", 125, 6, 6)

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

    self.CategoriesContainer = self.Left:Add("FDLib.ScrollPanel")
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

        if item.Modify and not item:GamemodeCheck() then
            this:SetEnabled(true)
            this:SetHoverText("Customize")
        else
            this:SetEnabled(false)
            this:SetHoverText("Unavailable")
        end

    end

    -- Equip button
    self.Equip = self.ControlsTop:Add("PS_Button")
    self.Equip:Dock(RIGHT)
    self.Equip:SetWide(111)
    self.Equip:SetText("Equip")
    self.Equip.HasItemEquipped = function(this) return this.Item and LocalPlayer():PS_HasItemEquipped(this.Item.ID) end
    self.Equip:TDLib()
        :ClearPaint()
        --:SetupTransition("HolsterItem", 6, self.Equip.HasItemEquipped)
        :On("Paint", function(this, w, h)
            if this:IsEnabled() then
                if this:HasItemEquipped() then
                    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("SuccessColor"))
                else
                    draw_RoundedBox(6, 0, 0, w, h, PS:GetThemeVar(this._main))
                end
                --draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar(this._main), 255 * this.HolsterItem))
                --draw_RoundedBox(6, 0, 0, w, h, ColorAlpha(PS:GetThemeVar("ErrorColor"), 255 * (1 - this.HolsterItem)))
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
        local button = self.CategoriesContainer:Add("DButton")
        table.insert(self.Categories, button)

        button:Dock(TOP)
        button:SetZPos(i)
        button:SetTall(46)

        if cat.Material then
            button.Mat = Material(cat.Material, "noclamp smooth")
        elseif cat.Icon then
            button.Mat = Material(string.format("icon16/%s.png", cat.Icon))
        end

        button:TDLib()
            :ClearPaint()
            :Text("")
            :On("PaintOver", function(this, w, h)
                PS.ShadowedText(cat.Name, "PS_Label", h, h * 0.5, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end)
            :On("DoClick", function(this)
                if this.Active then return end

                self:HidePanels()
                this.Active = true

                -- Disable item buttons and set bottom right texts to be the category's text
                PS.ActiveCategory = cat
                self:OnItemSelected(nil)
                self:SetDataText(cat.Name or cat.ID, cat.Description or "")

                if IsValid(this.CategoryPanel) then
                    this.CategoryPanel:Show()
                end
            end)
            PS:FadeHover(button, "Foreground2Color", 125, 6, 6)
            PS:FadeActive(button, "MainColor", 255, 6, 6)

        if cat.Material then
            button:On("PaintOver", function(this, w, h)
                PS.ShadowedImage(this.Mat, 0, 0, h, h)
            end)
        elseif cat.Icon then
            button:On("PaintOver", function(this, w, h)
                PS.ShadowedImage(this.Mat, h * 0.5, h * 0.5, 16, 16, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end)
        end

        self:MakeCategory(button, cat)
    end

    self.Categories[1]:DoClick()
end

function PANEL:HidePanels()
    for _, button in ipairs(self.Categories) do
        button.Active = false
        if IsValid(button.CategoryPanel) then
            button.CategoryPanel:Hide()
        end
    end
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
    local parsed = markup.Parse(string.format("<font=%s>%s</font>", "PS_Label", desc), 240)

    for i, block in ipairs(parsed.blocks) do
        local text = self.ItemDesc:Add("EditablePanel")
        text:Dock(BOTTOM)
        text:SetTall(18)
        text:SetZPos(-i)
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
    button.CategoryPanel = self.Container:Add("PS_ScrollPanel")
    button.CategoryPanel:Dock(FILL)
    button.CategoryPanel:DockMargin(12, 12, 0, 12)
    button.CategoryPanel:Hide()

    button.Grid = button.CategoryPanel:Add("DIconLayout")
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

function PANEL:OnItemSelected(item)
    local ply = LocalPlayer()

    local ang = self.MDL.Entity:GetAngles()
    self.MDL:SetModel(ply:GetModel())
    self.MDL.Entity:SetAngles(ang)

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

    if item.IsPlayermodel then
        self.MDL:SetModel(item.Model)
        return
    end

    if not item.Props then return end
    -- Modelos

    for id, prop in pairs(item.Props) do
        if not file.Exists(prop.model, "GAME") then continue end

        local model = prop.model
        model = ClientsideModel(model)
        if not model then continue end
        model:SetNoDraw(true)
        model:DrawShadow(false)
        model:DestroyShadow()
        local pos
        pos, ang = item:GetBonePosAng(self.MDL.Entity, prop.bone)
        if not pos or not ang then continue end
        -- Offset
        pos = pos + ang:Forward() * prop.pos.x - ang:Right() * prop.pos.y + ang:Up() * prop.pos.z
        ang:RotateAroundAxis(ang:Right(), prop.ang.p)
        ang:RotateAroundAxis(ang:Up(), prop.ang.y)
        ang:RotateAroundAxis(ang:Forward(), prop.ang.r)
        model:SetPos(pos)
        model:SetAngles(ang)
        model:SetRenderOrigin(pos)
        model:SetRenderAngles(ang)
        model:SetupBones()
        local matrix = Matrix()
        matrix:SetScale(prop.scale or Vector(1, 1, 1))
        model:EnableMatrix("RenderMultiply", matrix)
        model:SetMaterial(prop.material or "")
        model.alpha = prop.alpha or 1
        local color = prop.color or Color(255, 255,255)
        model.Color = Vector(color.r / 255, color.g / 255, color.b / 255)
        model.prop = prop

        table.insert(self.MDL.Models, model)
    end
end

vgui.Register("PS_Menu", PANEL, "DFrame")