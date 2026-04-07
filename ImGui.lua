-- ================================================
-- ImGui библиотека для Roblox
-- Имитирует стиль Dear ImGui для игрового UI
-- ================================================

local ImGui = {}

-- ================================================
-- СЕРВИСЫ
-- ================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ================================================
-- КОНСТАНТЫ И ТЕМА (Тёмная тема в стиле ImGui)
-- ================================================
local Theme = {
    -- Основные цвета окна
    WindowBg         = Color3.fromRGB(15, 15, 15),
    WindowBorder     = Color3.fromRGB(110, 110, 128),
    
    -- Заголовок окна
    TitleBg          = Color3.fromRGB(10, 10, 10),
    TitleBgActive    = Color3.fromRGB(41, 74, 122),
    TitleText        = Color3.fromRGB(255, 255, 255),
    
    -- Текст
    Text             = Color3.fromRGB(255, 255, 255),
    TextDisabled     = Color3.fromRGB(128, 128, 128),
    
    -- Кнопки
    Button           = Color3.fromRGB(66, 66, 66),
    ButtonHovered    = Color3.fromRGB(86, 86, 86),
    ButtonActive     = Color3.fromRGB(41, 74, 122),
    ButtonText       = Color3.fromRGB(255, 255, 255),
    
    -- Чекбокс
    CheckMark        = Color3.fromRGB(66, 150, 250),
    CheckBg          = Color3.fromRGB(32, 32, 32),
    CheckBorder      = Color3.fromRGB(110, 110, 128),
    
    -- Слайдер
    SliderBg         = Color3.fromRGB(32, 32, 32),
    SliderFill       = Color3.fromRGB(66, 150, 250),
    SliderGrab       = Color3.fromRGB(66, 150, 250),
    SliderBorder     = Color3.fromRGB(110, 110, 128),
    
    -- Поле ввода
    InputBg          = Color3.fromRGB(32, 32, 32),
    InputBorder      = Color3.fromRGB(110, 110, 128),
    InputBorderFocus = Color3.fromRGB(66, 150, 250),
    InputText        = Color3.fromRGB(255, 255, 255),
    
    -- Выпадающий список
    ComboBg          = Color3.fromRGB(20, 20, 20),
    ComboItem        = Color3.fromRGB(32, 32, 32),
    ComboItemHover   = Color3.fromRGB(66, 150, 250),
    ComboText        = Color3.fromRGB(255, 255, 255),
    
    -- Прогресс-бар
    ProgressBg       = Color3.fromRGB(32, 32, 32),
    ProgressFill     = Color3.fromRGB(66, 150, 250),
    ProgressBorder   = Color3.fromRGB(110, 110, 128),
    
    -- Разделитель
    Separator        = Color3.fromRGB(110, 110, 128),
    
    -- Скроллбар
    ScrollbarBg      = Color3.fromRGB(5, 5, 5),
    ScrollbarGrab    = Color3.fromRGB(79, 79, 79),
}

-- Настройки стиля
local Style = {
    WindowPadding     = Vector2.new(8, 8),     -- Отступ внутри окна
    WindowRounding    = 6,                      -- Скругление окна
    WindowBorderSize  = 1,                      -- Размер рамки
    TitleBarHeight    = 28,                     -- Высота заголовка
    ItemSpacing       = Vector2.new(8, 6),      -- Отступ между элементами
    ItemHeight        = 24,                     -- Стандартная высота элемента
    FramePadding      = Vector2.new(6, 4),      -- Отступ рамки элемента
    CheckboxSize      = 18,                     -- Размер чекбокса
    SliderHeight      = 18,                     -- Высота слайдера
    ScrollbarSize     = 8,                      -- Ширина скроллбара
    FontSize          = 14,                     -- Размер шрифта
    IndentSpacing     = 16,                     -- Отступ вложенности
}

-- ================================================
-- OBJECT POOL (Пул объектов для оптимизации)
-- Переиспользует GUI элементы вместо удаления
-- ================================================
local ObjectPool = {}
ObjectPool.__index = ObjectPool

function ObjectPool.new()
    local self = setmetatable({}, ObjectPool)
    self._pools = {}      -- Хранилище пулов по типу
    self._active = {}     -- Активные объекты
    return self
end

-- Получить объект из пула или создать новый
function ObjectPool:Acquire(className, parent)
    local pool = self._pools[className]
    
    if pool and #pool > 0 then
        -- Достаём объект из пула
        local obj = table.remove(pool, #pool)
        obj.Parent = parent
        obj.Visible = true
        return obj
    else
        -- Создаём новый объект
        local obj = Instance.new(className)
        obj.Parent = parent
        table.insert(self._active, obj)
        return obj
    end
end

-- Вернуть объект в пул (не удаляем, а прячем)
function ObjectPool:Release(obj)
    if not obj or not obj.Parent then return end
    
    local className = obj.ClassName
    
    -- Инициализируем пул для данного типа если нет
    if not self._pools[className] then
        self._pools[className] = {}
    end
    
    -- Сбрасываем объект и убираем из отображения
    obj.Visible = false
    obj.Parent = nil
    table.insert(self._pools[className], obj)
end

-- Освободить все объекты данного контейнера
function ObjectPool:ReleaseChildren(container, className)
    local children = container:GetChildren()
    for _, child in ipairs(children) do
        if child.ClassName == className then
            self:Release(child)
        end
    end
end

-- Очистить весь пул
function ObjectPool:Destroy()
    for className, pool in pairs(self._pools) do
        for _, obj in ipairs(pool) do
            if obj and obj.Parent ~= nil then
                obj:Destroy()
            end
        end
    end
    self._pools = {}
    self._active = {}
end

-- ================================================
-- СОСТОЯНИЕ БИБЛИОТЕКИ
-- ================================================
local State = {
    Windows       = {},           -- Все зарегистрированные окна
    CurrentWindow = nil,          -- Текущее обрабатываемое окно
    HoveredWindow = nil,          -- Окно под курсором
    ActiveWindow  = nil,          -- Активное (фокусное) окно
    
    -- Состояние перетаскивания
    Drag = {
        Active     = false,
        Window     = nil,
        Offset     = Vector2.new(0, 0),
    },
    
    -- Состояние мыши
    Mouse = {
        Position = Vector2.new(0, 0),
        Delta    = Vector2.new(0, 0),
        Pressed  = false,
        Released = false,
        Down     = false,
    },
    
    -- Уникальные ID для элементов
    IDCounter = 0,
    
    -- Стек ID (для иерархии)
    IDStack = {},
}

-- Глобальный пул объектов
local Pool = ObjectPool.new()

-- ================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ================================================

-- Генерация уникального ID
local function GenerateID(label)
    State.IDCounter = State.IDCounter + 1
    return label .. "_" .. State.IDCounter
end

-- Создание рамки/контейнера с тёмным фоном
local function CreateFrame(parent, props)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = props.Transparency or 0
    frame.BackgroundColor3 = props.Color or Theme.WindowBg
    frame.BorderSizePixel = 0
    frame.Position = props.Position or UDim2.new(0, 0, 0, 0)
    frame.Size = props.Size or UDim2.new(1, 0, 0, 24)
    frame.ZIndex = props.ZIndex or 1
    frame.Name = props.Name or "Frame"
    frame.ClipsDescendants = props.Clips or false
    frame.Parent = parent
    return frame
end

-- Создание текстовой метки
local function CreateLabel(parent, props)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = props.Text or ""
    label.TextColor3 = props.Color or Theme.Text
    label.TextSize = props.Size or Style.FontSize
    label.Font = Enum.Font.Code
    label.TextXAlignment = props.AlignX or Enum.TextXAlignment.Left
    label.TextYAlignment = props.AlignY or Enum.TextYAlignment.Center
    label.TextWrapped = props.Wrap or false
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.Size = props.Size2 or UDim2.new(1, 0, 1, 0)
    label.ZIndex = props.ZIndex or 2
    label.Name = props.Name or "Label"
    label.Parent = parent
    return label
end

-- Скругление углов через UICorner
local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or Style.WindowRounding)
    corner.Parent = parent
    return corner
