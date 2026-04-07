-- ================================================
-- ImGui библиотека для Roblox (Мобильная версия)
-- Оптимизировано для touch-экранов
-- ================================================

local ImGui = {}

-- ================================================
-- СЕРВИСЫ
-- ================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Определяем мобильное устройство
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ================================================
-- ТЁМНАЯ ТЕМА
-- ================================================
local Theme = {
    WindowBg         = Color3.fromRGB(15, 15, 15),
    WindowBorder     = Color3.fromRGB(80, 80, 100),
    TitleBg          = Color3.fromRGB(10, 10, 10),
    TitleBgActive    = Color3.fromRGB(41, 74, 122),
    TitleText        = Color3.fromRGB(255, 255, 255),
    Text             = Color3.fromRGB(255, 255, 255),
    TextDisabled     = Color3.fromRGB(128, 128, 128),
    Button           = Color3.fromRGB(55, 55, 55),
    ButtonHovered    = Color3.fromRGB(75, 75, 75),
    ButtonActive     = Color3.fromRGB(41, 74, 122),
    ButtonText       = Color3.fromRGB(255, 255, 255),
    CheckMark        = Color3.fromRGB(66, 150, 250),
    CheckBg          = Color3.fromRGB(32, 32, 32),
    CheckBorder      = Color3.fromRGB(100, 100, 120),
    SliderBg         = Color3.fromRGB(32, 32, 32),
    SliderFill       = Color3.fromRGB(66, 150, 250),
    SliderGrab       = Color3.fromRGB(100, 180, 255),
    SliderBorder     = Color3.fromRGB(100, 100, 120),
    InputBg          = Color3.fromRGB(28, 28, 28),
    InputBorder      = Color3.fromRGB(100, 100, 120),
    InputBorderFocus = Color3.fromRGB(66, 150, 250),
    InputText        = Color3.fromRGB(255, 255, 255),
    ComboBg          = Color3.fromRGB(20, 20, 20),
    ComboItem        = Color3.fromRGB(32, 32, 32),
    ComboItemHover   = Color3.fromRGB(41, 74, 122),
    ComboText        = Color3.fromRGB(255, 255, 255),
    ProgressBg       = Color3.fromRGB(32, 32, 32),
    ProgressFill     = Color3.fromRGB(66, 150, 250),
    ProgressBorder   = Color3.fromRGB(100, 100, 120),
    Separator        = Color3.fromRGB(80, 80, 100),
    ScrollbarBg      = Color3.fromRGB(5, 5, 5),
    ScrollbarGrab    = Color3.fromRGB(79, 79, 79),
}

-- ================================================
-- СТИЛЬ (адаптивный для мобильных)
-- ================================================
local Style = {
    -- На мобиле всё крупнее для удобства касания
    WindowPadding    = IsMobile and Vector2.new(6, 6)   or Vector2.new(8, 8),
    WindowRounding   = 8,
    TitleBarHeight   = IsMobile and 32                  or 26,
    ItemSpacing      = IsMobile and Vector2.new(4, 4)   or Vector2.new(6, 5),
    ItemHeight       = IsMobile and 32                  or 24,
    FramePadding     = IsMobile and Vector2.new(8, 6)   or Vector2.new(6, 4),
    CheckboxSize     = IsMobile and 24                  or 18,
    SliderHeight     = IsMobile and 26                  or 18,
    SliderGrabSize   = IsMobile and 20                  or 8,
    ScrollbarSize    = IsMobile and 10                  or 8,
    FontSize         = IsMobile and 15                  or 13,
    TitleFontSize    = IsMobile and 15                  or 13,
    CloseBtnSize     = IsMobile and 28                  or 18,
    BorderSize       = 1,
}

-- ================================================
-- СОСТОЯНИЕ БИБЛИОТЕКИ
-- ================================================
local State = {
    Windows       = {},
    CurrentWindow = nil,
    ActiveWindow  = nil,

    -- Перетаскивание (touch + mouse)
    Drag = {
        Active    = false,
        Window    = nil,
        OffsetX   = 0,
        OffsetY   = 0,
        TouchId   = nil,   -- ID касания для мультитач
    },

    -- Слайдер dragging
    SliderDrag = {
        Active  = false,
        State   = nil,
        TouchId = nil,
    },

    Mouse = {
        Position = Vector2.new(0, 0),
    },
}

-- ================================================
-- GUI КОНТЕЙНЕР
-- ================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "ImGui_Mobile"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder     = 100
ScreenGui.IgnoreGuiInset   = true
ScreenGui.Parent           = PlayerGui

local MainContainer = Instance.new("Frame")
MainContainer.Name                  = "MainContainer"
MainContainer.BackgroundTransparency = 1
MainContainer.Size                  = UDim2.new(1, 0, 1, 0)
MainContainer.ZIndex                = 1
MainContainer.Parent                = ScreenGui

-- ================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ================================================

-- Создать Frame
local function MkFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3       = props.Color       or Theme.WindowBg
    f.BackgroundTransparency = props.Alpha        or 0
    f.BorderSizePixel        = 0
    f.Position               = props.Pos         or UDim2.new(0,0,0,0)
    f.Size                   = props.Size        or UDim2.new(1,0,0,24)
    f.ZIndex                 = props.Z           or 1
    f.Name                   = props.Name        or "F"
    f.ClipsDescendants       = props.Clip        or false
    f.Parent                 = parent
    return f
end

