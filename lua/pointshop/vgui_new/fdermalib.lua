-- Fafy's Derma Lib
-- Uses TDLib
-- and circles!

local circles = include("pointshop/vgui_new/circles.lua")

-- Precached corners
local corners_tl = {}
local corners_bl = {}
local corners_tr = {}
local corners_br = {}

local GetCornerCircle = function(tbl, bordersize, thick, rotation)
    local key = string.format("%s-%s", bordersize, thick)
    -- We can reuse a corner
    if tbl[key] then
        return tbl[key]
    end

    -- Create and cache corner
    local corner = circles.New(CIRCLE_OUTLINED, bordersize, 0, 0, thick)
    corner:SetAngles(0, 90)
    corner:Rotate(rotation)
    corner:SetDistance(1)

    tbl[key] = corner

    return corner
end

local RoundedOutlinedBoxEx = function(bordersize, thick, x, y, w, h, color, tl, tr, bl, br)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    if bordersize <= 0 then
        return surface.DrawRect(x, y, w, h)
    end

    x, y, w, h = math.Round(x), math.Round(y), math.Round(w), math.Round(h)
    bordersize = math.min(math.Round(bordersize), math.floor(w / 2), math.floor(h / 2))

    surface.DrawRect(x + bordersize, y, w - bordersize * 2, thick)
    surface.DrawRect(x + bordersize, h - thick, w - bordersize * 2, thick)
    surface.DrawRect(x, y + bordersize, thick, h - bordersize * 2)
    surface.DrawRect(w - thick, y + bordersize, thick, h - bordersize * 2)

    draw.NoTexture()

    if tl then
        local corner = GetCornerCircle(corners_tl, bordersize, thick, 180)
        corner:SetPos(x + bordersize, y + bordersize)
        corner()
    else
        surface.DrawRect(x, y, bordersize, bordersize)
    end

    if tr then
        local corner = GetCornerCircle(corners_tr, bordersize, thick, 270)
        corner:SetPos(w - bordersize, y + bordersize)
        corner()
    else
        surface.DrawRect(x + w - bordersize, y, bordersize, bordersize)
    end

    if bl then
        local corner = GetCornerCircle(corners_bl, bordersize, thick, 90)
        corner:SetPos(x + bordersize, h - bordersize)
        corner()
    else
        surface.DrawRect(x, y + h - bordersize, bordersize, bordersize)
    end

    if br then
        local corner = GetCornerCircle(corners_br, bordersize, thick, 0)
        corner:SetPos(w - bordersize, h - bordersize)
        corner()
    else
        surface.DrawRect(x + w - bordersize, y + h - bordersize, bordersize, bordersize)
    end
end

local RoundedOutlinedBox = function(bordersize, thick, x, y, w, h, color)
    RoundedOutlinedBoxEx(bordersize, thick, x, y, w, h, color, true, true, true, true)
end

local RoundedBox = draw.RoundedBox
local RoundedBoxEx = draw.RoundedBoxEx

local COLOR_WHITE = Color(255, 255, 255)
local COLOR_SHADOW = Color(0, 0, 0, 125)

local COLOR_FOREGROUND = Color(50, 50, 50)
local COLOR_BACKGROUND = Color(25, 25, 25)

local COLOR_ACTIVE = Color(50, 200, 255)
local COLOR_INACTIVE = Color(175, 175, 175)

surface.CreateFont("FDLib.FrameTitle", {
    font = "Circular Std Medium",
    size = 22,
    weight = 500
})

surface.CreateFont("FDLib.Label", {
    font = "Circular Std Medium",
    size = 18,
    weight = 500
})

surface.CreateFont("FDLib.Entry", {
    font = "Roboto",
    size = 16,
    weight = 500
})

local PANEL = {}

AccessorFunc(PANEL, "barTall", "BarTall", FORCE_NUMBER)
AccessorFunc(PANEL, "barColor", "BarColor", nil)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)

