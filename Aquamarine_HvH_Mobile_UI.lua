--[[
================================================================================
AQUAMARINE // HVH UI CONCEPT
Версия: 1.0.0-mobile-prototype
Формат: Roblox Lua / LocalScript

ВАЖНО
-----
Это визуальный макет интерфейса для Roblox Studio. Переключатели, выпадающие
списки, слайдеры и кнопки изменяют только локальное состояние самого меню.
Скрипт НЕ содержит аимбота, ESP, телепортации, обходов, изменения скорости,
работы с RemoteEvent, чтения чужих данных или управления игровыми механиками.
Названия спорных игровых функций приведены исключительно как декоративные
элементы концепта. Они не выполняют заявленные игровые действия.

УСТАНОВКА
---------
1. Открой собственный проект в Roblox Studio.
2. Создай LocalScript внутри StarterPlayer > StarterPlayerScripts.
3. Вставь весь этот файл в LocalScript и запусти Play.
4. Для закрытия нажми X; маленькая кнопка A оставит возможность открыть UI снова.
5. Перемещай окно за верхнюю панель. На телефонах поддерживается Touch.

ПРИМЕЧАНИЯ ПО МОБИЛЬНОЙ ВЁРСТКЕ
-------------------------------
- Размер окна пересчитывается по размеру ViewportSize.
- Категории размещены в горизонтально прокручиваемой полосе.
- Карточки настроек идут вертикально, чтобы их было удобно нажимать пальцем.
- Кнопки имеют увеличенную зону нажатия, а панель можно перетаскивать касанием.
- Поиск фильтрует элементы активной вкладки.
- Все состояния хранятся только в памяти текущего LocalScript.

СТРУКТУРА
---------
1. Сервисы и палитра
2. Вспомогательные функции создания элементов
3. Каталог декоративных настроек
4. Построение окна и панели категорий
5. Создание карточек и контролов
6. Поиск, уведомления и переключение страниц
7. Обработка сенсорного ввода и изменение размеров окна
8. Инициализация и запуск

КОД НАПИСАН ДЛЯ ОБЫЧНОГО ROBLOX LOCAL SCRIPT И НЕ ИСПОЛЬЗУЕТ API ЭКЗЕКУТОРА.

Поддерживаемые интеракции интерфейса:
- Toggle: меняет булево значение и внешний вид переключателя.
- Slider: меняет локальное число прикосновением/мышью или кнопками +/-.
- Dropdown: циклически переключает пункты локального списка.
- Action: показывает toast с описанием демонстрационного действия.
- Search: фильтрует карточки по названию и описанию.
- Tabs: переключают визуальные разделы каталога.
- Minimize: прячет содержимое, сохраняя заголовок.
- Close: скрывает окно; плавающая кнопка открывает его снова.

Все игровые опции в каталоге являются фиктивными. Не подключай эти элементы к
игровому коду, если задача состоит только в создании визуального прототипа.
================================================================================
]]

--// Services ------------------------------------------------------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--// Constants -----------------------------------------------------------------
local APP_NAME = "AQUAMARINE"
local APP_SUBTITLE = "HVH UI CONCEPT"
local APP_VERSION = "1.0.0"
local UI_ONLY_NOTICE = "UI ONLY • NO GAMEPLAY EFFECTS"

local COLORS = {
    Background = Color3.fromRGB(8, 12, 18),
    Window = Color3.fromRGB(13, 19, 28),
    Header = Color3.fromRGB(16, 24, 35),
    Panel = Color3.fromRGB(17, 25, 36),
    Card = Color3.fromRGB(21, 31, 43),
    CardHover = Color3.fromRGB(25, 39, 53),
    CardPressed = Color3.fromRGB(28, 47, 60),
    Border = Color3.fromRGB(39, 57, 72),
    MutedBorder = Color3.fromRGB(29, 43, 56),
    Accent = Color3.fromRGB(73, 224, 205),
    AccentDeep = Color3.fromRGB(37, 163, 157),
    AccentSoft = Color3.fromRGB(23, 76, 78),
    Text = Color3.fromRGB(232, 242, 247),
    TextSoft = Color3.fromRGB(149, 169, 183),
    TextMuted = Color3.fromRGB(104, 126, 142),
    Positive = Color3.fromRGB(99, 225, 174),
    Warning = Color3.fromRGB(241, 190, 103),
    Negative = Color3.fromRGB(241, 111, 130),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0),
}

local FONT = Enum.Font.Gotham
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_HEAVY = Enum.Font.GothamBlack

local SETTINGS = {
    AnimationTime = 0.16,
    ToastTime = 2.4,
    RowHeight = 78,
    CompactRowHeight = 68,
    HeaderHeight = 54,
    NavigationHeight = 42,
    CornerRadius = 10,
    WindowRadius = 14,
    SearchPlaceholder = "Поиск в разделе...",
    DefaultTab = "combat",
    StartMinimized = false,
}

local state = {
    values = {},
    activeTab = SETTINGS.DefaultTab,
    query = "",
    minimized = SETTINGS.StartMinimized,
    windowVisible = true,
    compactRows = false,
    reducedMotion = false,
    accentName = "Aquamarine",
    toastSequence = 0,
}

local currentSliderDrag = nil
local draggingWindow = false
local dragStart = nil
local startWindowPosition = nil
local activeInput = nil
local tabButtons = {}
local renderedRows = {}
local featureById = {}
local tabById = {}
local toastHost
local renderActiveTab
local updateResponsiveSize

--// Utility functions ----------------------------------------------------------
local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function round(value)
    return math.floor(value + 0.5)
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    if parent then
        object.Parent = parent
    end
    return object
end

local function addCorner(parent, radius)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius or SETTINGS.CornerRadius),
    }, parent)
end

local function addStroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or COLORS.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function addPadding(parent, left, top, right, bottom)
    return make("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function addList(parent, direction, padding, horizontalAlignment, verticalAlignment)
    return make("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        Padding = UDim.new(0, padding or 0),
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment = verticalAlignment or Enum.VerticalAlignment.Top,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, parent)
end

local function tween(object, duration, properties, style, direction)
    if state.reducedMotion then
        for key, value in pairs(properties) do
            object[key] = value
        end
        return nil
    end
    local info = TweenInfo.new(
        duration or SETTINGS.AnimationTime,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    local animation = TweenService:Create(object, info, properties)
    animation:Play()
    return animation
end

local function makeLabel(parent, text, size, position, font, color, xAlignment)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or COLORS.Text,
        Font = font or FONT,
        TextSize = size or 14,
        TextXAlignment = xAlignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Position = position or UDim2.new(),
        Size = UDim2.new(1, 0, 0, 20),
        TextWrapped = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0,
    }, parent)
end

local function makeButton(parent, text, size, background, textColor)
    local button = make("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = background or COLORS.Card,
        BorderSizePixel = 0,
        Size = size or UDim2.fromOffset(40, 32),
        Text = text or "",
        TextColor3 = textColor or COLORS.Text,
        Font = FONT_MEDIUM,
        TextSize = 12,
        Selectable = true,
        Active = true,
    }, parent)
    addCorner(button, 8)
    addStroke(button, COLORS.Border, 1, 0.18)
    button.MouseEnter:Connect(function()
        tween(button, 0.1, { BackgroundColor3 = COLORS.CardHover })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.1, { BackgroundColor3 = background or COLORS.Card })
    end)
    button.MouseButton1Down:Connect(function()
        tween(button, 0.06, { BackgroundColor3 = COLORS.CardPressed })
    end)
    button.Activated:Connect(function()
        if button.Parent then
            tween(button, 0.1, { BackgroundColor3 = COLORS.CardHover })
        end
    end)
    return button
end

local function shorten(text, maxLength)
    if #text <= maxLength then
        return text
    end
    return string.sub(text, 1, math.max(1, maxLength - 1)) .. "…"
end

local function makeId(prefix, text)
    local cleaned = string.lower(text or "item")
    cleaned = string.gsub(cleaned, "[^%w]+", "_")
    cleaned = string.gsub(cleaned, "^_+", "")
    cleaned = string.gsub(cleaned, "_+$", "")
    return prefix .. "_" .. cleaned
end

local function updateAccent(name)
    state.accentName = name or state.accentName
    if name == "Midnight" then
        COLORS.Accent = Color3.fromRGB(135, 160, 255)
        COLORS.AccentDeep = Color3.fromRGB(81, 109, 210)
        COLORS.AccentSoft = Color3.fromRGB(42, 52, 94)
    elseif name == "Graphite" then
        COLORS.Accent = Color3.fromRGB(190, 205, 218)
        COLORS.AccentDeep = Color3.fromRGB(107, 128, 144)
        COLORS.AccentSoft = Color3.fromRGB(49, 61, 74)
    else
        COLORS.Accent = Color3.fromRGB(73, 224, 205)
        COLORS.AccentDeep = Color3.fromRGB(37, 163, 157)
        COLORS.AccentSoft = Color3.fromRGB(23, 76, 78)
    end
end

local function formatValue(value)
    if type(value) == "number" then
        if math.abs(value - math.floor(value)) < 0.001 then
            return tostring(math.floor(value))
        end
        return string.format("%.1f", value)
    end
    if type(value) == "boolean" then
        return value and "ON" or "OFF"
    end
    return tostring(value)
end

local function setLocalValue(item, value)
    if not item or not item.id then
        return
    end
    state.values[item.id] = value
end

local function getLocalValue(item)
    if state.values[item.id] ~= nil then
        return state.values[item.id]
    end
    return item.default
end

local function showToast(message, tone)
    if not toastHost or not toastHost.Parent then
        return
    end
    state.toastSequence += 1
    local sequence = state.toastSequence
    local toast = make("Frame", {
        Name = "Toast_" .. tostring(sequence),
        BackgroundColor3 = COLORS.Header,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 42),
        Position = UDim2.new(0, 0, 0, 0),
        LayoutOrder = sequence,
    }, toastHost)
    addCorner(toast, 9)
    addStroke(toast, tone == "warning" and COLORS.Warning or COLORS.Accent, 1, 0.28)
    make("Frame", {
        BackgroundColor3 = tone == "warning" and COLORS.Warning or COLORS.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
    }, toast)
    local label = makeLabel(toast, message, 11, UDim2.new(0, 18, 0, 0), FONT_MEDIUM, COLORS.Text)
    label.Size = UDim2.new(1, -25, 1, 0)
    label.TextWrapped = true
    toast.BackgroundTransparency = 1
    label.TextTransparency = 1
    tween(toast, 0.15, { BackgroundTransparency = 0.04 })
    tween(label, 0.15, { TextTransparency = 0 })
    task.delay(SETTINGS.ToastTime, function()
        if toast and toast.Parent and sequence <= state.toastSequence then
            tween(toast, 0.15, { BackgroundTransparency = 1 })
            tween(label, 0.15, { TextTransparency = 1 })
            task.delay(0.18, function()
                if toast and toast.Parent then
                    toast:Destroy()
                end
            end)
        end
    end)
end

--// User-facing state disclaimer ---------------------------------------------
local function isUiOnly()
    return true
end

local function notifyUiOnly(actionName)
    local action = actionName or "Действие"
    showToast(action .. ": только UI-макет", "warning")
end