end

-- Добавление обводки через UIStroke
local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.WindowBorder
    stroke.Thickness = thickness or Style.WindowBorderSize
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Проверка попадания мышки в объект
local function IsMouseOver(guiObject)
    local mouse = State.Mouse.Position
    local pos = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    
    return mouse.X >= pos.X and mouse.X <= pos.X + size.X
        and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y
end

-- Форматирование числа для отображения
local function FormatNumber(value, decimals)
    decimals = decimals or 1
    return string.format("%." .. decimals .. "f", value)
end

-- ================================================
-- ИНИЦИАЛИЗАЦИЯ GUI КОНТЕЙНЕРА
-- ================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ImGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- Главный контейнер для всех окон
local MainContainer = Instance.new("Frame")
MainContainer.Name = "MainContainer"
MainContainer.BackgroundTransparency = 1
MainContainer.Size = UDim2.new(1, 0, 1, 0)
MainContainer.Position = UDim2.new(0, 0, 0, 0)
MainContainer.ZIndex = 1
MainContainer.Parent = ScreenGui

-- ================================================
-- СТРУКТУРА ОКНА
-- ================================================
local Window = {}
Window.__index = Window

function Window.new(title, config)
    local self = setmetatable({}, Window)
    
    config = config or {}
    
    -- Основные свойства окна
    self.Title    = title
    self.ID       = title .. "_window"
    self.Visible  = config.Visible ~= false
    self.Width    = config.Width  or 300
    self.Height   = config.Height or 400
    self.MinWidth = config.MinWidth  or 150
    self.MinHeight = config.MinHeight or 100
    self.X        = config.X or 100
    self.Y        = config.Y or 100
    
    -- Состояние окна
    self.Collapsed  = false    -- Свёрнуто ли окно
    self.Focused    = false    -- В фокусе ли окно
    self.ZIndex     = 10       -- Порядок отрисовки
    
    -- Внутренний курсор для размещения виджетов
    self.CursorY    = 0        -- Текущая Y позиция виджета
    self.ContentWidth = 0      -- Доступная ширина для контента
    
    -- Скролл
    self.ScrollY    = 0        -- Текущий скролл
    self.MaxScrollY = 0        -- Максимальный скролл
    self.ContentHeight = 0     -- Полная высота контента
    
    -- Хранилище состояний виджетов
    self.WidgetStates = {}
    
    -- Список виджетов текущего фрейма
    self.Widgets = {}
    
    -- GUI элементы
    self:_CreateGUI()
    
    return self
end