-- Создать TextLabel
local function MkLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text                   = props.Text       or ""
    l.TextColor3             = props.Color      or Theme.Text
    l.TextSize               = props.FontSize   or Style.FontSize
    l.Font                   = Enum.Font.GothamBold
    l.TextXAlignment         = props.AlignX     or Enum.TextXAlignment.Left
    l.TextYAlignment         = props.AlignY     or Enum.TextYAlignment.Center
    l.TextWrapped            = props.Wrap       or false
    l.Position               = props.Pos        or UDim2.new(0,0,0,0)
    l.Size                   = props.Size       or UDim2.new(1,0,1,0)
    l.ZIndex                 = props.Z          or 2
    l.Name                   = props.Name       or "L"
    l.Parent                 = parent
    return l
end

-- Добавить скругление
local function MkCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or Style.WindowRounding)
    c.Parent = parent
    return c
end

-- Добавить обводку
local function MkStroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color           = color or Theme.WindowBorder
    s.Thickness       = thick or Style.BorderSize
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = parent
    return s
end

-- Получить позицию касания или мыши
local function GetTouchPos(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

-- Попадание точки в GUI объект
local function HitTest(obj, point)
    if not obj or not obj.Parent then return false end
    local p = obj.AbsolutePosition
    local s = obj.AbsoluteSize
    return point.X >= p.X and point.X <= p.X + s.X
       and point.Y >= p.Y and point.Y <= p.Y + s.Y
end

-- ================================================
-- КЛАСС ОКНА
-- ================================================
local Window = {}
Window.__index = Window

function Window.new(title, config)
    local self      = setmetatable({}, Window)
    config          = config or {}

    self.Title      = title
    self.ID         = title
    self.Visible    = config.Visible ~= false
    self.Width      = config.Width   or (IsMobile and 280 or 300)
    self.Height     = config.Height  or (IsMobile and 380 or 400)
    self.X          = config.X       or 10
    self.Y          = config.Y       or 10
    self.Collapsed  = false
    self.ZIndex     = 10

    self.CursorY       = 0
    self.ContentWidth  = 0
    self.ScrollY       = 0
    self.MaxScrollY    = 0
    self.ContentHeight = 0

    self.WidgetStates  = {}

    self:_Build()
    return self
end

-- ------------------------------------------------
-- Построение GUI окна
-- ------------------------------------------------
function Window:_Build()
    -- Основной фрейм
    self.Frame = MkFrame(MainContainer, {
        Name  = "Win_" .. self.ID,
        Pos   = UDim2.new(0, self.X, 0, self.Y),
        Size  = UDim2.new(0, self.Width, 0, self.Height),
        Color = Theme.WindowBg,
        Z     = self.ZIndex,
    })
    MkCorner(self.Frame, Style.WindowRounding)
    MkStroke(self.Frame, Theme.WindowBorder, Style.BorderSize)

    -- Тень
    local shadow = MkFrame(self.Frame, {
        Name  = "Shadow",
        Pos   = UDim2.new(0, 3, 0, 3),
        Size  = UDim2.new(1, 0, 1, 0),
        Color = Color3.fromRGB(0,0,0),
        Alpha = 0.75,
        Z     = self.ZIndex - 1,
    })
    MkCorner(shadow, Style.WindowRounding)

    -- Заголовок
    self.TitleBar = MkFrame(self.Frame, {
        Name  = "TitleBar",
        Pos   = UDim2.new(0,0,0,0),
        Size  = UDim2.new(1,0,0, Style.TitleBarHeight),
        Color = Theme.TitleBgActive,
        Z     = self.ZIndex + 1,
    })
    MkCorner(self.TitleBar, Style.WindowRounding)

    -- Заглушка нижних скруглений заголовка
    MkFrame(self.Frame, {
        Name  = "TitleFix",
        Pos   = UDim2.new(0,0,0, Style.TitleBarHeight - Style.WindowRounding),
        Size  = UDim2.new(1,0,0, Style.WindowRounding),
        Color = Theme.TitleBgActive,
        Z     = self.ZIndex + 1,
    })

    -- Текст заголовка
    MkLabel(self.TitleBar, {
        Name     = "TitleText",
        Text     = self.Title,
        Color    = Theme.TitleText,
        FontSize = Style.TitleFontSize,
        Pos      = UDim2.new(0, Style.WindowPadding.X, 0, 0),
        Size     = UDim2.new(1, -(Style.CloseBtnSize * 2 + 12), 1, 0),
        Z        = self.ZIndex + 2,
    })

    -- Кнопка свернуть
    self.CollapseBtn = Instance.new("TextButton")
    self.CollapseBtn.Name                 = "CollapseBtn"
    self.CollapseBtn.BackgroundTransparency = 1
    self.CollapseBtn.Text                 = "─"
    self.CollapseBtn.TextColor3           = Theme.TitleText
    self.CollapseBtn.TextSize             = Style.TitleFontSize
    self.CollapseBtn.Font                 = Enum.Font.GothamBold
    self.CollapseBtn.Size                 = UDim2.new(0, Style.CloseBtnSize, 0, Style.CloseBtnSize)
    self.CollapseBtn.Position             = UDim2.new(1, -(Style.CloseBtnSize*2+6), 0.5, -Style.CloseBtnSize/2)
    self.CollapseBtn.ZIndex               = self.ZIndex + 3
    self.CollapseBtn.Parent               = self.TitleBar

    -- Кнопка закрыть
    self.CloseBtn = Instance.new("TextButton")
    self.CloseBtn.Name                    = "CloseBtn"
    self.CloseBtn.BackgroundColor3        = Color3.fromRGB(180, 40, 40)
    self.CloseBtn.BackgroundTransparency  = 0
    self.CloseBtn.Text                    = "✕"
    self.CloseBtn.TextColor3              = Color3.fromRGB(255,255,255)
    self.CloseBtn.TextSize                = Style.TitleFontSize - 1
    self.CloseBtn.Font                    = Enum.Font.GothamBold
    self.CloseBtn.Size                    = UDim2.new(0, Style.CloseBtnSize, 0, Style.CloseBtnSize)
    self.CloseBtn.Position                = UDim2.new(1, -(Style.CloseBtnSize+3), 0.5, -Style.CloseBtnSize/2)
    self.CloseBtn.ZIndex                  = self.ZIndex + 3
    self.CloseBtn.Parent                  = self.TitleBar
    MkCorner(self.CloseBtn, 5)

    -- Область контента
    self.ContentClip = MkFrame(self.Frame, {
        Name  = "ContentClip",
        Pos   = UDim2.new(0,0,0, Style.TitleBarHeight),
        Size  = UDim2.new(1,0,1, -Style.TitleBarHeight),
        Alpha = 1,
        Z     = self.ZIndex,
        Clip  = true,
    })

    self.Content = MkFrame(self.ContentClip, {
        Name  = "Content",
        Pos   = UDim2.new(0,0,0,0),
        Size  = UDim2.new(1,0,1,0),
        Alpha = 1,
        Z     = self.ZIndex,
    })

    -- Скроллбар
    self.ScrollTrack = MkFrame(self.Frame, {
        Name  = "ScrollTrack",
        Pos   = UDim2.new(1, -(Style.ScrollbarSize+2), 0, Style.TitleBarHeight+2),
        Size  = UDim2.new(0, Style.ScrollbarSize, 1, -(Style.TitleBarHeight+4)),
        Color = Theme.ScrollbarBg,
        Z     = self.ZIndex + 2,
    })
    MkCorner(self.ScrollTrack, 4)

    self.ScrollGrab = MkFrame(self.ScrollTrack, {
        Name  = "ScrollGrab",
        Pos   = UDim2.new(0,0,0,0),
        Size  = UDim2.new(1,0,0.3,0),
        Color = Theme.ScrollbarGrab,
        Z     = self.ZIndex + 3,
    })
    MkCorner(self.ScrollGrab, 4)

    -- Коннекты кнопок
    self.CloseBtn.MouseButton1Click:Connect(function()
        self.Visible = false
        self.Frame.Visible = false
    end)
    -- Touch для закрытия
    self.CloseBtn.TouchTap:Connect(function()
        self.Visible = false
        self.Frame.Visible = false
    end)

    self.CollapseBtn.MouseButton1Click:Connect(function()
        self:ToggleCollapse()
    end)
    self.CollapseBtn.TouchTap:Connect(function()
        self:ToggleCollapse()
    end)

    -- Настройка перетаскивания
    self:_SetupDrag()
    -- Настройка скролла
    self:_SetupScroll()

    self.Frame.Visible = self.Visible
end

-- ------------------------------------------------
-- Перетаскивание (Touch + Mouse)
-- ------------------------------------------------
function Window:_SetupDrag()
    local dragging   = false
    local touchId    = nil
    local startTouchPos = Vector2.new(0,0)
    local startWinX  = self.X
    local startWinY  = self.Y

    -- ---- TOUCH ----
    self.TitleBar.InputBegan:Connect(function(input)
        -- Пропускаем если нажали на кнопки
        if HitTest(self.CloseBtn, GetTouchPos(input)) then return end
        if HitTest(self.CollapseBtn, GetTouchPos(input)) then return end

        if input.UserInputType == Enum.UserInputType.Touch then
            if dragging then return end  -- Уже тащим
            dragging        = true
            touchId         = input
            startTouchPos   = GetTouchPos(input)
            startWinX       = self.X
            startWinY       = self.Y
            self:Focus()

        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging        = true
            startTouchPos   = State.Mouse.Position
            startWinX       = self.X
            startWinY       = self.Y
            self:Focus()
        end
    end)

    self.TitleBar.InputChanged:Connect(function(input)
        if not dragging then return end

        local curPos
        if input.UserInputType == Enum.UserInputType.Touch then
            if input ~= touchId then return end
            curPos = GetTouchPos(input)
        elseif input.UserInputType == Enum.UserInputType.MouseMovement then
            curPos = State.Mouse.Position
        else
            return
        end

        local dx = curPos.X - startTouchPos.X
        local dy = curPos.Y - startTouchPos.Y

        local screenSize = workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(startWinX + dx, 0, screenSize.X - self.Width)
        local newY = math.clamp(startWinY + dy, 0, screenSize.Y - Style.TitleBarHeight)

        self.X = newX
        self.Y = newY
        self.Frame.Position = UDim2.new(0, newX, 0, newY)
    end)

    self.TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if input == touchId then
                dragging = false
                touchId  = nil
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- ------------------------------------------------
-- Скролл (Touch + Wheel)
-- ------------------------------------------------
function Window:_SetupScroll()
    local scrolling    = false
    local touchId      = nil
    local lastY        = 0

    -- Колесо мыши
    self.Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local delta = -input.Position.Z * 25
            self.ScrollY = math.clamp(self.ScrollY + delta, 0, math.max(0, self.MaxScrollY))
        end
    end)

    -- Touch скролл в контенте
    self.ContentClip.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            if scrolling then return end
            scrolling = true
            touchId   = input
            lastY     = input.Position.Y
        end
    end)

    self.ContentClip.InputChanged:Connect(function(input)
        if not scrolling then return end
        if input ~= touchId then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end

        local dy = lastY - input.Position.Y
        lastY    = input.Position.Y
        self.ScrollY = math.clamp(self.ScrollY + dy, 0, math.max(0, self.MaxScrollY))
    end)

    self.ContentClip.InputEnded:Connect(function(input)
        if input == touchId then
            scrolling = false
            touchId   = nil
        end
    end)