--// Catalog data is declared below. No entry executes gameplay code. ----------
local CATALOG = {
    -- Combat: decorative controls only
    {
        id = "combat",
        title = "COMBAT",
        name = "Combat",
        subtitle = "Боевой раздел · визуальные заглушки",
        features = {
            {
                id = "combat_1_aim_assist",
                title = "Aim Assist",
                description = "Демонстрационный переключатель для макета прицеливания.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_2_silent_aim",
                title = "Silent Aim",
                description = "Только внешний вид настройки; игровая логика отсутствует.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_3_rage_mode",
                title = "Rage Mode",
                description = "Переключатель состояния интерфейса без влияния на матч.",
                kind = "slider",
                default = 72,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_4_target_priority",
                title = "Target Priority",
                description = "Макет выбора приоритета цели.",
                kind = "dropdown",
                default = "Default",
                group = "Combat",
                options = { "Default", "Prefer Head", "Prefer Body" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_5_field_of_view",
                title = "Field of View",
                description = "Демонстрационный ползунок значения FOV.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_6_hit_chance",
                title = "Hit Chance",
                description = "Ползунок только для визуального предпросмотра.",
                kind = "action",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_7_minimum_damage",
                title = "Minimum Damage",
                description = "Демо-настройка числового значения.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_8_quick_stop",
                title = "Quick Stop",
                description = "Локальная UI-заглушка.",
                kind = "slider",
                default = 45,
                group = "Combat",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "combat_9_auto_scope",
                title = "Auto Scope",
                description = "Не взаимодействует с персонажем или камерой.",
                kind = "dropdown",
                default = "Default",
                group = "Combat",
                options = { "Default", "Prefer Head", "Prefer Body" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_10_auto_fire",
                title = "Auto Fire",
                description = "Косметическая настройка интерфейса.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_11_target_lock",
                title = "Target Lock",
                description = "Только индикатор состояния меню.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_12_multipoint_scale",
                title = "Multipoint Scale",
                description = "Демо-параметр с диапазоном значений.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_13_body_aim",
                title = "Body Aim",
                description = "Макет переключателя зоны приоритета.",
                kind = "slider",
                default = 50,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_14_prefer_head",
                title = "Prefer Head",
                description = "Визуальный переключатель, ничего не наводит.",
                kind = "dropdown",
                default = "Default",
                group = "Combat",
                options = { "Default", "Prefer Head", "Prefer Body" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_15_prefer_body",
                title = "Prefer Body",
                description = "Визуальный переключатель, игровой эффект отсутствует.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_16_damage_override",
                title = "Damage Override",
                description = "Макет состояния переопределения.",
                kind = "action",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_17_safe_point",
                title = "Safe Point",
                description = "Демонстрационная опция списка.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_18_resolver_preview",
                title = "Resolver Preview",
                description = "Только демонстрационное состояние.",
                kind = "slider",
                default = 35,
                group = "Combat",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "combat_19_accuracy_mode",
                title = "Accuracy Mode",
                description = "Макет выбора режима точности.",
                kind = "dropdown",
                default = "Default",
                group = "Combat",
                options = { "Default", "Prefer Head", "Prefer Body" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_20_spread_preview",
                title = "Spread Preview",
                description = "Локальный ползунок для концепта меню.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_21_recoil_preview",
                title = "Recoil Preview",
                description = "Не меняет отдачу или другие параметры игры.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_22_weapon_profiles",
                title = "Weapon Profiles",
                description = "Демо-список профилей оружия.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_23_target_indicator",
                title = "Target Indicator",
                description = "Меняет лишь визуальное состояние переключателя.",
                kind = "slider",
                default = 60,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_24_shot_log_preview",
                title = "Shot Log Preview",
                description = "Показывает только уведомление интерфейса.",
                kind = "dropdown",
                default = "Default",
                group = "Combat",
                options = { "Default", "Prefer Head", "Prefer Body" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_25_aim_key",
                title = "Aim Key",
                description = "Макет выбора клавиши без бинда.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_26_auto_peek",
                title = "Auto Peek",
                description = "Заглушка, движение персонажа не выполняется.",
                kind = "action",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_27_peek_assist",
                title = "Peek Assist",
                description = "Демонстрационный элемент настройки.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_28_damage_marker",
                title = "Damage Marker",
                description = "Внутренняя настройка макета.",
                kind = "slider",
                default = 25,
                group = "Combat",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "combat_29_prefer_close_range",
                title = "Prefer Close Range",
                description = "Только интерфейсная опция.",
                kind = "dropdown",
                default = "Default",
                group = "Combat",
                options = { "Default", "Prefer Head", "Prefer Body" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_30_combat_preset",
                title = "Combat Preset",
                description = "Демо-кнопка выбора локального пресета.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
    -- Anti-Aim: decorative controls only
    {
        id = "antiaim",
        title = "ANTI-AIM",
        name = "Anti-Aim",
        subtitle = "Anti-aim · интерфейсный прототип",
        features = {
            {
                id = "antiaim_1_anti_aim_master",
                title = "Anti-Aim Master",
                description = "Только декоративный переключатель.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_2_yaw_mode",
                title = "Yaw Mode",
                description = "Демонстрационный выбор режима.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_3_yaw_offset",
                title = "Yaw Offset",
                description = "Число меняется только в этом окне.",
                kind = "slider",
                default = 72,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_4_pitch_mode",
                title = "Pitch Mode",
                description = "Макет списка режимов.",
                kind = "dropdown",
                default = "Off",
                group = "Anti-Aim",
                options = { "Off", "Static", "Jitter", "Spin" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_5_pitch_amount",
                title = "Pitch Amount",
                description = "Визуальный числовой параметр.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_6_desync_preview",
                title = "Desync Preview",
                description = "Не меняет сетевое поведение персонажа.",
                kind = "action",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_7_jitter_mode",
                title = "Jitter Mode",
                description = "Демо-настройка без игровой логики.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_8_jitter_range",
                title = "Jitter Range",
                description = "Ползунок предпросмотра значения.",
                kind = "slider",
                default = 45,
                group = "Anti-Aim",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "antiaim_9_spin_speed",
                title = "Spin Speed",
                description = "Меняет только отображаемую цифру.",
                kind = "dropdown",
                default = "Off",
                group = "Anti-Aim",
                options = { "Off", "Static", "Jitter", "Spin" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_10_fake_flick",
                title = "Fake Flick",
                description = "Визуальная заглушка.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_11_lower_body_yaw",
                title = "Lower Body Yaw",
                description = "Макет переключателя.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_12_freestanding",
                title = "Freestanding",
                description = "Нет расчёта окружения или направлений.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_13_edge_preview",
                title = "Edge Preview",
                description = "Только состояние UI.",
                kind = "slider",
                default = 50,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_14_manual_left",
                title = "Manual Left",
                description = "Не меняет поворот персонажа.",
                kind = "dropdown",
                default = "Off",
                group = "Anti-Aim",
                options = { "Off", "Static", "Jitter", "Spin" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_15_manual_right",
                title = "Manual Right",
                description = "Не меняет поворот персонажа.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_16_manual_back",
                title = "Manual Back",
                description = "Не меняет поворот персонажа.",
                kind = "action",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_17_inverter",
                title = "Inverter",
                description = "Демо-переключатель направления.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_18_anti_bruteforce",
                title = "Anti-Bruteforce",
                description = "Нет анализа игроков или попаданий.",
                kind = "slider",
                default = 35,
                group = "Anti-Aim",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "antiaim_19_fake_lag_preview",
                title = "Fake Lag Preview",
                description = "Не задерживает и не меняет сеть.",
                kind = "dropdown",
                default = "Off",
                group = "Anti-Aim",
                options = { "Off", "Static", "Jitter", "Spin" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_20_condition_standing",
                title = "Condition: Standing",
                description = "Макет условия для профиля.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_21_condition_moving",
                title = "Condition: Moving",
                description = "Макет условия для профиля.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_22_condition_airborne",
                title = "Condition: Airborne",
                description = "Макет условия для профиля.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
    -- Visuals: decorative controls only
    {
        id = "visuals",
        title = "VISUALS",
        name = "Visuals",
        subtitle = "Визуальные настройки · без ESP-логики",
        features = {
            {
                id = "visuals_1_visuals_master",
                title = "Visuals Master",
                description = "Только UI-флаг; никаких объектов не рисуется.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_2_box_overlay",
                title = "Box Overlay",
                description = "Демо-переключатель оверлея.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_3_box_style",
                title = "Box Style",
                description = "Выбор стиля в макете.",
                kind = "slider",
                default = 72,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_4_name_tags",
                title = "Name Tags",
                description = "Не отображает имена над игроками.",
                kind = "dropdown",
                default = "Default",
                group = "Visuals",
                options = { "Default", "Minimal", "Outline", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_5_health_bar",
                title = "Health Bar",
                description = "Не читает здоровье персонажей.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_6_health_bar_style",
                title = "Health Bar Style",
                description = "Демо-список стилей.",
                kind = "action",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_7_skeleton_preview",
                title = "Skeleton Preview",
                description = "Нет отрисовки скелетов.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_8_snap_lines",
                title = "Snap Lines",
                description = "Только переключатель состояния.",
                kind = "slider",
                default = 45,
                group = "Visuals",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "visuals_9_distance_labels",
                title = "Distance Labels",
                description = "Не вычисляет дистанцию.",
                kind = "dropdown",
                default = "Default",
                group = "Visuals",
                options = { "Default", "Minimal", "Outline", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_10_weapon_labels",
                title = "Weapon Labels",
                description = "Не читает предметы игроков.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_11_flags",
                title = "Flags",
                description = "Демо-настройка флагов.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_12_chams_preview",
                title = "Chams Preview",
                description = "Не меняет материалы персонажей.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_13_chams_style",
                title = "Chams Style",
                description = "Визуальный выбор стиля.",
                kind = "slider",
                default = 50,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_14_glow_preview",
                title = "Glow Preview",
                description = "Не создаёт эффекты в мире.",
                kind = "dropdown",
                default = "Default",
                group = "Visuals",
                options = { "Default", "Minimal", "Outline", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_15_glow_strength",
                title = "Glow Strength",
                description = "Демо-ползунок яркости.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_16_offscreen_arrows",
                title = "Offscreen Arrows",
                description = "Не рисует игровые указатели.",
                kind = "action",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_17_arrow_size",
                title = "Arrow Size",
                description = "Изменяет лишь значение в панели.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_18_arrow_radius",
                title = "Arrow Radius",
                description = "Макет радиуса.",
                kind = "slider",
                default = 35,
                group = "Visuals",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "visuals_19_radar_preview",
                title = "Radar Preview",
                description = "Кнопка не создаёт игровой радар.",
                kind = "dropdown",
                default = "Default",
                group = "Visuals",
                options = { "Default", "Minimal", "Outline", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_20_radar_size",
                title = "Radar Size",
                description = "Визуальный ползунок размера.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_21_radar_zoom",
                title = "Radar Zoom",
                description = "Макет масштаба радара.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_22_world_tint",
                title = "World Tint",
                description = "Не перекрашивает мир Roblox.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_23_world_brightness",
                title = "World Brightness",
                description = "Не меняет Lighting.",
                kind = "slider",
                default = 60,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_24_skybox_preview",
                title = "Skybox Preview",
                description = "Нет замены skybox.",
                kind = "dropdown",
                default = "Default",
                group = "Visuals",
                options = { "Default", "Minimal", "Outline", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_25_fog_preview",
                title = "Fog Preview",
                description = "Не изменяет туман.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_26_third_person_preview",
                title = "Third Person Preview",
                description = "Камера не переключается.",
                kind = "action",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_27_viewmodel_offset",
                title = "Viewmodel Offset",
                description = "Не двигает viewmodel.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_28_viewmodel_fov",
                title = "Viewmodel FOV",
                description = "Только отображаемое значение.",
                kind = "slider",
                default = 25,
                group = "Visuals",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "visuals_29_hitmarker_preview",
                title = "Hitmarker Preview",
                description = "Показывает только UI-уведомление.",
                kind = "dropdown",
                default = "Default",
                group = "Visuals",
                options = { "Default", "Minimal", "Outline", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_30_damage_numbers",
                title = "Damage Numbers",
                description = "Не создаёт цифры у целей.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_31_crosshair_style",
                title = "Crosshair Style",
                description = "Демо-список вариантов прицела.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_32_crosshair_size",
                title = "Crosshair Size",
                description = "Ползунок предпросмотра.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
    -- Movement: decorative controls only
    {
        id = "movement",
        title = "MOVEMENT",
        name = "Movement",
        subtitle = "Перемещение · все параметры неактивны",
        features = {
            {
                id = "movement_1_movement_master",
                title = "Movement Master",
                description = "Декоративный переключатель.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_2_bunny_hop_preview",
                title = "Bunny Hop Preview",
                description = "Не управляет прыжками.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_3_auto_strafe_preview",
                title = "Auto Strafe Preview",
                description = "Не меняет движение.",
                kind = "slider",
                default = 72,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_4_air_strafe_mode",
                title = "Air Strafe Mode",
                description = "Макет списка режимов.",
                kind = "dropdown",
                default = "Default",
                group = "Movement",
                options = { "Default", "Subtle", "Classic" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_5_speed_display",
                title = "Speed Display",
                description = "Не меняет WalkSpeed.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_6_speed_value",
                title = "Speed Value",
                description = "Только цифра в интерфейсе.",
                kind = "action",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_7_jump_height",
                title = "Jump Height",
                description = "Не меняет силу прыжка.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_8_long_jump_preview",
                title = "Long Jump Preview",
                description = "Игрового действия нет.",
                kind = "slider",
                default = 45,
                group = "Movement",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "movement_9_edge_bug_preview",
                title = "Edge Bug Preview",
                description = "Демо-заглушка.",
                kind = "dropdown",
                default = "Default",
                group = "Movement",
                options = { "Default", "Subtle", "Classic" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_10_slow_walk",
                title = "Slow Walk",
                description = "Не изменяет скорость игрока.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_11_slow_walk_amount",
                title = "Slow Walk Amount",
                description = "Визуальный ползунок значения.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_12_crouch_assist",
                title = "Crouch Assist",
                description = "Не вызывает приседание.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_13_crouch_mode",
                title = "Crouch Mode",
                description = "Макет выбора режима.",
                kind = "slider",
                default = 50,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_14_slide_preview",
                title = "Slide Preview",
                description = "Не создаёт скольжение.",
                kind = "dropdown",
                default = "Default",
                group = "Movement",
                options = { "Default", "Subtle", "Classic" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_15_ladder_assist",
                title = "Ladder Assist",
                description = "Не взаимодействует с лестницами.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_16_water_movement",
                title = "Water Movement",
                description = "Не изменяет физику воды.",
                kind = "action",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_17_no_clip_preview",
                title = "No Clip Preview",
                description = "Не меняет столкновения.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_18_fly_preview",
                title = "Fly Preview",
                description = "Не поднимает и не двигает персонажа.",
                kind = "slider",
                default = 35,
                group = "Movement",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "movement_19_teleport_preset",
                title = "Teleport Preset",
                description = "Не телепортирует игрока.",
                kind = "dropdown",
                default = "Default",
                group = "Movement",
                options = { "Default", "Subtle", "Classic" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_20_movement_preset",
                title = "Movement Preset",
                description = "Кнопка показывает только уведомление.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
    -- Player: decorative controls only
    {
        id = "player",
        title = "PLAYER",
        name = "Player",
        subtitle = "Параметры игрока · UI-only",
        features = {
            {
                id = "player_1_player_panel",
                title = "Player Panel",
                description = "Включает только визуальную метку в меню.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_2_local_status",
                title = "Local Status",
                description = "Не читает чувствительные данные.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_3_profile_name",
                title = "Profile Name",
                description = "Демо-строка профиля.",
                kind = "slider",
                default = 72,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_4_profile_color",
                title = "Profile Color",
                description = "Макет выбора цвета профиля.",
                kind = "dropdown",
                default = "Default",
                group = "Player",
                options = { "Default", "Minimal", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "player_5_fake_rank",
                title = "Fake Rank",
                description = "Не меняет ранг или статистику.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_6_fake_level",
                title = "Fake Level",
                description = "Не меняет уровень аккаунта.",
                kind = "action",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_7_stat_preview",
                title = "Stat Preview",
                description = "Показывает только интерфейсный статус.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_8_health_display",
                title = "Health Display",
                description = "Не изменяет здоровье персонажа.",
                kind = "slider",
                default = 45,
                group = "Player",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "player_9_armor_display",
                title = "Armor Display",
                description = "Демо-настройка отображения.",
                kind = "dropdown",
                default = "Default",
                group = "Player",
                options = { "Default", "Minimal", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "player_10_stamina_preview",
                title = "Stamina Preview",
                description = "Не читает и не меняет выносливость.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_11_player_tag",
                title = "Player Tag",
                description = "Не меняет ник над персонажем.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_12_custom_tag_text",
                title = "Custom Tag Text",
                description = "Локальный текст для макета.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_13_tag_style",
                title = "Tag Style",
                description = "Демо-выбор стиля.",
                kind = "slider",
                default = 50,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_14_color_accent",
                title = "Color Accent",
                description = "Не меняет системные настройки.",
                kind = "dropdown",
                default = "Default",
                group = "Player",
                options = { "Default", "Minimal", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "player_15_hud_compact_mode",
                title = "HUD Compact Mode",
                description = "Переключает только оформление панели.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_16_hud_scale",
                title = "HUD Scale",
                description = "Масштабирует только элементы меню.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_17_hud_opacity",
                title = "HUD Opacity",
                description = "Демо-параметр прозрачности.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_18_notification_style",
                title = "Notification Style",
                description = "Выбирает стиль уведомлений.",
                kind = "slider",
                default = 35,
                group = "Player",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "player_19_status_badge",
                title = "Status Badge",
                description = "Не отправляет сообщения другим игрокам.",
                kind = "dropdown",
                default = "Default",
                group = "Player",
                options = { "Default", "Minimal", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "player_20_player_preset",
                title = "Player Preset",
                description = "Кнопка показывает уведомление.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
    -- World: decorative controls only
    {
        id = "world",
        title = "WORLD",
        name = "World",
        subtitle = "Окружение · без изменений Workspace",
        features = {
            {
                id = "world_1_world_panel",
                title = "World Panel",
                description = "Только UI-переключатель.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_2_ambient_preview",
                title = "Ambient Preview",
                description = "Не меняет Lighting.Ambient.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_3_clock_time",
                title = "Clock Time",
                description = "Не меняет время в мире.",
                kind = "slider",
                default = 72,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_4_time_preset",
                title = "Time Preset",
                description = "Демо-список времени.",
                kind = "dropdown",
                default = "Default",
                group = "World",
                options = { "Default", "Day", "Night", "Muted" },
                min = 0,
                max = 100,
            },
            {
                id = "world_5_rain_preview",
                title = "Rain Preview",
                description = "Не создаёт погодные эффекты.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_6_snow_preview",
                title = "Snow Preview",
                description = "Не создаёт частицы в Workspace.",
                kind = "action",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_7_particle_density",
                title = "Particle Density",
                description = "Меняет только числовую надпись.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_8_bloom_preview",
                title = "Bloom Preview",
                description = "Не добавляет BloomEffect.",
                kind = "slider",
                default = 45,
                group = "World",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "world_9_color_correction",
                title = "Color Correction",
                description = "Не меняет постобработку.",
                kind = "dropdown",
                default = "Default",
                group = "World",
                options = { "Default", "Day", "Night", "Muted" },
                min = 0,
                max = 100,
            },
            {
                id = "world_10_blur_preview",
                title = "Blur Preview",
                description = "Не применяет размытие камеры.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_11_sun_rays_preview",
                title = "Sun Rays Preview",
                description = "Не создаёт SunRaysEffect.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_12_atmosphere_preview",
                title = "Atmosphere Preview",
                description = "Не меняет Atmosphere.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_13_terrain_preview",
                title = "Terrain Preview",
                description = "Не изменяет Terrain.",
                kind = "slider",
                default = 50,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_14_water_color",
                title = "Water Color",
                description = "Не перекрашивает воду.",
                kind = "dropdown",
                default = "Default",
                group = "World",
                options = { "Default", "Day", "Night", "Muted" },
                min = 0,
                max = 100,
            },
            {
                id = "world_15_material_preview",
                title = "Material Preview",
                description = "Не меняет материалы объектов.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_16_world_theme",
                title = "World Theme",
                description = "Локальный выбор названия темы.",
                kind = "action",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_17_environment_profile",
                title = "Environment Profile",
                description = "Демо-переключатель профиля.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_18_lighting_profile",
                title = "Lighting Profile",
                description = "Никаких изменений освещения.",
                kind = "slider",
                default = 35,
                group = "World",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "world_19_world_reset_preview",
                title = "World Reset Preview",
                description = "Показывает уведомление, ничего не сбрасывает.",
                kind = "dropdown",
                default = "Default",
                group = "World",
                options = { "Default", "Day", "Night", "Muted" },
                min = 0,
                max = 100,
            },
            {
                id = "world_20_world_preset",
                title = "World Preset",
                description = "Демо-кнопка пресета.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
    -- Miscellaneous: decorative controls only
    {
        id = "misc",
        title = "MISC",
        name = "Miscellaneous",
        subtitle = "Дополнительные элементы интерфейса",
        features = {
            {
                id = "misc_1_watermark",
                title = "Watermark",
                description = "Локальный элемент интерфейса.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_2_watermark_style",
                title = "Watermark Style",
                description = "Выбор оформления надписи.",
                kind = "dropdown",
                default = "Default",
                group = "Misc",
                options = { "Default", "Compact", "Expanded" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_3_keybind_list",
                title = "Keybind List",
                description = "Не перехватывает игровые клавиши.",
                kind = "slider",
                default = 72,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_4_keybind_theme",
                title = "Keybind Theme",
                description = "Демо-выбор темы.",
                kind = "dropdown",
                default = "Default",
                group = "Misc",
                options = { "Default", "Compact", "Expanded" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_5_event_log_preview",
                title = "Event Log Preview",
                description = "Добавляет только локальную заметку.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_6_show_debug_labels",
                title = "Show Debug Labels",
                description = "Переключает метки только в меню.",
                kind = "action",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_7_menu_sounds",
                title = "Menu Sounds",
                description = "Без воспроизведения звуков игры.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_8_animations",
                title = "Animations",
                description = "Включает анимации UI.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_9_reduced_motion",
                title = "Reduced Motion",
                description = "Выключает часть UI-анимаций.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_10_open_on_spawn",
                title = "Open On Spawn",
                description = "Не сохраняет данные между сессиями.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_11_confirm_actions",
                title = "Confirm Actions",
                description = "Макет подтверждения действий.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_12_toast_duration",
                title = "Toast Duration",
                description = "Демо-ползунок длительности уведомления.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_13_ui_blur_preview",
                title = "UI Blur Preview",
                description = "Не применяет blur к игре.",
                kind = "slider",
                default = 50,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_14_panel_shadow",
                title = "Panel Shadow",
                description = "Настройка тени карточки.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_15_rounded_corners",
                title = "Rounded Corners",
                description = "Макет переключателя оформления.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_16_compact_rows",
                title = "Compact Rows",
                description = "Сжимает только список настроек.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_17_accent_animation",
                title = "Accent Animation",
                description = "Декоративная настройка.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_18_rainbow_accent",
                title = "Rainbow Accent",
                description = "Только выбор режима без бесконечного эффекта.",
                kind = "toggle",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_19_safe_mode_badge",
                title = "Safe Mode Badge",
                description = "Показывает отметку UI-only.",
                kind = "dropdown",
                default = "Default",
                group = "Misc",
                options = { "Default", "Compact", "Expanded" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_20_reset_ui_state",
                title = "Reset UI State",
                description = "Сбрасывает только локальные значения меню.",
                kind = "action",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_21_copy_ui_credits",
                title = "Copy UI Credits",
                description = "Кнопка покажет уведомление.",
                kind = "action",
                default = false,
                group = "Misc",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_22_misc_preset",
                title = "Misc Preset",
                description = "Демо-кнопка локального пресета.",
                kind = "dropdown",
                default = "Default",
                group = "Misc",
                options = { "Default", "Compact", "Expanded" },
                min = 0,
                max = 100,
            },
        },
    },
    -- Config: decorative controls only
    {
        id = "config",
        title = "CONFIG",
        name = "Config",
        subtitle = "Пресеты и настройки интерфейса (демо)",
        features = {
            {
                id = "config_1_active_config",
                title = "Active Config",
                description = "Список виртуальных профилей.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_2_config_slot",
                title = "Config Slot",
                description = "Демо-выбор слота.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_3_load_config",
                title = "Load Config",
                description = "Ничего не загружает с диска или сервера.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_4_save_config",
                title = "Save Config",
                description = "Ничего не сохраняет за пределами текущего UI.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_5_create_config",
                title = "Create Config",
                description = "Только уведомление интерфейса.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_6_rename_config",
                title = "Rename Config",
                description = "Не создаёт файлы.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_7_delete_config",
                title = "Delete Config",
                description = "Не удаляет никаких данных.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_8_export_preview",
                title = "Export Preview",
                description = "Не копирует исполняемый код.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_9_import_preview",
                title = "Import Preview",
                description = "Не читает содержимое буфера обмена.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_10_config_theme",
                title = "Config Theme",
                description = "Демо-выбор темы.",
                kind = "dropdown",
                default = "Slot 1",
                group = "Config",
                options = { "Slot 1", "Slot 2", "Slot 3", "Slot 4" },
                min = 0,
                max = 100,
            },
            {
                id = "config_11_config_notes",
                title = "Config Notes",
                description = "Локальный выбор заметки.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_12_auto_save",
                title = "Auto Save",
                description = "Не сохраняет параметры.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_13_config_backup",
                title = "Config Backup",
                description = "Нет доступа к файлам.",
                kind = "dropdown",
                default = "Slot 1",
                group = "Config",
                options = { "Slot 1", "Slot 2", "Slot 3", "Slot 4" },
                min = 0,
                max = 100,
            },
            {
                id = "config_14_reset_combat_ui",
                title = "Reset Combat UI",
                description = "Сбрасывает только значения вкладки.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_15_reset_visual_ui",
                title = "Reset Visual UI",
                description = "Сбрасывает только значения вкладки.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_16_reset_all_ui",
                title = "Reset All UI",
                description = "Восстанавливает стартовые значения макета.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_17_preset_aquamarine",
                title = "Preset: Aquamarine",
                description = "Демо-кнопка пресета.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_18_preset_midnight",
                title = "Preset: Midnight",
                description = "Демо-кнопка пресета.",
                kind = "slider",
                default = 35,
                group = "Config",
                options = {},
                min = 1,
                max = 180,
            },
        },
    },
    -- About: decorative controls only
    {
        id = "about",
        title = "ABOUT",
        name = "About",
        subtitle = "Информация о визуальном макете",
        features = {
            {
                id = "about_1_build_channel",
                title = "Build Channel",
                description = "Показывает только название версии.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_2_version_label",
                title = "Version Label",
                description = "Локальная строка версии.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_3_mobile_layout",
                title = "Mobile Layout",
                description = "Адаптация размеров окна к экрану.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_4_touch_input",
                title = "Touch Input",
                description = "Поддерживает нажатия и перетаскивание.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_5_ui_diagnostics",
                title = "UI Diagnostics",
                description = "Показывает уведомление интерфейса.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_6_credits",
                title = "Credits",
                description = "Демо-кнопка с информацией об авторстве.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_7_documentation",
                title = "Documentation",
                description = "Показывает краткую подсказку.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_8_safety_notice",
                title = "Safety Notice",
                description = "Все игровые функции являются заглушками.",
                kind = "slider",
                default = 45,
                group = "About",
                options = {},
                min = 1,
                max = 180,
            },
            {
                id = "about_9_theme_preview",
                title = "Theme Preview",
                description = "Демо-выбор темы оформления.",
                kind = "dropdown",
                default = "Aquamarine",
                group = "About",
                options = { "Aquamarine", "Midnight", "Graphite" },
                min = 0,
                max = 100,
            },
            {
                id = "about_10_reset_window_position",
                title = "Reset Window Position",
                description = "Возвращает окно в центр экрана.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_11_reopen_button",
                title = "Reopen Button",
                description = "Показывает кнопку быстрого открытия.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_12_close_menu",
                title = "Close Menu",
                description = "Скрывает меню, оставляя кнопку открытия.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
        },
    },
}
--// Index catalog for quick UI lookups ----------------------------------------
for _, tab in ipairs(CATALOG) do
    tabById[tab.id] = tab
    for _, item in ipairs(tab.features) do
        featureById[item.id] = item
        if state.values[item.id] == nil then
            state.values[item.id] = item.default
        end
    end
end

--// ScreenGui -----------------------------------------------------------------
local existingGui = PlayerGui:FindFirstChild("AquamarineHvHPrototype")
if existingGui then
    existingGui:Destroy()
end

local ScreenGui = make("ScreenGui", {
    Name = "AquamarineHvHPrototype",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 99,
    Enabled = true,
}, PlayerGui)

-- A soft overlay keeps the panel distinct without obscuring the whole game.
local backdrop = make("TextButton", {
    Name = "Backdrop",
    AutoButtonColor = false,
    Text = "",
    BackgroundColor3 = COLORS.Black,
    BackgroundTransparency = 0.62,
    BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1),
    Visible = false,
    ZIndex = 1,
}, ScreenGui)

-- Main floating window. Its pixel size is updated for both portrait and landscape.
local window = make("Frame", {
    Name = "MainWindow",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(740, 610),
    BackgroundColor3 = COLORS.Window,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 2,
    Visible = true,
}, ScreenGui)
addCorner(window, SETTINGS.WindowRadius)
addStroke(window, COLORS.Border, 1.2, 0.12)

local windowGradient = make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(16, 27, 39)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 16, 24)),
    }),
    Rotation = 90,
}, window)

-- Topbar ----------------------------------------------------------------------
local topbar = make("Frame", {
    Name = "Topbar",
    BackgroundColor3 = COLORS.Header,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, SETTINGS.HeaderHeight),
    Position = UDim2.new(0, 0, 0, 0),
    ZIndex = 3,
    Active = true,
}, window)
addCorner(topbar, SETTINGS.WindowRadius)

local topbarCover = make("Frame", {
    Name = "HeaderSquareBottom",
    BackgroundColor3 = COLORS.Header,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    ZIndex = 3,
}, topbar)

local logoMark = make("Frame", {
    Name = "LogoMark",
    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 14, 0, 13),
    Size = UDim2.fromOffset(28, 28),
    ZIndex = 4,
}, topbar)
addCorner(logoMark, 8)

local logoLetter = makeLabel(logoMark, "A", 16, UDim2.new(), FONT_HEAVY, COLORS.Window, Enum.TextXAlignment.Center)
logoLetter.Size = UDim2.fromScale(1, 1)
logoLetter.ZIndex = 5

local titleLabel = makeLabel(topbar, APP_NAME, 15, UDim2.new(0, 52, 0, 8), FONT_HEAVY, COLORS.Text)
titleLabel.Size = UDim2.new(0, 160, 0, 20)
titleLabel.ZIndex = 4

local subtitleLabel = makeLabel(topbar, APP_SUBTITLE .. "  /  v" .. APP_VERSION, 9, UDim2.new(0, 53, 0, 29), FONT_MEDIUM, COLORS.TextSoft)
subtitleLabel.Size = UDim2.new(0, 190, 0, 14)
subtitleLabel.ZIndex = 4

local safetyBadge = make("Frame", {
    Name = "SafetyBadge",
    BackgroundColor3 = COLORS.AccentSoft,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -112, 0.5, 0),
    Size = UDim2.fromOffset(134, 24),
    ZIndex = 4,
}, topbar)
addCorner(safetyBadge, 7)

local safetyDot = make("Frame", {
    Name = "SafetyDot",
    BackgroundColor3 = COLORS.Positive,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0.5, -3),
    Size = UDim2.fromOffset(6, 6),
    ZIndex = 5,
}, safetyBadge)
addCorner(safetyDot, 4)

local safetyText = makeLabel(safetyBadge, "UI ONLY", 9, UDim2.new(0, 20, 0, 0), FONT_BOLD, COLORS.Accent)
safetyText.Size = UDim2.new(1, -24, 1, 0)
safetyText.ZIndex = 5

local minimizeButton = makeButton(topbar, "—", UDim2.fromOffset(30, 30), COLORS.Card, COLORS.TextSoft)
minimizeButton.Name = "MinimizeButton"
minimizeButton.Position = UDim2.new(1, -72, 0.5, -15)
minimizeButton.ZIndex = 5

local closeButton = makeButton(topbar, "×", UDim2.fromOffset(30, 30), COLORS.Card, COLORS.Negative)
closeButton.Name = "CloseButton"
closeButton.Position = UDim2.new(1, -36, 0.5, -15)
closeButton.ZIndex = 5

local headerLine = make("Frame", {
    Name = "HeaderDivider",
    BackgroundColor3 = COLORS.Border,
    BackgroundTransparency = 0.25,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 4,
}, topbar)

-- Navigation ------------------------------------------------------------------
local nav = make("ScrollingFrame", {
    Name = "TabNavigation",
    BackgroundColor3 = COLORS.Window,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, SETTINGS.HeaderHeight),
    Size = UDim2.new(1, 0, 0, SETTINGS.NavigationHeight),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.X,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = COLORS.AccentDeep,
    ScrollingDirection = Enum.ScrollingDirection.X,
    HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
    VerticalScrollBarInset = Enum.ScrollBarInset.None,
    ClipsDescendants = true,
    ZIndex = 3,
}, window)
addPadding(nav, 10, 5, 10, 5)
local navLayout = addList(nav, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

-- Content body ----------------------------------------------------------------
local content = make("Frame", {
    Name = "ContentBody",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, SETTINGS.HeaderHeight + SETTINGS.NavigationHeight),
    Size = UDim2.new(1, 0, 1, -(SETTINGS.HeaderHeight + SETTINGS.NavigationHeight)),
    ZIndex = 3,
    ClipsDescendants = true,
}, window)

local sectionHeader = make("Frame", {
    Name = "SectionHeader",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 14, 0, 8),
    Size = UDim2.new(1, -28, 0, 42),
    ZIndex = 3,
}, content)

local sectionTitle = makeLabel(sectionHeader, "COMBAT", 14, UDim2.new(0, 0, 0, 0), FONT_BOLD, COLORS.Text)
sectionTitle.Size = UDim2.new(0.55, -5, 0, 20)
sectionTitle.ZIndex = 4

local sectionSubtitle = makeLabel(sectionHeader, "Боевой раздел · визуальные заглушки", 9, UDim2.new(0, 0, 0, 20), FONT, COLORS.TextSoft)
sectionSubtitle.Size = UDim2.new(0.65, -5, 0, 15)
sectionSubtitle.ZIndex = 4

local searchBox = make("TextBox", {
    Name = "SearchBox",
    ClearTextOnFocus = false,
    PlaceholderText = SETTINGS.SearchPlaceholder,
    Text = "",
    TextColor3 = COLORS.Text,
    PlaceholderColor3 = COLORS.TextMuted,
    Font = FONT,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = COLORS.Card,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -156, 0, 5),
    Size = UDim2.fromOffset(156, 30),
    ZIndex = 4,
}, sectionHeader)
addCorner(searchBox, 8)
addStroke(searchBox, COLORS.Border, 1, 0.25)
addPadding(searchBox, 10, 0, 6, 0)

local searchGlyph = makeLabel(sectionHeader, "⌕", 16, UDim2.new(1, -27, 0, 5), FONT_BOLD, COLORS.TextSoft, Enum.TextXAlignment.Center)
searchGlyph.Size = UDim2.fromOffset(20, 30)
searchGlyph.ZIndex = 5
searchGlyph.Active = false

local scroll = make("ScrollingFrame", {
    Name = "SettingsScroll",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 54),
    Size = UDim2.new(1, -24, 1, -92),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.AccentDeep,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
    HorizontalScrollBarInset = Enum.ScrollBarInset.None,
    ClipsDescendants = true,
    ZIndex = 3,
}, content)
addPadding(scroll, 1, 2, 5, 12)
local scrollLayout = addList(scroll, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

local footer = make("Frame", {
    Name = "Footer",
    BackgroundColor3 = COLORS.Header,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -30),
    Size = UDim2.new(1, 0, 0, 30),
    ZIndex = 4,
}, content)

local footerLine = make("Frame", {
    Name = "FooterDivider",
    BackgroundColor3 = COLORS.Border,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 1),
    ZIndex = 5,
}, footer)

local footerStatusDot = make("Frame", {
    Name = "FooterStatusDot",
    BackgroundColor3 = COLORS.Positive,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 14, 0.5, -3),
    Size = UDim2.fromOffset(6, 6),
    ZIndex = 5,
}, footer)
addCorner(footerStatusDot, 5)

local footerStatus = makeLabel(footer, UI_ONLY_NOTICE, 8, UDim2.new(0, 26, 0, 0), FONT_MEDIUM, COLORS.TextSoft)
footerStatus.Size = UDim2.new(0.72, -26, 1, 0)
footerStatus.ZIndex = 5

local footerCount = makeLabel(footer, "0 ITEMS", 8, UDim2.new(1, -94, 0, 0), FONT_BOLD, COLORS.Accent, Enum.TextXAlignment.Right)
footerCount.Size = UDim2.new(0, 78, 1, 0)
footerCount.ZIndex = 5

-- Toast area ------------------------------------------------------------------
toastHost = make("Frame", {
    Name = "ToastHost",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -10, 1, -10),
    Size = UDim2.fromOffset(250, 150),
    ZIndex = 50,
}, ScreenGui)
addList(toastHost, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

-- Floating reopen button is kept separate from the main window. ----------------
local reopenButton = make("TextButton", {
    Name = "ReopenAquamarine",
    AutoButtonColor = false,
    Text = "A",
    TextColor3 = COLORS.Window,
    Font = FONT_HEAVY,
    TextSize = 16,
    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -14, 1, -18),
    Size = UDim2.fromOffset(46, 46),
    Visible = false,
    ZIndex = 40,
    Active = true,
    Selectable = true,
}, ScreenGui)
addCorner(reopenButton, 14)
addStroke(reopenButton, COLORS.White, 1, 0.72)

local reopenHint = makeLabel(ScreenGui, "AQUAMARINE", 8, UDim2.new(1, -110, 1, -56), FONT_BOLD, COLORS.TextSoft, Enum.TextXAlignment.Right)
reopenHint.Size = UDim2.fromOffset(90, 18)
reopenHint.Visible = false
reopenHint.ZIndex = 39

--// Tab buttons ---------------------------------------------------------------
local function setTabButtonAppearance(button, active)
    if active then
        button.BackgroundColor3 = COLORS.AccentSoft
        button.TextColor3 = COLORS.Accent
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = COLORS.AccentDeep
            stroke.Transparency = 0.1
        end
    else
        button.BackgroundColor3 = COLORS.Header
        button.TextColor3 = COLORS.TextSoft
        local stroke = button:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = COLORS.Border
            stroke.Transparency = 0.6
        end
    end
end

for index, tab in ipairs(CATALOG) do
    local button = makeButton(nav, tab.title, UDim2.fromOffset(math.max(58, #tab.title * 7 + 22), 29), COLORS.Header, COLORS.TextSoft)
    button.Name = "Tab_" .. tab.id
    button.LayoutOrder = index
    button.TextSize = 10
    button:SetAttribute("TabId", tab.id)
    tabButtons[tab.id] = button
    setTabButtonAppearance(button, tab.id == state.activeTab)
end

--// Control components ---------------------------------------------------------
local function makeToggleControl(parent, item)
    local button = make("TextButton", {
        Name = "ToggleControl",
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = COLORS.MutedBorder,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(46, 25),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        ZIndex = 7,
    }, parent)
    addCorner(button, 13)
    local knob = make("Frame", {
        Name = "Knob",
        BackgroundColor3 = COLORS.TextSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 0.5, -9),
        Size = UDim2.fromOffset(18, 18),
        ZIndex = 8,
    }, button)
    addCorner(knob, 10)
    local miniLabel = makeLabel(parent, "OFF", 8, UDim2.new(1, -82, 0.5, -6), FONT_BOLD, COLORS.TextMuted, Enum.TextXAlignment.Right)
    miniLabel.Size = UDim2.fromOffset(30, 12)
    miniLabel.ZIndex = 7

    local function refresh(animated)
        local active = getLocalValue(item) == true
        local position = active and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local color = active and COLORS.AccentDeep or COLORS.TextSoft
        local bg = active and COLORS.AccentSoft or COLORS.MutedBorder
        if animated then
            tween(knob, 0.12, { Position = position, BackgroundColor3 = active and COLORS.White or COLORS.TextSoft })
            tween(button, 0.12, { BackgroundColor3 = bg })
        else
            knob.Position = position
            knob.BackgroundColor3 = active and COLORS.White or COLORS.TextSoft
            button.BackgroundColor3 = bg
        end
        miniLabel.Text = active and "ON" or "OFF"
        miniLabel.TextColor3 = active and COLORS.Accent or COLORS.TextMuted
    end

    button.Activated:Connect(function()
        setLocalValue(item, not (getLocalValue(item) == true))
        refresh(true)
        if item.title == "Reduced Motion" then
            state.reducedMotion = getLocalValue(item) == true
        elseif item.title == "Compact Rows" then
            state.compactRows = getLocalValue(item) == true
            renderActiveTab()
        elseif item.title == "HUD Scale" then
            notifyUiOnly("HUD Scale")
        elseif item.title == "Rounded Corners" then
            notifyUiOnly("Rounded Corners")
        elseif item.title == "Panel Shadow" then
            notifyUiOnly("Panel Shadow")
        elseif item.title == "Accent Animation" or item.title == "Rainbow Accent" then
            notifyUiOnly(item.title)
        end
    end)
    refresh(false)
    return button
end

local function makeSliderControl(parent, item)
    local holder = make("Frame", {
        Name = "SliderControl",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(112, 44),
        ZIndex = 7,
    }, parent)

    local minus = makeButton(holder, "−", UDim2.fromOffset(20, 20), COLORS.Header, COLORS.TextSoft)
    minus.Position = UDim2.new(0, 0, 0, 0)
    minus.TextSize = 14
    minus.ZIndex = 8

    local valueLabel = makeLabel(holder, formatValue(getLocalValue(item)), 10, UDim2.new(0, 24, 0, 0), FONT_BOLD, COLORS.Accent, Enum.TextXAlignment.Center)
    valueLabel.Size = UDim2.fromOffset(64, 20)
    valueLabel.ZIndex = 8

    local plus = makeButton(holder, "+", UDim2.fromOffset(20, 20), COLORS.Header, COLORS.TextSoft)
    plus.Position = UDim2.new(1, -20, 0, 0)
    plus.TextSize = 14
    plus.ZIndex = 8

    local track = make("Frame", {
        Name = "Track",
        BackgroundColor3 = COLORS.MutedBorder,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 29),
        Size = UDim2.new(1, 0, 0, 6),
        ZIndex = 8,
        Active = true,
    }, holder)
    addCorner(track, 5)

    local fill = make("Frame", {
        Name = "Fill",
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 9,
    }, track)
    addCorner(fill, 5)

    local function update(value, animated)
        local minValue = item.min or 0
        local maxValue = item.max or 100
        value = clamp(round(value), minValue, maxValue)
        setLocalValue(item, value)
        local alpha = (value - minValue) / math.max(1, maxValue - minValue)
        valueLabel.Text = formatValue(value)
        if animated then
            tween(fill, 0.08, { Size = UDim2.new(alpha, 0, 1, 0) })
        else
            fill.Size = UDim2.new(alpha, 0, 1, 0)
        end
    end

    local step = (item.max or 100) - (item.min or 0) > 100 and 5 or 1
    minus.Activated:Connect(function()
        update((tonumber(getLocalValue(item)) or 0) - step, true)
    end)
    plus.Activated:Connect(function()
        update((tonumber(getLocalValue(item)) or 0) + step, true)
    end)

    local function updateFromInput(input)
        if not track or not track.Parent then
            return
        end
        local width = math.max(1, track.AbsoluteSize.X)
        local rel = clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
        local value = (item.min or 0) + rel * ((item.max or 100) - (item.min or 0))
        update(value, false)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            currentSliderDrag = {
                itemId = item.id,
                track = track,
                update = updateFromInput,
                inputType = input.UserInputType,
            }
            updateFromInput(input)
        end
    end)

    update(tonumber(getLocalValue(item)) or 0, false)
    return holder
end

local function makeDropdownControl(parent, item)
    local options = item.options or { "Default", "Option 2", "Option 3" }
    if #options == 0 then
        options = { "Default" }
    end
    local current = tostring(getLocalValue(item) or options[1])
    local button = makeButton(parent, shorten(current, 12) .. "  ▾", UDim2.fromOffset(108, 30), COLORS.Header, COLORS.Accent)
    button.Name = "DropdownControl"
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.TextSize = 9
    button.ZIndex = 8
    local function refresh()
        button.Text = shorten(tostring(getLocalValue(item) or options[1]), 12) .. "  ▾"
    end
    button.Activated:Connect(function()
        local value = tostring(getLocalValue(item) or options[1])
        local currentIndex = 1
        for index, option in ipairs(options) do
            if option == value then
                currentIndex = index
                break
            end
        end
        currentIndex += 1
        if currentIndex > #options then
            currentIndex = 1
        end
        setLocalValue(item, options[currentIndex])
        refresh()
    end)
    refresh()
    return button
end

local function makeActionControl(parent, item)
    local button = makeButton(parent, "EXECUTE", UDim2.fromOffset(88, 30), COLORS.AccentSoft, COLORS.Accent)
    button.Name = "ActionControl"
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    button.TextSize = 9
    button.ZIndex = 8
    button.Activated:Connect(function()
        if item.title == "Reset UI State" or item.title == "Reset All UI" then
            for _, tab in ipairs(CATALOG) do
                for _, entry in ipairs(tab.features) do
                    setLocalValue(entry, entry.default)
                end
            end
            state.query = ""
            searchBox.Text = ""
            showToast("UI-состояния сброшены", "success")
            renderActiveTab()
        elseif item.title == "Reset Combat UI" or item.title == "Reset Visual UI" then
            local desiredTab = item.title == "Reset Combat UI" and "combat" or "visuals"
            local tab = tabById[desiredTab]
            if tab then
                for _, entry in ipairs(tab.features) do
                    setLocalValue(entry, entry.default)
                end
            end
            showToast("Сброшены значения UI", "success")
            renderActiveTab()
        elseif item.title == "Reset Window Position" then
            window.Position = UDim2.fromScale(0.5, 0.5)
            showToast("Окно возвращено в центр", "success")
        elseif item.title == "Close Menu" then
            window.Visible = false
            reopenButton.Visible = true
            reopenHint.Visible = true
            state.windowVisible = false
        elseif item.title == "Reopen Button" then
            reopenButton.Visible = true
            reopenHint.Visible = true
            showToast("Кнопка открытия включена", "success")
        elseif item.title == "Load Config" or item.title == "Save Config" or item.title == "Create Config" or item.title == "Delete Config" or item.title == "Rename Config" or item.title == "Export Preview" or item.title == "Import Preview" then
            notifyUiOnly(item.title)
        elseif item.title == "Documentation" then
            showToast("LocalScript · Roblox Studio · UI only", "success")
        elseif item.title == "Credits" or item.title == "Copy UI Credits" then
            showToast("Aquamarine UI concept · demo build", "success")
        elseif item.title == "UI Diagnostics" then
            showToast("Панель работает в режиме макета", "success")
        else
            notifyUiOnly(item.title)
        end
    end)
    return button
end

--// Feature cards -------------------------------------------------------------
local function createFeatureRow(item, order)
    local rowHeight = state.compactRows and SETTINGS.CompactRowHeight or SETTINGS.RowHeight
    local row = make("Frame", {
        Name = "FeatureRow_" .. item.id,
        BackgroundColor3 = COLORS.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -2, 0, rowHeight),
        LayoutOrder = order or 1,
        ZIndex = 4,
        ClipsDescendants = true,
    }, scroll)
    row:SetAttribute("DynamicRow", true)
    row:SetAttribute("FeatureId", item.id)
    addCorner(row, 9)
    addStroke(row, COLORS.Border, 1, 0.45)

    local accentRail = make("Frame", {
        Name = "LeftAccent",
        BackgroundColor3 = COLORS.AccentDeep,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 12),
        Size = UDim2.new(0, 2, 1, -24),
        ZIndex = 5,
    }, row)
    addCorner(accentRail, 2)

    local title = makeLabel(row, item.title, 11, UDim2.new(0, 12, 0, 12), FONT_BOLD, COLORS.Text)
    title.Name = "FeatureTitle"
    title.Size = UDim2.new(1, -145, 0, 18)
    title.ZIndex = 6

    local description = makeLabel(row, item.description or "Демонстрационный параметр интерфейса.", 9, UDim2.new(0, 12, 0, 32), FONT, COLORS.TextSoft)
    description.Name = "FeatureDescription"
    description.Size = UDim2.new(1, -145, 0, 30)
    description.TextYAlignment = Enum.TextYAlignment.Top
    description.TextWrapped = true
    description.TextTruncate = Enum.TextTruncate.AtEnd
    description.ZIndex = 6

    local kindLabel = makeLabel(row, string.upper(item.kind or "toggle"), 7, UDim2.new(0, 12, 1, -15), FONT_BOLD, COLORS.TextMuted)
    kindLabel.Name = "TypeBadge"
    kindLabel.Size = UDim2.new(0, 76, 0, 10)
    kindLabel.ZIndex = 6

    local controlHost = make("Frame", {
        Name = "ControlHost",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(item.kind == "slider" and 112 or (item.kind == "dropdown" and 108 or (item.kind == "action" and 88 or 82)), 48),
        ZIndex = 7,
    }, row)

    if item.kind == "toggle" then
        makeToggleControl(controlHost, item)
    elseif item.kind == "slider" then
        makeSliderControl(controlHost, item)
    elseif item.kind == "dropdown" then
        makeDropdownControl(controlHost, item)
    elseif item.kind == "action" then
        makeActionControl(controlHost, item)
    else
        makeToggleControl(controlHost, item)
    end

    row.MouseEnter:Connect(function()
        tween(row, 0.1, { BackgroundColor3 = COLORS.CardHover })
        tween(accentRail, 0.1, { BackgroundTransparency = 0 })
    end)
    row.MouseLeave:Connect(function()
        tween(row, 0.1, { BackgroundColor3 = COLORS.Card })
        tween(accentRail, 0.1, { BackgroundTransparency = 0.18 })
    end)

    renderedRows[item.id] = row
    return row
end

local function clearDynamicRows()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:GetAttribute("DynamicRow") == true then
            child:Destroy()
        end
    end
    table.clear(renderedRows)
end

local function rowMatchesQuery(item, query)
    if not query or query == "" then
        return true
    end
    local normalizedQuery = string.lower(query)
    local title = string.lower(item.title or "")
    local description = string.lower(item.description or "")
    local group = string.lower(item.group or "")
    return string.find(title, normalizedQuery, 1, true) ~= nil
        or string.find(description, normalizedQuery, 1, true) ~= nil
        or string.find(group, normalizedQuery, 1, true) ~= nil
end

renderActiveTab = function()
    local tab = tabById[state.activeTab]
    if not tab then
        return
    end
    clearDynamicRows()
    sectionTitle.Text = tab.title
    sectionSubtitle.Text = tab.subtitle
    local shown = 0
    for _, item in ipairs(tab.features) do
        if rowMatchesQuery(item, state.query) then
            shown += 1
            createFeatureRow(item, shown)
        end
    end
    footerCount.Text = tostring(shown) .. " ITEMS"
    scroll.CanvasPosition = Vector2.new(0, 0)
    for id, button in pairs(tabButtons) do
        setTabButtonAppearance(button, id == state.activeTab)
    end
end

local function switchTab(tabId)
    if not tabById[tabId] then
        return
    end
    state.activeTab = tabId
    state.query = searchBox.Text or ""
    renderActiveTab()
end

for tabId, button in pairs(tabButtons) do
    button.Activated:Connect(function()
        switchTab(tabId)
    end)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    state.query = searchBox.Text or ""
    renderActiveTab()
end)

--// Window controls -----------------------------------------------------------
local function setMinimized(minimized)
    state.minimized = minimized
    if minimized then
        nav.Visible = false
        content.Visible = false
        window.Size = UDim2.new(window.Size.X.Scale, window.Size.X.Offset, 0, SETTINGS.HeaderHeight)
        minimizeButton.Text = "+"
    else
        nav.Visible = true
        content.Visible = true
        minimizeButton.Text = "—"
        updateResponsiveSize()
    end
end

minimizeButton.Activated:Connect(function()
    setMinimized(not state.minimized)
end)

closeButton.Activated:Connect(function()
    window.Visible = false
    state.windowVisible = false
    reopenButton.Visible = true
    reopenHint.Visible = true
end)

reopenButton.Activated:Connect(function()
    window.Visible = true
    state.windowVisible = true
    reopenButton.Visible = false
    reopenHint.Visible = false
    if state.minimized then
        setMinimized(false)
    end
end)

backdrop.Activated:Connect(function()
    -- The backdrop is hidden by default; retained for future UI-only styling.
end)

--// Touch and mouse dragging --------------------------------------------------
topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = true
        dragStart = input.Position
        startWindowPosition = window.Position
        activeInput = input
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingWindow = false
                activeInput = nil
            end
        end)
    end
end)

topbar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        activeInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingWindow and dragStart and startWindowPosition then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startWindowPosition.X.Scale,
                startWindowPosition.X.Offset + delta.X,
                startWindowPosition.Y.Scale,
                startWindowPosition.Y.Offset + delta.Y
            )
        end
    end

    if currentSliderDrag then
        local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
        local isTouch = input.UserInputType == Enum.UserInputType.Touch
        if isMouse or isTouch then
            local track = currentSliderDrag.track
            if track and track.Parent then
                currentSliderDrag.update(input)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingWindow = false
        currentSliderDrag = nil
        activeInput = nil
    end
end)

--// Responsive layout ---------------------------------------------------------
updateResponsiveSize = function()
    if not Camera then
        Camera = workspace.CurrentCamera
    end
    local viewport = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    local width = math.min(math.max(viewport.X * 0.94, 280), 980)
    local height = math.min(math.max(viewport.Y * 0.84, 280), 760)
    width = math.min(width, math.max(220, viewport.X - 12))
    height = math.min(height, math.max(220, viewport.Y - 12))
    if state.minimized then
        height = SETTINGS.HeaderHeight
    end
    window.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
    if viewport.X < 430 then
        safetyBadge.Visible = false
        subtitleLabel.Text = "MOBILE CONCEPT  /  v" .. APP_VERSION
        sectionTitle.TextSize = 12
        sectionSubtitle.TextSize = 8
        searchBox.Size = UDim2.fromOffset(120, 28)
        searchBox.Position = UDim2.new(1, -120, 0, 6)
        searchGlyph.Visible = false
        titleLabel.Size = UDim2.new(0, 126, 0, 20)
        subtitleLabel.Size = UDim2.new(0, 145, 0, 14)
    else
        safetyBadge.Visible = true
        subtitleLabel.Text = APP_SUBTITLE .. "  /  v" .. APP_VERSION
        searchBox.Size = UDim2.fromOffset(156, 30)
        searchBox.Position = UDim2.new(1, -156, 0, 5)
        searchGlyph.Visible = true
        titleLabel.Size = UDim2.new(0, 160, 0, 20)
        subtitleLabel.Size = UDim2.new(0, 190, 0, 14)
    end
    if viewport.Y < 440 then
        sectionHeader.Size = UDim2.new(1, -28, 0, 36)
        scroll.Position = UDim2.new(0, 12, 0, 44)
        scroll.Size = UDim2.new(1, -24, 1, -78)
        footer.Visible = false
    else
        sectionHeader.Size = UDim2.new(1, -28, 0, 42)
        scroll.Position = UDim2.new(0, 12, 0, 54)
        scroll.Size = UDim2.new(1, -24, 1, -92)
        footer.Visible = true
    end
    renderActiveTab()
end

if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveSize)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
    if Camera then
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveSize)
        updateResponsiveSize()
    end
end)

--// Search focus visual feedback ---------------------------------------------
searchBox.Focused:Connect(function()
    local stroke = searchBox:FindFirstChildOfClass("UIStroke")
    if stroke then
        tween(stroke, 0.12, { Color = COLORS.AccentDeep, Transparency = 0 })
    end
end)

searchBox.FocusLost:Connect(function()
    local stroke = searchBox:FindFirstChildOfClass("UIStroke")
    if stroke then
        tween(stroke, 0.12, { Color = COLORS.Border, Transparency = 0.25 })
    end
end)

--// Keyboard / device niceties -----------------------------------------------
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.RightControl then
        window.Visible = not window.Visible
        state.windowVisible = window.Visible
        reopenButton.Visible = not window.Visible
        reopenHint.Visible = not window.Visible
    elseif input.KeyCode == Enum.KeyCode.Escape then
        if searchBox:IsFocused() then
            searchBox:ReleaseFocus()
        else
            window.Visible = false
            state.windowVisible = false
            reopenButton.Visible = true
            reopenHint.Visible = true
        end
    end
end)

--// Accessibility and convenience --------------------------------------------
local function setCompactRows(enabled)
    state.compactRows = enabled == true
    renderActiveTab()
end

local function setReducedMotion(enabled)
    state.reducedMotion = enabled == true
end

local function showSafetyToast()
    showToast("Все функции декоративные и не влияют на игру", "success")
end

--// Final initialization -------------------------------------------------------
renderActiveTab()
updateResponsiveSize()
window.Visible = not SETTINGS.StartMinimized
reopenButton.Visible = SETTINGS.StartMinimized
reopenHint.Visible = SETTINGS.StartMinimized

-- A tiny delayed welcome notice helps confirm that the LocalScript ran.
task.delay(0.45, function()
    if ScreenGui and ScreenGui.Parent then
        showSafetyToast()
    end
end)

--// Optional UI-only hooks ----------------------------------------------------
-- These helpers are intentionally local and do not connect to game mechanics.
local function getActiveTabId()
    return state.activeTab
end

local function getVisibleFeatureCount()
    local count = 0
    for _, row in pairs(renderedRows) do
        if row and row.Visible then
            count += 1
        end
    end
    return count
end

local function resetOnlyUiValues()
    for _, tab in ipairs(CATALOG) do
        for _, item in ipairs(tab.features) do
            setLocalValue(item, item.default)
        end
    end
    state.query = ""
    if searchBox then
        searchBox.Text = ""
    end
    renderActiveTab()
end

local function getUiPrototypeInfo()
    return {
        name = APP_NAME,
        version = APP_VERSION,
        localOnly = isUiOnly(),
        tabCount = #CATALOG,
        visibleItemCount = getVisibleFeatureCount(),
        activeTab = getActiveTabId(),
    }
end

-- Prototype script end. Any future implementation should preserve this boundary:
-- UI controls are not wired to character, camera, workspace, remotes, or services
-- that would alter gameplay. This file ends here by design.
--[[
================================================================================
MAINTENANCE NOTES / UI STYLE GUIDE
================================================================================

THEME TOKENS
------------
Background: almost-black navy used behind the main panel.
Window: main panel background.
Header: topbar and footer surface.
Panel: generic content surface.
Card: default state for a feature card.
CardHover: subtle surface highlight for pointer hover.
CardPressed: touch or mouse press feedback.
Border: low-contrast edge for separators and cards.
Accent: aquamarine mint, reserved for active controls and focus.
AccentDeep: deeper mint used for fills and active rails.
AccentSoft: low-opacity-looking dark mint surface used behind active badges.
Text: main light text.
TextSoft: secondary text for descriptions.
TextMuted: hint labels and metadata.
Positive: visual-only success accent.
Warning: visual-only warning accent.
Negative: close and error accent.

LAYOUT SIZING
-------------
The topbar stays the same height across device sizes for predictable touch use.
The category navigation is horizontally scrollable, not wrapped into tiny buttons.
The section title and search box use a breakpoint at 430 horizontal pixels.
The footer is hidden on short landscape viewports to make room for settings.
The content list scrolls vertically and uses a minimum row height for touch targets.
The window uses viewport-relative calculations but sets pixel offsets for exact fit.

CONTROL TYPES
-------------
Toggle:
    A rounded switch with ON/OFF label. Its state is stored by item.id.
Slider:
    A small track plus value label and two accessible step buttons.
    Touch or mouse input can move the fill by touching the track.
Dropdown:
    A compact button that cycles through its configured list.
Action:
    A clear demo button. It triggers a toast, not a gameplay action.

CATALOG CONVENTIONS
-------------------
Each tab has a stable id used by the navigation system.
Each feature id is unique across the whole catalog.
Every item has a title, description, kind, default, and group.
Dropdown entries additionally provide options.
Slider entries additionally provide min and max.
The catalog is static so the UI does not need external requests.

ADDING A CATEGORY
-----------------
1. Add a category object to CATALOG before ScreenGui creation.
2. Give it unique id, title, name and subtitle values.
3. Add a features array containing the desired decorative controls.
4. Each control should have a unique id and a short plain-language description.
5. Use kind = toggle, slider, dropdown, or action.
6. Use default = false for toggles, a number for sliders, and a listed string
   for dropdowns. Actions may use false as their placeholder default.
7. Keep the UI-only boundary intact: never wire fake controls to gameplay.

ADDING A TOGGLE
---------------
A toggle is rendered by makeToggleControl().
State changes happen in state.values and remain local to this LocalScript.
The visual switch is refreshed after each Activated event.
If a toggle affects a UI presentation option such as compact rows, handle that
case inside the relevant UI branch, not in game logic.

ADDING A SLIDER
---------------
A slider is rendered by makeSliderControl().
Its min and max properties define the value range.
The step size is small for short ranges and larger for long ranges.
The control is designed for a narrow mobile right column.
Keep slider labels short so the text remains readable on small screens.

ADDING A DROPDOWN
-----------------
A dropdown is rendered by makeDropdownControl().
The current value is found in item.options and advances to the next item.
The small control does not use a pop-up panel, avoiding screen overflow on mobile.
Options should be short enough to fit a compact button.

ADDING AN ACTION
----------------
An action is rendered by makeActionControl().
Action handlers are intentionally limited to changing UI state or showing toasts.
A new action should call notifyUiOnly() unless it is an explicit UI reset,
window-position reset, or another harmless interface-only operation.
Never add remote invocation, data exfiltration, or character manipulation here.

SEARCH BEHAVIOUR
----------------
The active query is stored in state.query.
Rows match when their title, description, or group contains the query.
Search is case-insensitive and uses plain substring matching.
The result counter updates whenever the category or query changes.
The scroll position resets after a render for predictable navigation.

MOBILE INTERACTION
------------------
Use Activated for buttons so mouse, touch, and gamepad activation are supported.
Use InputBegan / InputChanged for dragging and the slider track.
The window's drag origin is captured at touch begin to prevent sudden jumps.
Keep controls sufficiently separated so taps are less likely to hit the wrong row.
Do not rely on hover feedback as the only indication that a control was activated.

ANIMATION GUIDELINES
--------------------
Use short easing transitions for switch knobs, card highlights, and toast feedback.
Respect state.reducedMotion for users who prefer immediate UI changes.
Avoid long looping effects that consume mobile battery or obscure content.
The prototype intentionally does not use expensive blur effects or 3D render loops.

ROBLOX STUDIO NOTES
-------------------
Run this in a LocalScript because PlayerGui is local to a player.
For an in-experience menu, use StarterPlayerScripts or a suitable ScreenGui script.
Do not place it in a server Script; server scripts do not have LocalPlayer.
For a production game, recreate the visual design in your own experience and
connect only legitimate, intended settings supported by your game design.
This prototype does not attempt to bypass platform protections or game rules.

TEST CHECKLIST
--------------
[ ] Play in Studio with a mouse.
[ ] Test portrait viewport at 320 x 700.
[ ] Test portrait viewport at 390 x 844.
[ ] Test landscape viewport at 800 x 360.
[ ] Test a desktop-like viewport at 1366 x 768.
[ ] Tap each category and verify the active state moves.
[ ] Type in the search box and verify that rows filter.
[ ] Toggle a decorative option and verify only the switch changes.
[ ] Drag a slider and verify only the displayed value changes.
[ ] Press a dropdown and cycle through its options.
[ ] Press an action and verify the toast appears.
[ ] Minimize and restore the window.
[ ] Close the window and reopen it with the A button.
[ ] Confirm that no gameplay properties are modified.

KNOWN LIMITATIONS
-----------------
This is a visual prototype, not a full production design system.
The dropdown intentionally cycles options rather than opening a popup list.
The config page demonstrates UI affordances; it does not save external files.
The feature descriptions are decorative and should not be interpreted as claims
that the corresponding gameplay behaviour has been implemented.
The UI does not attempt cross-session persistence.
The exact visual appearance may differ slightly across Roblox device emulators.

MAINTENANCE BOUNDARY
--------------------
The implementation should remain a local UI mockup. The state table is a view
model, not an authoritative source of gameplay data. The ScreenGui is parented
to PlayerGui and uses ordinary Roblox APIs. No external libraries are required.
No network calls, remote events, filesystem access, executor APIs, hidden APIs,
or third-party dependencies are part of the design.

END OF MAINTENANCE GUIDE
================================================================================
]]

--// Catalog reference index (title => local id / control type) ----------------
-- [COMBAT] Боевой раздел · визуальные заглушки
-- combat_1_aim_assist: Aim Assist [toggle]
-- combat_2_silent_aim: Silent Aim [toggle]
-- combat_3_rage_mode: Rage Mode [slider]
-- combat_4_target_priority: Target Priority [dropdown]
-- combat_5_field_of_view: Field of View [toggle]
-- combat_6_hit_chance: Hit Chance [action]
-- combat_7_minimum_damage: Minimum Damage [toggle]
-- combat_8_quick_stop: Quick Stop [slider]
-- combat_9_auto_scope: Auto Scope [dropdown]
-- combat_10_auto_fire: Auto Fire [toggle]
-- combat_11_target_lock: Target Lock [toggle]
-- combat_12_multipoint_scale: Multipoint Scale [toggle]
-- combat_13_body_aim: Body Aim [slider]
-- combat_14_prefer_head: Prefer Head [dropdown]
-- combat_15_prefer_body: Prefer Body [toggle]
-- combat_16_damage_override: Damage Override [action]
-- combat_17_safe_point: Safe Point [toggle]
-- combat_18_resolver_preview: Resolver Preview [slider]
-- combat_19_accuracy_mode: Accuracy Mode [dropdown]
-- combat_20_spread_preview: Spread Preview [toggle]
-- combat_21_recoil_preview: Recoil Preview [toggle]
-- combat_22_weapon_profiles: Weapon Profiles [toggle]
-- combat_23_target_indicator: Target Indicator [slider]
-- combat_24_shot_log_preview: Shot Log Preview [dropdown]
-- combat_25_aim_key: Aim Key [toggle]
-- combat_26_auto_peek: Auto Peek [action]
-- combat_27_peek_assist: Peek Assist [toggle]
-- combat_28_damage_marker: Damage Marker [slider]
-- combat_29_prefer_close_range: Prefer Close Range [dropdown]
-- combat_30_combat_preset: Combat Preset [toggle]
-- [ANTI-AIM] Anti-aim · интерфейсный прототип
-- antiaim_1_anti_aim_master: Anti-Aim Master [toggle]
-- antiaim_2_yaw_mode: Yaw Mode [toggle]
-- antiaim_3_yaw_offset: Yaw Offset [slider]
-- antiaim_4_pitch_mode: Pitch Mode [dropdown]
-- antiaim_5_pitch_amount: Pitch Amount [toggle]
-- antiaim_6_desync_preview: Desync Preview [action]
-- antiaim_7_jitter_mode: Jitter Mode [toggle]
-- antiaim_8_jitter_range: Jitter Range [slider]
-- antiaim_9_spin_speed: Spin Speed [dropdown]
-- antiaim_10_fake_flick: Fake Flick [toggle]
-- antiaim_11_lower_body_yaw: Lower Body Yaw [toggle]
-- antiaim_12_freestanding: Freestanding [toggle]
-- antiaim_13_edge_preview: Edge Preview [slider]
-- antiaim_14_manual_left: Manual Left [dropdown]
-- antiaim_15_manual_right: Manual Right [toggle]
-- antiaim_16_manual_back: Manual Back [action]
-- antiaim_17_inverter: Inverter [toggle]
-- antiaim_18_anti_bruteforce: Anti-Bruteforce [slider]
-- antiaim_19_fake_lag_preview: Fake Lag Preview [dropdown]
-- antiaim_20_condition_standing: Condition: Standing [toggle]
-- antiaim_21_condition_moving: Condition: Moving [toggle]
-- antiaim_22_condition_airborne: Condition: Airborne [toggle]
-- [VISUALS] Визуальные настройки · без ESP-логики
-- visuals_1_visuals_master: Visuals Master [toggle]
-- visuals_2_box_overlay: Box Overlay [toggle]
-- visuals_3_box_style: Box Style [slider]
-- visuals_4_name_tags: Name Tags [dropdown]
-- visuals_5_health_bar: Health Bar [toggle]
-- visuals_6_health_bar_style: Health Bar Style [action]
-- visuals_7_skeleton_preview: Skeleton Preview [toggle]
-- visuals_8_snap_lines: Snap Lines [slider]
-- visuals_9_distance_labels: Distance Labels [dropdown]
-- visuals_10_weapon_labels: Weapon Labels [toggle]
-- visuals_11_flags: Flags [toggle]
-- visuals_12_chams_preview: Chams Preview [toggle]
-- visuals_13_chams_style: Chams Style [slider]
-- visuals_14_glow_preview: Glow Preview [dropdown]
-- visuals_15_glow_strength: Glow Strength [toggle]
-- visuals_16_offscreen_arrows: Offscreen Arrows [action]
-- visuals_17_arrow_size: Arrow Size [toggle]
-- visuals_18_arrow_radius: Arrow Radius [slider]
-- visuals_19_radar_preview: Radar Preview [dropdown]
-- visuals_20_radar_size: Radar Size [toggle]
-- visuals_21_radar_zoom: Radar Zoom [toggle]
-- visuals_22_world_tint: World Tint [toggle]
-- visuals_23_world_brightness: World Brightness [slider]
-- visuals_24_skybox_preview: Skybox Preview [dropdown]
-- visuals_25_fog_preview: Fog Preview [toggle]
-- visuals_26_third_person_preview: Third Person Preview [action]
-- visuals_27_viewmodel_offset: Viewmodel Offset [toggle]
-- visuals_28_viewmodel_fov: Viewmodel FOV [slider]
-- visuals_29_hitmarker_preview: Hitmarker Preview [dropdown]
-- visuals_30_damage_numbers: Damage Numbers [toggle]
-- visuals_31_crosshair_style: Crosshair Style [toggle]
-- visuals_32_crosshair_size: Crosshair Size [toggle]
-- [MOVEMENT] Перемещение · все параметры неактивны
-- movement_1_movement_master: Movement Master [toggle]
-- movement_2_bunny_hop_preview: Bunny Hop Preview [toggle]
-- movement_3_auto_strafe_preview: Auto Strafe Preview [slider]
-- movement_4_air_strafe_mode: Air Strafe Mode [dropdown]
-- movement_5_speed_display: Speed Display [toggle]
-- movement_6_speed_value: Speed Value [action]
-- movement_7_jump_height: Jump Height [toggle]
-- movement_8_long_jump_preview: Long Jump Preview [slider]
-- movement_9_edge_bug_preview: Edge Bug Preview [dropdown]
-- movement_10_slow_walk: Slow Walk [toggle]
-- movement_11_slow_walk_amount: Slow Walk Amount [toggle]
-- movement_12_crouch_assist: Crouch Assist [toggle]
-- movement_13_crouch_mode: Crouch Mode [slider]
-- movement_14_slide_preview: Slide Preview [dropdown]
-- movement_15_ladder_assist: Ladder Assist [toggle]
-- movement_16_water_movement: Water Movement [action]
-- movement_17_no_clip_preview: No Clip Preview [toggle]
-- movement_18_fly_preview: Fly Preview [slider]
-- movement_19_teleport_preset: Teleport Preset [dropdown]
-- movement_20_movement_preset: Movement Preset [toggle]
-- [PLAYER] Параметры игрока · UI-only
-- player_1_player_panel: Player Panel [toggle]
-- player_2_local_status: Local Status [toggle]
-- player_3_profile_name: Profile Name [slider]
-- player_4_profile_color: Profile Color [dropdown]
-- player_5_fake_rank: Fake Rank [toggle]
-- player_6_fake_level: Fake Level [action]
-- player_7_stat_preview: Stat Preview [toggle]
-- player_8_health_display: Health Display [slider]
-- player_9_armor_display: Armor Display [dropdown]
-- player_10_stamina_preview: Stamina Preview [toggle]
-- player_11_player_tag: Player Tag [toggle]
-- player_12_custom_tag_text: Custom Tag Text [toggle]
-- player_13_tag_style: Tag Style [slider]
-- player_14_color_accent: Color Accent [dropdown]
-- player_15_hud_compact_mode: HUD Compact Mode [toggle]
-- player_16_hud_scale: HUD Scale [toggle]
-- player_17_hud_opacity: HUD Opacity [toggle]
-- player_18_notification_style: Notification Style [slider]
-- player_19_status_badge: Status Badge [dropdown]
-- player_20_player_preset: Player Preset [toggle]
-- [WORLD] Окружение · без изменений Workspace
-- world_1_world_panel: World Panel [toggle]
-- world_2_ambient_preview: Ambient Preview [toggle]
-- world_3_clock_time: Clock Time [slider]
-- world_4_time_preset: Time Preset [dropdown]
-- world_5_rain_preview: Rain Preview [toggle]
-- world_6_snow_preview: Snow Preview [action]
-- world_7_particle_density: Particle Density [toggle]
-- world_8_bloom_preview: Bloom Preview [slider]
-- world_9_color_correction: Color Correction [dropdown]
-- world_10_blur_preview: Blur Preview [toggle]
-- world_11_sun_rays_preview: Sun Rays Preview [toggle]
-- world_12_atmosphere_preview: Atmosphere Preview [toggle]
-- world_13_terrain_preview: Terrain Preview [slider]
-- world_14_water_color: Water Color [dropdown]
-- world_15_material_preview: Material Preview [toggle]
-- world_16_world_theme: World Theme [action]
-- world_17_environment_profile: Environment Profile [toggle]
-- world_18_lighting_profile: Lighting Profile [slider]
-- world_19_world_reset_preview: World Reset Preview [dropdown]
-- world_20_world_preset: World Preset [toggle]
-- [MISC] Дополнительные элементы интерфейса
-- misc_1_watermark: Watermark [toggle]
-- misc_2_watermark_style: Watermark Style [dropdown]
-- misc_3_keybind_list: Keybind List [slider]
-- misc_4_keybind_theme: Keybind Theme [dropdown]
-- misc_5_event_log_preview: Event Log Preview [toggle]
-- misc_6_show_debug_labels: Show Debug Labels [action]
-- misc_7_menu_sounds: Menu Sounds [toggle]
-- misc_8_animations: Animations [toggle]
-- misc_9_reduced_motion: Reduced Motion [toggle]
-- misc_10_open_on_spawn: Open On Spawn [toggle]
-- misc_11_confirm_actions: Confirm Actions [toggle]
-- misc_12_toast_duration: Toast Duration [toggle]
-- misc_13_ui_blur_preview: UI Blur Preview [slider]
-- misc_14_panel_shadow: Panel Shadow [toggle]
-- misc_15_rounded_corners: Rounded Corners [toggle]
-- misc_16_compact_rows: Compact Rows [toggle]
-- misc_17_accent_animation: Accent Animation [toggle]
-- misc_18_rainbow_accent: Rainbow Accent [toggle]
-- misc_19_safe_mode_badge: Safe Mode Badge [dropdown]
-- misc_20_reset_ui_state: Reset UI State [action]
-- misc_21_copy_ui_credits: Copy UI Credits [action]
-- misc_22_misc_preset: Misc Preset [toggle]
-- [CONFIG] Пресеты и настройки интерфейса (демо)
-- config_1_active_config: Active Config [toggle]
-- config_2_config_slot: Config Slot [toggle]
-- config_3_load_config: Load Config [action]
-- config_4_save_config: Save Config [action]
-- config_5_create_config: Create Config [action]
-- config_6_rename_config: Rename Config [action]
-- config_7_delete_config: Delete Config [action]
-- config_8_export_preview: Export Preview [action]
-- config_9_import_preview: Import Preview [action]
-- config_10_config_theme: Config Theme [toggle]
-- config_11_config_notes: Config Notes [toggle]
-- config_12_auto_save: Auto Save [toggle]
-- config_13_config_backup: Config Backup [slider]
-- config_14_reset_combat_ui: Reset Combat UI [action]
-- config_15_reset_visual_ui: Reset Visual UI [action]
-- config_16_reset_all_ui: Reset All UI [action]
-- config_17_preset_aquamarine: Preset: Aquamarine [toggle]
-- config_18_preset_midnight: Preset: Midnight [slider]
-- [ABOUT] Информация о визуальном макете
-- about_1_build_channel: Build Channel [toggle]
-- about_2_version_label: Version Label [toggle]
-- about_3_mobile_layout: Mobile Layout [toggle]
-- about_4_touch_input: Touch Input [toggle]
-- about_5_ui_diagnostics: UI Diagnostics [action]
-- about_6_credits: Credits [action]
-- about_7_documentation: Documentation [action]
-- about_8_safety_notice: Safety Notice [slider]
-- about_9_theme_preview: Theme Preview [dropdown]
-- about_10_reset_window_position: Reset Window Position [action]
-- about_11_reopen_button: Reopen Button [toggle]
-- about_12_close_menu: Close Menu [action]
--// Quick customization glossary ---------------------------------------------
-- Change COLORS.Accent to adjust the main aquamarine highlight.
-- Change COLORS.Window to make the panel brighter or darker.
-- Change SETTINGS.HeaderHeight to alter the topbar touch target.
-- Change SETTINGS.NavigationHeight to adjust the category strip.
-- Change SETTINGS.RowHeight to change the height of each feature card.
-- Change SETTINGS.CompactRowHeight to adjust compact mode.
-- Change SETTINGS.ToastTime to control demo notification duration.
-- Change SETTINGS.DefaultTab to choose the first tab.
-- Change SETTINGS.StartMinimized to start with only the reopen button visible.
-- Change APP_VERSION to update the version label.
-- Change APP_SUBTITLE to adjust the topbar subheading.
-- Change UI_ONLY_NOTICE to change the footer status text.
-- Change SETTINGS.SearchPlaceholder to edit the search hint.
-- Change the tab `title` field to update its navigation label.
-- Change the tab `subtitle` field to update the section hint.
-- Change a feature `description` to customize the secondary card text.
-- Change a feature `kind` to select toggle, slider, dropdown, or action.
-- Change slider `min` and `max` to set its numeric display range.
-- Change dropdown `options` to set the values cycled by the control.
-- Change an item's `default` to set its initial UI state.
-- Feature values are stored by stable id in state.values.
-- Unique ids prevent two decorative controls from sharing one state value.
-- The footer item count reflects the filtered rows in the current category.
-- The search field filters one category at a time to keep results predictable.
-- The navigation bar scrolls sideways when all tabs do not fit the viewport.
-- The row style deliberately prioritizes labels and descriptions over decoration.
-- The left accent rail gives the cards a subtle signature without visual clutter.
-- The corner radius is shared across most components for a consistent appearance.
-- The status badge is hidden at narrow widths to preserve usable header space.
-- The search box shrinks at narrow widths to leave space for the section title.
-- The footer is hidden on very short viewports to leave more room for controls.
-- The reopen button is a separate sibling so it remains available after closing.
-- The header drag handler supports both touch and mouse input.
-- The slider track also handles touch and mouse input.
-- The toggle uses Activated for mobile-friendly activation.
-- The action button displays a toast instead of performing game actions.
-- The preset actions are placeholders; they do not save profile files.
-- The reset actions only reset in-memory values in this UI.
-- The current config profile is only displayed in a dropdown.
-- There is no datastore or backend service attached to the prototype.
-- Nothing in this script changes Humanoid properties.
-- Nothing in this script changes Camera properties for gameplay.
-- Nothing in this script adds instances to Workspace.
-- Nothing in this script calls RemoteEvent or RemoteFunction.
-- Nothing in this script reads other players' private data.
-- Nothing in this script uses an executor-specific environment.
-- The LocalScript runs entirely in the client UI layer.
-- Keep this boundary if you extend the design later.
--[[
CHANGE LOG
----------
1.0.0-mobile-prototype
- Initial aquamarine palette.
- Responsive centered window.
- Nine navigable categories.
- Static local catalog for decorative feature cards.
- Toggle, slider, dropdown and action controls.
- Touch and mouse support.
- Search filtering.
- Toast notifications.
- Minimize, close, reopen and recenter UI actions.
- Local-only settings reset.
- No gameplay features intentionally implemented.

FUTURE UI-ONLY IDEAS
--------------------
- Additional color palettes with a controlled list of presets.
- A separate visual theme preview panel.
- Optional icon glyphs for navigation tabs.
- A focus outline for keyboard/gamepad navigation.
- A dedicated changelog screen with local static text.
- More localized labels for language selection.
- Adjustable row density for very small screens.
- A non-persistent preset preview that changes card labels only.
- A simple layout guide to explain each decorative control type.
- An isolated theme editor that only changes COLORS tokens.

This file intentionally ends as a UI concept. Any future work should preserve
its no-gameplay-effect scope and be tested in a Roblox Studio experience that
you own or have permission to modify.
]]