function PANEL:Init()
    self.btnMaxim:SetVisible(false)
    self.btnMinim:SetVisible(false)
    self.btnClose:TDLib()
        :ClearPaint()
        :FadeHover(COLOR_SHADOW, 4, 4)
        :Text("r", "Marlett", COLOR_WHITE, TEXT_ALIGN_CENTER, 0, 0, true)
        :SetExpensiveShadow(1, COLOR_SHADOW)

    self.lblTitle:SetTextColor(COLOR_WHITE)
    self.lblTitle:SetFont("FDLib.FrameTitle")
    self.lblTitle:SetContentAlignment(4)
    self.lblTitle:SetExpensiveShadow(1, COLOR_SHADOW)

    self:SetBarTall(24)
    self:SetBackgroundColor(COLOR_BACKGROUND)
    self:SetBarColor(COLOR_FOREGROUND)
    self:DockPadding(0, 24, 0, 0)
end

function PANEL:Paint(w, h)
    RoundedBoxEx(4, 0, 0, w, h, self:GetBackgroundColor(), true, true, true, true)
    RoundedBoxEx(4, 0, 0, w, self:GetBarTall(), self:GetBarColor(), true, true, false, false)
end

function PANEL:PerformLayout()
    local w = self:GetWide()
    local bar = self:GetBarTall()

    self.btnClose:SetPos(w - bar, 0)
    self.btnClose:SetSize(bar, bar)
    self.lblTitle:SetPos(6, 2)
    self.lblTitle:SetSize(w - bar, bar)
end

function PANEL:Think()
    local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
    local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

    if self.Dragging then
        local x = mousex - self.Dragging[1]
        local y = mousey - self.Dragging[2]

        -- Lock to screen bounds if screenlock is enabled
        if ( self:GetScreenLock() ) then
            x = math.Clamp(x, 0, ScrW() - self:GetWide())
            y = math.Clamp(y, 0, ScrH() - self:GetTall())
        end

        self:SetPos(x, y)

    end

    if self.Sizing then

        local x = mousex - self.Sizing[1]
        local y = mousey - self.Sizing[2]
        local px, py = self:GetPos()

        if x < self.m_iMinWidth then x = self.m_iMinWidth elseif x > ScrW() - px and self:GetScreenLock() then x = ScrW() - px end
        if y < self.m_iMinHeight then y = self.m_iMinHeight elseif y > ScrH() - py and self:GetScreenLock() then y = ScrH() - py end

        self:SetSize(x, y)
        self:SetCursor( "sizenwse" )
        return
    end

    local screenX, screenY = self:LocalToScreen(0, 0)

    if self.Hovered and self.m_bSizable and mousex > ( screenX + self:GetWide() - 20 ) and mousey > ( screenY + self:GetTall() - 20 ) then
        self:SetCursor("sizenwse")
        return
    end

    local tall = self:GetBarTall()
    if self.Hovered and self:GetDraggable() and mousey < ( screenY + tall) then
        self:SetCursor("sizeall")
        return
    end

    self:SetCursor("arrow")

    -- Don't allow the frame to go higher than 0
    if self.y < 0 then
        self:SetPos(self.x, 0)
    end
end

function PANEL:SetFont(font)
    self.lblTitle:SetFont(font)
end

vgui.Register("FDLib.Frame", PANEL, "DFrame")

PANEL = {}

function PANEL:Init()
    self:SetExpensiveShadow(1, COLOR_SHADOW)
    self:SetFont("FDLib.Label")
    self:SetTextColor(COLOR_WHITE)
end

vgui.Register("FDLib.Label", PANEL, "DLabel")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)
AccessorFunc(PANEL, "cornerRadious", "CornerRadious", FORCE_NUMBER)
AccessorFunc(PANEL, "outlined", "Outlined", FORCE_BOOL)
AccessorFunc(PANEL, "outlineThick", "OutlineTickness", FORCE_NUMBER)
AccessorFunc(PANEL, "outlineColor", "OutlineColor", nil)


function PANEL:Init()
    self:SetFont("FDLib.Label")
    self:SetText("Button")
    self:SetTextColor(COLOR_WHITE)
    self:SetCornerRadious(6)
    self:SetBackgroundColor(COLOR_ACTIVE)
    self:SetColor(COLOR_FOREGROUND)
    self:SetOutlineTickness(4)
    self:SetOutlineColor(COLOR_ACTIVE)

    self:SetSize(80, 24)

    self:TDLib()
        :CircleClick(COLOR_SHADOW, 5)