-- Создание GUI элементов окна
function Window:_CreateGUI()
    -- Основной фрейм окна
    self.Frame = CreateFrame(MainContainer, {
        Name = self.ID,
        Position = UDim2.new(0, self.X, 0, self.Y),
        Size = UDim2.new(0, self.Width, 0, self.Height),
        Color = Theme.WindowBg,
        ZIndex = self.ZIndex,
    })
    AddCorner(self.Frame, Style.WindowRounding)
    AddStroke(self.Frame, Theme.WindowBorder, Style.WindowBorderSize)
    
    -- Тень под окном (для глубины)
    local shadow = CreateFrame(self.Frame, {
        Name = "Shadow",
        Position = UDim2.new(0, 4, 0, 4),
        Size = UDim2.new(1, 0, 1, 0),
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.7,
        ZIndex = self.ZIndex - 1,
    })
    AddCorner(shadow, Style.WindowRounding)
    
    -- Заголовок окна
    self.TitleBar = CreateFrame(self.Frame, {
        Name = "TitleBar",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, Style.TitleBarHeight),
        Color = Theme.TitleBgActive,
        ZIndex = self.ZIndex + 1,
    })
    
    -- Скругляем только верхние углы заголовка
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, Style.WindowRounding)
    titleCorner.Parent = self.TitleBar
    
    -- Прямоугольник чтобы скрыть нижние скруглённые углы тайтла
    local titleBottom = CreateFrame(self.Frame, {
        Name = "TitleBottom",
        Position = UDim2.new(0, 0, 0, Style.TitleBarHeight - Style.WindowRounding),
        Size = UDim2.new(1, 0, 0, Style.WindowRounding),
        Color = Theme.TitleBgActive,
        ZIndex = self.ZIndex + 1,
    })
    
    -- Текст заголовка
    self.TitleText = CreateLabel(self.TitleBar, {
        Name = "TitleText",
        Text = self.Title,
        Color = Theme.TitleText,
        Size = Style.FontSize,
        Position = UDim2.new(0, Style.WindowPadding.X, 0, 0),
        Size2 = UDim2.new(1, -50, 1, 0),
        ZIndex = self.ZIndex + 2,
    })
    
    -- Кнопка сворачивания [_]
    self.CollapseBtn = Instance.new("TextButton")
    self.CollapseBtn.Name = "CollapseBtn"
    self.CollapseBtn.BackgroundTransparency = 1
    self.CollapseBtn.Text = "─"
    self.CollapseBtn.TextColor3 = Theme.TitleText
    self.CollapseBtn.TextSize = Style.FontSize
    self.CollapseBtn.Font = Enum.Font.Code
    self.CollapseBtn.Size = UDim2.new(0, 22, 0, 22)
    self.CollapseBtn.Position = UDim2.new(1, -48, 0.5, -11)
    self.CollapseBtn.ZIndex = self.ZIndex + 3
    self.CollapseBtn.Parent = self.TitleBar
    
    -- Кнопка закрытия [X]
    self.CloseBtn = Instance.new("TextButton")
    self.CloseBtn.Name = "CloseBtn"
    self.CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    self.CloseBtn.BackgroundTransparency = 0.3
    self.CloseBtn.Text = "✕"
    self.CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.CloseBtn.TextSize = 12
    self.CloseBtn.Font = Enum.Font.Code
    self.CloseBtn.Size = UDim2.new(0, 18, 0, 18)
    self.CloseBtn.Position = UDim2.new(1, -24, 0.5, -9)
    self.CloseBtn.ZIndex = self.ZIndex + 3
    self.CloseBtn.Parent = self.TitleBar
    AddCorner(self.CloseBtn, 4)
    
    -- Область контента (со скроллом)
    self.ContentClip = CreateFrame(self.Frame, {
        Name = "ContentClip",
        Position = UDim2.new(0, 0, 0, Style.TitleBarHeight),
        Size = UDim2.new(1, 0, 1, -Style.TitleBarHeight),
        Color = Theme.WindowBg,
        Transparency = 1,
        ZIndex = self.ZIndex,
        Clips = true,    -- Обрезаем содержимое по границам
    })
    
    -- Контейнер для виджетов
    self.Content = CreateFrame(self.ContentClip, {
        Name = "Content",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        Color = Theme.WindowBg,
        Transparency = 1,
        ZIndex = self.ZIndex,
    })
    
    -- Скроллбар (вертикальный)
    self.ScrollbarTrack = CreateFrame(self.Frame, {
        Name = "ScrollbarTrack",
        Position = UDim2.new(1, -(Style.ScrollbarSize + 2), 0, Style.TitleBarHeight + 2),
        Size = UDim2.new(0, Style.ScrollbarSize, 1, -(Style.TitleBarHeight + 4)),
        Color = Theme.ScrollbarBg,
        ZIndex = self.ZIndex + 2,
    })
    AddCorner(self.ScrollbarTrack, 4)
    
    self.ScrollbarGrab = CreateFrame(self.ScrollbarTrack, {
        Name = "ScrollbarGrab",
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        Color = Theme.ScrollbarGrab,
        ZIndex = self.ZIndex + 3,
    })
    AddCorner(self.ScrollbarGrab, 4)
    
    -- Подключаем кнопки
    self.CloseBtn.MouseButton1Click:Connect(function()
        self.Visible = false
        self.Frame.Visible = false
    end)
    
    self.CollapseBtn.MouseButton1Click:Connect(function()
        self:ToggleCollapse()
    end)
    
    -- Эффект наведения на кнопку закрытия
    self.CloseBtn.MouseEnter:Connect(function()
        self.CloseBtn.BackgroundTransparency = 0
    end)
    self.CloseBtn.MouseLeave:Connect(function()
        self.CloseBtn.BackgroundTransparency = 0.3
    end)
    
    -- Настройка перетаскивания
    self:_SetupDragging()
    
    -- Устанавливаем начальную видимость
    self.Frame.Visible = self.Visible
end

-- Настройка перетаскивания окна
function Window:_SetupDragging()
    -- Начало перетаскивания по нажатию на заголовок
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Игнорируем клики по кнопкам
            if not IsMouseOver(self.CloseBtn) and not IsMouseOver(self.CollapseBtn) then
                State.Drag.Active = true
                State.Drag.Window = self
                
                -- Вычисляем смещение мыши от позиции окна
                local framePos = self.Frame.AbsolutePosition
                State.Drag.Offset = Vector2.new(
                    State.Mouse.Position.X - framePos.X,
                    State.Mouse.Position.Y - framePos.Y
                )
                
                -- Выводим окно на передний план
                self:Focus()
            end
        end
    end)
    
    -- Конец перетаскивания
    self.TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if State.Drag.Window == self then
                State.Drag.Active = false
                State.Drag.Window = nil
            end
        end
    end)
end

-- Сворачивание/разворачивание окна
function Window:ToggleCollapse()
    self.Collapsed = not self.Collapsed
    
    if self.Collapsed then
        -- Скрываем контент
        self.ContentClip.Visible = false
        self.ScrollbarTrack.Visible = false
        self.CollapseBtn.Text = "▶"
        
        -- Анимация сворачивания
        local tween = TweenService:Create(
            self.Frame,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.Width, 0, Style.TitleBarHeight)}
        )
        tween:Play()
    else
        -- Показываем контент
        self.ContentClip.Visible = true
        self.ScrollbarTrack.Visible = true
        self.CollapseBtn.Text = "─"
        
        -- Анимация разворачивания
        local tween = TweenService:Create(
            self.Frame,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            {Size = UDim2.new(0, self.Width, 0, self.Height)}
        )
        tween:Play()
    end
end

-- Сфокусировать окно (вывести на передний план)
function Window:Focus()
    if State.ActiveWindow == self then return end
    
    -- Находим максимальный ZIndex среди всех окон
    local maxZ = 10
    for _, win in pairs(State.Windows) do
        if win.ZIndex > maxZ then
            maxZ = win.ZIndex
        end
    end
    
    -- Устанавливаем ZIndex выше остальных
    self.ZIndex = maxZ + 5
    self.Frame.ZIndex = self.ZIndex
    
    -- Обновляем ZIndex всех дочерних элементов
    self:_UpdateZIndex(self.Frame, self.ZIndex)
    
    -- Активная подсветка заголовка
    self.TitleBar.BackgroundColor3 = Theme.TitleBgActive
    
    -- Снимаем фокус с предыдущего активного окна
    if State.ActiveWindow and State.ActiveWindow ~= self then
        State.ActiveWindow.TitleBar.BackgroundColor3 = Theme.TitleBg
    end
    
    State.ActiveWindow = self
end

-- Рекурсивное обновление ZIndex для всех дочерних элементов
function Window:_UpdateZIndex(parent, baseZ)
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("GuiObject") then
            child.ZIndex = baseZ + 1
            self:_UpdateZIndex(child, baseZ + 1)
        end
    end
end

