-- ================================================
-- ImGui для Roblox (Мобильная версия)
-- Исправлены кнопки через глобальный InputBegan
-- ================================================

local ImGui = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local IsMobile = UserInputService.TouchEnabled

-- ================================================
-- ТЕМА
-- ================================================
local Theme = {
    WindowBg         = Color3.fromRGB(15, 15, 15),
    WindowBorder     = Color3.fromRGB(80, 80, 100),
    TitleBgActive    = Color3.fromRGB(41, 74, 122),
    TitleBg          = Color3.fromRGB(20, 20, 40),
    TitleText        = Color3.fromRGB(255, 255, 255),
    Text             = Color3.fromRGB(255, 255, 255),
    TextDisabled     = Color3.fromRGB(128, 128, 128),
    Button           = Color3.fromRGB(55, 55, 65),
    ButtonHovered    = Color3.fromRGB(75, 75, 90),
    ButtonActive     = Color3.fromRGB(41, 74, 122),
    ButtonText       = Color3.fromRGB(255, 255, 255),
    CheckMark        = Color3.fromRGB(66, 150, 250),
    CheckBg          = Color3.fromRGB(32, 32, 40),
    CheckBorder      = Color3.fromRGB(100, 100, 120),
    SliderBg         = Color3.fromRGB(32, 32, 40),
    SliderFill       = Color3.fromRGB(66, 150, 250),
    SliderGrab       = Color3.fromRGB(120, 180, 255),
    SliderBorder     = Color3.fromRGB(100, 100, 120),
    InputBg          = Color3.fromRGB(28, 28, 35),
    InputBorder      = Color3.fromRGB(100, 100, 120),
    InputBorderFocus = Color3.fromRGB(66, 150, 250),
    InputText        = Color3.fromRGB(255, 255, 255),
    ComboBg          = Color3.fromRGB(20, 20, 28),
    ComboItem        = Color3.fromRGB(35, 35, 45),
    ComboItemHover   = Color3.fromRGB(41, 74, 122),
    ComboText        = Color3.fromRGB(255, 255, 255),
    ProgressBg       = Color3.fromRGB(32, 32, 40),
    ProgressFill     = Color3.fromRGB(66, 150, 250),
    ProgressBorder   = Color3.fromRGB(100, 100, 120),
    Separator        = Color3.fromRGB(80, 80, 100),
    ScrollbarBg      = Color3.fromRGB(8, 8, 8),
    ScrollbarGrab    = Color3.fromRGB(80, 80, 90),
}

-- ================================================
-- СТИЛЬ
-- ================================================
local Style = {
    WindowPadding  = Vector2.new(6, 6),
    WindowRounding = 8,
    TitleBarHeight = IsMobile and 36 or 28,
    ItemSpacing    = Vector2.new(4, 4),
    ItemHeight     = IsMobile and 36 or 26,
    FramePadding   = Vector2.new(8, 6),
    CheckboxSize   = IsMobile and 28 or 20,
    SliderHeight   = IsMobile and 30 or 20,
    SliderGrabW    = IsMobile and 18 or 10,
    ScrollbarSize  = IsMobile and 10 or 8,
    FontSize       = IsMobile and 16 or 14,
    TitleFontSize  = IsMobile and 16 or 14,
    CloseBtnSize   = IsMobile and 30 or 20,
    BorderSize     = 1,
}

-- ================================================
-- ГЛАВНЫЙ GUI
-- ================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ImGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 100
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

-- Главный прозрачный контейнер
local Root = Instance.new("Frame")
Root.Name                  = "Root"
Root.BackgroundTransparency = 1
Root.Size                  = UDim2.new(1, 0, 1, 0)
Root.ZIndex                = 1
Root.Parent                = ScreenGui

-- ================================================
-- ГЛОБАЛЬНЫЙ РЕЕСТР КНОПОК
-- Все интерактивные элементы регистрируются здесь
-- и обрабатываются через единый InputBegan
-- ================================================
local ButtonRegistry = {}
-- Формат записи:
-- { frame = GuiObject, onDown = fn, onUp = fn, onClick = fn }

-- Регистрируем кликабельный элемент
local function RegisterButton(frame, onClick, onDown, onUp)
    table.insert(ButtonRegistry, {
        frame   = frame,
        onClick = onClick,
        onDown  = onDown,
        onUp    = onUp,
    })
end

-- Удалить все регистрации для frame
local function UnregisterButton(frame)
    for i = #ButtonRegistry, 1, -1 do
        if ButtonRegistry[i].frame == frame then
            table.remove(ButtonRegistry, i)
        end
    end
end

-- Проверка попадания точки в объект
local function Hit(obj, pt)
    if not obj or not obj.Visible then return false end
    -- Проверяем видимость всей цепочки родителей
    local cur = obj
    while cur do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur == Root then break end
        cur = cur.Parent
    end
    local p = obj.AbsolutePosition
    local s = obj.AbsoluteSize
    return pt.X >= p.X and pt.X <= p.X + s.X
       and pt.Y >= p.Y and pt.Y <= p.Y + s.Y
end

-- ================================================
-- ГЛОБАЛЬНАЯ ОБРАБОТКА НАЖАТИЙ
-- Единая точка входа для всех касаний и кликов
-- ================================================
local ActiveTouch    = nil  -- текущий touch input
local ActiveBtn      = nil  -- текущая нажатая кнопка