end

-- ------------------------------------------------
-- Сворачивание
-- ------------------------------------------------
function Window:ToggleCollapse()
    self.Collapsed = not self.Collapsed
    if self.Collapsed then
        self.ContentClip.Visible  = false
        self.ScrollTrack.Visible  = false
        self.CollapseBtn.Text     = "▶"
        TweenService:Create(self.Frame,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.Width, 0, Style.TitleBarHeight)}
        ):Play()
    else
        self.ContentClip.Visible  = true
        self.ScrollTrack.Visible  = true
        self.CollapseBtn.Text     = "─"
        TweenService:Create(self.Frame,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.Width, 0, self.Height)}
        ):Play()
    end
end

-- ------------------------------------------------
-- Фокус окна
-- ------------------------------------------------
function Window:Focus()
    local maxZ = 10
    for _, w in pairs(State.Windows) do
        if w.ZIndex > maxZ then maxZ = w.ZIndex end
    end
    self.ZIndex = maxZ + 5
    self:_ApplyZ(self.Frame, self.ZIndex)
    self.TitleBar.BackgroundColor3 = Theme.TitleBgActive
    if State.ActiveWindow and State.ActiveWindow ~= self then
        State.ActiveWindow.TitleBar.BackgroundColor3 = Theme.TitleBg
    end
    State.ActiveWindow = self