-- Обновление скроллбара
function Window:_UpdateScrollbar()
    local clipHeight = self.ContentClip.AbsoluteSize.Y
    local contentHeight = self.ContentHeight
    
    if contentHeight <= clipHeight then
        -- Контент помещается без скролла
        self.ScrollbarTrack.Visible = false
        self.MaxScrollY = 0
        self.ScrollY = 0
    else
        -- Нужен скролл
        self.ScrollbarTrack.Visible = true
        self.MaxScrollY = contentHeight - clipHeight
        
        -- Соотношение размера ползунка к треку
        local ratio = clipHeight / contentHeight
        local grabSize = math.max(ratio, 0.05)
        
        -- Позиция ползунка
        local scrollRatio = (self.MaxScrollY > 0) and (self.ScrollY / self.MaxScrollY) or 0
        local grabPos = scrollRatio * (1 - grabSize)
        
        self.ScrollbarGrab.Size = UDim2.new(1, 0, grabSize, 0)
        self.ScrollbarGrab.Position = UDim2.new(0, 0, grabPos, 0)
    end
    
    -- Применяем скролл к контенту
    self.Content.Position = UDim2.new(0, 0, 0, -self.ScrollY)
end

-- Начало нового фрейма для окна
function Window:_BeginFrame()
    -- Сбрасываем курсор в начало контента
    self.CursorY = Style.WindowPadding.Y
    self.ContentWidth = self.Width - Style.WindowPadding.X * 2 - Style.ScrollbarSize - 4
    self.ContentHeight = Style.WindowPadding.Y
    
    -- Помечаем все виджеты как неактивные (для пула)
    self._widgetIndex = 0
end

-- Конец фрейма окна
function Window:_EndFrame()
    -- Обновляем высоту контента
    self.ContentHeight = self.CursorY + Style.WindowPadding.Y
    
    -- Обновляем скроллбар
    self:_UpdateScrollbar()
end

-- Получить следующую позицию для виджета
function Window:_NextWidgetPos(height)
    local pos = UDim2.new(
        0, Style.WindowPadding.X,
        0, self.CursorY
    )
    -- Двигаем курсор вниз
    self.CursorY = self.CursorY + height + Style.ItemSpacing.Y
    self.ContentHeight = math.max(self.ContentHeight, self.CursorY)
    return pos
end

-- Получить или создать состояние виджета
function Window:_GetWidgetState(id, default)
    if not self.WidgetStates[id] then
        self.WidgetStates[id] = default or {}
    end
    return self.WidgetStates[id]
end

-- ================================================
-- ВИДЖЕТЫ
-- ================================================

-- ------------------------------------------------
-- ТЕКСТ
-- ------------------------------------------------
function Window:Text(text, color)
    if not self.Visible or self.Collapsed then return end
    
    local id = "text_" .. text
    local state = self:_GetWidgetState(id, {frame = nil})
    
    -- Создаём фрейм для текста если нет
    if not state.frame then
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.WindowBg,
            Transparency = 1,
            ZIndex = self.ZIndex + 1,
        })
        state.label = CreateLabel(state.frame, {
            Text = text,
            Color = color or Theme.Text,
            Size = Style.FontSize,
            ZIndex = self.ZIndex + 2,
            Wrap = true,
        })
    end
    
    -- Вычисляем высоту текста
    local textHeight = math.max(Style.ItemHeight, Style.FontSize + 4)
    
    -- Обновляем позицию и размер
    local pos = self:_NextWidgetPos(textHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, textHeight)
    state.label.Text = text
    state.label.TextColor3 = color or Theme.Text
    state.frame.Visible = true
end

-- ------------------------------------------------
-- ЦВЕТНОЙ ТЕКСТ
-- ------------------------------------------------
function Window:TextColored(text, color)
    self:Text(text, color)
end

-- ------------------------------------------------
-- РАЗДЕЛИТЕЛЬ
-- ------------------------------------------------
function Window:Separator()
    if not self.Visible or self.Collapsed then return end
    
    local id = "sep_" .. self.CursorY
    local state = self:_GetWidgetState(id, {frame = nil})
    
    if not state.frame then
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.Separator,
            ZIndex = self.ZIndex + 1,
        })
    end
    
    local pos = self:_NextWidgetPos(1)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, 1)
    state.frame.Visible = true
end

-- ------------------------------------------------
-- КНОПКА
-- ------------------------------------------------
function Window:Button(label, width, height)
    if not self.Visible or self.Collapsed then return false end
    
    local id = "btn_" .. label
    local state = self:_GetWidgetState(id, {
        frame = nil,
        hovered = false,
        pressed = false,
        clicked = false,
    })
    
    local btnWidth = width or self.ContentWidth
    local btnHeight = height or Style.ItemHeight
    
    -- Создаём GUI кнопки если нет
    if not state.frame then
        state.frame = Instance.new("TextButton")
        state.frame.Name = id
        state.frame.BackgroundColor3 = Theme.Button
        state.frame.BorderSizePixel = 0
        state.frame.Font = Enum.Font.Code
        state.frame.Text = label
        state.frame.TextColor3 = Theme.ButtonText
        state.frame.TextSize = Style.FontSize
        state.frame.ZIndex = self.ZIndex + 1
        state.frame.Parent = self.Content
        AddCorner(state.frame, 4)
        AddStroke(state.frame, Theme.WindowBorder, 1)
        
        -- Эффект наведения
        state.frame.MouseEnter:Connect(function()
            state.hovered = true
            state.frame.BackgroundColor3 = Theme.ButtonHovered
        end)
        state.frame.MouseLeave:Connect(function()
            state.hovered = false
            state.pressed = false
            state.frame.BackgroundColor3 = Theme.Button
        end)
        
        -- Нажатие
        state.frame.MouseButton1Down:Connect(function()
            state.pressed = true
            state.frame.BackgroundColor3 = Theme.ButtonActive
        end)
        state.frame.MouseButton1Up:Connect(function()
            state.pressed = false
            if state.hovered then
                state.frame.BackgroundColor3 = Theme.ButtonHovered
            end
        end)
        
        -- Клик (возвращает true в эту итерацию)
        state.frame.MouseButton1Click:Connect(function()
            state.clicked = true
        end)
    end
    
    -- Обновляем позицию и размер
    local pos = self:_NextWidgetPos(btnHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, btnWidth, 0, btnHeight)
    state.frame.Text = label
    state.frame.Visible = true
    
    -- Возвращаем true если кликнули в этом фрейме
    local clicked = state.clicked
    state.clicked = false  -- Сбрасываем флаг
    return clicked
end