UserInputService.InputBegan:Connect(function(input, gp)
    -- Не блокируем textbox фокус
    local isTap   = input.UserInputType == Enum.UserInputType.Touch
    local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1

    if not isTap and not isMouse then return end

    -- Уже обрабатываем другое касание
    if isTap and ActiveTouch then return end

    local pt = Vector2.new(input.Position.X, input.Position.Y)

    -- Ищем кнопку под пальцем/курсором (с конца — верхние слои)
    local found = nil
    for i = #ButtonRegistry, 1, -1 do
        local reg = ButtonRegistry[i]
        if reg.frame and reg.frame.Parent and Hit(reg.frame, pt) then
            found = reg
            break
        end
    end

    if found then
        ActiveBtn = found
        if isTap then ActiveTouch = input end

        -- Визуальный отклик нажатия
        if found.onDown then
            found.onDown()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local isTap   = input.UserInputType == Enum.UserInputType.Touch
    local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1

    if not isTap and not isMouse then return end
    if isTap and input ~= ActiveTouch then return end

    if ActiveBtn then
        local pt = Vector2.new(input.Position.X, input.Position.Y)

        -- Если палец/курсор всё ещё над кнопкой — засчитываем клик
        if Hit(ActiveBtn.frame, pt) then
            if ActiveBtn.onClick then
                ActiveBtn.onClick()
            end
        end

        if ActiveBtn.onUp then
            ActiveBtn.onUp()
        end

        ActiveBtn  = nil
    end

    if isTap then ActiveTouch = nil end
end)

-- ================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ================================================
local function MkFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3       = props.Color or Theme.WindowBg
    f.BackgroundTransparency = props.Alpha or 0
    f.BorderSizePixel        = 0
    f.Position               = props.Pos  or UDim2.new(0,0,0,0)
    f.Size                   = props.Size or UDim2.new(1,0,0,24)
    f.ZIndex                 = props.Z    or 1
    f.Name                   = props.Name or "F"
    f.ClipsDescendants       = props.Clip or false
    f.Parent                 = parent
    return f
end

local function MkLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text          = props.Text    or ""
    l.TextColor3    = props.Color   or Theme.Text
    l.TextSize      = props.FS      or Style.FontSize
    l.Font          = Enum.Font.GothamBold
    l.TextXAlignment = props.AX    or Enum.TextXAlignment.Left
    l.TextYAlignment = props.AY    or Enum.TextYAlignment.Center
    l.TextWrapped   = props.Wrap    or false
    l.Position      = props.Pos     or UDim2.new(0,0,0,0)
    l.Size          = props.Size    or UDim2.new(1,0,1,0)
    l.ZIndex        = props.Z       or 2
    l.Name          = props.Name    or "L"
    l.Parent        = parent
    return l
end

local function MkCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or Style.WindowRounding)
    c.Parent = p
end

local function MkStroke(p, color, thick)
    local s = Instance.new("UIStroke")
    s.Color           = color or Theme.WindowBorder
    s.Thickness       = thick or Style.BorderSize
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = p
    return s
end

-- ================================================
-- КЛАСС ОКНА
-- ================================================
local Window = {}
Window.__index = Window

function Window.new(title, cfg)
    local self  = setmetatable({}, Window)
    cfg         = cfg or {}

    self.Title   = title
    self.Visible = cfg.Visible ~= false
    self.Width   = cfg.Width  or (IsMobile and 280 or 300)
    self.Height  = cfg.Height or (IsMobile and 380 or 400)
    self.X       = cfg.X or 80
    self.Y       = cfg.Y or 10
    self.Collapsed  = false
    self.ZIndex     = 10

    self.CursorY      = 0
    self.ContentWidth = 0
    self.ScrollY      = 0
    self.MaxScrollY   = 0
    self.ContentHeight = 0
    self.WidgetStates  = {}

    self:_Build()
    return self
end

