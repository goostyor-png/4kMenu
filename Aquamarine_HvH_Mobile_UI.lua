local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

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

local function isUiOnly()
    return true
end

local function notifyUiOnly(actionName)
    local action = actionName or "Действие"
    showToast(action .. ": только UI-макет", "warning")
end

local CATALOG = {

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
            {
                id = "combat_extra_01_aim_ring_preview",
                title = "Aim Ring Preview",
                description = "Настройка кольца прицела только в макете.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_02_aim_ring_radius",
                title = "Aim Ring Radius",
                description = "Размер декоративного кольца в условных единицах.",
                kind = "slider",
                default = 68,
                group = "Combat",
                options = {},
                min = 10,
                max = 180,
            },
            {
                id = "combat_extra_03_target_card_style",
                title = "Target Card Style",
                description = "Вариант оформления демонстрационной карточки цели.",
                kind = "dropdown",
                default = "Minimal",
                group = "Combat",
                options = { "Minimal", "Outlined", "Filled" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_04_target_card_opacity",
                title = "Target Card Opacity",
                description = "Прозрачность визуального примера карточки.",
                kind = "slider",
                default = 80,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_05_shot_marker_preview",
                title = "Shot Marker Preview",
                description = "Показывает только состояние выбранного маркера.",
                kind = "toggle",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_06_shot_marker_style",
                title = "Shot Marker Style",
                description = "Стиль условного маркера без регистрации попаданий.",
                kind = "dropdown",
                default = "Circle",
                group = "Combat",
                options = { "Circle", "Cross", "Diamond" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_07_damage_label_size",
                title = "Damage Label Size",
                description = "Размер макетной подписи урона.",
                kind = "slider",
                default = 14,
                group = "Combat",
                options = {},
                min = 8,
                max = 28,
            },
            {
                id = "combat_extra_08_hit_indicator_theme",
                title = "Hit Indicator Theme",
                description = "Цветовая схема демонстрационного индикатора.",
                kind = "dropdown",
                default = "Aquamarine",
                group = "Combat",
                options = { "Aquamarine", "Midnight", "Graphite" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_09_reticle_preview",
                title = "Reticle Preview",
                description = "Включает локальный визуальный образец прицела.",
                kind = "toggle",
                default = true,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_10_reticle_gap",
                title = "Reticle Gap",
                description = "Расстояние между элементами демонстрационного прицела.",
                kind = "slider",
                default = 5,
                group = "Combat",
                options = {},
                min = 0,
                max = 20,
            },
            {
                id = "combat_extra_11_reticle_thickness",
                title = "Reticle Thickness",
                description = "Толщина штрихов в выбранном макете.",
                kind = "slider",
                default = 2,
                group = "Combat",
                options = {},
                min = 1,
                max = 8,
            },
            {
                id = "combat_extra_12_combat_panel_density",
                title = "Combat Panel Density",
                description = "Плотность отображения параметров в разделе.",
                kind = "dropdown",
                default = "Comfortable",
                group = "Combat",
                options = { "Compact", "Comfortable", "Spacious" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_13_status_accent_preview",
                title = "Status Accent Preview",
                description = "Переключатель акцентной метки состояния.",
                kind = "toggle",
                default = true,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_14_combat_layout_sample",
                title = "Combat Layout Sample",
                description = "Демонстрационное действие с уведомлением интерфейса.",
                kind = "action",
                default = false,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_15_target_panel_header",
                title = "Target Panel Header",
                description = "Оформление заголовка локальной карточки цели.",
                kind = "dropdown",
                default = "Compact",
                group = "Combat",
                options = { "Compact", "Standard", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_16_aim_ring_smoothness",
                title = "Aim Ring Smoothness",
                description = "Значение плавности для визуального образца кольца.",
                kind = "slider",
                default = 55,
                group = "Combat",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "combat_extra_17_hit_marker_lifetime",
                title = "Hit Marker Lifetime",
                description = "Длительность подписи в демонстрационном макете.",
                kind = "slider",
                default = 1.2,
                group = "Combat",
                options = {},
                min = 0.2,
                max = 3.0,
            },
            {
                id = "combat_extra_18_reticle_gap_style",
                title = "Reticle Gap Style",
                description = "Вариант оформления интервала между штрихами.",
                kind = "dropdown",
                default = "Balanced",
                group = "Combat",
                options = { "Tight", "Balanced", "Wide" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "antiaim_extra_01_angle_profile_preview",
                title = "Angle Profile Preview",
                description = "Меняет только сохранённый выбор профиля в UI.",
                kind = "dropdown",
                default = "Balanced",
                group = "Anti-Aim",
                options = { "Balanced", "Dynamic", "Subtle" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_02_yaw_indicator",
                title = "Yaw Indicator",
                description = "Включает декоративную метку направления.",
                kind = "toggle",
                default = true,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_03_yaw_indicator_size",
                title = "Yaw Indicator Size",
                description = "Размер визуальной метки направления.",
                kind = "slider",
                default = 46,
                group = "Anti-Aim",
                options = {},
                min = 12,
                max = 100,
            },
            {
                id = "antiaim_extra_04_desync_graph_preview",
                title = "Desync Graph Preview",
                description = "Состояние макета графика без сетевой логики.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_05_desync_graph_scale",
                title = "Desync Graph Scale",
                description = "Масштаб демонстрационного графика.",
                kind = "slider",
                default = 60,
                group = "Anti-Aim",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "antiaim_extra_06_condition_badge_style",
                title = "Condition Badge Style",
                description = "Стиль локальной метки состояния.",
                kind = "dropdown",
                default = "Pill",
                group = "Anti-Aim",
                options = { "Pill", "Square", "Minimal" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_07_standing_state_sample",
                title = "Standing State Sample",
                description = "Переключатель образца состояния стоя.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_08_moving_state_sample",
                title = "Moving State Sample",
                description = "Переключатель образца состояния движения.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_09_airborne_state_sample",
                title = "Airborne State Sample",
                description = "Переключатель образца состояния в воздухе.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_10_jitter_label_preview",
                title = "Jitter Label Preview",
                description = "Показывает только пример подписи jitter.",
                kind = "toggle",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_11_pattern_card",
                title = "Pattern Card",
                description = "Стиль карточки выбранного макетного паттерна.",
                kind = "dropdown",
                default = "Soft",
                group = "Anti-Aim",
                options = { "Soft", "Sharp", "Glass" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_12_state_refresh_preview",
                title = "State Refresh Preview",
                description = "Демо-действие обновления визуального статуса.",
                kind = "action",
                default = false,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_13_antiaim_panel_spacing",
                title = "Antiaim Panel Spacing",
                description = "Расстояние между элементами панели.",
                kind = "slider",
                default = 12,
                group = "Anti-Aim",
                options = {},
                min = 4,
                max = 24,
            },
            {
                id = "antiaim_extra_14_antiaim_profile_label",
                title = "Antiaim Profile Label",
                description = "Включает небольшую подпись профиля.",
                kind = "toggle",
                default = true,
                group = "Anti-Aim",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_15_condition_label_position",
                title = "Condition Label Position",
                description = "Положение метки состояния в карточке.",
                kind = "dropdown",
                default = "Right",
                group = "Anti-Aim",
                options = { "Left", "Right", "Top" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_16_pattern_preview_density",
                title = "Pattern Preview Density",
                description = "Плотность элементов в графическом образце.",
                kind = "dropdown",
                default = "Normal",
                group = "Anti-Aim",
                options = { "Low", "Normal", "High" },
                min = 0,
                max = 100,
            },
            {
                id = "antiaim_extra_17_angle_badge_opacity",
                title = "Angle Badge Opacity",
                description = "Прозрачность декоративного индикатора угла.",
                kind = "slider",
                default = 85,
                group = "Anti-Aim",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "antiaim_extra_18_state_card_theme",
                title = "State Card Theme",
                description = "Цветовая схема карточек состояния.",
                kind = "dropdown",
                default = "Ocean",
                group = "Anti-Aim",
                options = { "Ocean", "Night", "Monochrome" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "visuals_extra_01_overlay_master_preview",
                title = "Overlay Master Preview",
                description = "Общее состояние декоративного overlay-примера.",
                kind = "toggle",
                default = true,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_02_overlay_border_width",
                title = "Overlay Border Width",
                description = "Толщина границ у визуального образца.",
                kind = "slider",
                default = 1,
                group = "Visuals",
                options = {},
                min = 1,
                max = 5,
            },
            {
                id = "visuals_extra_03_overlay_corner_style",
                title = "Overlay Corner Style",
                description = "Стиль углов демонстрационной рамки.",
                kind = "dropdown",
                default = "Rounded",
                group = "Visuals",
                options = { "Rounded", "Sharp", "Cut" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_04_name_label_background",
                title = "Name Label Background",
                description = "Показывает фон под макетными подписями.",
                kind = "toggle",
                default = true,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_05_name_label_scale",
                title = "Name Label Scale",
                description = "Масштаб текста в демонстрационной подписи.",
                kind = "slider",
                default = 100,
                group = "Visuals",
                options = {},
                min = 70,
                max = 140,
            },
            {
                id = "visuals_extra_06_health_bar_theme",
                title = "Health Bar Theme",
                description = "Палитра локального примера индикатора здоровья.",
                kind = "dropdown",
                default = "Gradient",
                group = "Visuals",
                options = { "Gradient", "Solid", "Muted" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_07_health_bar_height",
                title = "Health Bar Height",
                description = "Высота образца шкалы здоровья.",
                kind = "slider",
                default = 5,
                group = "Visuals",
                options = {},
                min = 2,
                max = 12,
            },
            {
                id = "visuals_extra_08_distance_label_format",
                title = "Distance Label Format",
                description = "Формат декоративной подписи дистанции.",
                kind = "dropdown",
                default = "Meters",
                group = "Visuals",
                options = { "Meters", "Studs", "Compact" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_09_skeleton_line_style",
                title = "Skeleton Line Style",
                description = "Вариант линий в демонстрационном превью.",
                kind = "dropdown",
                default = "Thin",
                group = "Visuals",
                options = { "Thin", "Bold", "Dotted" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_10_glow_intensity_preview",
                title = "Glow Intensity Preview",
                description = "Числовой параметр для визуального макета свечения.",
                kind = "slider",
                default = 35,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_11_visuals_accent_toggle",
                title = "Visuals Accent Toggle",
                description = "Включает акцентную отметку у элементов UI.",
                kind = "toggle",
                default = true,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_12_crosshair_outline",
                title = "Crosshair Outline",
                description = "Переключатель контура макетного прицела.",
                kind = "toggle",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_13_crosshair_opacity",
                title = "Crosshair Opacity",
                description = "Прозрачность демонстрационного прицела.",
                kind = "slider",
                default = 90,
                group = "Visuals",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "visuals_extra_14_visual_preset_sample",
                title = "Visual Preset Sample",
                description = "Показывает уведомление о выбранном образце.",
                kind = "action",
                default = false,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_15_overlay_fill_opacity",
                title = "Overlay Fill Opacity",
                description = "Прозрачность заливки визуальной карточки.",
                kind = "slider",
                default = 20,
                group = "Visuals",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_16_distance_label_placement",
                title = "Distance Label Placement",
                description = "Позиция подписи расстояния в макете.",
                kind = "dropdown",
                default = "Bottom",
                group = "Visuals",
                options = { "Top", "Bottom", "Side" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_17_name_tag_background_style",
                title = "Name Tag Background Style",
                description = "Стиль фона для демонстрационных имён.",
                kind = "dropdown",
                default = "Soft",
                group = "Visuals",
                options = { "Soft", "Solid", "Outline" },
                min = 0,
                max = 100,
            },
            {
                id = "visuals_extra_18_indicator_padding",
                title = "Indicator Padding",
                description = "Внутренние отступы визуальных индикаторов.",
                kind = "slider",
                default = 6,
                group = "Visuals",
                options = {},
                min = 0,
                max = 18,
            },
        },
    },

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
            {
                id = "movement_extra_01_speedometer_preview",
                title = "Speedometer Preview",
                description = "Показывает настройку локального спидометра.",
                kind = "toggle",
                default = true,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_02_speedometer_position",
                title = "Speedometer Position",
                description = "Расположение демонстрационного индикатора.",
                kind = "dropdown",
                default = "Bottom Left",
                group = "Movement",
                options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_03_speedometer_scale",
                title = "Speedometer Scale",
                description = "Масштаб UI-образца скорости.",
                kind = "slider",
                default = 100,
                group = "Movement",
                options = {},
                min = 60,
                max = 150,
            },
            {
                id = "movement_extra_04_input_meter_preview",
                title = "Input Meter Preview",
                description = "Включает декоративный индикатор ввода.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_05_input_meter_style",
                title = "Input Meter Style",
                description = "Выбор оформления индикатора клавиш.",
                kind = "dropdown",
                default = "Keycaps",
                group = "Movement",
                options = { "Keycaps", "Flat", "Minimal" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_06_movement_graph_preview",
                title = "Movement Graph Preview",
                description = "Состояние графического образца без измерения физики.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_07_graph_history_length",
                title = "Graph History Length",
                description = "Количество точек в условном макетном графике.",
                kind = "slider",
                default = 30,
                group = "Movement",
                options = {},
                min = 5,
                max = 120,
            },
            {
                id = "movement_extra_08_jump_state_badge",
                title = "Jump State Badge",
                description = "Включает декоративный бейдж прыжка.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_09_movement_hint_style",
                title = "Movement Hint Style",
                description = "Стиль небольших подсказок в UI.",
                kind = "dropdown",
                default = "Quiet",
                group = "Movement",
                options = { "Quiet", "Standard", "Prominent" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_10_movement_card_radius",
                title = "Movement Card Radius",
                description = "Радиус скругления карточек раздела.",
                kind = "slider",
                default = 10,
                group = "Movement",
                options = {},
                min = 0,
                max = 20,
            },
            {
                id = "movement_extra_11_touch_joystick_sample",
                title = "Touch Joystick Sample",
                description = "Предпросмотр неуправляющего джойстика.",
                kind = "toggle",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_12_touch_joystick_size",
                title = "Touch Joystick Size",
                description = "Размер декоративной зоны джойстика.",
                kind = "slider",
                default = 84,
                group = "Movement",
                options = {},
                min = 48,
                max = 140,
            },
            {
                id = "movement_extra_13_movement_layout_profile",
                title = "Movement Layout Profile",
                description = "Вариант плотности макета настроек движения.",
                kind = "dropdown",
                default = "Comfortable",
                group = "Movement",
                options = { "Compact", "Comfortable", "Spacious" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_14_movement_ui_refresh",
                title = "Movement UI Refresh",
                description = "Демо-действие обновления панели.",
                kind = "action",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_15_input_meter_opacity",
                title = "Input Meter Opacity",
                description = "Прозрачность демонстрационной шкалы ввода.",
                kind = "slider",
                default = 82,
                group = "Movement",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "movement_extra_16_speed_label_units",
                title = "Speed Label Units",
                description = "Подпись единиц в макетном спидометре.",
                kind = "dropdown",
                default = "Studs",
                group = "Movement",
                options = { "Studs", "Relative", "None" },
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_17_indicator_update_sample",
                title = "Indicator Update Sample",
                description = "Демо-действие для проверки обновления панели.",
                kind = "action",
                default = false,
                group = "Movement",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "movement_extra_18_movement_panel_position",
                title = "Movement Panel Position",
                description = "Расположение вспомогательной панели движения.",
                kind = "dropdown",
                default = "Bottom Right",
                group = "Movement",
                options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "player_extra_01_profile_card_preview",
                title = "Profile Card Preview",
                description = "Показывает состояние макетной карточки профиля.",
                kind = "toggle",
                default = true,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_02_profile_card_variant",
                title = "Profile Card Variant",
                description = "Выбор стиля локальной карточки.",
                kind = "dropdown",
                default = "Glass",
                group = "Player",
                options = { "Glass", "Flat", "Outlined" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_03_avatar_frame_preview",
                title = "Avatar Frame Preview",
                description = "Включает декоративную рамку аватара.",
                kind = "toggle",
                default = true,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_04_avatar_frame_shape",
                title = "Avatar Frame Shape",
                description = "Форма рамки в макете профиля.",
                kind = "dropdown",
                default = "Rounded",
                group = "Player",
                options = { "Rounded", "Circle", "Square" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_05_player_tag_scale",
                title = "Player Tag Scale",
                description = "Размер демонстрационной метки игрока.",
                kind = "slider",
                default = 100,
                group = "Player",
                options = {},
                min = 70,
                max = 140,
            },
            {
                id = "player_extra_06_session_clock_preview",
                title = "Session Clock Preview",
                description = "Переключатель макетных часов сессии.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_07_session_clock_format",
                title = "Session Clock Format",
                description = "Формат отображения времени в образце.",
                kind = "dropdown",
                default = "24 Hour",
                group = "Player",
                options = { "24 Hour", "12 Hour", "Compact" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_08_local_stats_panel",
                title = "Local Stats Panel",
                description = "Показывает состояние демонстрационной панели статистики.",
                kind = "toggle",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_09_stats_number_style",
                title = "Stats Number Style",
                description = "Оформление чисел в локальном макете.",
                kind = "dropdown",
                default = "Tabular",
                group = "Player",
                options = { "Tabular", "Rounded", "Compact" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_10_player_card_padding",
                title = "Player Card Padding",
                description = "Внутренние отступы карточки профиля.",
                kind = "slider",
                default = 12,
                group = "Player",
                options = {},
                min = 4,
                max = 24,
            },
            {
                id = "player_extra_11_badge_border_preview",
                title = "Badge Border Preview",
                description = "Включает контур декоративного бейджа.",
                kind = "toggle",
                default = true,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_12_profile_accent_color",
                title = "Profile Accent Color",
                description = "Цветовой пресет для образца профиля.",
                kind = "dropdown",
                default = "Aquamarine",
                group = "Player",
                options = { "Aquamarine", "Midnight", "Graphite" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_13_player_status_sample",
                title = "Player Status Sample",
                description = "Демо-действие уведомления о статусе.",
                kind = "action",
                default = false,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_14_profile_layout_density",
                title = "Profile Layout Density",
                description = "Плотность элементов карточки профиля.",
                kind = "dropdown",
                default = "Normal",
                group = "Player",
                options = { "Compact", "Normal", "Wide" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_15_profile_accent_preview",
                title = "Profile Accent Preview",
                description = "Переключатель акцентной линии карточки профиля.",
                kind = "toggle",
                default = true,
                group = "Player",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_16_status_dot_size",
                title = "Status Dot Size",
                description = "Размер декоративной точки состояния.",
                kind = "slider",
                default = 6,
                group = "Player",
                options = {},
                min = 3,
                max = 14,
            },
            {
                id = "player_extra_17_profile_badge_position",
                title = "Profile Badge Position",
                description = "Место бейджа в карточке профиля.",
                kind = "dropdown",
                default = "Top Right",
                group = "Player",
                options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
                min = 0,
                max = 100,
            },
            {
                id = "player_extra_18_player_card_border",
                title = "Player Card Border",
                description = "Стиль границы демонстрационной карточки.",
                kind = "dropdown",
                default = "Subtle",
                group = "Player",
                options = { "None", "Subtle", "Strong" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "world_extra_01_world_panel_preview",
                title = "World Panel Preview",
                description = "Отображение только локального макета панели мира.",
                kind = "toggle",
                default = true,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_02_environment_card_style",
                title = "Environment Card Style",
                description = "Стиль карточек с настройками окружения.",
                kind = "dropdown",
                default = "Layered",
                group = "World",
                options = { "Layered", "Flat", "Outline" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_03_weather_label_preview",
                title = "Weather Label Preview",
                description = "Декоративная метка погоды без изменения мира.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_04_time_display_format",
                title = "Time Display Format",
                description = "Формат надписи времени в предпросмотре.",
                kind = "dropdown",
                default = "24 Hour",
                group = "World",
                options = { "24 Hour", "12 Hour", "Minimal" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_05_lighting_label_scale",
                title = "Lighting Label Scale",
                description = "Размер условной подписи освещения.",
                kind = "slider",
                default = 100,
                group = "World",
                options = {},
                min = 70,
                max = 140,
            },
            {
                id = "world_extra_06_skybox_card_opacity",
                title = "Skybox Card Opacity",
                description = "Прозрачность демонстрационной карточки неба.",
                kind = "slider",
                default = 82,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_07_world_color_palette",
                title = "World Color Palette",
                description = "Палитра для макета настроек мира.",
                kind = "dropdown",
                default = "Ocean",
                group = "World",
                options = { "Ocean", "Dusk", "Mono" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_08_atmosphere_panel",
                title = "Atmosphere Panel",
                description = "Включает визуальный раздел атмосферы в макете.",
                kind = "toggle",
                default = true,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_09_world_preview_badge",
                title = "World Preview Badge",
                description = "Показывает бейдж режима предпросмотра.",
                kind = "toggle",
                default = true,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_10_environment_grid",
                title = "Environment Grid",
                description = "Переключатель сетки карточек окружения.",
                kind = "toggle",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_11_environment_grid_gap",
                title = "Environment Grid Gap",
                description = "Расстояние между карточками сетки.",
                kind = "slider",
                default = 10,
                group = "World",
                options = {},
                min = 2,
                max = 20,
            },
            {
                id = "world_extra_12_world_profile_card",
                title = "World Profile Card",
                description = "Вариант карточки профиля мира.",
                kind = "dropdown",
                default = "Soft",
                group = "World",
                options = { "Soft", "Crisp", "Glass" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_13_world_settings_summary",
                title = "World Settings Summary",
                description = "Демо-действие показа сводки UI-настроек.",
                kind = "action",
                default = false,
                group = "World",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_14_world_panel_density",
                title = "World Panel Density",
                description = "Плотность карточек в разделе окружения.",
                kind = "dropdown",
                default = "Comfortable",
                group = "World",
                options = { "Compact", "Comfortable", "Spacious" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_15_world_label_opacity",
                title = "World Label Opacity",
                description = "Прозрачность подписей в макетном разделе мира.",
                kind = "slider",
                default = 80,
                group = "World",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "world_extra_16_lighting_card_density",
                title = "Lighting Card Density",
                description = "Плотность карточек настроек освещения.",
                kind = "dropdown",
                default = "Normal",
                group = "World",
                options = { "Compact", "Normal", "Spacious" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_17_sky_preview_style",
                title = "Sky Preview Style",
                description = "Стиль карточки неба без изменения окружения.",
                kind = "dropdown",
                default = "Horizon",
                group = "World",
                options = { "Horizon", "Gradient", "Minimal" },
                min = 0,
                max = 100,
            },
            {
                id = "world_extra_18_environment_badge_position",
                title = "Environment Badge Position",
                description = "Позиция бейджа на карточке окружения.",
                kind = "dropdown",
                default = "Top Right",
                group = "World",
                options = { "Top Left", "Top Right", "Bottom Right" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "misc_extra_01_watermark_scale",
                title = "Watermark Scale",
                description = "Размер локального водяного знака.",
                kind = "slider",
                default = 100,
                group = "Miscellaneous",
                options = {},
                min = 70,
                max = 150,
            },
            {
                id = "misc_extra_02_watermark_opacity",
                title = "Watermark Opacity",
                description = "Прозрачность водяного знака в макете.",
                kind = "slider",
                default = 88,
                group = "Miscellaneous",
                options = {},
                min = 15,
                max = 100,
            },
            {
                id = "misc_extra_03_toast_position",
                title = "Toast Position",
                description = "Позиция демонстрационных уведомлений.",
                kind = "dropdown",
                default = "Top Right",
                group = "Miscellaneous",
                options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_04_toast_animation",
                title = "Toast Animation",
                description = "Стиль анимации уведомления интерфейса.",
                kind = "dropdown",
                default = "Slide",
                group = "Miscellaneous",
                options = { "Fade", "Slide", "Scale" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_05_keybind_panel_preview",
                title = "Keybind Panel Preview",
                description = "Включает декоративный список горячих клавиш.",
                kind = "toggle",
                default = false,
                group = "Miscellaneous",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_06_keybind_panel_width",
                title = "Keybind Panel Width",
                description = "Ширина локального списка клавиш.",
                kind = "slider",
                default = 220,
                group = "Miscellaneous",
                options = {},
                min = 140,
                max = 320,
            },
            {
                id = "misc_extra_07_notification_sound_preview",
                title = "Notification Sound Preview",
                description = "Только переключатель состояния без воспроизведения звука.",
                kind = "toggle",
                default = false,
                group = "Miscellaneous",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_08_accent_animation",
                title = "Accent Animation",
                description = "Включает состояние анимации акцента UI.",
                kind = "toggle",
                default = true,
                group = "Miscellaneous",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_09_accent_animation_speed",
                title = "Accent Animation Speed",
                description = "Скорость условной анимации темы.",
                kind = "slider",
                default = 50,
                group = "Miscellaneous",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "misc_extra_10_footer_style",
                title = "Footer Style",
                description = "Оформление нижней строки окна.",
                kind = "dropdown",
                default = "Subtle",
                group = "Miscellaneous",
                options = { "Subtle", "Compact", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_11_touch_feedback_preview",
                title = "Touch Feedback Preview",
                description = "Показывает состояние сенсорной обратной связи.",
                kind = "toggle",
                default = true,
                group = "Miscellaneous",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_12_touch_target_size",
                title = "Touch Target Size",
                description = "Целевой размер сенсорных кнопок в макете.",
                kind = "slider",
                default = 44,
                group = "Miscellaneous",
                options = {},
                min = 32,
                max = 64,
            },
            {
                id = "misc_extra_13_toast_queue_preview",
                title = "Toast Queue Preview",
                description = "Демо-действие для очереди уведомлений.",
                kind = "action",
                default = false,
                group = "Miscellaneous",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_14_misc_panel_density",
                title = "Misc Panel Density",
                description = "Плотность элементов вспомогательного раздела.",
                kind = "dropdown",
                default = "Comfortable",
                group = "Miscellaneous",
                options = { "Compact", "Comfortable", "Spacious" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_15_toast_duration_preview",
                title = "Toast Duration Preview",
                description = "Настраиваемая длительность-пример уведомления.",
                kind = "slider",
                default = 2.4,
                group = "Miscellaneous",
                options = {},
                min = 0.5,
                max = 6.0,
            },
            {
                id = "misc_extra_16_watermark_position",
                title = "Watermark Position",
                description = "Положение водяного знака в макете.",
                kind = "dropdown",
                default = "Top Left",
                group = "Miscellaneous",
                options = { "Top Left", "Top Right", "Bottom Left", "Bottom Right" },
                min = 0,
                max = 100,
            },
            {
                id = "misc_extra_17_keybind_row_height",
                title = "Keybind Row Height",
                description = "Высота строки списка клавиш в предпросмотре.",
                kind = "slider",
                default = 28,
                group = "Miscellaneous",
                options = {},
                min = 20,
                max = 44,
            },
            {
                id = "misc_extra_18_ui_feedback_style",
                title = "UI Feedback Style",
                description = "Оформление обратной связи на нажатия.",
                kind = "dropdown",
                default = "Soft",
                group = "Miscellaneous",
                options = { "Soft", "Sharp", "Minimal" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "config_extra_01_config_card_style",
                title = "Config Card Style",
                description = "Оформление карточек профилей настроек.",
                kind = "dropdown",
                default = "Outlined",
                group = "Config",
                options = { "Outlined", "Flat", "Glass" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_02_config_list_density",
                title = "Config List Density",
                description = "Плотность списка локальных пресетов.",
                kind = "dropdown",
                default = "Comfortable",
                group = "Config",
                options = { "Compact", "Comfortable", "Spacious" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_03_autosave_badge_preview",
                title = "Autosave Badge Preview",
                description = "Декоративный бейдж состояния автосохранения.",
                kind = "toggle",
                default = true,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_04_autosave_interval_label",
                title = "Autosave Interval Label",
                description = "Макет значения интервала без сохранения на диск.",
                kind = "slider",
                default = 30,
                group = "Config",
                options = {},
                min = 5,
                max = 120,
            },
            {
                id = "config_extra_05_profile_description_preview",
                title = "Profile Description Preview",
                description = "Включает описания в карточках локальных профилей.",
                kind = "toggle",
                default = true,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_06_profile_icon_style",
                title = "Profile Icon Style",
                description = "Выбор иконок для карточек профиля.",
                kind = "dropdown",
                default = "Line",
                group = "Config",
                options = { "Line", "Solid", "Minimal" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_07_import_panel_preview",
                title = "Import Panel Preview",
                description = "Показывает состояние панели импорта без чтения файлов.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_08_export_panel_preview",
                title = "Export Panel Preview",
                description = "Показывает состояние панели экспорта без доступа к буферу.",
                kind = "toggle",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_09_config_slot_count",
                title = "Config Slot Count",
                description = "Количество отображаемых слотов-примеров.",
                kind = "slider",
                default = 6,
                group = "Config",
                options = {},
                min = 1,
                max = 12,
            },
            {
                id = "config_extra_10_config_timestamp_format",
                title = "Config Timestamp Format",
                description = "Формат даты в демонстрационной строке профиля.",
                kind = "dropdown",
                default = "ISO",
                group = "Config",
                options = { "ISO", "Short", "Relative" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_11_config_confirmation_style",
                title = "Config Confirmation Style",
                description = "Стиль диалогов подтверждения макета.",
                kind = "dropdown",
                default = "Modal",
                group = "Config",
                options = { "Modal", "Inline", "Toast" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_12_config_status_marker",
                title = "Config Status Marker",
                description = "Показывает локальную метку активного профиля.",
                kind = "toggle",
                default = true,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_13_config_profile_preview",
                title = "Config Profile Preview",
                description = "Демо-действие просмотра профиля.",
                kind = "action",
                default = false,
                group = "Config",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_14_config_section_spacing",
                title = "Config Section Spacing",
                description = "Отступы между карточками конфигурации.",
                kind = "slider",
                default = 12,
                group = "Config",
                options = {},
                min = 4,
                max = 24,
            },
            {
                id = "config_extra_15_config_slot_style",
                title = "Config Slot Style",
                description = "Вариант оформления слотов конфигурации.",
                kind = "dropdown",
                default = "Tiles",
                group = "Config",
                options = { "Tiles", "Rows", "Compact" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_16_config_badge_opacity",
                title = "Config Badge Opacity",
                description = "Прозрачность бейджа активного пресета.",
                kind = "slider",
                default = 86,
                group = "Config",
                options = {},
                min = 10,
                max = 100,
            },
            {
                id = "config_extra_17_config_preview_density",
                title = "Config Preview Density",
                description = "Плотность списка параметров предпросмотра.",
                kind = "dropdown",
                default = "Normal",
                group = "Config",
                options = { "Compact", "Normal", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "config_extra_18_profile_detail_level",
                title = "Profile Detail Level",
                description = "Объём описаний в карточках локальных профилей.",
                kind = "dropdown",
                default = "Standard",
                group = "Config",
                options = { "Brief", "Standard", "Extended" },
                min = 0,
                max = 100,
            },
        },
    },

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
            {
                id = "about_extra_01_build_label_style",
                title = "Build Label Style",
                description = "Оформление версии в верхней панели.",
                kind = "dropdown",
                default = "Badge",
                group = "About",
                options = { "Badge", "Plain", "Compact" },
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_02_about_card_layout",
                title = "About Card Layout",
                description = "Компоновка карточек информации о проекте.",
                kind = "dropdown",
                default = "Two Column",
                group = "About",
                options = { "One Column", "Two Column", "List" },
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_03_feature_count_preview",
                title = "Feature Count Preview",
                description = "Показывает демонстрационный счётчик компонентов.",
                kind = "toggle",
                default = true,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_04_runtime_status_preview",
                title = "Runtime Status Preview",
                description = "Состояние индикатора запуска UI-макета.",
                kind = "toggle",
                default = true,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_05_accessibility_contrast",
                title = "Accessibility Contrast",
                description = "Вариант контрастности элементов интерфейса.",
                kind = "dropdown",
                default = "Standard",
                group = "About",
                options = { "Standard", "High", "Soft" },
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_06_large_touch_controls",
                title = "Large Touch Controls",
                description = "Включает состояние увеличенных сенсорных контролов.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_07_large_touch_scale",
                title = "Large Touch Scale",
                description = "Размер условного увеличения контролов.",
                kind = "slider",
                default = 110,
                group = "About",
                options = {},
                min = 100,
                max = 140,
            },
            {
                id = "about_extra_08_reduced_motion_preview",
                title = "Reduced Motion Preview",
                description = "Переключатель режима уменьшенного движения UI.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_09_diagnostics_detail",
                title = "Diagnostics Detail",
                description = "Уровень подробности локальных сведений.",
                kind = "dropdown",
                default = "Standard",
                group = "About",
                options = { "Basic", "Standard", "Detailed" },
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_10_panel_border_preview",
                title = "Panel Border Preview",
                description = "Показывает состояние границ панелей.",
                kind = "toggle",
                default = true,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_11_panel_shadow_preview",
                title = "Panel Shadow Preview",
                description = "Переключатель состояния тени в образце.",
                kind = "toggle",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_12_about_spacing_scale",
                title = "About Spacing Scale",
                description = "Масштаб отступов информационного раздела.",
                kind = "slider",
                default = 100,
                group = "About",
                options = {},
                min = 75,
                max = 130,
            },
            {
                id = "about_extra_13_prototype_status_sample",
                title = "Prototype Status Sample",
                description = "Демо-действие с уведомлением о режиме макета.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_14_about_layout_refresh",
                title = "About Layout Refresh",
                description = "Демо-действие для проверки отзывчивости панели.",
                kind = "action",
                default = false,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_15_accessibility_hint_preview",
                title = "Accessibility Hint Preview",
                description = "Показывает состояние подсказки доступности.",
                kind = "toggle",
                default = true,
                group = "About",
                options = {},
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_16_diagnostics_badge_style",
                title = "Diagnostics Badge Style",
                description = "Оформление бейджа диагностики интерфейса.",
                kind = "dropdown",
                default = "Outlined",
                group = "About",
                options = { "Outlined", "Filled", "Minimal" },
                min = 0,
                max = 100,
            },
            {
                id = "about_extra_17_layout_scale_preview",
                title = "Layout Scale Preview",
                description = "Масштаб UI-макета в условных процентах.",
                kind = "slider",
                default = 100,
                group = "About",
                options = {},
                min = 80,
                max = 125,
            },
            {
                id = "about_extra_18_information_card_spacing",
                title = "Information Card Spacing",
                description = "Расстояние между информационными карточками.",
                kind = "slider",
                default = 12,
                group = "About",
                options = {},
                min = 4,
                max = 28,
            },
        },
    },
}

for _, tab in ipairs(CATALOG) do
    tabById[tab.id] = tab
    for _, item in ipairs(tab.features) do
        featureById[item.id] = item
        if state.values[item.id] == nil then
            state.values[item.id] = item.default
        end
    end
end

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

end)

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

renderActiveTab()
updateResponsiveSize()
window.Visible = not SETTINGS.StartMinimized
reopenButton.Visible = SETTINGS.StartMinimized
reopenHint.Visible = SETTINGS.StartMinimized

task.delay(0.45, function()
    if ScreenGui and ScreenGui.Parent then
        showSafetyToast()
    end
end)

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