-- ------------------------------------------------
-- ЧЕКБОКС
-- ------------------------------------------------
function Window:Checkbox(label, value)
    if not self.Visible or self.Collapsed then return value end
    
    local id = "chk_" .. label
    local state = self:_GetWidgetState(id, {
        frame = nil,
        value = value or false,
        hovered = false,
    })
    
    -- Синхронизируем значение если передано новое
    if value ~= nil then
        state.value = value
    end
    
    local totalHeight = Style.CheckboxSize
    
    -- Создаём GUI чекбокса если нет
    if not state.frame then
        -- Контейнер
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.WindowBg,
            Transparency = 1,
            ZIndex = self.ZIndex + 1,
        })
        
        -- Интерактивная зона
        local hitbox = Instance.new("TextButton")
        hitbox.BackgroundTransparency = 1
        hitbox.Text = ""
        hitbox.Size = UDim2.new(1, 0, 1, 0)
        hitbox.ZIndex = self.ZIndex + 4
        hitbox.Parent = state.frame
        
        -- Квадрат чекбокса
        state.box = CreateFrame(state.frame, {
            Name = "Box",
            Position = UDim2.new(0, 0, 0.5, -Style.CheckboxSize/2),
            Size = UDim2.new(0, Style.CheckboxSize, 0, Style.CheckboxSize),
            Color = Theme.CheckBg,
            ZIndex = self.ZIndex + 2,
        })
        AddCorner(state.box, 3)
        AddStroke(state.box, Theme.CheckBorder, 1)
        
        -- Галочка (отметка)
        state.mark = CreateLabel(state.box, {
            Name = "Mark",
            Text = "✓",
            Color = Theme.CheckMark,
            Size = Style.FontSize,
            AlignX = Enum.TextXAlignment.Center,
            AlignY = Enum.TextYAlignment.Center,
            ZIndex = self.ZIndex + 3,
        })
        
        -- Текст метки
        state.label = CreateLabel(state.frame, {
            Name = "Label",
            Text = label,
            Color = Theme.Text,
            Size = Style.FontSize,
            Position = UDim2.new(0, Style.CheckboxSize + Style.ItemSpacing.X, 0, 0),
            Size2 = UDim2.new(1, -(Style.CheckboxSize + Style.ItemSpacing.X), 1, 0),
            ZIndex = self.ZIndex + 2,
        })
        
        -- Клик по чекбоксу - переключение значения
        hitbox.MouseButton1Click:Connect(function()
            state.value = not state.value
            state.mark.Visible = state.value
            
            -- Анимация нажатия
            if state.value then
                state.box.BackgroundColor3 = Theme.CheckMark
                task.delay(0.1, function()
                    if state.box then
                        state.box.BackgroundColor3 = Theme.CheckBg
                    end
                end)
            end
        end)
        
        -- Эффект наведения
        hitbox.MouseEnter:Connect(function()
            state.hovered = true
            state.box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end)
        hitbox.MouseLeave:Connect(function()
            state.hovered = false
            state.box.BackgroundColor3 = Theme.CheckBg
        end)
    end
    
    -- Обновляем состояние отображения
    state.mark.Visible = state.value
    
    -- Обновляем позицию
    local pos = self:_NextWidgetPos(totalHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, totalHeight)
    state.frame.Visible = true
    
    return state.value
end

-- ------------------------------------------------
-- СЛАЙДЕР
-- ------------------------------------------------
function Window:Slider(label, value, min, max, format)
    if not self.Visible or self.Collapsed then return value end
    
    local id = "sld_" .. label
    local state = self:_GetWidgetState(id, {
        frame = nil,
        value = value or 0,
        dragging = false,
    })
    
    -- Обновляем значение если передали новое
    if value ~= nil then
        state.value = math.clamp(value, min, max)
    end
    
    min = min or 0
    max = max or 1
    format = format or "%.1f"
    
    local totalHeight = Style.SliderHeight + Style.FontSize + Style.ItemSpacing.Y
    
    -- Создаём GUI слайдера если нет
    if not state.frame then
        -- Контейнер
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.WindowBg,
            Transparency = 1,
            ZIndex = self.ZIndex + 1,
        })
        
        -- Метка над слайдером
        state.labelText = CreateLabel(state.frame, {
            Name = "Label",
            Text = label,
            Color = Theme.Text,
            Size = Style.FontSize,
            Position = UDim2.new(0, 0, 0, 0),
            Size2 = UDim2.new(1, 0, 0, Style.FontSize + 2),
            ZIndex = self.ZIndex + 2,
        })
        
        -- Трек слайдера
        state.track = CreateFrame(state.frame, {
            Name = "Track",
            Position = UDim2.new(0, 0, 0, Style.FontSize + Style.ItemSpacing.Y),
            Size = UDim2.new(1, 0, 0, Style.SliderHeight),
            Color = Theme.SliderBg,
            ZIndex = self.ZIndex + 2,
        })
        AddCorner(state.track, 4)
        AddStroke(state.track, Theme.SliderBorder, 1)
        
        -- Заливка (заполненная часть)
        state.fill = CreateFrame(state.track, {
            Name = "Fill",
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            Color = Theme.SliderFill,
            ZIndex = self.ZIndex + 3,
        })
        AddCorner(state.fill, 4)
        
        -- Текст значения на слайдере
        state.valueText = CreateLabel(state.track, {
            Name = "Value",
            Text = string.format(format, state.value),
            Color = Theme.Text,
            Size = Style.FontSize - 1,
            AlignX = Enum.TextXAlignment.Center,
            AlignY = Enum.TextYAlignment.Center,
            ZIndex = self.ZIndex + 4,
        })
        
        -- Хватаемый ползунок
        state.grab = CreateFrame(state.track, {
            Name = "Grab",
            Position = UDim2.new(0, 0, 0.5, -7),
            Size = UDim2.new(0, 6, 0, 14),
            Color = Theme.SliderGrab,
            ZIndex = self.ZIndex + 5,
        })
        AddCorner(state.grab, 3)
        
        -- Интерактивная зона для перетаскивания
        local hitbox = Instance.new("TextButton")
        hitbox.BackgroundTransparency = 1
        hitbox.Text = ""
        hitbox.Size = UDim2.new(1, 0, 1, 0)
        hitbox.ZIndex = self.ZIndex + 6
        hitbox.Parent = state.track
        
        -- Начало перетаскивания слайдера
        hitbox.MouseButton1Down:Connect(function()
            state.dragging = true
        end)
        
        -- Конец перетаскивания
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                state.dragging = false
            end
        end)
        
        -- Обновление значения при перемещении мыши
        RunService.RenderStepped:Connect(function()
            if state.dragging and state.track then
                local trackPos = state.track.AbsolutePosition
                local trackSize = state.track.AbsoluteSize
                
                -- Нормализованная позиция мыши на треке (0-1)
                local relX = (State.Mouse.Position.X - trackPos.X) / trackSize.X
                relX = math.clamp(relX, 0, 1)
                
                -- Конвертируем в значение диапазона
                state.value = min + relX * (max - min)
                state.value = math.clamp(state.value, min, max)
            end
        end)
    end
    
    -- Вычисляем позицию ползунка
    local t = (max ~= min) and ((state.value - min) / (max - min)) or 0
    
    -- Обновляем визуальные элементы
    state.fill.Size = UDim2.new(t, 0, 1, 0)
    state.grab.Position = UDim2.new(t, -3, 0.5, -7)
    state.valueText.Text = string.format(format, state.value)
    state.labelText.Text = label
    
    -- Обновляем позицию контейнера
    local pos = self:_NextWidgetPos(totalHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, totalHeight)
    state.frame.Visible = true
    
    return state.value
