local COLOR_WHITE = Color(255, 255, 255)
local emptyfunc = function() end

PS.ActiveTheme = cookie.GetString("PS_Theme", "default")
PS.Theme = table.Copy(PS.Config.Themes.default)

if PS.ActiveTheme ~= "default" and istable(PS.Config.Themes[PS.ActiveTheme]) then
    table.Merge(PS.Theme, PS.Config.Themes[PS.ActiveTheme])
end

function PS:GetThemeVar(element)
    return PS.Theme[element]
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
end

function PS:FadeFunction(panel, transition, color_string, alpha, speed, round, func)
    panel:TDLib()
        :SetupTransition(transition, speed, func)
        :On("Paint", function(this, w, h)
            draw.RoundedBox(round, 0, 0, w, h, ColorAlpha(self:GetThemeVar(color_string), alpha * this[transition]))
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
PS.ShadowedText = function(text, font, x, y, color, alignx, aligny, blur)
    blur = blur or 1
    if blur ~= 0 then
        text_shadow.a = color.a * 0.25
        draw.SimpleText(text, font, x + blur * 2, y + blur * 2, text_shadow, alignx, aligny)
        text_shadow.a = color.a * 0.5
        draw.SimpleText(text, font, x + blur, y + blur, text_shadow, alignx, aligny)
    end

    return draw.SimpleText(text, font, x, y, color, alignx, aligny)
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
    draw.RoundedBox(0, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local foreground1roundfunc = function(panel, w, h)
    draw.RoundedBox(6, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
end

local PANEL = {}
PANEL.BarHeight = 34

function PANEL:Init()
    self:SetSize(math.Clamp(1024, 0, ScrW()), math.Clamp(768, 0, ScrH()))
    self:Center()
    self:MakePopup()
    self:SetDraggable(false)
    self:SetTitle("")
    self:DockPadding(0, self.BarHeight, 0, 0)

    self.btnMaxim:SetVisible(false)
    self.btnMinim:SetVisible(false)
    self.btnClose.Mat = Material("lbg_pointshop/derma/close.png", "noclamp smooth")
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
    self.Buy:SetHoverText("-1234567890")
    self.Buy:SetHoverIcon("lbg_pointshop/derma/sell.png", 18, 18)

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
    self.Customize:SetHoverText("Unavailable")

    -- Equip button
    self.Equip = self.ControlsTop:Add("PS_Button")
    self.Equip:Dock(RIGHT)
    self.Equip:SetWide(111)
    self.Equip:SetText("Equip")
    self.Equip:SetHoverText("Holster")

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

    self:SetDataText("Playermodels", "Multi-line text goes here, but can it support multi line? The answer is surprisingly yes")
    --self:SetDataText("Deez", "nuts")

    self.ModelPanel = self.Right:Add("EditablePanel")
    self.ModelPanel:Dock(FILL)
    self.ModelPanel:DockMargin(0, 0, 0, 12)
    self.ModelPanel.Paint = foreground1roundfunc

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

    draw.RoundedBoxEx(6, 0, self.BarHeight - 6, w, h - self.BarHeight + 6, back, false, false, true, true)
    draw.RoundedBox(6, 0, 0, w, self.BarHeight, main)

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

    local cats = {}
    for _, cat in pairs(PS.Categories) do
        table.insert(cats, cat)
    end
    table.sort(cats, function(a, b)
        a.Index = a.Index or 0
        b.Index = b.Index or 0

        return a.Index < b.Index
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
                if IsValid(this.CategoryPanel) then
                    this.CategoryPanel:Show()
                end

            end)
            PS:FadeHover(button, "Foreground2Color", 125, 6, 6)
            PS:FadeActive(button, "MainColor", 125, 6, 6)

        if cat.Material then
            button:On("PaintOver", function(this, w, h)
                PS.ShadowedImage(this.Mat, 0, 0, h, h)
            end)
        elseif cat.Icon then
            button:On("PaintOver", function(this, w, h)
                PS.ShadowedImage(this.Mat, h * 0.5, h * 0.5, 16, 16, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end)
        end
    end
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

vgui.Register("PS_Menu", PANEL, "DFrame")
vgui.Create("PS_Menu")