end

function Window:_ApplyZ(obj, z)
    for _, c in ipairs(obj:GetChildren()) do
        if c:IsA("GuiObject") then
            c.ZIndex = z + 1
            self:_ApplyZ(c, z + 1)
        end
    end
end

-- ------------------------------------------------
-- Скроллбар обновление
-- ------------------------------------------------
function Window:_UpdateScrollbar()
    local clipH    = self.ContentClip.AbsoluteSize.Y
    local totalH   = self.ContentHeight

    if totalH <= clipH then
        self.ScrollTrack.Visible = false
        self.MaxScrollY = 0
        self.ScrollY    = 0
    else
        self.ScrollTrack.Visible = true
        self.MaxScrollY          = totalH - clipH
        self.ScrollY             = math.clamp(self.ScrollY, 0, self.MaxScrollY)

        local ratio    = math.clamp(clipH / totalH, 0.08, 1)
        local scrollT  = self.MaxScrollY > 0 and (self.ScrollY / self.MaxScrollY) or 0
        local grabPos  = scrollT * (1 - ratio)

        self.ScrollGrab.Size     = UDim2.new(1, 0, ratio, 0)
        self.ScrollGrab.Position = UDim2.new(0, 0, grabPos, 0)
    end

    self.Content.Position = UDim2.new(0, 0, 0, -self.ScrollY)
end

-- ------------------------------------------------
-- Начало / конец кадра
-- ------------------------------------------------
function Window:_BeginFrame()
    self.CursorY      = Style.WindowPadding.Y
    self.ContentWidth = self.Width - Style.WindowPadding.X * 2
                        - Style.ScrollbarSize - 4
    self.ContentHeight = Style.WindowPadding.Y
end

function Window:_EndFrame()
    self.ContentHeight = self.CursorY + Style.WindowPadding.Y
    self:_UpdateScrollbar()
end

-- Следующая позиция виджета
function Window:_Next(h)
    local pos = UDim2.new(0, Style.WindowPadding.X, 0, self.CursorY)
    self.CursorY = self.CursorY + h + Style.ItemSpacing.Y
    return pos
end

-- Получить/создать состояние виджета
function Window:_WS(id, def)
    if not self.WidgetStates[id] then
        self.WidgetStates[id] = def or {}
    end
    return self.WidgetStates[id]
end

-- ================================================
-- ВСЕ ВИДЖЕТЫ
-- ================================================

-- ------------------------------------------------
-- TEXT
-- ------------------------------------------------
function Window:Text(text, color)
    if not self.Visible or self.Collapsed then return end
    local id = "txt_" .. text
    local s  = self:_WS(id, {})

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name  = id, Alpha = 1, Z = self.ZIndex + 1,
        })
        s.lbl = MkLabel(s.frame, {
            Text = text, Color = color or Theme.Text,
            FontSize = Style.FontSize, Z = self.ZIndex + 2, Wrap = true,
        })
    end

    local h   = Style.FontSize + 4
    local pos = self:_Next(h)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, h)
    s.lbl.Text       = text
    s.lbl.TextColor3 = color or Theme.Text
    s.frame.Visible  = true
end

function Window:TextColored(text, color)
    self:Text(text, color)
end

-- ------------------------------------------------
-- SEPARATOR
-- ------------------------------------------------
function Window:Separator()
    if not self.Visible or self.Collapsed then return end
    local id = "sep_" .. math.floor(self.CursorY)
    local s  = self:_WS(id, {})

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name = id, Color = Theme.Separator, Z = self.ZIndex + 1,
        })
    end

    local pos = self:_Next(1)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, 1)
    s.frame.Visible  = true
end

function Window:Spacing(h)
    if not self.Visible or self.Collapsed then return end
    self.CursorY = self.CursorY + (h or Style.ItemSpacing.Y)
end