end

-- ------------------------------------------------
-- ПОЛЕ ВВОДА ТЕКСТА
-- ------------------------------------------------
function Window:InputText(label, value, placeholder)
    if not self.Visible or self.Collapsed then return value end
    
    local id = "inp_" .. label
    local state = self:_GetWidgetState(id, {
        frame = nil,
        value = value or "",
        focused = false,
    })
    
    -- Синхронизируем значение
    if value ~= nil and not state.focused then
        state.value = value
    end
    
    placeholder = placeholder or ""
    
    local totalHeight = Style.ItemHeight + Style.FontSize + Style.ItemSpacing.Y
    
    -- Создаём GUI поля ввода если нет
    if not state.frame then
        -- Контейнер
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.WindowBg,
            Transparency = 1,
            ZIndex = self.ZIndex + 1,
        })
        
        -- Метка
        state.labelText = CreateLabel(state.frame, {
            Name = "Label",
            Text = label,
            Color = Theme.Text,
            Size = Style.FontSize,
            Position = UDim2.new(0, 0, 0, 0),
            Size2 = UDim2.new(1, 0, 0, Style.FontSize + 2),
            ZIndex = self.ZIndex + 2,
        })
        
        -- Фрейм поля ввода
        state.inputFrame = CreateFrame(state.frame, {
            Name = "InputFrame",
            Position = UDim2.new(0, 0, 0, Style.FontSize + Style.ItemSpacing.Y),
            Size = UDim2.new(1, 0, 0, Style.ItemHeight),
            Color = Theme.InputBg,
            ZIndex = self.ZIndex + 2,
        })
        AddCorner(state.inputFrame, 4)
        state.stroke = AddStroke(state.inputFrame, Theme.InputBorder, 1)
        
        -- Текстовый бокс
        state.textbox = Instance.new("TextBox")
        state.textbox.BackgroundTransparency = 1
        state.textbox.Text = state.value
        state.textbox.PlaceholderText = placeholder
        state.textbox.PlaceholderColor3 = Theme.TextDisabled
        state.textbox.TextColor3 = Theme.InputText
        state.textbox.TextSize = Style.FontSize
        state.textbox.Font = Enum.Font.Code
        state.textbox.TextXAlignment = Enum.TextXAlignment.Left
        state.textbox.Size = UDim2.new(1, -(Style.FramePadding.X * 2), 1, 0)
        state.textbox.Position = UDim2.new(0, Style.FramePadding.X, 0, 0)
        state.textbox.ZIndex = self.ZIndex + 3
        state.textbox.ClearTextOnFocus = false
        state.textbox.Parent = state.inputFrame
        
        -- Подсветка при фокусе
        state.textbox.Focused:Connect(function()
            state.focused = true
            state.stroke.Color = Theme.InputBorderFocus
        end)
        
        state.textbox.FocusLost:Connect(function()
            state.focused = false
            state.value = state.textbox.Text
            state.stroke.Color = Theme.InputBorder
        end)
        
        -- Обновление значения в реальном времени
        state.textbox:GetPropertyChangedSignal("Text"):Connect(function()
            state.value = state.textbox.Text
        end)
    end
    
    -- Синхронизируем текст если не в фокусе
    if not state.focused then
        state.textbox.Text = state.value
    end
    
    state.labelText.Text = label
    state.textbox.PlaceholderText = placeholder
    
    -- Обновляем позицию
    local pos = self:_NextWidgetPos(totalHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, totalHeight)
    state.frame.Visible = true
    
    return state.value
end