function Window:_Build()
    -- Основной фрейм
    self.Frame = MkFrame(Root, {
        Name  = "W_" .. self.Title,
        Pos   = UDim2.new(0, self.X, 0, self.Y),
        Size  = UDim2.new(0, self.Width, 0, self.Height),
        Color = Theme.WindowBg,
        Z     = self.ZIndex,
    })
    MkCorner(self.Frame, Style.WindowRounding)
    MkStroke(self.Frame, Theme.WindowBorder, Style.BorderSize)

    -- Тень
    local sh = MkFrame(self.Frame, {
        Pos   = UDim2.new(0,3,0,3),
        Size  = UDim2.new(1,0,1,0),
        Color = Color3.new(0,0,0),
        Alpha = 0.7,
        Z     = self.ZIndex - 1,
    })
    MkCorner(sh, Style.WindowRounding)

    -- Заголовок
    self.TitleBar = MkFrame(self.Frame, {
        Name  = "TitleBar",
        Size  = UDim2.new(1,0,0, Style.TitleBarHeight),
        Color = Theme.TitleBgActive,
        Z     = self.ZIndex + 1,
    })
    MkCorner(self.TitleBar, Style.WindowRounding)

    -- Заплатка скруглений
    MkFrame(self.Frame, {
        Pos   = UDim2.new(0,0,0, Style.TitleBarHeight - Style.WindowRounding),
        Size  = UDim2.new(1,0,0, Style.WindowRounding),
        Color = Theme.TitleBgActive,
        Z     = self.ZIndex + 1,
    })

    -- Текст заголовка
    MkLabel(self.TitleBar, {
        Text = self.Title,
        Color = Theme.TitleText,
        FS   = Style.TitleFontSize,
        Pos  = UDim2.new(0, Style.WindowPadding.X, 0, 0),
        Size = UDim2.new(1, -(Style.CloseBtnSize*2 + 14), 1, 0),
        Z    = self.ZIndex + 2,
    })

    -- Кнопка сворачивания (Frame вместо TextButton)
    self.CollapseFrame = MkFrame(self.TitleBar, {
        Name  = "CollapseBtn",
        Pos   = UDim2.new(1, -(Style.CloseBtnSize*2+8), 0.5, -Style.CloseBtnSize/2),
        Size  = UDim2.new(0, Style.CloseBtnSize, 0, Style.CloseBtnSize),
        Color = Theme.WindowBg,
        Alpha = 0.6,
        Z     = self.ZIndex + 3,
    })
    MkCorner(self.CollapseFrame, 5)
    self.CollapseLbl = MkLabel(self.CollapseFrame, {
        Text = "─",
        Color = Theme.TitleText,
        FS   = Style.TitleFontSize,
        AX   = Enum.TextXAlignment.Center,
        Z    = self.ZIndex + 4,
    })
    RegisterButton(self.CollapseFrame, function()
        self:ToggleCollapse()
    end)

    -- Кнопка закрытия (Frame вместо TextButton)
    self.CloseFrame = MkFrame(self.TitleBar, {
        Name  = "CloseBtn",
        Pos   = UDim2.new(1, -(Style.CloseBtnSize+4), 0.5, -Style.CloseBtnSize/2),
        Size  = UDim2.new(0, Style.CloseBtnSize, 0, Style.CloseBtnSize),
        Color = Color3.fromRGB(160, 35, 35),
        Z     = self.ZIndex + 3,
    })
    MkCorner(self.CloseFrame, 5)
    MkLabel(self.CloseFrame, {
        Text  = "✕",
        Color = Color3.new(1,1,1),
        FS    = Style.TitleFontSize - 1,
        AX    = Enum.TextXAlignment.Center,
        Z     = self.ZIndex + 4,
    })
    RegisterButton(self.CloseFrame,
        function() -- onClick
            self.Visible          = false
            self.Frame.Visible    = false
        end,
        function() -- onDown
            self.CloseFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end,
        function() -- onUp
            self.CloseFrame.BackgroundColor3 = Color3.fromRGB(160, 35, 35)
        end
    )

    -- Область контента
    self.ContentClip = MkFrame(self.Frame, {
        Name  = "Clip",
        Pos   = UDim2.new(0,0,0, Style.TitleBarHeight),
        Size  = UDim2.new(1,0,1,-Style.TitleBarHeight),
        Alpha = 1,
        Z     = self.ZIndex,
        Clip  = true,
    })
    self.Content = MkFrame(self.ContentClip, {
        Name  = "Content",
        Alpha = 1,
        Z     = self.ZIndex,
    })

    -- Скроллбар
    self.ScrollTrack = MkFrame(self.Frame, {
        Pos   = UDim2.new(1,-(Style.ScrollbarSize+2), 0, Style.TitleBarHeight+2),
        Size  = UDim2.new(0, Style.ScrollbarSize, 1, -(Style.TitleBarHeight+4)),
        Color = Theme.ScrollbarBg,
        Z     = self.ZIndex + 2,
    })
    MkCorner(self.ScrollTrack, 4)

    self.ScrollGrab = MkFrame(self.ScrollTrack, {
        Size  = UDim2.new(1,0,0.3,0),
        Color = Theme.ScrollbarGrab,
        Z     = self.ZIndex + 3,
    })
    MkCorner(self.ScrollGrab, 4)

    self:_SetupDrag()
    self:_SetupScroll()
    self.Frame.Visible = self.Visible
end

-- ------------------------------------------------
-- Перетаскивание
-- ------------------------------------------------
function Window:_SetupDrag()
    local drag     = false
    local touchRef = nil
    local startTP  = Vector2.new(0,0)
    local startX   = self.X
    local startY   = self.Y

    -- Зона drag = заголовок минус кнопки
    local function IsDragZone(pt)
        if not Hit(self.TitleBar, pt) then return false end
        if Hit(self.CloseFrame, pt)   then return false end
        if Hit(self.CollapseFrame, pt) then return false end
        return true
    end

    self.TitleBar.InputBegan:Connect(function(input)
        local isTap   = input.UserInputType == Enum.UserInputType.Touch
        local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
        if not isTap and not isMouse then return end
        if drag then return end

        local pt = Vector2.new(input.Position.X, input.Position.Y)
        if not IsDragZone(pt) then return end

        drag    = true
        touchRef = isTap and input or nil
        startTP  = pt
        startX   = self.X
        startY   = self.Y
        self:Focus()
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not drag then return end
        local isTap   = input.UserInputType == Enum.UserInputType.Touch
        local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
        if isTap and input ~= touchRef then return end
        if not isTap and not isMouse then return end

        local pt = Vector2.new(input.Position.X, input.Position.Y)
        local dx = pt.X - startTP.X
        local dy = pt.Y - startTP.Y
        local sv = workspace.CurrentCamera.ViewportSize
        self.X   = math.clamp(startX + dx, 0, sv.X - self.Width)
        self.Y   = math.clamp(startY + dy, 0, sv.Y - Style.TitleBarHeight)
        self.Frame.Position = UDim2.new(0, self.X, 0, self.Y)
    end)

    UserInputService.InputEnded:Connect(function(input)
        local isTap   = input.UserInputType == Enum.UserInputType.Touch
        local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
        if isTap and input == touchRef then drag = false; touchRef = nil
        elseif isMouse then drag = false end
    end)
