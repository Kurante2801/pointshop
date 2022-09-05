local COLOR_WHITE = Color(255, 255, 255)
local emptyfunc = function() end

PS.ActiveTheme = cookie.GetString("PS_Theme", "default")

function PS:GetThemeVar(element)
    return self.Config.Themes[self.ActiveTheme][element] or self.Config.Themes.default[element]
end

surface.CreateFont("PS_Header", {
    font = "Rubik SemiBold",
    size = 30, shadow = false, antialias = true,
})

surface.CreateFont("PS_SideBar", {
    font = "Rubik Regular",
    size = 20, shadow = false, antialias = true,
})

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
function PS:FadeActive(panel, color_string, alpha, speed, round)
    return self:FadeFunction(panel, "PS_FadeActive", color_string, alpha, speed, round, activefunc)
end

function PS:ClearPaint(panel)
    panel:TDLib().Paint = emptyfunc
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
            PS.ActiveTheme = PS.ActiveTheme == "default" and "dark" or "default"
        end)
    PS:FadeHover(self.Settings, "Foreground1Color", 125, 6, 6)

    -- Left bar
    self.Left = self:Add("DPanel")
    self.Left:Dock(LEFT)
    self.Left.Active = cookie.GetString("PS_SideBar", 0) == "1"
    self.Left:SetWide(self.Left.Active and 46 or 186)
    self.Left.Paint = function(this, w, h)
        draw.RoundedBox(0, 0, 0, w, h, PS:GetThemeVar("Foreground1Color"))
    end

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
    self.Right:SetWide(246)
    self.Right.Paint = emptyfunc



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
                PS.ShadowedText(cat.Name, "PS_SideBar", h, h * 0.5, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

vgui.Register("PS_Menu", PANEL, "DFrame")
--vgui.Create("PS_Menu")