-- ------------------------------------------------
-- ВЫПАДАЮЩИЙ СПИСОК (COMBO)
-- ------------------------------------------------
function Window:Combo(label, selectedIndex, items)
    if not self.Visible or self.Collapsed then return selectedIndex end
    
    local id = "cmb_" .. label
    local state = self:_GetWidgetState(id, {
        frame = nil,
        selectedIndex = selectedIndex or 1,
        open = false,
        itemFrames = {},
    })
    
    -- Обновляем выбранный индекс
    if selectedIndex ~= nil then
        state.selectedIndex = selectedIndex
    end
    
    items = items or {}
    
    local comboHeight = Style.ItemHeight + Style.FontSize + Style.ItemSpacing.Y
    
    -- Создаём GUI комбобокса если нет
    if not state.frame then
        -- Контейнер
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.WindowBg,
            Transparency = 1,
            ZIndex = self.ZIndex + 1,
        })
        
        -- Метка
        state.labelText = CreateLabel(state.frame, {
            Name = "Label",
            Text = label,
            Color = Theme.Text,
            Size = Style.FontSize,
            Position = UDim2.new(0, 0, 0, 0),
            Size2 = UDim2.new(1, 0, 0, Style.FontSize + 2),
            ZIndex = self.ZIndex + 2,
        })
        
        -- Кнопка выбора
        state.button = Instance.new("TextButton")
        state.button.Name = "ComboButton"
        state.button.BackgroundColor3 = Theme.InputBg
        state.button.BorderSizePixel = 0
        state.button.Text = ""
        state.button.ZIndex = self.ZIndex + 2
        state.button.Parent = state.frame
        AddCorner(state.button, 4)
        AddStroke(state.button, Theme.InputBorder, 1)
        
        -- Текст выбранного элемента
        state.selectedText = CreateLabel(state.button, {
            Name = "SelectedText",
            Text = items[state.selectedIndex] or "",
            Color = Theme.Text,
            Size = Style.FontSize,
            Position = UDim2.new(0, Style.FramePadding.X, 0, 0),
            Size2 = UDim2.new(1, -30, 1, 0),
            ZIndex = self.ZIndex + 3,
        })
        
        -- Стрелка раскрытия
        state.arrow = CreateLabel(state.button, {
            Name = "Arrow",
            Text = "▼",
            Color = Theme.TextDisabled,
            Size = Style.FontSize - 2,
            Position = UDim2.new(1, -24, 0, 0),
            Size2 = UDim2.new(0, 24, 1, 0),
            AlignX = Enum.TextXAlignment.Center,
            ZIndex = self.ZIndex + 3,
        })
        
        -- Выпадающий список (рендерится поверх всего)
        state.dropdown = CreateFrame(MainContainer, {
            Name = id .. "_dropdown",
            Color = Theme.ComboBg,
            ZIndex = 100,
        })
        state.dropdown.Visible = false
        AddCorner(state.dropdown, 4)
        AddStroke(state.dropdown, Theme.WindowBorder, 1)
        
        -- Переключение списка
        state.button.MouseButton1Click:Connect(function()
            state.open = not state.open
            state.dropdown.Visible = state.open
            state.arrow.Text = state.open and "▲" or "▼"
            
            if state.open then
                -- Позиционируем дропдаун под кнопкой
                local btnPos = state.button.AbsolutePosition
                local btnSize = state.button.AbsoluteSize
                local itemH = Style.ItemHeight + 2
                local dropH = #items * itemH + 4
                
                state.dropdown.Position = UDim2.new(
                    0, btnPos.X,
                    0, btnPos.Y + btnSize.Y + 2
                )
                state.dropdown.Size = UDim2.new(
                    0, btnSize.X,
                    0, dropH
                )
                
                -- Очищаем и создаём элементы списка
                for _, child in ipairs(state.dropdown:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                
                for i, item in ipairs(items) do
                    local itemBtn = Instance.new("TextButton")
                    itemBtn.BackgroundColor3 = Theme.ComboItem
                    itemBtn.BackgroundTransparency = 1
                    itemBtn.Text = item
                    itemBtn.TextColor3 = Theme.ComboText
                    itemBtn.TextSize = Style.FontSize
                    itemBtn.Font = Enum.Font.Code
                    itemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    itemBtn.Size = UDim2.new(1, -4, 0, itemH)
                    itemBtn.Position = UDim2.new(0, 2, 0, (i-1) * itemH + 2)
                    itemBtn.ZIndex = 101
                    itemBtn.Parent = state.dropdown
                    
                    -- Подсветка выбранного
                    if i == state.selectedIndex then
                        itemBtn.BackgroundTransparency = 0
                        itemBtn.BackgroundColor3 = Theme.ComboItemHover
                    end
                    
                    local padding = Instance.new("UIPadding")
                    padding.PaddingLeft = UDim.new(0, Style.FramePadding.X)
                    padding.Parent = itemBtn
                    AddCorner(itemBtn, 3)
                    
                    -- Наведение на элемент
                    itemBtn.MouseEnter:Connect(function()
                        itemBtn.BackgroundTransparency = 0
                        itemBtn.BackgroundColor3 = Theme.ComboItemHover
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        if i ~= state.selectedIndex then
                            itemBtn.BackgroundTransparency = 1
                        end
                    end)
                    
                    -- Выбор элемента
                    local capturedIndex = i
                    itemBtn.MouseButton1Click:Connect(function()
                        state.selectedIndex = capturedIndex
                        state.selectedText.Text = items[capturedIndex] or ""
                        state.open = false
                        state.dropdown.Visible = false
                        state.arrow.Text = "▼"
                    end)
                end
            end
        end)
        
        -- Закрытие при клике вне списка
        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if state.open then
                    task.defer(function()
                        if not IsMouseOver(state.button) and not IsMouseOver(state.dropdown) then
                            state.open = false
                            state.dropdown.Visible = false
                            state.arrow.Text = "▼"
                        end
                    end)
                end
            end
        end)
    end
    
    -- Обновляем отображение выбранного элемента
    state.selectedText.Text = items[state.selectedIndex] or ""
    state.labelText.Text = label
    
    -- Обновляем позицию
    local pos = self:_NextWidgetPos(comboHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, comboHeight)
    
    -- Позиция кнопки внутри фрейма
    state.button.Position = UDim2.new(0, 0, 0, Style.FontSize + Style.ItemSpacing.Y)
    state.button.Size = UDim2.new(1, 0, 0, Style.ItemHeight)
    
    state.frame.Visible = true
    
    return state.selectedIndex
end

-- ------------------------------------------------
-- ПРОГРЕСС-БАР
-- ------------------------------------------------
function Window:ProgressBar(label, value, min, max, showText)
    if not self.Visible or self.Collapsed then return end
    
    local id = "prg_" .. label
    local state = self:_GetWidgetState(id, {
        frame = nil,
    })
    
    min = min or 0
    max = max or 1
    value = math.clamp(value or 0, min, max)
    showText = showText ~= false
    
    local totalHeight = Style.SliderHeight + Style.FontSize + Style.ItemSpacing.Y
    
    -- Создаём GUI прогресс-бара если нет
    if not state.frame then
        -- Контейнер
        state.frame = CreateFrame(self.Content, {
            Name = id,
            Color = Theme.WindowBg,
            Transparency = 1,
            ZIndex = self.ZIndex + 1,
        })
        
        -- Метка
        state.labelText = CreateLabel(state.frame, {
            Name = "Label",
            Text = label,
            Color = Theme.Text,
            Size = Style.FontSize,
            Position = UDim2.new(0, 0, 0, 0),
            Size2 = UDim2.new(1, 0, 0, Style.FontSize + 2),
            ZIndex = self.ZIndex + 2,
        })
        
        -- Фон прогресс-бара
        state.bg = CreateFrame(state.frame, {
            Name = "Background",
            Position = UDim2.new(0, 0, 0, Style.FontSize + Style.ItemSpacing.Y),
            Size = UDim2.new(1, 0, 0, Style.SliderHeight),
            Color = Theme.ProgressBg,
            ZIndex = self.ZIndex + 2,
        })
        AddCorner(state.bg, 4)
        AddStroke(state.bg, Theme.ProgressBorder, 1)
        
        -- Заливка прогресса
        state.fill = CreateFrame(state.bg, {
            Name = "Fill",
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
            Color = Theme.ProgressFill,
            ZIndex = self.ZIndex + 3,
        })
        AddCorner(state.fill, 4)
        
        -- Текст процента в центре
        state.percentText = CreateLabel(state.bg, {
            Name = "Percent",
            Text = "0%",
            Color = Theme.Text,
            Size = Style.FontSize - 1,
            AlignX = Enum.TextXAlignment.Center,
            AlignY = Enum.TextYAlignment.Center,
            ZIndex = self.ZIndex + 4,
        })
    end
    
    -- Вычисляем прогресс (0-1)
    local progress = (max ~= min) and ((value - min) / (max - min)) or 0
    progress = math.clamp(progress, 0, 1)
    
    -- Обновляем визуал
    state.fill.Size = UDim2.new(progress, 0, 1, 0)
    state.labelText.Text = label
    
    if showText then
        state.percentText.Text = string.format("%d%%", math.floor(progress * 100))
        state.percentText.Visible = true
    else
        state.percentText.Visible = false
    end
    
    -- Обновляем позицию
    local pos = self:_NextWidgetPos(totalHeight)
    state.frame.Position = pos
    state.frame.Size = UDim2.new(0, self.ContentWidth, 0, totalHeight)
    state.frame.Visible = true