end

-- ------------------------------------------------
-- Скролл
-- ------------------------------------------------
function Window:_SetupScroll()
    local scrolling = false
    local touchRef  = nil
    local lastY     = 0
    local velocity  = 0  -- инерция скролла

    self.Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            self.ScrollY = math.clamp(
                self.ScrollY - input.Position.Z * 30,
                0, math.max(0, self.MaxScrollY)
            )
        end
    end)

    self.ContentClip.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        if scrolling then return end
        scrolling = true
        touchRef  = input
        lastY     = input.Position.Y
        velocity  = 0
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not scrolling or input ~= touchRef then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        local dy  = lastY - input.Position.Y
        velocity  = dy
        lastY     = input.Position.Y
        self.ScrollY = math.clamp(
            self.ScrollY + dy,
            0, math.max(0, self.MaxScrollY)
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == touchRef then
            scrolling = false
            touchRef  = nil
            -- Инерция скролла
            task.spawn(function()
                while math.abs(velocity) > 0.5 do
                    velocity  = velocity * 0.88
                    self.ScrollY = math.clamp(
                        self.ScrollY + velocity,
                        0, math.max(0, self.MaxScrollY)
                    )
                    task.wait()
                end
            end)
        end
    end)
end

function Window:ToggleCollapse()
    self.Collapsed = not self.Collapsed
    if self.Collapsed then
        self.ContentClip.Visible = false
        self.ScrollTrack.Visible = false
        self.CollapseLbl.Text    = "▶"
        TweenService:Create(self.Frame,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.Width, 0, Style.TitleBarHeight)}
        ):Play()
    else
        self.ContentClip.Visible = true
        self.ScrollTrack.Visible = true
        self.CollapseLbl.Text    = "─"
        TweenService:Create(self.Frame,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.Width, 0, self.Height)}
        ):Play()
    end
end

function Window:Focus()
    local maxZ = 10
    for _, w in pairs(ImGui._state.Windows) do
        if w.ZIndex > maxZ then maxZ = w.ZIndex end
    end
    self.ZIndex = maxZ + 5
    self.Frame.ZIndex = self.ZIndex
    local function applyZ(obj, z)
        for _, c in ipairs(obj:GetChildren()) do
            if c:IsA("GuiObject") then
                c.ZIndex = z + 1
                applyZ(c, z+1)
            end
        end
    end
    applyZ(self.Frame, self.ZIndex)
end

function Window:_UpdateScrollbar()
    local clipH  = self.ContentClip.AbsoluteSize.Y
    local totalH = self.ContentHeight

    if totalH <= clipH then
        self.ScrollTrack.Visible = false
        self.MaxScrollY = 0
        self.ScrollY    = 0
    else
        self.ScrollTrack.Visible = true
        self.MaxScrollY = totalH - clipH
        self.ScrollY    = math.clamp(self.ScrollY, 0, self.MaxScrollY)

        local ratio   = math.clamp(clipH / totalH, 0.06, 1)
        local scrollT = self.MaxScrollY > 0 and (self.ScrollY / self.MaxScrollY) or 0
        self.ScrollGrab.Size     = UDim2.new(1, 0, ratio, 0)
        self.ScrollGrab.Position = UDim2.new(0, 0, scrollT * (1 - ratio), 0)
    end
    self.Content.Position = UDim2.new(0, 0, 0, -self.ScrollY)
end

function Window:_BeginFrame()
    self.CursorY      = Style.WindowPadding.Y
    self.ContentWidth = self.Width
                      - Style.WindowPadding.X * 2
                      - Style.ScrollbarSize - 4
    self.ContentHeight = Style.WindowPadding.Y
end

function Window:_EndFrame()
    self.ContentHeight = self.CursorY + Style.WindowPadding.Y
    self:_UpdateScrollbar()
end

function Window:_Next(h)
    local pos = UDim2.new(0, Style.WindowPadding.X, 0, self.CursorY)
    self.CursorY = self.CursorY + h + Style.ItemSpacing.Y
    return pos
end

function Window:_WS(id, def)
    if not self.WidgetStates[id] then
        self.WidgetStates[id] = def or {}
    end
    return self.WidgetStates[id]
end

-- ================================================
-- ВИДЖЕТЫ
-- ================================================

-- ------------------------------------------------
-- TEXT
-- ------------------------------------------------
function Window:Text(text, color)
    if not self.Visible or self.Collapsed then return end
    local id = "t_" .. text
    local s  = self:_WS(id, {})
    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Alpha=1, Z=self.ZIndex+1})
        s.l = MkLabel(s.f, {
            Text=text, Color=color or Theme.Text,
            FS=Style.FontSize, Z=self.ZIndex+2, Wrap=true,
        })
    end
    local h = Style.FontSize + 4
    s.f.Position = self:_Next(h)
    s.f.Size     = UDim2.new(0, self.ContentWidth, 0, h)
    s.l.Text     = text
    s.l.TextColor3 = color or Theme.Text
    s.f.Visible  = true