-- ------------------------------------------------
-- BUTTON (исправленные коннекты для touch)
-- ------------------------------------------------
function Window:Button(label, w, h)
    if not self.Visible or self.Collapsed then return false end

    local id = "btn_" .. label
    local s  = self:_WS(id, {clicked = false, held = false})

    local bw = w or self.ContentWidth
    local bh = h or Style.ItemHeight

    if not s.frame then
        -- TextButton для надёжной работы касаний
        local btn = Instance.new("TextButton")
        btn.Name                   = id
        btn.BackgroundColor3       = Theme.Button
        btn.BorderSizePixel        = 0
        btn.Text                   = label
        btn.TextColor3             = Theme.ButtonText
        btn.TextSize               = Style.FontSize
        btn.Font                   = Enum.Font.GothamBold
        btn.ZIndex                 = self.ZIndex + 1
        btn.AutoButtonColor        = false  -- Управляем вручную
        btn.Parent                 = self.Content
        MkCorner(btn, 5)
        MkStroke(btn, Theme.WindowBorder, 1)

        -- ---- Mouse коннекты ----
        btn.MouseEnter:Connect(function()
            if not s.held then
                btn.BackgroundColor3 = Theme.ButtonHovered
            end
        end)
        btn.MouseLeave:Connect(function()
            s.held = false
            btn.BackgroundColor3 = Theme.Button
        end)
        btn.MouseButton1Down:Connect(function()
            s.held = true
            btn.BackgroundColor3 = Theme.ButtonActive
        end)
        btn.MouseButton1Up:Connect(function()
            s.held = false
            btn.BackgroundColor3 = Theme.ButtonHovered
        end)
        btn.MouseButton1Click:Connect(function()
            s.clicked = true
            btn.BackgroundColor3 = Theme.ButtonActive
            task.delay(0.08, function()
                if btn and btn.Parent then
                    btn.BackgroundColor3 = Theme.Button
                end
            end)
        end)

        -- ---- Touch коннекты ----
        btn.TouchTap:Connect(function()
            s.clicked = true
            -- Визуальный отклик
            btn.BackgroundColor3 = Theme.ButtonActive
            task.delay(0.1, function()
                if btn and btn.Parent then
                    btn.BackgroundColor3 = Theme.Button
                end
            end)
        end)

        s.frame = btn
    end

    local pos = self:_Next(bh)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, bw, 0, bh)
    s.frame.Text     = label
    s.frame.Visible  = true

    local clicked = s.clicked
    s.clicked = false
    return clicked
end

-- ------------------------------------------------
-- CHECKBOX (touch-friendly)
-- ------------------------------------------------
function Window:Checkbox(label, value)
    if not self.Visible or self.Collapsed then return value end

    local id = "chk_" .. label
    local s  = self:_WS(id, {value = value or false})

    if value ~= nil then s.value = value end

    local sz = Style.CheckboxSize
    local h  = math.max(sz, Style.ItemHeight)

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name = id, Alpha = 1, Z = self.ZIndex + 1,
        })

        -- Невидимая кнопка на весь ряд (легче нажать на мобиле)
        local hitBtn = Instance.new("TextButton")
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text                   = ""
        hitBtn.Size                   = UDim2.new(1, 0, 1, 0)
        hitBtn.ZIndex                 = self.ZIndex + 4
        hitBtn.AutoButtonColor        = false
        hitBtn.Parent                 = s.frame

        -- Квадрат
        s.box = MkFrame(s.frame, {
            Name  = "Box",
            Pos   = UDim2.new(0, 0, 0.5, -sz/2),
            Size  = UDim2.new(0, sz, 0, sz),
            Color = Theme.CheckBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.box, 4)
        MkStroke(s.box, Theme.CheckBorder, 1)

        -- Галочка
        s.mark = MkLabel(s.box, {
            Text     = "✓",
            Color    = Theme.CheckMark,
            FontSize = sz - 4,
            AlignX   = Enum.TextXAlignment.Center,
            AlignY   = Enum.TextYAlignment.Center,
            Z        = self.ZIndex + 3,
        })

        -- Текст
        MkLabel(s.frame, {
            Text     = label,
            Color    = Theme.Text,
            FontSize = Style.FontSize,
            Pos      = UDim2.new(0, sz + Style.ItemSpacing.X, 0, 0),
            Size     = UDim2.new(1, -(sz + Style.ItemSpacing.X), 1, 0),
            Z        = self.ZIndex + 2,
        })

        local function Toggle()
            s.value = not s.value
            s.mark.Visible = s.value
            -- Анимация
            s.box.BackgroundColor3 = s.value and Theme.CheckMark or Theme.CheckBg
            task.delay(0.08, function()
                if s.box and s.box.Parent then
                    s.box.BackgroundColor3 = Theme.CheckBg
                end
            end)
        end

        hitBtn.MouseButton1Click:Connect(Toggle)
        hitBtn.TouchTap:Connect(Toggle)
    end

    s.mark.Visible = s.value

    local pos = self:_Next(h)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, h)
    s.frame.Visible  = true

    return s.value
end