end

-- ------------------------------------------------
-- ПУСТОЕ ПРОСТРАНСТВО
-- ------------------------------------------------
function Window:Spacing(height)
    if not self.Visible or self.Collapsed then return end
    self.CursorY = self.CursorY + (height or Style.ItemSpacing.Y)
end

-- ------------------------------------------------
-- СКРОЛЛИНГ КОЛЕСОМ МЫШИ
-- ------------------------------------------------
function Window:_SetupScrolling()
    self.Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local delta = -input.Position.Z * 20  -- Скорость скролла
            self.ScrollY = math.clamp(
                self.ScrollY + delta,
                0,
                math.max(0, self.MaxScrollY)
            )
        end
    end)
end

-- ================================================
-- ОСНОВНОЙ API ImGui
-- ================================================

-- Начало работы с окном
function ImGui.Begin(title, config)
    -- Создаём окно если не существует
    if not State.Windows[title] then
        State.Windows[title] = Window.new(title, config)
        State.Windows[title]:_SetupScrolling()
    end
    
    local win = State.Windows[title]
    State.CurrentWindow = win
    
    -- Обновляем видимость
    win.Frame.Visible = win.Visible
    
    if win.Visible then
        win:_BeginFrame()
    end
    
    return win.Visible
end

-- Конец работы с окном
function ImGui.End()
    local win = State.CurrentWindow
    if not win then return end
    
    if win.Visible then
        win:_EndFrame()
    end
    
    State.CurrentWindow = nil
end

-- Установить размер следующего окна
function ImGui.SetNextWindowSize(width, height)
    ImGui._nextWindowSize = Vector2.new(width, height)
end

-- Установить позицию следующего окна
function ImGui.SetNextWindowPos(x, y)
    ImGui._nextWindowPos = Vector2.new(x, y)
end

-- Скрыть/показать окно
function ImGui.SetWindowVisible(title, visible)
    if State.Windows[title] then
        State.Windows[title].Visible = visible
        State.Windows[title].Frame.Visible = visible
    end
end

-- ================================================
-- ВИДЖЕТ-ПРОКСИ ФУНКЦИИ
-- (делегирование к текущему окну)
-- ================================================

function ImGui.Text(text, color)
    if State.CurrentWindow then
        State.CurrentWindow:Text(text, color)
    end
end

function ImGui.TextColored(text, color)
    if State.CurrentWindow then
        State.CurrentWindow:TextColored(text, color)
    end
end

function ImGui.Separator()
    if State.CurrentWindow then
        State.CurrentWindow:Separator()
    end
end

function ImGui.Spacing(height)
    if State.CurrentWindow then
        State.CurrentWindow:Spacing(height)
    end
end

function ImGui.Button(label, width, height)
    if State.CurrentWindow then
        return State.CurrentWindow:Button(label, width, height)
    end
    return false
end

function ImGui.Checkbox(label, value)
    if State.CurrentWindow then
        return State.CurrentWindow:Checkbox(label, value)
    end
    return value
end

function ImGui.Slider(label, value, min, max, format)
    if State.CurrentWindow then
        return State.CurrentWindow:Slider(label, value, min, max, format)
    end
    return value
end

function ImGui.InputText(label, value, placeholder)
    if State.CurrentWindow then
        return State.CurrentWindow:InputText(label, value, placeholder)
    end
    return value
end

function ImGui.Combo(label, selectedIndex, items)
    if State.CurrentWindow then
        return State.CurrentWindow:Combo(label, selectedIndex, items)
    end
    return selectedIndex
end

function ImGui.ProgressBar(label, value, min, max, showText)
    if State.CurrentWindow then
        State.CurrentWindow:ProgressBar(label, value, min, max, showText)
    end
end

-- ================================================
-- ОБНОВЛЕНИЕ СОСТОЯНИЯ МЫШИ
-- ================================================
local function UpdateMouseState()
    local mousePos = UserInputService:GetMouseLocation()
    State.Mouse.Delta = mousePos - State.Mouse.Position
    State.Mouse.Position = mousePos
end

-- ================================================
-- ОБНОВЛЕНИЕ ПЕРЕТАСКИВАНИЯ ОКОН
-- ================================================
local function UpdateDragging()
    if not State.Drag.Active or not State.Drag.Window then return end
    
    local win = State.Drag.Window
    local newX = State.Mouse.Position.X - State.Drag.Offset.X
    local newY = State.Mouse.Position.Y - State.Drag.Offset.Y
    
    -- Ограничиваем окно в пределах экрана
    local screenSize = workspace.CurrentCamera.ViewportSize
    newX = math.clamp(newX, 0, screenSize.X - win.Width)
    newY = math.clamp(newY, 0, screenSize.Y - Style.TitleBarHeight)
    
    -- Обновляем позицию
    win.X = newX
    win.Y = newY
    win.Frame.Position = UDim2.new(0, newX, 0, newY)
end

-- Конец перетаскивания при отпускании мыши
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        State.Drag.Active = false
        State.Drag.Window = nil
    end
end)

-- ================================================
-- ГЛАВНЫЙ ЦИКЛ (RenderStepped)
-- ================================================
RunService.RenderStepped:Connect(function(deltaTime)
    -- Обновляем состояние мыши
    UpdateMouseState()
    
    -- Обновляем перетаскивание окон
    UpdateDragging()
end)

-- ================================================
-- ОЧИСТКА ПРИ УНИЧТОЖЕНИИ
-- ================================================
function ImGui.Destroy()
    -- Уничтожаем все окна
    for title, win in pairs(State.Windows) do
        if win.Frame then
            win.Frame:Destroy()
        end
    end
    State.Windows = {}
    
    -- Очищаем пул объектов
    Pool:Destroy()
    
    -- Удаляем GUI
    if ScreenGui then
        ScreenGui:Destroy()
    end
end

-- ================================================
-- ДОСТУП К ТЕМЕ И СТИЛЮ
-- ================================================
ImGui.Theme = Theme
ImGui.Style = Style

return ImGui