end

function PANEL:Paint(w, h)
    if self:GetOutlined() then
        RoundedOutlinedBox(self:GetCornerRadious(), self:GetOutlineTickness(), 0, 0, w, h, self:GetOutlineColor())
        RoundedBox(self:GetCornerRadious(), 0, 0, w, h, self:GetBackgroundColor())
    else
        RoundedBox(self:GetCornerRadious(), 0, 0, w, h, self:GetBackgroundColor())
    end
end

vgui.Register("FDLib.Button", PANEL, "DButton")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)
AccessorFunc(PANEL, "cornerRadious", "CornerRadious", FORCE_NUMBER)
AccessorFunc(PANEL, "outlined", "Outlined", FORCE_BOOL)
AccessorFunc(PANEL, "outlineThick", "OutlineTickness", FORCE_NUMBER)
AccessorFunc(PANEL, "outlineColor", "OutlineColor", nil)
AccessorFunc(PANEL, "barColor", "BarColor", nil)
AccessorFunc(PANEL, "barBackground", "BarBackground", nil)
AccessorFunc(PANEL, "highlightColor", "HighlightColor", nil)
AccessorFunc(PANEL, "placeholder", "Placeholder", FORCE_STRING)

function PANEL:Init()
    self:SetFont("FDLib.Entry")
    self:SetTextColor(COLOR_WHITE)
    self:SetCornerRadious(6)
    self:SetBackgroundColor(COLOR_FOREGROUND)
    self:SetOutlineTickness(4)
    self:SetOutlineColor(COLOR_ACTIVE)
    self:SetBarColor(COLOR_ACTIVE)
    self:SetBarBackground(COLOR_INACTIVE)
    self:SetHighlightColor(COLOR_ACTIVE)
    self:SetPlaceholder("Placeholder")

    self:SetSize(100, 24)

    self:TDLib()
        :SetupTransition("TextEntryReady", 6, function()
            return self:IsEditing()
        end)
end

function PANEL:Paint(w, h)
    if self:GetOutlined() then
        RoundedOutlinedBox(self:GetCornerRadious(), self:GetOutlineTickness(), 0, 0, w, h, self:GetOutlineColor())
        RoundedBox(self:GetCornerRadious(), 0, 0, w, h, self:GetBackgroundColor())
    else
        RoundedBox(self:GetCornerRadious(), 0, 0, w, h, self:GetBackgroundColor())
    end

    local offset = self:GetOutlined() and self:GetCornerRadious() or 2

    local color = self:GetBarColor()
    if color then
        RoundedBox(0, offset + 1, h - offset - 1, w - offset * 2 - 2, 1, self:GetBarBackground())

        local bar = math.Round((w / 2 - offset - 1) * self.TextEntryReady)
        if bar > 0 then
            RoundedBox(0, w / 2, h - offset - 1, bar, 1, self:GetBarColor())
            RoundedBox(0, w / 2  - bar, h - offset - 1, bar, 1, self:GetBarColor())
        end
    end

    local placeholder = self:GetPlaceholder()
    if self:GetText() == "" and placeholder ~= "" then
        self:SetText(placeholder)
        self:DrawTextEntryText(COLOR_INACTIVE, COLOR_INACTIVE, COLOR_INACTIVE)
        self:SetText("")
    else
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetHighlightColor())
    end
end