-- ------------------------------------------------
-- SLIDER (touch + mouse drag)
-- ------------------------------------------------
function Window:Slider(label, value, minV, maxV, fmt)
    if not self.Visible or self.Collapsed then return value end

    local id = "sld_" .. label
    local s  = self:_WS(id, {value = value or 0, dragging = false, touchId = nil})

    minV = minV or 0
    maxV = maxV or 1
    fmt  = fmt  or "%.1f"
    if value ~= nil then
        s.value = math.clamp(value, minV, maxV)
    end

    local labelH = Style.FontSize + 2
    local totalH = labelH + Style.SliderHeight + Style.ItemSpacing.Y

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name = id, Alpha = 1, Z = self.ZIndex + 1,
        })

        s.lbl = MkLabel(s.frame, {
            Text = label, Color = Theme.Text, FontSize = Style.FontSize,
            Pos  = UDim2.new(0,0,0,0),
            Size = UDim2.new(1,0,0,labelH),
            Z    = self.ZIndex + 2,
        })

        -- Трек
        s.track = MkFrame(s.frame, {
            Name  = "Track",
            Pos   = UDim2.new(0,0,0, labelH + Style.ItemSpacing.Y),
            Size  = UDim2.new(1,0,0, Style.SliderHeight),
            Color = Theme.SliderBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.track, 5)
        MkStroke(s.track, Theme.SliderBorder, 1)

        -- Заливка
        s.fill = MkFrame(s.track, {
            Name  = "Fill",
            Pos   = UDim2.new(0,0,0,0),
            Size  = UDim2.new(0,0,1,0),
            Color = Theme.SliderFill,
            Z     = self.ZIndex + 3,
        })
        MkCorner(s.fill, 5)

        -- Значение
        s.valLbl = MkLabel(s.track, {
            Text     = "",
            Color    = Theme.Text,
            FontSize = Style.FontSize - 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = self.ZIndex + 5,
        })

        -- Ползунок
        s.grab = MkFrame(s.track, {
            Name  = "Grab",
            Color = Theme.SliderGrab,
            Z     = self.ZIndex + 4,
        })
        MkCorner(s.grab, Style.SliderGrabSize / 2)

        -- ---- Функция обновления значения по позиции ----
        local function ApplyPos(px)
            local tp  = s.track.AbsolutePosition
            local tsz = s.track.AbsoluteSize
            local rel = math.clamp((px - tp.X) / tsz.X, 0, 1)
            s.value   = minV + rel * (maxV - minV)
        end

        -- ---- TOUCH ----
        s.track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                s.dragging = true
                s.touchId  = input
                ApplyPos(input.Position.X)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                s.dragging = true
                ApplyPos(State.Mouse.Position.X)
            end
        end)

        s.track.InputChanged:Connect(function(input)
            if not s.dragging then return end
            if input.UserInputType == Enum.UserInputType.Touch then
                if input ~= s.touchId then return end
                ApplyPos(input.Position.X)
            elseif input.UserInputType == Enum.UserInputType.MouseMovement then
                ApplyPos(State.Mouse.Position.X)
            end
        end)

        s.track.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and input == s.touchId then
                s.dragging = false
                s.touchId  = nil
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                s.dragging = false
            end
        end)

        -- Глобальное завершение drag (если палец ушёл за пределы)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and input == s.touchId then
                s.dragging = false
                s.touchId  = nil
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                s.dragging = false
            end
        end)

        -- Глобальное перемещение (если мышь вышла за пределы трека)
        UserInputService.InputChanged:Connect(function(input)
            if not s.dragging then return end
            if input.UserInputType == Enum.UserInputType.Touch and input == s.touchId then
                ApplyPos(input.Position.X)
            elseif input.UserInputType == Enum.UserInputType.MouseMovement then
                ApplyPos(State.Mouse.Position.X)
            end
        end)
    end

    -- Обновляем визуал
    local t    = (maxV ~= minV) and ((s.value - minV) / (maxV - minV)) or 0
    local grabW = Style.SliderGrabSize
    local grabH = Style.SliderHeight - 2

    s.fill.Size         = UDim2.new(t, 0, 1, 0)
    s.grab.Size         = UDim2.new(0, grabW, 0, grabH)
    s.grab.Position     = UDim2.new(t, -grabW/2, 0.5, -grabH/2)
    s.valLbl.Text       = string.format(fmt, s.value)
    s.lbl.Text          = label

    local pos = self:_Next(totalH)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.frame.Visible  = true

    return s.value
end

-- ------------------------------------------------
-- INPUT TEXT
-- ------------------------------------------------
function Window:InputText(label, value, placeholder)
    if not self.Visible or self.Collapsed then return value end

    local id = "inp_" .. label
    local s  = self:_WS(id, {value = value or "", focused = false})

    if value ~= nil and not s.focused then s.value = value end
    placeholder = placeholder or ""

    local labelH = Style.FontSize + 2
    local totalH = labelH + Style.ItemHeight + Style.ItemSpacing.Y

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name = id, Alpha = 1, Z = self.ZIndex + 1,
        })
        s.lbl = MkLabel(s.frame, {
            Text = label, Color = Theme.Text, FontSize = Style.FontSize,
            Pos  = UDim2.new(0,0,0,0),
            Size = UDim2.new(1,0,0,labelH),
            Z    = self.ZIndex + 2,
        })

        s.inputFrame = MkFrame(s.frame, {
            Name  = "InputF",
            Pos   = UDim2.new(0,0,0, labelH + Style.ItemSpacing.Y),
            Size  = UDim2.new(1,0,0, Style.ItemHeight),
            Color = Theme.InputBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.inputFrame, 5)
        s.stroke = MkStroke(s.inputFrame, Theme.InputBorder, 1)

        local tb = Instance.new("TextBox")
        tb.BackgroundTransparency = 1
        tb.Text                   = s.value
        tb.PlaceholderText        = placeholder
        tb.PlaceholderColor3      = Theme.TextDisabled
        tb.TextColor3             = Theme.InputText
        tb.TextSize               = Style.FontSize
        tb.Font                   = Enum.Font.Gotham
        tb.TextXAlignment         = Enum.TextXAlignment.Left
        tb.Size                   = UDim2.new(1, -Style.FramePadding.X*2, 1, 0)
        tb.Position               = UDim2.new(0, Style.FramePadding.X, 0, 0)
        tb.ZIndex                 = self.ZIndex + 3
        tb.ClearTextOnFocus       = false
        tb.Parent                 = s.inputFrame

        tb.Focused:Connect(function()
            s.focused = true
            s.stroke.Color = Theme.InputBorderFocus
        end)
        tb.FocusLost:Connect(function()
            s.focused = false
            s.value   = tb.Text
            s.stroke.Color = Theme.InputBorder
        end)
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            s.value = tb.Text
        end)

        s.tb = tb
    end

    if not s.focused then s.tb.Text = s.value end
    s.lbl.Text         = label
    s.tb.PlaceholderText = placeholder

    local pos = self:_Next(totalH)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.frame.Visible  = true

    return s.value
end