end

function Window:TextColored(t, c) self:Text(t, c) end

function Window:Separator()
    if not self.Visible or self.Collapsed then return end
    local id = "sp_" .. math.floor(self.CursorY)
    local s  = self:_WS(id, {})
    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Color=Theme.Separator, Z=self.ZIndex+1})
    end
    s.f.Position = self:_Next(1)
    s.f.Size     = UDim2.new(0, self.ContentWidth, 0, 1)
    s.f.Visible  = true
end

function Window:Spacing(h)
    if not self.Visible or self.Collapsed then return end
    self.CursorY = self.CursorY + (h or Style.ItemSpacing.Y)
end

-- ------------------------------------------------
-- BUTTON — Frame + глобальный реестр
-- ------------------------------------------------
function Window:Button(label, w, h)
    if not self.Visible or self.Collapsed then return false end

    local id = "b_" .. label
    local s  = self:_WS(id, {clicked=false, registered=false})
    local bw = w or self.ContentWidth
    local bh = h or Style.ItemHeight

    if not s.f then
        -- Используем Frame а не TextButton
        s.f = MkFrame(self.Content, {
            Name  = id,
            Color = Theme.Button,
            Z     = self.ZIndex + 1,
        })
        MkCorner(s.f, 5)
        MkStroke(s.f, Theme.WindowBorder, 1)

        s.lbl = MkLabel(s.f, {
            Text  = label,
            Color = Theme.ButtonText,
            FS    = Style.FontSize,
            AX    = Enum.TextXAlignment.Center,
            Z     = self.ZIndex + 2,
        })

        -- Регистрируем в глобальном реестре
        RegisterButton(
            s.f,
            function() -- onClick
                s.clicked = true
            end,
            function() -- onDown — нажато
                s.f.BackgroundColor3 = Theme.ButtonActive
            end,
            function() -- onUp — отпущено
                s.f.BackgroundColor3 = Theme.Button
            end
        )
    end

    s.f.Position = self:_Next(bh)
    s.f.Size     = UDim2.new(0, bw, 0, bh)
    s.lbl.Text   = label
    s.f.Visible  = true

    local clicked = s.clicked
    s.clicked = false
    return clicked
end