-- https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/mp/src/vgui2/vgui_controls/TextEntry.cpp#L969
function PANEL:GetNumLines()
    local num_lines = 1

    local wide = self:GetWide() - 2

    local vbar = self:GetChildren()[1]
    if vbar then
        wide = wide - vbar:GetWide()
    end

    local char_width
    local x = 3

    local word_start_index = 1
    local word_start_len
    local word_length = 0
    local has_word = false
    local just_started_new_line = true
    local word_started_on_new_line = true

    local start_char = 1

    surface.SetFont(self:GetFont())

    local i = start_char
    local text, n = utf8.force(self:GetText())
    local caret_line = 0
    local caret_pos = self:GetCaretPos()
    local caret_i = 1
    while i <= n do
        local ch_len = utf8.char_bytes(text:byte(i))
        local ch = text:sub(i, i + ch_len - 1)

        if ch ~= " " then
            if not has_word then
                word_start_index = i
                word_start_len = ch_len
                has_word = true
                word_started_on_new_line = just_started_new_line
                word_length = 0
            end
        else
            has_word = false
        end

        char_width = surface.GetTextSize(ch)
        just_started_new_line = false

        if (x + char_width) >= wide then
            x = 3

            just_started_new_line = true
            has_word = false

            if word_started_on_new_line then
                num_lines = num_lines + 1
            else
                num_lines = num_lines + 1
                i = (word_start_index + word_start_len) - ch_len
            end

            word_length = 0
        end

        x = x + char_width
        word_length = word_length + char_width

        if caret_i == caret_pos then
            caret_line = num_lines
        end

        i = i + ch_len
        caret_i = caret_i + 1
    end

    return num_lines, caret_line
end

vgui.Register("FDLib.TextEntry", PANEL, "DTextEntry")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)
AccessorFunc(PANEL, "cornerRadious", "CornerRadious", FORCE_NUMBER)
AccessorFunc(PANEL, "outlined", "Outlined", FORCE_BOOL)
AccessorFunc(PANEL, "outlineThick", "OutlineTickness", FORCE_NUMBER)
AccessorFunc(PANEL, "outlineColor", "OutlineColor", nil)

function PANEL:Init()
    self:SetSize(120, 24)
    self:SetFont("FDLib.Label")
    self:SetTextColor(COLOR_WHITE)
    self:SetCornerRadious(6)
    self:SetBackgroundColor(COLOR_FOREGROUND)
    self:SetOutlineTickness(4)
    self:SetOutlineColor(COLOR_ACTIVE)

    self:TDLib()
        :CircleClick(COLOR_SHADOW, 5)
end

function PANEL:Paint(w, h)
    if self:GetOutlined() then
        RoundedOutlinedBox(self:GetCornerRadious(), self:GetOutlineTickness(), 0, 0, w, h, self:GetOutlineColor())
        RoundedBox(self:GetCornerRadious(), 0, 0, w, h, self:GetBackgroundColor())
    else
        RoundedBox(self:GetCornerRadious(), 0, 0, w, h, self:GetBackgroundColor())
    end
end

function PANEL:DoClick()
    if #self.Choices < 1 then return end

    if IsValid(self.Menu) then
        self.Menu:Remove()
        self.Menu = nil
        return
    end

    local parent = self
    while IsValid(parent) and not parent:IsModal() do
        parent = parent:GetParent()
    end

    if not IsValid(parent) then
        parent = self
    end

    CloseDermaMenus()
    self.Menu = parent:Add("FDLib.Menu")

    if self:GetSortItems() then
        local sorted = {}
        for k, v in pairs(self.Choices) do
            local val = tostring(v)
            if string.len(val) > 1 and not tonumber(val) and val:StartWith("#") then val = language.GetPhrase(val:sub(2)) end
            table.insert(sorted, { id = k, data = v, label = val })
        end
        for k, v in SortedPairsByMemberValue(sorted, "label") do
            local option = self.Menu:AddOption(v.data, function() self:ChooseOption(v.data, v.id) end)
            if (self.ChoiceIcons[v.id]) then
                option:SetIcon(self.ChoiceIcons[v.id])
            end
            if (self.Spacers[v.id]) then
                self.Menu:AddSpacer()
            end
        end
    else
        for k, v in pairs(self.Choices) do
            local option = self.Menu:AddOption(v, function() self:ChooseOption(v, k) end)
            if (self.ChoiceIcons[k]) then
                option:SetIcon(self.ChoiceIcons[k])
            end
            if (self.Spacers[k]) then
                self.Menu:AddSpacer()
            end
        end
    end

    local x, y = self:LocalToScreen(0, self:GetTall())

    self.Menu:SetMinimumWidth(self:GetWide())
    self.Menu:Open(x, y, false, self)
end

vgui.Register("FDLib.ComboBox", PANEL, "DComboBox")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)
AccessorFunc(PANEL, "hoverColor", "HoverColor", nil)

function PANEL:Init()
    self:SetBackgroundColor(COLOR_FOREGROUND)
    self:SetHoverColor(COLOR_ACTIVE)