-- ------------------------------------------------
-- COMBO (touch-friendly dropdown)
-- ------------------------------------------------
function Window:Combo(label, selIdx, items)
    if not self.Visible or self.Collapsed then return selIdx end

    local id = "cmb_" .. label
    local s  = self:_WS(id, {selIdx = selIdx or 1, open = false})

    if selIdx ~= nil then s.selIdx = selIdx end
    items = items or {}

    local labelH = Style.FontSize + 2
    local totalH = labelH + Style.ItemHeight + Style.ItemSpacing.Y

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name = id, Alpha = 1, Z = self.ZIndex + 1,
        })
        s.lbl = MkLabel(s.frame, {
            Text = label, Color = Theme.Text, FontSize = Style.FontSize,
            Pos  = UDim2.new(0,0,0,0),
            Size = UDim2.new(1,0,0,labelH),
            Z    = self.ZIndex + 2,
        })

        -- Кнопка combo
        s.btn = Instance.new("TextButton")
        s.btn.Name                   = "ComboBtn"
        s.btn.BackgroundColor3       = Theme.InputBg
        s.btn.BorderSizePixel        = 0
        s.btn.Text                   = ""
        s.btn.AutoButtonColor        = false
        s.btn.ZIndex                 = self.ZIndex + 2
        s.btn.Parent                 = s.frame
        MkCorner(s.btn, 5)
        MkStroke(s.btn, Theme.InputBorder, 1)

        s.selText = MkLabel(s.btn, {
            Text     = items[s.selIdx] or "",
            Color    = Theme.Text,
            FontSize = Style.FontSize,
            Pos      = UDim2.new(0, Style.FramePadding.X, 0, 0),
            Size     = UDim2.new(1, -Style.ItemHeight, 1, 0),
            Z        = self.ZIndex + 3,
        })

        s.arrow = MkLabel(s.btn, {
            Text     = "▼",
            Color    = Theme.TextDisabled,
            FontSize = Style.FontSize,
            Pos      = UDim2.new(1, -Style.ItemHeight, 0, 0),
            Size     = UDim2.new(0, Style.ItemHeight, 1, 0),
            AlignX   = Enum.TextXAlignment.Center,
            Z        = self.ZIndex + 3,
        })

        -- Выпадающий список
        s.dropdown = MkFrame(MainContainer, {
            Name  = id .. "_drop",
            Color = Theme.ComboBg,
            Z     = 200,
        })
        s.dropdown.Visible = false
        MkCorner(s.dropdown, 5)
        MkStroke(s.dropdown, Theme.WindowBorder, 1)

        local function OpenDropdown()
            s.open = not s.open
            s.dropdown.Visible = s.open
            s.arrow.Text = s.open and "▲" or "▼"

            if s.open then
                -- Удаляем старые кнопки
                for _, c in ipairs(s.dropdown:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end

                local iH   = Style.ItemHeight + 2
                local dropH = #items * iH + 6
                local bPos  = s.btn.AbsolutePosition
                local bSz   = s.btn.AbsoluteSize

                -- Определяем: открывать вниз или вверх
                local screenH = workspace.CurrentCamera.ViewportSize.Y
                local openUp  = (bPos.Y + bSz.Y + dropH) > screenH

                s.dropdown.Size = UDim2.new(0, bSz.X, 0, dropH)
                if openUp then
                    s.dropdown.Position = UDim2.new(0, bPos.X, 0, bPos.Y - dropH - 2)
                else
                    s.dropdown.Position = UDim2.new(0, bPos.X, 0, bPos.Y + bSz.Y + 2)
                end

                for i, item in ipairs(items) do
                    local ib = Instance.new("TextButton")
                    ib.BackgroundColor3      = i == s.selIdx and Theme.ComboItemHover or Theme.ComboItem
                    ib.BackgroundTransparency = i == s.selIdx and 0 or 0.6
                    ib.Text                  = item
                    ib.TextColor3            = Theme.ComboText
                    ib.TextSize              = Style.FontSize
                    ib.Font                  = Enum.Font.Gotham
                    ib.TextXAlignment        = Enum.TextXAlignment.Left
                    ib.Size                  = UDim2.new(1, -6, 0, iH)
                    ib.Position              = UDim2.new(0, 3, 0, (i-1)*iH + 3)
                    ib.ZIndex                = 201
                    ib.AutoButtonColor       = false
                    ib.Parent                = s.dropdown
                    MkCorner(ib, 4)

                    local pad = Instance.new("UIPadding")
                    pad.PaddingLeft = UDim.new(0, Style.FramePadding.X)
                    pad.Parent      = ib

                    ib.MouseEnter:Connect(function()
                        ib.BackgroundTransparency = 0
                        ib.BackgroundColor3       = Theme.ComboItemHover
                    end)
                    ib.MouseLeave:Connect(function()
                        if i ~= s.selIdx then
                            ib.BackgroundTransparency = 0.6
                            ib.BackgroundColor3       = Theme.ComboItem
                        end
                    end)

                    local ci = i
                    local function Select()
                        s.selIdx          = ci
                        s.selText.Text    = items[ci] or ""
                        s.open            = false
                        s.dropdown.Visible = false
                        s.arrow.Text      = "▼"
                    end

                    ib.MouseButton1Click:Connect(Select)
                    ib.TouchTap:Connect(Select)
                end
            end
        end

        s.btn.MouseButton1Click:Connect(OpenDropdown)
        s.btn.TouchTap:Connect(OpenDropdown)

        -- Закрытие при тапе вне
        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

            if s.open then
                task.defer(function()
                    local tp = GetTouchPos(input)
                    if not HitTest(s.btn, tp) and not HitTest(s.dropdown, tp) then
                        s.open             = false
                        s.dropdown.Visible = false
                        s.arrow.Text       = "▼"
                    end
                end)
            end
        end)
    end

    s.selText.Text = items[s.selIdx] or ""
    s.lbl.Text     = label

    local pos = self:_Next(totalH)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.btn.Position   = UDim2.new(0, 0, 0, labelH + Style.ItemSpacing.Y)
    s.btn.Size       = UDim2.new(1, 0, 0, Style.ItemHeight)
    s.frame.Visible  = true

    return s.selIdx