-- ------------------------------------------------
-- CHECKBOX
-- ------------------------------------------------
function Window:Checkbox(label, value)
    if not self.Visible or self.Collapsed then return value end

    local id = "c_" .. label
    local s  = self:_WS(id, {value = value or false})
    if value ~= nil then s.value = value end

    local sz = Style.CheckboxSize
    local h  = math.max(sz, Style.ItemHeight)

    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Alpha=1, Z=self.ZIndex+1})

        -- Кликабельный фрейм на всю строку
        s.hit = MkFrame(s.f, {
            Name  = "Hit",
            Alpha = 1,
            Z     = self.ZIndex + 4,
        })

        s.box = MkFrame(s.f, {
            Name  = "Box",
            Pos   = UDim2.new(0, 0, 0.5, -sz/2),
            Size  = UDim2.new(0, sz, 0, sz),
            Color = Theme.CheckBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.box, 4)
        MkStroke(s.box, Theme.CheckBorder, 1)

        s.mark = MkLabel(s.box, {
            Text  = "✓",
            Color = Theme.CheckMark,
            FS    = sz - 4,
            AX    = Enum.TextXAlignment.Center,
            AY    = Enum.TextYAlignment.Center,
            Z     = self.ZIndex + 3,
        })

        MkLabel(s.f, {
            Text = label,
            Color = Theme.Text,
            FS   = Style.FontSize,
            Pos  = UDim2.new(0, sz + Style.ItemSpacing.X + 4, 0, 0),
            Size = UDim2.new(1, -(sz + Style.ItemSpacing.X + 4), 1, 0),
            Z    = self.ZIndex + 2,
        })

        RegisterButton(
            s.hit,
            function() -- onClick
                s.value = not s.value
                s.mark.Visible = s.value
            end,
            function() -- onDown
                s.box.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
            end,
            function() -- onUp
                s.box.BackgroundColor3 = Theme.CheckBg
            end
        )
    end

    s.mark.Visible = s.value

    local pos = self:_Next(h)
    s.f.Position   = pos
    s.f.Size       = UDim2.new(0, self.ContentWidth, 0, h)
    s.hit.Size     = UDim2.new(1, 0, 1, 0)
    s.hit.Position = UDim2.new(0, 0, 0, 0)
    s.f.Visible    = true

    return s.value
end

-- ------------------------------------------------
-- SLIDER
-- ------------------------------------------------
function Window:Slider(label, value, minV, maxV, fmt)
    if not self.Visible or self.Collapsed then return value end

    local id = "s_" .. label
    local s  = self:_WS(id, {value=value or 0, drag=false, touchRef=nil})

    minV = minV or 0
    maxV = maxV or 1
    fmt  = fmt  or "%.1f"
    if value ~= nil then
        s.value = math.clamp(value, minV, maxV)
    end

    local lh     = Style.FontSize + 2
    local totalH = lh + Style.SliderHeight + Style.ItemSpacing.Y

    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Alpha=1, Z=self.ZIndex+1})

        s.lbl = MkLabel(s.f, {
            Text = label, Color=Theme.Text, FS=Style.FontSize,
            Pos  = UDim2.new(0,0,0,0),
            Size = UDim2.new(1,0,0,lh),
            Z    = self.ZIndex + 2,
        })

        s.track = MkFrame(s.f, {
            Name  = "Tr",
            Pos   = UDim2.new(0,0,0, lh + Style.ItemSpacing.Y),
            Size  = UDim2.new(1,0,0, Style.SliderHeight),
            Color = Theme.SliderBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.track, 5)
        MkStroke(s.track, Theme.SliderBorder, 1)

        s.fill = MkFrame(s.track, {
            Name  = "Fill",
            Color = Theme.SliderFill,
            Z     = self.ZIndex + 3,
        })
        MkCorner(s.fill, 5)

        s.grab = MkFrame(s.track, {
            Name  = "Grab",
            Color = Theme.SliderGrab,
            Z     = self.ZIndex + 4,
        })
        MkCorner(s.grab, Style.SliderGrabW/2)

        s.valLbl = MkLabel(s.track, {
            Text  = "",
            Color = Theme.Text,
            FS    = Style.FontSize - 1,
            AX    = Enum.TextXAlignment.Center,
            Z     = self.ZIndex + 5,
        })

        -- Функция применения позиции
        local function ApplyX(px)
            if not s.track or not s.track.Parent then return end
            local tp  = s.track.AbsolutePosition
            local tsz = s.track.AbsoluteSize
            if tsz.X == 0 then return end
            local rel  = math.clamp((px - tp.X) / tsz.X, 0, 1)
            s.value    = minV + rel * (maxV - minV)
        end

        -- Трек обрабатывается через глобальный реестр
        RegisterButton(
            s.track,
            nil,  -- onClick не нужен
            function() -- onDown — начало drag
                s.drag = true
                local pt = ActiveTouch
                    and Vector2.new(ActiveTouch.Position.X, ActiveTouch.Position.Y)
                    or  UserInputService:GetMouseLocation()
                ApplyX(pt.X)
            end,
            function() -- onUp
                s.drag = false
                s.touchRef = nil
            end
        )

        -- Движение слайдера (глобально)
        UserInputService.InputChanged:Connect(function(input)
            if not s.drag then return end
            local isTap   = input.UserInputType == Enum.UserInputType.Touch
            local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
            if not isTap and not isMouse then return end
            ApplyX(input.Position.X)
        end)

        UserInputService.InputEnded:Connect(function(input)
            local isTap   = input.UserInputType == Enum.UserInputType.Touch
            local isMouse = input.UserInputType == Enum.UserInputType.MouseButton1
            if isTap or isMouse then
                s.drag     = false
                s.touchRef = nil
            end
        end)
    end

    -- Обновляем визуал
    local t   = (maxV ~= minV) and ((s.value - minV) / (maxV - minV)) or 0
    local gw  = Style.SliderGrabW
    local gh  = Style.SliderHeight - 4

    s.fill.Size     = UDim2.new(t, 0, 1, 0)
    s.grab.Size     = UDim2.new(0, gw, 0, gh)
    s.grab.Position = UDim2.new(t, -gw/2, 0.5, -gh/2)
    s.valLbl.Text   = string.format(fmt, s.value)
    s.lbl.Text      = label

    local pos = self:_Next(totalH)
    s.f.Position = pos
    s.f.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.f.Visible  = true

    return s.value
end

-- ------------------------------------------------
-- INPUT TEXT
-- ------------------------------------------------
function Window:InputText(label, value, placeholder)
    if not self.Visible or self.Collapsed then return value end

    local id = "i_" .. label
    local s  = self:_WS(id, {value=value or "", focused=false})
    if value ~= nil and not s.focused then s.value = value end

    local lh     = Style.FontSize + 2
    local totalH = lh + Style.ItemHeight + Style.ItemSpacing.Y

    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Alpha=1, Z=self.ZIndex+1})
        s.lbl = MkLabel(s.f, {
            Text=label, Color=Theme.Text, FS=Style.FontSize,
            Pos=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,lh),
            Z=self.ZIndex+2,
        })
        s.box = MkFrame(s.f, {
            Name  = "Box",
            Pos   = UDim2.new(0,0,0, lh + Style.ItemSpacing.Y),
            Size  = UDim2.new(1,0,0, Style.ItemHeight),
            Color = Theme.InputBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.box, 5)
        s.stroke = MkStroke(s.box, Theme.InputBorder, 1)

        local tb = Instance.new("TextBox")
        tb.BackgroundTransparency = 1
        tb.Text             = s.value
        tb.PlaceholderText  = placeholder or ""
        tb.PlaceholderColor3 = Theme.TextDisabled
        tb.TextColor3       = Theme.InputText
        tb.TextSize         = Style.FontSize
        tb.Font             = Enum.Font.Gotham
        tb.TextXAlignment   = Enum.TextXAlignment.Left
        tb.Size             = UDim2.new(1, -Style.FramePadding.X*2, 1, 0)
        tb.Position         = UDim2.new(0, Style.FramePadding.X, 0, 0)
        tb.ZIndex           = self.ZIndex + 3
        tb.ClearTextOnFocus = false
        tb.Parent           = s.box

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
    s.lbl.Text = label
    s.tb.PlaceholderText = placeholder or ""

    local pos = self:_Next(totalH)
    s.f.Position = pos
    s.f.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.f.Visible  = true

    return s.value
end

-- ------------------------------------------------
-- COMBO
-- ------------------------------------------------
function Window:Combo(label, selIdx, items)
    if not self.Visible or self.Collapsed then return selIdx end

    local id = "cm_" .. label
    local s  = self:_WS(id, {selIdx=selIdx or 1, open=false})
    if selIdx ~= nil then s.selIdx = selIdx end
    items = items or {}

    local lh     = Style.FontSize + 2
    local totalH = lh + Style.ItemHeight + Style.ItemSpacing.Y

    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Alpha=1, Z=self.ZIndex+1})
        s.lbl = MkLabel(s.f, {
            Text=label, Color=Theme.Text, FS=Style.FontSize,
            Pos=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,0,lh),
            Z=self.ZIndex+2,
        })

        -- Кнопка открытия combo
        s.btn = MkFrame(s.f, {
            Name  = "Btn",
            Color = Theme.InputBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.btn, 5)
        MkStroke(s.btn, Theme.InputBorder, 1)

        s.selText = MkLabel(s.btn, {
            Text  = items[s.selIdx] or "",
            Color = Theme.Text,
            FS    = Style.FontSize,
            Pos   = UDim2.new(0, Style.FramePadding.X, 0, 0),
            Size  = UDim2.new(1, -Style.ItemHeight, 1, 0),
            Z     = self.ZIndex + 3,
        })
        s.arrow = MkLabel(s.btn, {
            Text  = "▼",
            Color = Theme.TextDisabled,
            FS    = Style.FontSize,
            Pos   = UDim2.new(1, -Style.ItemHeight, 0, 0),
            Size  = UDim2.new(0, Style.ItemHeight, 1, 0),
            AX    = Enum.TextXAlignment.Center,
            Z     = self.ZIndex + 3,
        })

        -- Дропдаун
        s.drop = MkFrame(Root, {
            Name  = id .. "_d",
            Color = Theme.ComboBg,
            Z     = 200,
        })
        s.drop.Visible = false
        MkCorner(s.drop, 5)
        MkStroke(s.drop, Theme.WindowBorder, 1)

        local function Rebuild()
            for _, c in ipairs(s.drop:GetChildren()) do
                if c:IsA("Frame") then
                    UnregisterButton(c)
                    c:Destroy()
                end
            end

            local iH    = Style.ItemHeight + 2
            local dropH = #items * iH + 6
            local bPos  = s.btn.AbsolutePosition
            local bSz   = s.btn.AbsoluteSize
            local svH   = workspace.CurrentCamera.ViewportSize.Y
            local openUp = (bPos.Y + bSz.Y + dropH) > svH

            s.drop.Size     = UDim2.new(0, bSz.X, 0, dropH)
            s.drop.Position = openUp
                and UDim2.new(0, bPos.X, 0, bPos.Y - dropH - 2)
                or  UDim2.new(0, bPos.X, 0, bPos.Y + bSz.Y + 2)

            for i, item in ipairs(items) do
                local isBg = i == s.selIdx
                local itm  = MkFrame(s.drop, {
                    Pos   = UDim2.new(0, 3, 0, (i-1)*iH + 3),
                    Size  = UDim2.new(1, -6, 0, iH),
                    Color = isBg and Theme.ComboItemHover or Theme.ComboItem,
                    Alpha = isBg and 0 or 0.4,
                    Z     = 201,
                })
                MkCorner(itm, 4)
                MkLabel(itm, {
                    Text = item, Color=Theme.ComboText, FS=Style.FontSize,
                    Pos  = UDim2.new(0, Style.FramePadding.X, 0, 0),
                    Size = UDim2.new(1,0,1,0),
                    Z    = 202,
                })

                local ci = i
                RegisterButton(
                    itm,
                    function() -- onClick
                        s.selIdx       = ci
                        s.selText.Text = items[ci] or ""
                        s.open         = false
                        s.drop.Visible = false
                        s.arrow.Text   = "▼"
                    end,
                    function() -- onDown
                        itm.BackgroundColor3       = Theme.ComboItemHover
                        itm.BackgroundTransparency = 0
                    end,
                    function() -- onUp
                        if ci ~= s.selIdx then
                            itm.BackgroundColor3       = Theme.ComboItem
                            itm.BackgroundTransparency = 0.4
                        end
                    end
                )
            end
        end

        RegisterButton(
            s.btn,
            function() -- onClick
                s.open = not s.open
                s.drop.Visible = s.open
                s.arrow.Text   = s.open and "▲" or "▼"
                if s.open then Rebuild() end
            end,
            function() s.btn.BackgroundColor3 = Theme.ComboItemHover end,
            function() s.btn.BackgroundColor3 = Theme.InputBg end
        )
    end

    s.selText.Text = items[s.selIdx] or ""
    s.lbl.Text     = label

    local pos  = self:_Next(totalH)
    s.f.Position  = pos
    s.f.Size      = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.btn.Position = UDim2.new(0,0,0, lh + Style.ItemSpacing.Y)
    s.btn.Size     = UDim2.new(1,0,0, Style.ItemHeight)
    s.f.Visible   = true

    return s.selIdx
end

-- ------------------------------------------------
-- PROGRESS BAR
-- ------------------------------------------------
function Window:ProgressBar(label, value, minV, maxV, showPct)
    if not self.Visible or self.Collapsed then return end

    local id = "p_" .. label
    local s  = self:_WS(id, {})
    minV    = minV    or 0
    maxV    = maxV    or 1
    showPct = showPct ~= false
    value   = math.clamp(value or 0, minV, maxV)

    local hidden = label == "" or label:sub(1,2) == "##"
    local lh     = hidden and 0 or (Style.FontSize + 2)
    local totalH = lh + Style.SliderHeight + (lh > 0 and Style.ItemSpacing.Y or 0)

    if not s.f then
        s.f = MkFrame(self.Content, {Name=id, Alpha=1, Z=self.ZIndex+1})
        s.lbl = MkLabel(s.f, {
            Text=label, Color=Theme.Text, FS=Style.FontSize,
            Pos=UDim2.new(0,0,0,0),
            Size=UDim2.new(1,0,0, math.max(lh,1)),
            Z=self.ZIndex+2,
        })
        s.bg = MkFrame(s.f, {
            Name  = "BG",
            Pos   = UDim2.new(0,0,0, lh > 0 and lh + Style.ItemSpacing.Y or 0),
            Size  = UDim2.new(1,0,0, Style.SliderHeight),
            Color = Theme.ProgressBg,
            Z     = self.ZIndex + 2,
        })
        MkCorner(s.bg, 5)
        MkStroke(s.bg, Theme.ProgressBorder, 1)
        s.fill = MkFrame(s.bg, {
            Name="Fill", Color=Theme.ProgressFill, Z=self.ZIndex+3,
        })
        MkCorner(s.fill, 5)
        s.pct = MkLabel(s.bg, {
            Color=Theme.Text, FS=Style.FontSize-1,
            AX=Enum.TextXAlignment.Center, Z=self.ZIndex+4,
        })
    end

    local t = (maxV ~= minV) and ((value - minV)/(maxV - minV)) or 0
    s.fill.Size   = UDim2.new(math.clamp(t,0,1), 0, 1, 0)
    s.lbl.Text    = hidden and "" or label
    s.lbl.Visible = not hidden
    s.pct.Text    = showPct and string.format("%d%%", math.floor(t*100)) or ""

    local pos = self:_Next(totalH)
    s.f.Position = pos
    s.f.Size     = UDim2.new(0, self.ContentWidth, 0, totalH)
    s.f.Visible  = true
end

-- ================================================
-- СОСТОЯНИЕ ImGui
-- ================================================
ImGui._state = {Windows = {}}

-- ================================================
-- PUBLIC API
-- ================================================
function ImGui.Begin(title, cfg)
    if not ImGui._state.Windows[title] then
        ImGui._state.Windows[title] = Window.new(title, cfg)
    end
    local win = ImGui._state.Windows[title]
    ImGui._state.current = win

    if cfg and cfg.Visible ~= nil then
        win.Visible       = cfg.Visible
        win.Frame.Visible = cfg.Visible
    end

    if win.Visible then
        win.Frame.Visible = true
        win:_BeginFrame()
    end
    return win.Visible
end

function ImGui.End()
    local win = ImGui._state.current
    if win and win.Visible then win:_EndFrame() end
    ImGui._state.current = nil
end

function ImGui.SetWindowVisible(title, v)
    local w = ImGui._state.Windows[title]
    if w then w.Visible = v; w.Frame.Visible = v end
end

function ImGui.Text(t,c)       local w=ImGui._state.current; if w then w:Text(t,c) end end
function ImGui.TextColored(t,c) local w=ImGui._state.current; if w then w:TextColored(t,c) end end
function ImGui.Separator()     local w=ImGui._state.current; if w then w:Separator() end end
function ImGui.Spacing(h)      local w=ImGui._state.current; if w then w:Spacing(h) end end

function ImGui.Button(l,w2,h)
    local w=ImGui._state.current; if w then return w:Button(l,w2,h) end; return false
end
function ImGui.Checkbox(l,v)
    local w=ImGui._state.current; if w then return w:Checkbox(l,v) end; return v
end
function ImGui.Slider(l,v,mn,mx,f)
    local w=ImGui._state.current; if w then return w:Slider(l,v,mn,mx,f) end; return v
end
function ImGui.InputText(l,v,p)
    local w=ImGui._state.current; if w then return w:InputText(l,v,p) end; return v
end
function ImGui.Combo(l,i,items)
    local w=ImGui._state.current; if w then return w:Combo(l,i,items) end; return i
end
function ImGui.ProgressBar(l,v,mn,mx,s)
    local w=ImGui._state.current; if w then w:ProgressBar(l,v,mn,mx,s) end
end

function ImGui.Destroy()
    for _,w in pairs(ImGui._state.Windows) do
        if w.Frame then w.Frame:Destroy() end
    end
    ImGui._state.Windows = {}
    ButtonRegistry = {}
    if ScreenGui then ScreenGui:Destroy() end
end

ImGui.Theme    = Theme
ImGui.Style    = Style
ImGui.IsMobile = IsMobile

return ImGui