end

function PANEL:Paint(w, h)
    RoundedBox(4, 0, 0, w, h, self:GetBackgroundColor())
end

function PANEL:AddOption(text, callback)
    local panel = self:Add("FDLib.Button")
    panel:SetText(text)
    panel:SetTall(22)
    panel:SetBackgroundColor(Color(0, 0, 0, 0))
    panel:SetTextColor(COLOR_WHITE)
    panel:On("Paint", function(this, w, h)
        if this:IsHovered() then
            local color = self:GetHoverColor()
            RoundedOutlinedBox(4, 1, 0, 0, w, h, color)
            RoundedBox(4, 0, 0, w, h, ColorAlpha(color, 25))
        end
    end)

    if callback then
        panel.DoClick = callback
    end

    self:AddPanel(panel)
    return panel
end

vgui.Register("FDLib.Menu", PANEL, "DMenu")

PANEL = {}

function PANEL:Init()
    self.Panels = {}
    self.Tabs = {}

    self.Bar = self:Add("EditablePanel")
    self.Bar:Dock(TOP)
    self.Bar:SetTall(24)
end

function PANEL:AddTab(name, panel)
    if isstring(panel) then
        panel = self:Add(panel)
    end

    panel:Dock(FILL)
    panel:SetVisible(#self.Tabs < 1)

    local tab = self.Bar:Add("FDLib.Button")
    tab:Dock(LEFT)
    tab:SetText(name)
    tab:SetTextColor(COLOR_WHITE)
    tab:SetupTransition("TabActive", 6, function()
        return tab.Panel:IsVisible()
    end)
    tab.Panel = panel

    tab.Paint = function(this, w, h)
        local bar = math.Round(w * this.TabActive)
        if bar > 0 then
            RoundedBox(0, (w / 2) - (bar / 2), h - 2, bar, 2, COLOR_ACTIVE)
        end
    end

    tab.DoClick = function(this)
        for i = 1, #self.Panels do
            self.Panels[i]:SetVisible(false)
        end

        this.Panel:SetVisible(true)
    end

    table.insert(self.Panels, panel)
    table.insert(self.Tabs, tab)
end

vgui.Register("FDLib.Tabs", PANEL, "EditablePanel")

PANEL = {}

AccessorFunc(PANEL, "color", "Color", nil)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)

function PANEL:Init()
    self:SetColor(COLOR_ACTIVE)
    self:SetBackgroundColor(COLOR_FOREGROUND)

    self.Label:Remove()
    self.Label = self:Add("FDLib.Label")
    self.Label:Dock(LEFT)
    self.Label:SetMouseInputEnabled(true)

    self.TextArea:Remove()
    self.TextArea = self:Add("FDLib.TextEntry")
    self.TextArea:Dock(RIGHT)
    self.TextArea:SetWide(50)
    self.TextArea:SetNumeric(true)
    self.TextArea:SetBackgroundColor(Color(0, 0, 0, 0))
    self.TextArea:SetBarColor(nil)
    self.TextArea:SetPlaceholder("")
    self.TextArea.OnChange = function(this, value) self:SetValue(this:GetText()) end

    self.Scratch = self.Label:Add("DNumberScratch")
    self.Scratch:SetImageVisible(false)
    self.Scratch:Dock(FILL)
    self.Scratch.OnValueChanged = function(this) self:ValueChanged(this:GetFloatValue()) end

    self.Wang = self.Scratch

    self:SetValue(0.5)
    self.Slider.Knob:SetSize(16, 16)
    self.Slider.Knob:TDLib()
        :SetupTransition("KnobPressed", 6, function()
            return self:IsEditing()
        end)

    self.Slider.Knob.CircleOpaque = circles.New(CIRCLE_FILLED, 8, 8, 8)
    self.Slider.Knob.CircleOpaque:SetDistance(1)
    self.Slider.Knob.CircleOutline = circles.New(CIRCLE_OUTLINED, 8, 8, 8, 2)
    self.Slider.Knob.CircleOutline:SetDistance(1)

    self.Slider.Knob.Paint = function(this, w, h)
        local color = self:GetColor()
        surface.SetDrawColor(color.r, color.g, color.b, this.KnobPressed * color.a)
        draw.NoTexture()
        this.CircleOpaque()
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        this.CircleOutline()
    end

    self.Slider.Paint = function(this, w, h)
        local color = self:GetBackgroundColor()
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawRect(8, h / 2 - 1, w - 16, 2)

        color = self:GetColor()
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        local len = w - 8
        len = ((self:GetValue() - self:GetMin()) / (self:GetMax() - self:GetMin()) * (len - 8))
        surface.DrawRect(8, h / 2 - 1, len, 2)
    end