end

-- ------------------------------------------------
-- PROGRESS BAR
-- ------------------------------------------------
function Window:ProgressBar(label, value, minV, maxV, showPct)
    if not self.Visible or self.Collapsed then return end

    local id = "prg_" .. label
    local s  = self:_WS(id, {})

    minV    = minV    or 0
    maxV    = maxV    or 1
    showPct = showPct ~= false
    value   = math.clamp(value or 0, minV, maxV)

    local labelH = (label ~= "" and label:sub(1,2) ~= "##") and (Style.FontSize + 2) or 0
    local totalH = labelH + Style.SliderHeight + (labelH > 0 and Style.ItemSpacing.Y or 0)

    if not s.frame then
        s.frame = MkFrame(self.Content, {
            Name = id, Alpha = 1, Z = self.ZIndex + 1,
        })
        s.lbl = MkLabel(s.frame, {
            Text = label, Color = Theme.Text, FontSize = Style.FontSize,
            Pos  = UDim2.new(0,0,0,0),
            Size = UDim2.new(1,0,0, math.max(labelH, 1)),
            Z    = self.ZIndex + 2,
        })
        s.bg = MkFrame(s.frame, {
            Name  = "BG",
            Pos   = UDim2.new(0,0,0, math.max(labelH + Style.ItemSpacing.Y, 0)),
            Size  = UDim2.new(1,0,0, Style.SliderHeight),
            Color = Theme.ProgressBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.bg, 5)
        MkStroke(s.bg, Theme.ProgressBorder, 1)

        s.fill = MkFrame(s.bg, {
            Name  = "Fill",
            Color = Theme.ProgressFill,
            Z     = self.ZIndex + 3,
        })
        MkCorner(s.fill, 5)

        s.pct = MkLabel(s.bg, {
            Text     = "",
            Color    = Theme.Text,
            FontSize = Style.FontSize - 1,
            AlignX   = Enum.TextXAlignment.Center,
            Z        = self.ZIndex + 4,
        })
    end

    local t        = (maxV ~= minV) and ((value - minV) / (maxV - minV)) or 0
    s.fill.Size    = UDim2.new(math.clamp(t, 0, 1), 0, 1, 0)
    s.lbl.Text     = (label:sub(1,2) == "##") and "" or label
    s.lbl.Visible  = labelH > 0
    s.pct.Text     = showPct and string.format("%d%%", math.floor(t * 100)) or ""
    s.pct.Visible  = showPct

    local pos = self:_Next(totalH)
    s.frame.Position = pos
    s.frame.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.frame.Visible  = true
end

-- ================================================
-- PUBLIC API
-- ================================================

function ImGui.Begin(title, config)
    if not State.Windows[title] then
        State.Windows[title] = Window.new(title, config)
    end

    local win = State.Windows[title]
    State.CurrentWindow = win

    -- Применяем конфиг если окно только что создано
    if config and config.Visible ~= nil then
        win.Visible        = config.Visible
        win.Frame.Visible  = config.Visible
    end

    if win.Visible then
        win.Frame.Visible = true
        win:_BeginFrame()
    end

    return win.Visible
end

function ImGui.End()
    local win = State.CurrentWindow
    if win and win.Visible then
        win:_EndFrame()
    end
    State.CurrentWindow = nil
end

function ImGui.SetWindowVisible(title, visible)
    local win = State.Windows[title]
    if win then
        win.Visible       = visible
        win.Frame.Visible = visible
    end
end

-- Прокси виджеты
function ImGui.Text(t, c)          if State.CurrentWindow then State.CurrentWindow:Text(t, c) end end
function ImGui.TextColored(t, c)   if State.CurrentWindow then State.CurrentWindow:TextColored(t, c) end end
function ImGui.Separator()         if State.CurrentWindow then State.CurrentWindow:Separator() end end
function ImGui.Spacing(h)          if State.CurrentWindow then State.CurrentWindow:Spacing(h) end end

function ImGui.Button(l, w, h)
    if State.CurrentWindow then return State.CurrentWindow:Button(l, w, h) end
    return false
end
function ImGui.Checkbox(l, v)
    if State.CurrentWindow then return State.CurrentWindow:Checkbox(l, v) end
    return v
end
function ImGui.Slider(l, v, mn, mx, f)
    if State.CurrentWindow then return State.CurrentWindow:Slider(l, v, mn, mx, f) end
    return v
end
function ImGui.InputText(l, v, p)
    if State.CurrentWindow then return State.CurrentWindow:InputText(l, v, p) end
    return v
end
function ImGui.Combo(l, i, items)
    if State.CurrentWindow then return State.CurrentWindow:Combo(l, i, items) end
    return i
end
function ImGui.ProgressBar(l, v, mn, mx, s)
    if State.CurrentWindow then State.CurrentWindow:ProgressBar(l, v, mn, mx, s) end
end

-- ================================================
-- ОБНОВЛЕНИЕ ПОЗИЦИИ МЫШИ
-- ================================================
RunService.RenderStepped:Connect(function()
    State.Mouse.Position = UserInputService:GetMouseLocation()
end)

-- ================================================
-- УНИЧТОЖЕНИЕ
-- ================================================
function ImGui.Destroy()
    for _, win in pairs(State.Windows) do
        if win.Frame then win.Frame:Destroy() end
    end
    State.Windows = {}
    if ScreenGui then ScreenGui:Destroy() end
end

ImGui.Theme = Theme
ImGui.Style = Style
ImGui.IsMobile = IsMobile

return ImGui