end

vgui.Register("FDLib.NumberSlider", PANEL, "DNumSlider")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)
AccessorFunc(PANEL, "color", "Color", nil)
AccessorFunc(PANEL, "activeColor", "ActiveColor", nil)
AccessorFunc(PANEL, "inactiveColor", "InactiveColor", nil)

function PANEL:Init()
    self:TDLib():SetupTransition("Checked", 6, function()
        return self:GetChecked()
    end)

    self.Knob = circles.New(CIRCLE_FILLED, 12, 12, 12)
    self.Knob:SetDistance(1)

    self.Left = circles.New(CIRCLE_FILLED, 6, 6, 6)
    self.Left:SetDistance(1)
    self.Left:SetAngles(90, 270)

    self.Right = circles.New(CIRCLE_FILLED, 6, 6, 6)
    self.Right:SetDistance(1)
    self.Right:SetAngles(90, 270)
    self.Right:Rotate(180)

    self:SetBackgroundColor(COLOR_FOREGROUND)
    self:SetInactiveColor(COLOR_INACTIVE)
    self:SetActiveColor(COLOR_ACTIVE)
end

function PANEL:PerformLayout(w, h)
    self.Knob:SetRadius(h / 2)
    self.Left:SetRadius(h * 0.4)
    self.Left:SetPos(h / 2, h / 2)
    self.Right:SetRadius(h * 0.4)
    self.Right:SetPos(w - h / 2, h / 2)
end

function PANEL:Paint(w, h)
    draw.NoTexture()

    local color = self:GetBackgroundColor()
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    self.Left()
    self.Right()
    surface.DrawRect(h / 2, h / 2 - self.Left:GetRadius(), self.Right:GetX() - h / 2, h - self.Left:GetRadius() * 0.4)

    local x = w - h
    x = x * self.Checked
    self.Knob:SetPos(h / 2 + x, h / 2)

    color = self:GetInactiveColor()
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    self.Knob()
    color = self:GetActiveColor()
    surface.SetDrawColor(color.r, color.g, color.b, color.a * self.Checked)
    self.Knob()
end

vgui.Register("FDLib.CheckBox", PANEL, "DCheckBox")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor", nil)
AccessorFunc(PANEL, "color", "Color", nil)
AccessorFunc(PANEL, "hoverColor", "HoverColor", nil)

function PANEL:Init()
    self:SetBackgroundColor(COLOR_FOREGROUND)
    self:SetColor(COLOR_FOREGROUND)
    self:SetHoverColor(COLOR_ACTIVE)
    self.VBar:SetHideButtons(true)
    self.VBar:TDLib():SetupTransition("Hover", 6, function()
        return self:IsHovered() or self.VBar:IsHovered() or self.VBar.btnGrip:IsHovered() or self.VBar.btnGrip.Depressed
    end)

    self.VBar.Paint = function(this, w, h)
        local color = self:GetBackgroundColor()
        surface.SetDrawColor(color.r, color.g, color.b, color.a * this.Hover)
        surface.DrawRect(0, 0, w, h)
    end

    self.VBar.btnGrip:TDLib():SetupTransition("Press", 6, function()
        return self.VBar.btnGrip.Depressed or self.VBar.btnGrip:IsHovered()
    end)
    self.VBar.btnGrip.Paint = function(this, w, h)
        local color = self:GetColor()
        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawRect(0, 0, w, h)

        color = self:GetHoverColor()
        surface.SetDrawColor(color.r, color.g, color.b, color.a * this.Press)
        surface.DrawRect(0, 0, w, h)
    end
end

vgui.Register("FDLib.ScrollPanel", PANEL, "DScrollPanel")