-- AquariumClient: показывает монеты, рыб, окна паков и коллекции; отправляет запросы серверу.
-- Клиент только рисует и просит; все решения (деньги, выпадение, продажа, награды) принимает сервер.
-- Все тексты — через Strings.t(...) (ru/en), см. ReplicatedStorage/Shared/Strings.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local gui = script.Parent
local localPlayer = Players.LocalPlayer

local tank = gui:WaitForChild("Tank")
local coinsLabel = gui:WaitForChild("CoinsLabel")
local buyButton = gui:WaitForChild("BuyButton")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local openPackEvent = remotes:WaitForChild("OpenPack")
local packResultEvent = remotes:WaitForChild("PackResult")
local collectionChangedEvent = remotes:WaitForChild("CollectionChanged")
local sellFishEvent = remotes:WaitForChild("SellFish")
local coinsChangedEvent = remotes:WaitForChild("CoinsChanged")
local fishChangedEvent = remotes:WaitForChild("FishChanged")
local clientReadyEvent = remotes:WaitForChild("ClientReady")
local buySlotEvent = remotes:WaitForChild("BuySlot")
local adminCommandEvent = remotes:WaitForChild("AdminCommand")
local offlineIncomeEvent = remotes:WaitForChild("OfflineIncome")
local buyTankEvent = remotes:WaitForChild("BuyTank")
local dailyStateEvent = remotes:WaitForChild("DailyState")
local claimDailyEvent = remotes:WaitForChild("ClaimDaily")
local tutorialDoneEvent = remotes:WaitForChild("TutorialDone")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FishConfig = require(Shared:WaitForChild("FishConfig"))
local Sprites = require(Shared:WaitForChild("Sprites"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local Strings = require(Shared:WaitForChild("Strings"))
local T = Strings.t

-- ===== ЗВУК =====
-- Только встроенные клиентские файлы rbxasset://sounds/... (загружать ничего не нужно).
-- Громкость каждого звука не выше 0.4. Фоновая музыка — плейлист Playlist: треки играют по очереди
-- (каждый раз в случайном порядке) с паузой между ними и громкостью AmbientVolume.
-- Все треки из Creator Store (бесплатные для использования в играх Roblox, автор DistrokidOfficial).
local Audio = {
	Volume = 0.35, -- общая громкость эффектов (потолок 0.4)
	Sounds = {
		click = "rbxasset://sounds/clickfast.wav", -- нажатие кнопки
		open = "rbxasset://sounds/impact_water.mp3", -- открытие пака
		reveal = "rbxasset://sounds/electronicpingshort.wav", -- показ карточки рыбы
		reward = "rbxasset://sounds/victory.wav", -- получение награды
		buy = "rbxasset://sounds/snap.mp3", -- покупка (пак, место, аквариум)
	},
	Gain = { click = 0.7, open = 0.6, reveal = 0.8, reward = 0.7, buy = 0.9 }, -- множитель от Volume
	Playlist = {
		"rbxassetid://140662085604483", -- Aroma calm ritual
		"rbxassetid://115907387271753", -- Winds of Stillness
		"rbxassetid://103491917833365", -- Silent Moon Drift
		"rbxassetid://88326647335364", -- Warm stones meditation
		"rbxassetid://106345640140355", -- Soothing Cosmic Drift
	},
	AmbientVolume = 0.2,
	AmbientGap = 6, -- пауза между треками, секунд
}
local MAX_SFX_VOLUME = 0.4
-- =====================

local Sfx = { enabled = true, musicEnabled = true, sounds = {}, ambient = nil }

function Sfx.play(key)
	if not Sfx.enabled then
		return
	end
	local sound = Sfx.sounds[key]
	if sound ~= nil then
		pcall(function()
			sound.TimePosition = 0
			sound:Play()
		end)
	end
end

function Sfx.click()
	Sfx.play("click")
end

-- Показывает ошибку в консоли, но не роняет остальной интерфейс
local function safely(label, fn)
	return function(...)
		local ok, err = pcall(fn, ...)
		if not ok then
			warn("[Ataraxia] " .. label .. ": " .. tostring(err))
		end
	end
end

-- Создаёт объект, задаёт свойства и в конце помещает в родителя.
-- Служебные поля: MinText/MaxText — границы UITextSizeConstraint для TextScaled (по умолчанию 11..32),
-- NoSfx — не играть звук нажатия.
local function make(className, props, parent)
	local minText, maxText, noSfx = props.MinText, props.MaxText, props.NoSfx
	props.MinText, props.MaxText, props.NoSfx = nil, nil, nil
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	UIKit.font(inst) -- единый пиксельный шрифт для всех текстов
	if props.TextScaled and (className == "TextLabel" or className == "TextButton") then
		local limit = Instance.new("UITextSizeConstraint")
		limit.MinTextSize = minText or 11
		limit.MaxTextSize = maxText or 32
		limit.Parent = inst
	end
	if className == "TextButton" and not noSfx then
		inst.Activated:Connect(function()
			Sfx.click()
		end)
	end
	inst.Parent = parent
	if className == "TextButton" and props.BackgroundTransparency == nil then
		UIKit.button(inst)
	end
	return inst
end

-- Одна заготовка Sound на каждый эффект (если что-то не создалось — звук просто не играет)
pcall(function()
	for key, id in pairs(Audio.Sounds) do
		local volume = math.min(Audio.Volume * (Audio.Gain[key] or 1), MAX_SFX_VOLUME)
		Sfx.sounds[key] = make("Sound", { Name = "Sfx_" .. key, SoundId = id, Volume = volume }, gui)
	end
end)

-- Фоновая музыка: один Sound, в который по очереди подставляются треки плейлиста.
-- Трек, который не загрузился, пропускается; если не играет ни один, цикл тихо останавливается.
task.spawn(function()
	local list = Audio.Playlist
	if list == nil or #list == 0 then
		return
	end
	local ok = pcall(function()
		Sfx.ambient = make("Sound", {
			Name = "Ambient",
			Volume = math.min(Audio.AmbientVolume, MAX_SFX_VOLUME),
			Looped = false,
		}, gui)
	end)
	if not ok or Sfx.ambient == nil then
		return
	end
	local rng = Random.new()
	local failures = 0
	while failures < #list * 2 do
		-- новый случайный порядок на каждый круг плейлиста
		local order = table.clone(list)
		for i = #order, 2, -1 do
			local j = rng:NextInteger(1, i)
			order[i], order[j] = order[j], order[i]
		end
		for _, id in ipairs(order) do
			local sound = Sfx.ambient
			sound.SoundId = id
			sound:Play()
			if not Sfx.musicEnabled then
				sound:Pause() -- музыка выключена в настройках: трек стоит, пока её не включат
			end
			local started = os.clock()
			-- ждём конец трека; если за 15 секунд он так и не начал играть, трек не загрузился
			local ended = false
			local connection = sound.Ended:Connect(function()
				ended = true
			end)
			while not ended and sound.Parent ~= nil do
				task.wait(1)
				if not sound.IsPlaying and not sound.IsLoaded and os.clock() - started > 15 then
					break
				end
			end
			connection:Disconnect()
			sound:Stop()
			if os.clock() - started < 20 then
				failures += 1 -- слишком короткий «трек» = не загрузился
			else
				failures = 0
			end
			task.wait(Audio.AmbientGap)
		end
	end
end)

-- Звуки (нажатия, пак, награды) включаются отдельно от музыки
function Sfx.setEnabled(value)
	Sfx.enabled = value
	pcall(function()
		if not value then
			for _, sound in pairs(Sfx.sounds) do
				sound:Stop()
			end
		end
	end)
end

-- Фоновая музыка: выключенная ставится на паузу, включённая продолжает с того же места
function Sfx.setMusic(value)
	Sfx.musicEnabled = value
	pcall(function()
		if Sfx.ambient then
			if value then
				Sfx.ambient:Resume()
			else
				Sfx.ambient:Pause()
			end
		end
	end)
end

-- ===== БЕЗОПАСНАЯ ЗОНА =====
-- Интерфейс (кнопки, панели) рисуется внутри CoreUISafeInsets: ниже верхней панели Roblox,
-- вне выреза/чёлки и полоски жестов. Фон аквариума с рыбами переезжает в отдельный ScreenGui
-- без отступов, чтобы он по-прежнему занимал весь экран.
pcall(function()
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.IgnoreGuiInset = false
	gui.ClipToDeviceSafeArea = false
end)
do
	local ok, backdrop = pcall(function()
		local screen = Instance.new("ScreenGui")
		screen.Name = "AquariumBackdrop"
		screen.ResetOnSpawn = false
		screen.IgnoreGuiInset = true
		screen.ScreenInsets = Enum.ScreenInsets.None
		screen.ClipToDeviceSafeArea = false
		screen.DisplayOrder = gui.DisplayOrder - 1
		screen.Parent = localPlayer:WaitForChild("PlayerGui")
		return screen
	end)
	if ok then
		tank.Parent = backdrop
	end
end

-- ===== НАСТРОЙКИ =====
local FISH_SIZE = UDim2.fromScale(0.16, 0.1) -- высоту задаёт UIAspectRatioConstraint (квадрат по ширине)
local FISH_SPEED = 0.1
local FISH_ZINDEX = 2 -- выше фона (1), ниже кнопок и монет (3)
local MIN_X, MAX_X = 0.14, 0.86
local MIN_Y, MAX_Y = 0.38, 0.64 -- координаты всего экрана; сверху карточка выбранной рыбы, снизу подсказка и кнопки
local currentTank = "lagoon" -- какой аквариум сейчас на экране

local WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_PANEL = Color3.fromRGB(10, 70, 95)
local COLOR_ROW = Color3.fromRGB(8, 52, 72)
local COLOR_BUTTON = Color3.fromRGB(38, 166, 154)
local COLOR_MUTED = Color3.fromRGB(120, 144, 156)
local COLOR_GOLD = Color3.fromRGB(255, 202, 40)
local COLOR_WARN = Color3.fromRGB(231, 111, 81)
local COLOR_ALERT = Color3.fromRGB(229, 57, 53)
local FONT = Enum.Font.GothamBold -- запасной; поверх него UIKit.font ставит пиксельный FontFace
-- Тексты, созданные в Studio (монеты, число рыб, кнопка паков и др.), тоже получают пиксельный шрифт
for _, d in ipairs(gui:GetDescendants()) do
	UIKit.font(d)
end

-- Раскладка верхней части экрана (доли безопасной зоны): строка 1 — монеты, рыбы, кнопки; строка 2 — аквариум
local TOP_Y, TOP_H = 0.012, 0.07
local TANK_ROW_Y = 0.092
-- =====================

-- 35.00 -> "35%", 33.33333 -> "33.33%"
local function formatPercent(value)
	local text = string.format("%.2f", value)
	text = text:gsub("%.?0+$", "")
	return text .. "%"
end

-- Шанс каждого вида в паке: шанс редкости, поделённый на число видов этой редкости
local function speciesChances(pack)
	local result = {}
	for _, rarity in ipairs(FishConfig.RarityOrder) do
		local pool = FishConfig.speciesOfRarity(rarity, pack.tank)
		for _, id in ipairs(pool) do
			result[id] = (pack.odds[rarity] or 0) / #pool
		end
	end
	return result
end

-- Фон аквариума: пиксельная картинка поверх цвета воды (если картинки нет — виден просто цвет)
local background = make("ImageLabel", {
	Name = "Background",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ScaleType = Enum.ScaleType.Crop,
	Visible = false,
	ZIndex = 1,
}, tank)
local function applyBackground(tankId)
	local key = FishConfig.Tanks[tankId].background
	background.Visible = key ~= nil and Sprites.apply(background, key, false)
end
applyBackground(currentTank)

-- Пак текущего аквариума
local function currentPack()
	return FishConfig.Packs[FishConfig.Tanks[currentTank].pack]
end
local discovered = {} -- id вида -> true (собранные виды, присылает сервер)
-- Подсказки (ожидание монет, полная офлайн-копилка): реальный код задаёт блок магазина ниже, пока это заглушки.
-- noCoins() возвращает true, если сам показал подсказку и обычное сообщение не нужно.
local CurrentUi = { state = nil, receivedAt = 0 } -- течения и мутации от сервера (см. блок «Течения» ниже)
local Hints = { noCoins = function() return false end, offline = function(gained, capped) end }
local LeaderboardUi = { open = function() end } -- окно таблиц лидеров (настоящую функцию задаёт блок ниже)
local DecorUi = { show = function(tankId) end, build = function(parent, tankId, z) return function() end end } -- декор (блок ниже)
local setsState = {} -- наборы коллекции от сервера: { [tankId] = { bonus, tiers = { {have, need, done, bonus}, ... } } }
local revealBusy = false -- идёт анимация открытия пака
local pendingReveals = {} -- очередь результатов, если они пришли во время анимации

-- Заготовки для обучения и ежедневной награды (заполняются ниже; обращаемся к ним в рантайме)
local Tutorial = { active = false, resolved = false, finished = false, sent = false, step = 0, gotPack = false }
local Daily = { state = nil, syncedAt = 0, autoShown = false, pending = false, refetched = false }

-- ===== Верхняя строка: монеты, счётчик рыб, подарок, звук =====
local function iconButton(name, text, posX)
	local button = make("TextButton", {
		Name = name,
		Position = UDim2.fromScale(posX, TOP_Y),
		Size = UDim2.fromScale(0.1, TOP_H),
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		Text = text,
		TextScaled = true,
		MinText = 14,
		MaxText = 30,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 3,
	}, gui)
	make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, button)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, button)
	return button
end

coinsLabel.Position = UDim2.fromScale(0.02, TOP_Y)
coinsLabel.Size = UDim2.fromScale(0.34, TOP_H)
coinsLabel.Text = T("coins", 0)
make("UITextSizeConstraint", { MinTextSize = 12, MaxTextSize = 28 }, coinsLabel)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, coinsLabel)
UIKit.label(coinsLabel, 0.72) -- справа от иконки монеты
UIKit.icon(coinsLabel, "ui_coin", 0.05)

local fishCountLabel = make("TextLabel", {
	Name = "FishCountLabel",
	Position = UDim2.fromScale(0.37, TOP_Y),
	Size = UDim2.fromScale(0.18, TOP_H),
	BackgroundColor3 = COLOR_PANEL,
	BorderSizePixel = 0,
	Text = "",
	TextScaled = true,
	MinText = 12,
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 3,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, fishCountLabel)
UIKit.label(fishCountLabel)

local giftButton = iconButton("DailyButton", "🎁", 0.57)
local giftDot = make("Frame", {
	Name = "RedDot",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.92, 0.1),
	Size = UDim2.fromScale(0.36, 0.36),
	BackgroundColor3 = COLOR_ALERT,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 4,
}, giftButton)
make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, giftDot)
make("UIStroke", { Color = WHITE, Thickness = 1.5 }, giftDot)

local soundButton = iconButton("SoundButton", "🎧", 0.88) -- открывает настройки звука (см. блок «Настройки» ниже)

-- ===== Монеты и покупка пака =====
buyButton.AnchorPoint = Vector2.new(0.5, 1)
buyButton.Position = UDim2.fromScale(0.5, 0.985)
buyButton.Size = UDim2.fromScale(0.96, 0.095)
make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 34 }, buyButton)
make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, buyButton)
-- Кнопка паков — «цирковой билет», который пульсирует и привлекает внимание.
-- Создана в Studio, а не через make(), поэтому скин вешаем вручную.
buyButton.TextColor3 = Color3.fromRGB(255, 241, 193)
UIKit.ticket(buyButton)
UIKit.pulse(buyButton)

local function refreshBuyButton()
	local pack = currentPack()
	local key = if pack.currency == "candy" then "buy_pack_candy" else "buy_pack"
	buyButton.Text = T(key, Strings.pack(FishConfig.Tanks[currentTank].pack), pack.price)
end
refreshBuyButton()

buyButton.Activated:Connect(function()
	Sfx.click()
	if revealBusy then
		return
	end
	openPackEvent:FireServer(FishConfig.Tanks[currentTank].pack) -- отправляем только id пака
end)

coinsChangedEvent.OnClientEvent:Connect(function(newCoins)
	coinsLabel.Text = T("coins", newCoins)
end)

-- Вторичные кнопки над главной
local function makeSecondaryButton(name, text, posX)
	local button = make("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(posX, 0.88),
		Size = UDim2.fromScale(0.31, 0.075),
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		Text = text,
		TextScaled = true,
		MinText = 12,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 3,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, button)
	return button
end

local collectionButton = makeSecondaryButton("CollectionButton", "", 0.02)
local oddsButton = makeSecondaryButton("OddsButton", T("odds"), 0.345)
local expandButton = makeSecondaryButton("ExpandButton", "", 0.67)

local tankSlots = {} -- [tankId] = сколько рыб помещается (присылает сервер; нет записи = аквариум не открыт)
local tankCounts = {} -- [tankId] = сколько рыб сейчас
local onTanksChanged = nil -- обновление окна выбора аквариума (задаётся ниже)

local function refreshSlotsUi()
	local slots = tankSlots[currentTank] or FishConfig.START_SLOTS
	fishCountLabel.Text = "🐟 " .. tostring(tankCounts[currentTank] or 0) .. "/" .. tostring(slots)
	local nextPrice = FishConfig.slotPrice(currentTank, slots + 1)
	if nextPrice == nil or slots >= FishConfig.MAX_SLOTS then
		expandButton.Text = T("slots_max")
		expandButton.BackgroundColor3 = COLOR_MUTED
	else
		expandButton.Text = T("slot_buy", nextPrice)
		expandButton.BackgroundColor3 = COLOR_BUTTON
	end
end

expandButton.Activated:Connect(function()
	if (tankSlots[currentTank] or FishConfig.START_SLOTS) < FishConfig.MAX_SLOTS then
		buySlotEvent:FireServer(currentTank) -- только id аквариума: цену берёт сервер
	end
end)
refreshSlotsUi()

-- Выбор аквариума (вторая строка сверху)
local tankButton = make("TextButton", {
	Name = "TankButton",
	Position = UDim2.fromScale(0.02, TANK_ROW_Y),
	Size = UDim2.fromScale(0.72, TOP_H), -- справа от выбора аквариума стоит кнопка музея
	BackgroundColor3 = COLOR_PANEL,
	BorderSizePixel = 0,
	TextScaled = true,
	MinText = 13,
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 3,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, tankButton)

-- ===== Уведомление («Аквариум полон», «Не хватает монет») =====
local toast = make("TextLabel", {
	Name = "ToastLabel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.43),
	Size = UDim2.fromScale(0.9, 0.075),
	BackgroundColor3 = COLOR_WARN,
	BorderSizePixel = 0,
	TextScaled = true,
	MinText = 12,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 15,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, toast)
local toastToken = 0

local function showToast(text, color, duration)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.BackgroundColor3 = color or COLOR_WARN
	toast.Visible = true
	task.delay(duration or 2, function()
		if toastToken == token then
			toast.Visible = false
		end
	end)
end

-- ===== Окно-панель: затемнение + карточка с заголовком, списком и кнопкой «Закрыть» =====
local function makePanel(name)
	local overlay = make("TextButton", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 10,
		Visible = false,
	}, gui)

	local card = make("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.78),
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		Active = true, -- не пропускает нажатия сквозь карточку
		ZIndex = 11,
	}, overlay)
	make("UICorner", { CornerRadius = UDim.new(0.04, 0) }, card)
	UIKit.frame(card, "ui_panel")

	local title = make("TextLabel", {
		Name = "Title",
		Position = UDim2.fromScale(0.05, 0.02),
		Size = UDim2.fromScale(0.9, 0.1),
		BackgroundTransparency = 1,
		TextScaled = true,
		MinText = 13,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 12,
	}, card)

	local list = make("Frame", {
		Name = "List",
		Position = UDim2.fromScale(0.05, 0.14),
		Size = UDim2.fromScale(0.9, 0.58),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, card)
	make("UIListLayout", { Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local close = make("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.96),
		Size = UDim2.fromScale(0.5, 0.1),
		BackgroundColor3 = COLOR_BUTTON,
		BorderSizePixel = 0,
		Text = T("close"),
		TextScaled = true,
		MinText = 13,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 12,
	}, card)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, close)

	close.Activated:Connect(function()
		overlay.Visible = false
	end)
	overlay.Activated:Connect(function()
		overlay.Visible = false -- нажатие вне карточки тоже закрывает
	end)

	return { overlay = overlay, card = card, title = title, list = list, close = close }
end

-- Прокручиваемые списки: окно с большим числом строк (магазин, музей). Высоту строк задаём в пикселях (доля от высоты списка),
-- потому что у прокручиваемого списка доли высоты считать нельзя: размер холста зависит от самих строк.
local ListKit = {}
function ListKit.scroll(panel)
	local old = panel.list
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Position = old.Position
	scroll.Size = old.Size
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ZIndex = old.ZIndex
	make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	scroll.Parent = old.Parent
	old:Destroy()
	panel.list = scroll
	return scroll
end
function ListKit.rowSize(list, fraction)
	local height = list.AbsoluteSize.Y
	if height < 50 then
		height = 420 -- размер ещё не посчитан
	end
	return UDim2.new(1, 0, 0, math.floor(height * fraction))
end

-- Подсказка под списком (до двух строк)
local function addHint(panel, text)
	return make("TextLabel", {
		Name = "Hint",
		Position = UDim2.fromScale(0.05, 0.73),
		Size = UDim2.fromScale(0.9, 0.1),
		BackgroundTransparency = 1,
		Text = text,
		TextScaled = true,
		MinText = 11,
		MaxText = 18,
		TextWrapped = true,
		TextColor3 = COLOR_MUTED,
		Font = FONT,
		ZIndex = 12,
	}, panel.card)
end

local function clearRows(list)
	-- Список обновляется каждые несколько секунд: запоминаем прокрутку и возвращаем её после перестройки строк
	if list:IsA("ScrollingFrame") then
		local keepY = list.CanvasPosition.Y
		if keepY > 0 then
			task.spawn(function()
				game:GetService("RunService").Heartbeat:Wait()
				game:GetService("RunService").Heartbeat:Wait()
				list.CanvasPosition = Vector2.new(0, keepY)
			end)
		end
	end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

-- Строка списка: слева текст, справа текст
local function addRow(list, order, leftText, rightText, color)
	local row = make("Frame", {
		Size = UDim2.fromScale(1, 0.15),
		BackgroundColor3 = COLOR_ROW,
		BorderSizePixel = 0,
		LayoutOrder = order,
		ZIndex = 12,
	}, list)
	make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, row)
	make("TextLabel", {
		Size = UDim2.fromScale(0.64, 0.7),
		Position = UDim2.fromScale(0.03, 0.15),
		BackgroundTransparency = 1,
		Text = leftText,
		TextColor3 = color,
		TextScaled = true,
		MinText = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		ZIndex = 13,
	}, row)
	make("TextLabel", {
		Size = UDim2.fromScale(0.28, 0.7),
		Position = UDim2.fromScale(0.69, 0.15),
		BackgroundTransparency = 1,
		Text = rightText,
		TextColor3 = color,
		TextScaled = true,
		MinText = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = FONT,
		ZIndex = 13,
	}, row)
end

-- ===== Коллекция =====
local collectionPanel = makePanel("CollectionPanel")
addHint(collectionPanel, T("coll_hint"))

local function discoveredCount()
	local count = 0
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		if discovered[id] then
			count += 1
		end
	end
	return count
end

local function refreshCollection()
	local count = discoveredCount()
	-- виды ивентовых аквариумов считаем, только если такой аквариум у игрока есть
	local totalSpecies = 0
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		local tankId = FishConfig.Species[id].tank
		if FishConfig.Tanks[tankId].event == nil or tankSlots[tankId] ~= nil then
			totalSpecies += 1
		end
	end
	collectionButton.Text = T("collection", count, totalSpecies)
	local tankIds = FishConfig.speciesOfTank(currentTank)
	local tankFound = 0
	for _, id in ipairs(tankIds) do
		if discovered[id] then
			tankFound += 1
		end
	end
	collectionPanel.title.Text = T("coll_title", Strings.tank(currentTank), tankFound, #tankIds, count, totalSpecies)

	clearRows(collectionPanel.list)
	for index, id in ipairs(tankIds) do
		local species = FishConfig.Species[id]
		local rarity = FishConfig.Rarities[species.rarity]
		local entry = discovered[id]
		if entry then
			addRow(
				collectionPanel.list,
				index,
				species.emoji .. " " .. Strings.species(id) .. " ×" .. tostring(entry.pulled),
				"💰 " .. Strings.num(entry.earned),
				rarity.color
			)
		else
			addRow(collectionPanel.list, index, T("unknown_fish"), "—", COLOR_MUTED)
		end
	end

	-- Итоговая строка: прогресс набора (все виды / золотые / радужные) и прибавка к доходу этого аквариума
	local sets = setsState[currentTank]
	if sets ~= nil and sets.tiers ~= nil then
		local function part(tier)
			return if tier == nil then "?" else (tostring(tier.have) .. "/" .. tostring(tier.need))
		end
		local bonusPercent = math.floor((sets.bonus or 0) * 100 + 0.5)
		addRow(
			collectionPanel.list,
			99,
			T("set_row", part(sets.tiers[1]), part(sets.tiers[2]), part(sets.tiers[3])),
			T("set_bonus", bonusPercent),
			if bonusPercent > 0 then COLOR_GOLD else COLOR_MUTED
		)
	end

	-- Мутации: какие уже находили и сколько рыб с каждой
	local mutations = CurrentUi.state and CurrentUi.state.mutations
	if mutations ~= nil then
		addRow(collectionPanel.list, 100, T("mut_title"), "", COLOR_MUTED)
		for index, id in ipairs(FishConfig.MutationOrder) do
			local info = mutations[id]
			local def = FishConfig.Mutations[id]
			if info ~= nil and info.seen then
				addRow(collectionPanel.list, 100 + index, T("mut_row", def.emoji, Strings.mutation(id), string.format("%g", def.mult)), T("mut_count", info.count), COLOR_GOLD)
			else
				addRow(collectionPanel.list, 100 + index, T("unknown_fish"), "—", COLOR_MUTED)
			end
		end
	end
end

collectionButton.Activated:Connect(function()
	refreshCollection()
	collectionPanel.overlay.Visible = true
end)

collectionChangedEvent.OnClientEvent:Connect(function(list)
	discovered = {}
	for _, entry in ipairs(list) do
		discovered[entry.id] = entry -- { id, pulled, earned }
	end
	refreshCollection()
end)

-- ===== Шансы пака (всегда показываем игроку) =====
local oddsPanel = makePanel("OddsPanel")

-- Шансы цветовых вариантов (золотая, радужная) — тоже показываем игроку
do
	local totalWeight = 0
	for _, id in ipairs(FishConfig.VariantOrder) do
		totalWeight += FishConfig.Variants[id].weight
	end
	local parts = {}
	for _, id in ipairs(FishConfig.VariantOrder) do
		local variant = FishConfig.Variants[id]
		if id ~= "normal" then
			table.insert(parts, variant.emoji .. " " .. Strings.variant(id) .. " " .. formatPercent(variant.weight / totalWeight * 100) .. " (×" .. tostring(variant.mult) .. ")")
		end
	end
	addHint(oddsPanel, T("variant_hint", table.concat(parts, " · ")))
end

oddsButton.Activated:Connect(function()
	local pack = currentPack()
	oddsPanel.title.Text = T("odds_title", Strings.pack(FishConfig.Tanks[currentTank].pack))
	clearRows(oddsPanel.list)
	-- Конкретные рыбы скрыты ("❓"): показываем шанс каждой редкости,
	-- число видов в ней и долю одного вида. Сумма шансов редкостей = 100%.
	local chances = speciesChances(pack)
	local index = 0
	for _, rarityId in ipairs(FishConfig.RarityOrder) do
		local pool = FishConfig.speciesOfRarity(rarityId, pack.tank)
		if #pool > 0 then
			local total = 0
			for _, id in ipairs(pool) do
				total += chances[id] or 0
			end
			index += 1
			addRow(
				oddsPanel.list,
				index,
				T("odds_row", Strings.rarity(rarityId), #pool, formatPercent(total / #pool)),
				formatPercent(total),
				FishConfig.Rarities[rarityId].color
			)
		end
	end
	oddsPanel.overlay.Visible = true
end)

-- ===== Анимация открытия пака =====
local reveal = make("TextButton", {
	Name = "RevealOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.35,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 20,
	Visible = false,
}, gui)

local revealCard = make("Frame", {
	Name = "Card",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.8, 0.55),
	BackgroundColor3 = COLOR_PANEL,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 21,
}, reveal)
make("UICorner", { CornerRadius = UDim.new(0.05, 0) }, revealCard)
local revealStroke = make("UIStroke", { Color = COLOR_BUTTON, Thickness = 4 }, revealCard)

local revealEmoji = make("TextLabel", {
	Name = "Emoji",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.04),
	Size = UDim2.fromScale(0.6, 0.38),
	BackgroundTransparency = 1,
	Text = "❓",
	TextScaled = true,
	MaxText = 120,
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 22,
}, revealCard)
local revealScale = make("UIScale", { Scale = 1 }, revealEmoji)

-- Картинка рыбы на карточке открытия (если картинки нет — остаётся эмодзи)
local revealSprite = make("ImageLabel", {
	Name = "Sprite",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.04),
	Size = UDim2.fromScale(0.6, 0.38),
	BackgroundTransparency = 1,
	ScaleType = Enum.ScaleType.Fit,
	Visible = false,
	ZIndex = 22,
}, revealCard)
local revealSpriteScale = make("UIScale", { Scale = 1 }, revealSprite)

local revealName = make("TextLabel", {
	Name = "FishName",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromScale(0.9, 0.12),
	BackgroundTransparency = 1,
	TextScaled = true,
	MinText = 14,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 22,
}, revealCard)

local revealRarity = make("TextLabel", {
	Name = "Rarity",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.58),
	Size = UDim2.fromScale(0.9, 0.09),
	BackgroundTransparency = 1,
	TextScaled = true,
	MinText = 12,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 22,
}, revealCard)

local revealNew = make("TextLabel", {
	Name = "NewMark",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.69),
	Size = UDim2.fromScale(0.9, 0.08),
	BackgroundTransparency = 1,
	Text = T("new_in_collection"),
	TextScaled = true,
	MinText = 12,
	TextColor3 = COLOR_GOLD,
	Font = FONT,
	Visible = false,
	ZIndex = 22,
}, revealCard)

local revealClose = make("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.95),
	Size = UDim2.fromScale(0.5, 0.14),
	BackgroundColor3 = COLOR_BUTTON,
	BorderSizePixel = 0,
	Text = T("great"),
	TextScaled = true,
	MinText = 13,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 22,
}, revealCard)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, revealClose)

-- ===== Рулетка открытия пака =====
-- Полоса карточек едет влево и замедляется, останавливаясь выпавшей рыбой под указателем.
-- Результат уже решён сервером: рулетка только красиво его показывает. Карточки-«наполнители» берутся
-- из того же пака по его шансам; виды, которых игрок ещё не находил, показываются тёмным силуэтом «???».
local Roulette = {}
do
	local CARDS = 34 -- карточек на полосе
	local TARGET = 29 -- на какой остановимся
	local SPIN_TIME = 4.2
	local band = make("Frame", {
		Name = "Roulette",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 0.2),
		BackgroundColor3 = Color3.fromRGB(16, 30, 44),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 22,
	}, reveal)
	local strip = make("Frame", {
		Name = "Strip",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 22,
	}, band)
	-- указатели сверху и снизу (золотые треугольники)
	for _, top in ipairs({ true, false }) do
		make("TextLabel", {
			Name = if top then "PointerTop" else "PointerBottom",
			AnchorPoint = Vector2.new(0.5, if top then 0 else 1),
			Position = UDim2.fromScale(0.5, if top then 0 else 1),
			Size = UDim2.fromScale(0.08, 0.22),
			BackgroundTransparency = 1,
			Text = if top then "▼" else "▲",
			TextScaled = true,
			TextColor3 = COLOR_GOLD,
			ZIndex = 26,
		}, band)
	end
	make("Frame", { -- тонкая центральная линия
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(0, 2, 1, 0),
		BackgroundColor3 = COLOR_GOLD,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 25,
	}, band)

	-- Случайный вид из пака аквариума по шансам редкостей (только для вида, не влияет на результат)
	local function fillerSpecies(tankId)
		local pack = FishConfig.Packs[FishConfig.Tanks[tankId].pack]
		local roll = math.random() * 100
		local acc = 0
		for _, rarity in ipairs(FishConfig.RarityOrder) do
			acc += pack.odds[rarity] or 0
			if roll < acc then
				local pool = FishConfig.speciesOfRarity(rarity, tankId)
				if #pool > 0 then
					return pool[math.random(1, #pool)]
				end
			end
		end
		local all = FishConfig.speciesOfTank(tankId)
		return all[math.random(1, #all)]
	end

	local function makeCard(index, speciesId, known, cardW, gap)
		local species = FishConfig.Species[speciesId]
		local rarity = FishConfig.Rarities[species.rarity]
		local card = make("Frame", {
			Name = "Card" .. index,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, (index - 1) * (cardW + gap), 0.5, 0),
			Size = UDim2.new(0, cardW, 0.86, 0),
			BackgroundColor3 = rarity.color:Lerp(Color3.new(0, 0, 0), 0.72),
			BorderSizePixel = 0,
			ZIndex = 23,
		}, strip)
		make("UICorner", { CornerRadius = UDim.new(0.08, 0) }, card)
		make("UIStroke", { Color = rarity.color, Thickness = 2 }, card)
		local image = make("ImageLabel", {
			Name = "Fish",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.06),
			Size = UDim2.fromScale(0.8, 0.62),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = if known then WHITE else Color3.new(0, 0, 0),
			ZIndex = 24,
		}, card)
		image.ResampleMode = Enum.ResamplerMode.Pixelated
		if not Sprites.apply(image, speciesId, false) then
			image:Destroy()
			make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.06),
				Size = UDim2.fromScale(0.8, 0.62),
				BackgroundTransparency = 1,
				Text = if known then species.emoji else "❓",
				TextScaled = true,
				ZIndex = 24,
			}, card)
		end
		make("TextLabel", {
			Name = "Name",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.fromScale(0.92, 0.26),
			BackgroundTransparency = 1,
			Text = if known then Strings.species(speciesId) else "???",
			TextScaled = true,
			TextColor3 = rarity.color,
			Font = FONT,
			ZIndex = 24,
		}, card)
		return card
	end

	-- Крутит рулетку и ждёт, пока она остановится. result.species — выпавшая рыба.
	function Roulette.spin(result)
		local species = FishConfig.Species[result.species]
		if species == nil then
			return
		end
		strip:ClearAllChildren()
		band.Visible = true
		task.wait() -- дать посчитаться размерам
		local bandW, bandH = band.AbsoluteSize.X, band.AbsoluteSize.Y
		local cardW = math.max(40, math.floor(bandH * 0.72))
		local gap = math.max(4, math.floor(cardW * 0.08))
		for index = 1, CARDS do
			local id = if index == TARGET then result.species else fillerSpecies(species.tank)
			local known = index == TARGET or discovered[id] ~= nil
			makeCard(index, id, known, cardW, gap)
		end
		local step = cardW + gap
		-- небольшой случайный сдвиг внутри карточки, чтобы остановка не была всегда ровно по центру
		local jitter = math.random(-math.floor(cardW * 0.3), math.floor(cardW * 0.3))
		local finalX = -((TARGET - 1) * step + cardW / 2 - bandW / 2 + jitter)
		strip.Position = UDim2.new(0, 0, 0, 0)
		local tween = TweenService:Create(strip, TweenInfo.new(SPIN_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, finalX, 0, 0),
		})
		-- щелчок каждый раз, когда под указателем проходит новая карточка
		local lastIndex = -1
		local RunService = game:GetService("RunService")
		local connection = RunService.Heartbeat:Connect(function()
			local passed = math.floor((-strip.Position.X.Offset + bandW / 2) / step)
			if passed ~= lastIndex then
				lastIndex = passed
				Sfx.click()
			end
		end)
		tween:Play()
		tween.Completed:Wait()
		connection:Disconnect()
		-- выделяем выигрышную карточку
		local winner = strip:FindFirstChild("Card" .. TARGET)
		if winner then
			local pulse = make("UIScale", { Scale = 1 }, winner)
			TweenService:Create(pulse, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true), { Scale = 1.12 }):Play()
		end
		task.wait(0.55)
		band.Visible = false
		strip:ClearAllChildren()
	end
end

local function playReveal(result)
	revealBusy = true
	local species = FishConfig.Species[result.species] or FishConfig.Species.guppy
	local speciesId = if FishConfig.Species[result.species] then result.species else "guppy"
	local rarity = FishConfig.Rarities[result.rarity] or FishConfig.Rarities.common
	local rarityId = if FishConfig.Rarities[result.rarity] then result.rarity else "common"

	revealEmoji.Text = "❓"
	revealEmoji.Rotation = 0
	revealScale.Scale = 1
	revealSprite.Visible = false
	revealName.Visible = false
	revealRarity.Visible = false
	revealNew.Visible = false
	revealClose.Visible = false
	revealStroke.Color = COLOR_BUTTON
	reveal.Visible = true
	Sfx.play("open")

	-- Рулетка (при быстром открытии пачки паков пропускаем)
	if not result.fast then
		revealCard.Visible = false
		local ok, err = pcall(Roulette.spin, result)
		if not ok then
			warn("[Roulette] " .. tostring(err))
		end
		revealCard.Visible = true
	end

	-- Показываем рыбу
	local hasSprite = Sprites.apply(revealSprite, result.species, false)
	revealSprite.Visible = hasSprite
	revealEmoji.Text = if hasSprite then "" else species.emoji
	revealScale.Scale = 0.4
	revealSpriteScale.Scale = 0.4
	local pop = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(revealScale, pop, { Scale = 1 }):Play()
	TweenService:Create(revealSpriteScale, pop, { Scale = 1 }):Play()
	Sfx.play("reveal")
	local variant = FishConfig.variantOf(result.variant)
	local special = result.variant ~= nil and result.variant ~= "normal"
	revealStroke.Color = if special then variant.color else rarity.color
	revealName.Text = Strings.species(speciesId)
	revealRarity.Text = if special
		then Strings.rarity(rarityId) .. " · " .. variant.emoji .. " " .. Strings.variant(result.variant)
		else Strings.rarity(rarityId)
	revealRarity.TextColor3 = rarity.color
	revealName.Visible = true
	revealRarity.Visible = true
	revealNew.Visible = result.isNew == true
	task.wait(0.35)
	revealClose.Visible = true
end

local function closeReveal()
	if not revealClose.Visible then
		return -- анимация ещё идёт
	end
	reveal.Visible = false
	revealBusy = false
	local nextResult = table.remove(pendingReveals, 1)
	if nextResult then
		task.spawn(playReveal, nextResult)
	end
	safely("tutorial reveal", function()
		Tutorial.onRevealClosed()
	end)()
end

revealClose.Activated:Connect(closeReveal)
reveal.Activated:Connect(closeReveal)

packResultEvent.OnClientEvent:Connect(function(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.ok then
		Sfx.play("buy")
		Tutorial.gotPack = true
		if revealBusy then
			table.insert(pendingReveals, result)
		else
			task.spawn(playReveal, result)
		end
	elseif result.reason == "full" then
		showToast(T("toast_full"))
	elseif result.reason == "coins" then
		if not Hints.noCoins() then
			showToast(T("toast_coins"))
		end
	elseif result.reason == "merge" then
		showToast(T("toast_merge_fail"))
	elseif result.reason == "candy" then
		showToast(T("toast_candy"), nil, 3)
	elseif result.reason == "over" then
		showToast(T("toast_event_over"), nil, 3)
	end
end)

refreshCollection()

-- Доход, пока игрока не было (сервер сам начисляет монеты, мы лишь сообщаем)
offlineIncomeEvent.OnClientEvent:Connect(function(gained, capped)
	if typeof(gained) == "number" and gained > 0 then
		showToast(T("toast_offline", gained), COLOR_BUTTON, 5)
		Hints.offline(gained, capped == true)
	end
end)

-- ===== Карточка статистики выбранной рыбы (под вторым рядом кнопок) =====
local infoCard = make("Frame", {
	Name = "FishInfo",
	Position = UDim2.fromScale(0.02, 0.175), -- компактная плашка слева, чтобы не закрывать аквариум
	Size = UDim2.fromScale(0.72, 0.105),
	BackgroundColor3 = COLOR_PANEL,
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 4,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, infoCard)

local function infoLine(name, y, h, color)
	return make("TextLabel", {
		Name = name,
		Position = UDim2.fromScale(0.03, y),
		Size = UDim2.fromScale(0.94, h),
		BackgroundTransparency = 1,
		TextScaled = true,
		MinText = 9,
		MaxText = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		Font = FONT,
		ZIndex = 5,
	}, infoCard)
end
local infoTitle = infoLine("Title", 0.05, 0.3, WHITE)
local infoIncome = infoLine("Income", 0.37, 0.28, Color3.fromRGB(190, 220, 230))
local infoStats = infoLine("Stats", 0.67, 0.28, Color3.fromRGB(190, 220, 230))

-- Кнопка «закрыть» справа от плашки: снимает выбор рыбы (то же делает клавиша Esc)
local infoClose = make("TextButton", {
	Name = "InfoClose",
	Position = UDim2.fromScale(0.76, 0.175),
	SizeConstraint = Enum.SizeConstraint.RelativeYY, -- ширина и высота считаются от высоты экрана: кнопка квадратная
	Size = UDim2.fromScale(0.075, 0.075),
	BackgroundColor3 = COLOR_PANEL,
	BorderSizePixel = 0,
	Text = "✕",
	TextScaled = true,
	MinText = 12,
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 4,
	Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, infoClose)

-- Кнопка продажи (появляется при выборе рыбы)
local sellButton = make("TextButton", {
	Name = "SellButton",
	Position = UDim2.fromScale(0.02, 0.285),
	Size = UDim2.fromScale(0.72, 0.052),
	BackgroundColor3 = COLOR_WARN,
	BorderSizePixel = 0,
	TextScaled = true,
	MinText = 12,
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 4,
	Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, sellButton)

-- ===== Рыбы =====
local fishById = {} -- id -> { label, species, alive, tween }
local selectedId = nil -- id выбранной рыбы или nil

local function randomPoint()
	local x = MIN_X + math.random() * (MAX_X - MIN_X)
	local y = MIN_Y + math.random() * (MAX_Y - MIN_Y)
	return UDim2.fromScale(x, y)
end

-- 75 -> "1м 15с" / "1m 15s", 4000 -> "1ч 6м" / "1h 6m"
local function formatAge(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds < 60 then
		return T("age_s", seconds)
	end
	if seconds < 3600 then
		return T("age_ms", seconds // 60, seconds % 60)
	end
	return T("age_hm", seconds // 3600, (seconds % 3600) // 60)
end

-- Карточка статистики: вид, редкость, доход, цена продажи, возраст и сколько заработала эта рыба
local function updateInfo()
	local fish = selectedId ~= nil and fishById[selectedId] or nil
	if fish == nil then
		infoCard.Visible = false
		return
	end
	local species = fish.species
	local rarity = FishConfig.Rarities[species.rarity]
	local data = fish.data
	local age = data.age + (os.clock() - fish.receivedAt) -- возраст с сервера + прошедшее время
	local stage = FishConfig.stageFor(age)
	local variant = FishConfig.variantOf(data.variant)
	local special = data.variant ~= nil and data.variant ~= "normal"
	local income = FishConfig.incomeOf(data.species, data.variant, age, data.mutation)
	local sellPrice = FishConfig.sellPriceOf(data.species, data.variant, age)
	local speciesName = Strings.species(data.species)
	local prefix = if special then variant.emoji .. " " .. Strings.variant(data.variant) .. " " else ""
	if FishConfig.Mutations[data.mutation or ""] then
		prefix = FishConfig.Mutations[data.mutation].emoji .. " " .. Strings.mutation(data.mutation) .. " " .. prefix
	end
	infoTitle.Text = prefix .. species.emoji .. " " .. speciesName .. " · " .. Strings.rarity(species.rarity)
	infoTitle.TextColor3 = rarity.color
	infoIncome.Text = T("info_income", income, T("age_s", FishConfig.INCOME_INTERVAL), sellPrice)
	infoStats.Text = T("info_stats", Strings.stage(stage.name), string.format("%g", FishConfig.multiplierOf(data.variant, age)), formatAge(age), data.earned)
	sellButton.Text = T("sell", speciesName, sellPrice)
	infoCard.Visible = true
end

local MergeUi = { refresh = function() end } -- кнопку слияния создаёт блок ниже, он подменяет refresh

-- Обновляет подсветку выбранной рыбы, кнопку продажи и карточку статистики
local function refreshSelection()
	if selectedId ~= nil and fishById[selectedId] == nil then
		selectedId = nil
	end
	for id, fish in pairs(fishById) do
		fish.label.BackgroundTransparency = if id == selectedId then 0.7 else 1
	end
	sellButton.Visible = selectedId ~= nil -- текст кнопки (цену) выставляет updateInfo
	infoClose.Visible = selectedId ~= nil
	updateInfo()
	MergeUi.refresh()
end

-- Закрыть плашку рыбы: кнопка ✕ и клавиша Esc. Esc сначала закрывает открытое окно (магазин, коллекция...), и только потом снимает выбор.
do
	local UserInputService = game:GetService("UserInputService")
	infoClose.Activated:Connect(function()
		Sfx.click()
		selectedId = nil
		refreshSelection()
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Escape then
			return -- Esc обрабатываем даже если Roblox уже занял клавишу: меню Roblox всё равно откроется, но игра тоже отреагирует
		end
		for _, child in ipairs(gui:GetChildren()) do
			if child:IsA("TextButton") and child.Name:match("Panel$") and child.Visible then
				child.Visible = false
				return
			end
		end
		if selectedId ~= nil then
			selectedId = nil
			refreshSelection()
		end
	end)
end

local function selectFish(id)
	Sfx.click()
	if selectedId == id then
		selectedId = nil -- повторное нажатие снимает выбор
	else
		selectedId = id
	end
	refreshSelection()
	if selectedId ~= nil then
		safely("tutorial select", function()
			Tutorial.onFishSelected()
		end)()
	end
end

sellButton.Activated:Connect(function()
	if selectedId ~= nil then
		sellFishEvent:FireServer(selectedId) -- отправляем только id
		selectedId = nil
		refreshSelection()
	end
end)

-- ===== Слияние и наборы =====
-- Кнопка под «Продать»: пять одинаковых рыб (вид + цвет в этом аквариуме) сливаются в одну следующего цвета.
-- Пока рыб меньше пяти, кнопка серая и показывает прогресс. Что и как сливать, решает сервер.
do
	local mergeEvent = remotes:WaitForChild("MergeFish")
	local setsEvent = remotes:WaitForChild("SetsChanged")
	local mergeButton = make("TextButton", {
		Name = "MergeButton",
		Position = UDim2.fromScale(0.02, 0.343),
		Size = UDim2.fromScale(0.72, 0.052),
		BackgroundColor3 = COLOR_BUTTON,
		BorderSizePixel = 0,
		TextScaled = true,
		MinText = 12,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 4,
		Visible = false,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, mergeButton)

	-- Сколько рыб того же вида и цвета в том же аквариуме (включая выбранную)
	local function sameCount(data)
		local count = 0
		for _, fish in pairs(fishById) do
			local other = fish.data
			if other.tank == data.tank and other.species == data.species and (other.variant or "normal") == (data.variant or "normal") then
				count += 1
			end
		end
		return count
	end

	function MergeUi.refresh()
		local fish = selectedId ~= nil and fishById[selectedId] or nil
		local nextVariant = fish ~= nil and FishConfig.nextVariant(fish.data.variant) or nil
		if fish == nil or nextVariant == nil then
			mergeButton.Visible = false
			return
		end
		local have = sameCount(fish.data)
		mergeButton.Visible = true
		if have >= FishConfig.MERGE_COUNT then
			mergeButton.Text = T("merge", FishConfig.MERGE_COUNT, Strings.variant(nextVariant))
			mergeButton.BackgroundColor3 = COLOR_BUTTON
		else
			mergeButton.Text = T("merge_progress", have, FishConfig.MERGE_COUNT)
			mergeButton.BackgroundColor3 = COLOR_MUTED
		end
	end

	mergeButton.Activated:Connect(function()
		local fish = selectedId ~= nil and fishById[selectedId] or nil
		if fish == nil then
			return
		end
		if sameCount(fish.data) >= FishConfig.MERGE_COUNT then
			mergeEvent:FireServer(selectedId) -- только id: остальных рыб и результат выбирает сервер
			selectedId = nil
			refreshSelection()
		else
			showToast(T("toast_merge_fail"))
		end
	end)

	setsEvent.OnClientEvent:Connect(function(state)
		if typeof(state) == "table" then
			setsState = state
			refreshCollection()
		end
	end)
end

-- ===== Музей: посетители, заказы, билеты =====
-- Сервер держит очередь из 3 гостей и сам решает, подходит ли рыба. Здесь только рисуем и шлём намерения:
-- ("fulfill", id заказа) и ("shop", товар, аквариум). Рыба при показе не тратится.
do
	local visitorsEvent = remotes:WaitForChild("VisitorsState")
	local actionEvent = remotes:WaitForChild("VisitorAction")
	local VC = FishConfig.Visitors
	local museum = { state = nil, receivedAt = 0 }

	local museumButton = make("TextButton", {
		Name = "MuseumButton",
		Position = UDim2.fromScale(0.76, TANK_ROW_Y),
		Size = UDim2.fromScale(0.22, TOP_H),
		BackgroundColor3 = COLOR_GOLD,
		BorderSizePixel = 0,
		Text = T("museum_btn", 0),
		TextScaled = true,
		MinText = 12,
		TextColor3 = Color3.fromRGB(60, 40, 0),
		Font = FONT,
		ZIndex = 3,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, museumButton)
	local museumDot = make("Frame", {
		Name = "RedDot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.96, 0.08),
		Size = UDim2.fromScale(0.2, 0.34),
		BackgroundColor3 = COLOR_ALERT,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 6,
	}, museumButton)
	make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, museumDot)
	make("UIStroke", { Color = WHITE, Thickness = 1.5 }, museumDot)

	local museumPanel = makePanel("MuseumPanel")
	addHint(museumPanel, T("museum_hint"))
	museumPanel.list.Size = UDim2.fromScale(0.9, 0.6)
	ListKit.scroll(museumPanel) -- со вторым залом в очереди 6 гостей, список прокручивается

	-- Строка: слева текст в две строки, справа кнопка (enabled — зелёная, иначе серая).
	-- Строки не пересоздаются при каждом обновлении (раз в секунду), а меняют текст на месте:
	-- иначе список дёргается при прокрутке. museumRows[order] = { frame, info, button, onClick }
	local museumRows = {}
	local usedRows = {}
	local function addMuseumRow(order, leftText, leftColor, buttonText, enabled, onClick)
		usedRows[order] = true
		local entry = museumRows[order]
		if entry == nil then
			local row = make("Frame", {
				Size = ListKit.rowSize(museumPanel.list, 0.3),
				BackgroundColor3 = COLOR_ROW,
				BorderSizePixel = 0,
				LayoutOrder = order,
				ZIndex = 12,
			}, museumPanel.list)
			make("UICorner", { CornerRadius = UDim.new(0.15, 0) }, row)
			UIKit.frame(row, "ui_row")
			local info = make("TextLabel", {
				Name = "Info",
				Position = UDim2.fromScale(0.03, 0.08),
				BackgroundTransparency = 1,
				TextScaled = true,
				TextWrapped = true,
				MinText = 9,
				MaxText = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = FONT,
				ZIndex = 13,
			}, row)
			local button = make("TextButton", {
				Name = "Action",
				Position = UDim2.fromScale(0.66, 0.14),
				Size = UDim2.fromScale(0.31, 0.72),
				BorderSizePixel = 0,
				TextScaled = true,
				MinText = 10,
				MaxText = 20,
				TextColor3 = WHITE,
				Font = FONT,
				ZIndex = 13,
			}, row)
			make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, button)
			entry = { frame = row, info = info, button = button, onClick = nil }
			button.Activated:Connect(function()
				if entry.onClick then
					entry.onClick()
				end
			end)
			museumRows[order] = entry
		end
		entry.info.Text = leftText
		entry.info.TextColor3 = leftColor
		entry.info.Size = UDim2.fromScale(if buttonText then 0.6 else 0.94, 0.84)
		entry.button.Visible = buttonText ~= nil
		entry.button.Text = buttonText or ""
		entry.button.BackgroundColor3 = if enabled then COLOR_BUTTON else COLOR_MUTED
		entry.onClick = onClick
	end

	local function timeLeft(seconds)
		return formatAge(math.max(0, seconds - (os.clock() - museum.receivedAt)))
	end

	local function refreshPanel()
		local state = museum.state
		if state == nil then
			return
		end
		museumPanel.title.Text = T("museum_title", state.rank, state.tickets)
		table.clear(usedRows)
		for index, order in ipairs(state.orders) do
			if order.waiting then
				addMuseumRow(index, T("order_waiting", timeLeft(order.left)), COLOR_MUTED)
			else
				local species = FishConfig.Species[order.species]
				local stage = FishConfig.GrowthStages[order.stage]
				local variantText = ""
				if order.variant ~= "normal" then
					variantText = " " .. FishConfig.Variants[order.variant].emoji .. Strings.variant(order.variant)
				end
				local left = species.emoji .. " " .. Strings.species(order.species) .. "\n"
					.. T("order_line2", Strings.stage(stage.name), variantText, order.tickets, timeLeft(order.left))
				local orderId = order.id
				addMuseumRow(index, left, FishConfig.Rarities[species.rarity].color, if order.ready then T("order_show") else T("order_nofish"), order.ready, function()
					Sfx.click()
					if order.ready then
						actionEvent:FireServer("fulfill", orderId)
					else
						showToast(T("toast_order_fail"))
					end
				end)
			end
		end

		-- траты билетов в текущем аквариуме
		local slots = tankSlots[currentTank] or FishConfig.START_SLOTS
		local packItem = VC.Shop.rarepack
		addMuseumRow(10, T("museum_shop_pack", packItem.price), COLOR_GOLD, T("shop_buy"), state.tickets >= packItem.price, function()
			Sfx.click()
			if state.tickets < packItem.price then
				showToast(T("toast_tickets_need"))
			elseif revealBusy then
				return
			else
				actionEvent:FireServer("shop", "rarepack", currentTank)
			end
		end)
		local extra = slots - FishConfig.MAX_SLOTS
		local slotItem = VC.Shop.slot
		if extra < 0 then
			addMuseumRow(11, T("museum_shop_locked"), COLOR_MUTED)
		elseif extra >= slotItem.maxBonus then
			addMuseumRow(11, T("slots_max"), COLOR_MUTED)
		else
			local price = slotItem.price * (extra + 1)
			addMuseumRow(11, T("museum_shop_slot", price), COLOR_GOLD, T("shop_buy"), state.tickets >= price, function()
				Sfx.click()
				if state.tickets < price then
					showToast(T("toast_tickets_need"))
				else
					actionEvent:FireServer("shop", "slot", currentTank)
				end
			end)
		end

		-- строки, которых больше нет (например, гостей стало меньше), убираем
		for order, entry in pairs(museumRows) do
			if not usedRows[order] then
				entry.frame:Destroy()
				museumRows[order] = nil
			end
		end
	end

	museumButton.Activated:Connect(function()
		Sfx.click()
		refreshPanel()
		museumPanel.overlay.Visible = true
	end)

	visitorsEvent.OnClientEvent:Connect(function(state)
		if typeof(state) ~= "table" or typeof(state.orders) ~= "table" then
			return
		end
		museum.state = state
		museum.receivedAt = os.clock()
		museumButton.Text = T("museum_btn", state.tickets)
		local anyReady = false
		for _, order in ipairs(state.orders) do
			anyReady = anyReady or order.ready == true
		end
		museumDot.Visible = anyReady
		local notice = state.notice
		if typeof(notice) == "table" then
			if notice.kind == "reward" then
				Sfx.play("reward")
				showToast(T("toast_ticket", notice.tickets or 0), COLOR_BUTTON, 3)
				if notice.rankUp then
					task.delay(2.2, function()
						showToast(T("toast_rankup", notice.rank or 1), COLOR_BUTTON, 3)
					end)
				end
			elseif notice.kind == "fail" then
				showToast(if notice.reason == "tickets" then T("toast_tickets_need") elseif notice.reason == "slotlimit" then T("toast_slot_limit") else T("toast_order_fail"))
			end
		end
		if museumPanel.overlay.Visible then
			refreshPanel()
		end
	end)

	-- пока окно открыто, раз в секунду обновляем таймеры гостей
	task.spawn(function()
		while true do
			task.wait(1)
			if museumPanel.overlay.Visible then
				refreshPanel()
			end
		end
	end)
end

-- Жизнь одной рыбы: выбрать точку -> доплыть -> пауза -> повторить
local function swim(fish)
	while fish.alive do
		local target = randomPoint()
		local from = fish.label.Position
		local dx = target.X.Scale - from.X.Scale
		local dy = target.Y.Scale - from.Y.Scale
		local distance = math.sqrt(dx * dx + dy * dy)
		local duration = math.max(distance / FISH_SPEED, 1)

		-- Рыба поворачивается мордой по направлению плавания (картинка нарисована смотрящей вправо)
		if fish.sprite and dx ~= 0 then
			local right = dx > 0
			if right ~= fish.facingRight then
				fish.facingRight = right
				Sprites.apply(fish.sprite, fish.data.species, not right)
			end
		end

		local tween = TweenService:Create(
			fish.label,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Position = target }
		)
		fish.tween = tween
		tween:Play()
		tween.Completed:Wait()

		if not fish.alive then
			break
		end
		task.wait(math.random() * 1.5)
	end
end

-- Размер рыбы зависит от стадии роста; при переходе на новую стадию плавно увеличивается
local function applyLook(fish)
	local age = fish.data.age + (os.clock() - fish.receivedAt)
	local target = FishConfig.stageFor(age).scale
	if fish.lastScale ~= target then
		fish.lastScale = target
		TweenService:Create(fish.uiScale, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Scale = target }):Play()
	end
end

local function addFish(fishData)
	local species = FishConfig.Species[fishData.species] or FishConfig.Species.guppy

	local label = Instance.new("TextButton") -- кнопка, чтобы рыбу можно было нажать
	label.Name = "Fish_" .. tostring(fishData.id)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = FISH_SIZE
	label.Position = randomPoint()
	label.AutoButtonColor = false
	label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = species.emoji
	label.TextScaled = true
	label.ZIndex = FISH_ZINDEX
	label.Visible = fishData.tank == currentTank -- рыбы других аквариумов скрыты
	label.Parent = tank

	-- Рыба квадратная и не мельчает/не раздувается на разных экранах
	make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, label)
	make("UISizeConstraint", { MinSize = Vector2.new(40, 40), MaxSize = Vector2.new(96, 96) }, label)
	local startScale = FishConfig.stageFor(fishData.age).scale
	local uiScale = make("UIScale", { Scale = startScale }, label)

	local fish = {
		label = label,
		species = species,
		alive = true,
		tween = nil,
		data = fishData,
		receivedAt = os.clock(),
		uiScale = uiScale,
		lastScale = startScale,
	}
	fishById[fishData.id] = fish

	-- Пиксельная картинка вида поверх кнопки (если картинки нет — остаётся эмодзи)
	local spriteLabel = make("ImageLabel", {
		Name = "Sprite",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = FISH_ZINDEX,
	}, label)
	if Sprites.apply(spriteLabel, fishData.species, false) then
		label.Text = ""
		fish.sprite = spriteLabel
		fish.facingRight = true
	else
		spriteLabel:Destroy()
	end

	-- Особые варианты обводятся цветным кольцом (радужная переливается)
	if fishData.variant ~= nil and fishData.variant ~= "normal" then
		local variant = FishConfig.variantOf(fishData.variant)
		local ring = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = FISH_ZINDEX }, label)
		make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
		local stroke = make("UIStroke", { Color = variant.color, Thickness = 3 }, ring)
		if fishData.variant == "rainbow" then
			task.spawn(function()
				while fish.alive do
					stroke.Color = Color3.fromHSV((os.clock() * 0.3) % 1, 0.6, 1)
					task.wait(0.1)
				end
			end)
		end
	end

	label.Activated:Connect(function()
		selectFish(fishData.id)
	end)

	task.spawn(swim, fish)
end

local function removeFish(id)
	local fish = fishById[id]
	if fish == nil then
		return
	end
	fish.alive = false
	if fish.tween then
		fish.tween:Cancel()
	end
	fish.label:Destroy()
	fishById[id] = nil
end

local slotsSynced = false -- первый ответ сервера не считаем «покупкой» для звука

-- Сервер прислал ВЕСЬ список рыб: сверяем с экраном
fishChangedEvent.OnClientEvent:Connect(function(fishList, tanksInfo)
	local present = {}
	tankCounts = {}
	for _, fishData in ipairs(fishList) do
		tankCounts[fishData.tank] = (tankCounts[fishData.tank] or 0) + 1
	end
	if typeof(tanksInfo) == "table" then
		-- Звук покупки: открылся новый аквариум или добавилось место
		if slotsSynced then
			for tankId, slots in pairs(tanksInfo) do
				local old = tankSlots[tankId]
				if old == nil or slots > old then
					Sfx.play("buy")
					break
				end
			end
		end
		slotsSynced = true
		tankSlots = tanksInfo
	end
	refreshSlotsUi()

	for _, fishData in ipairs(fishList) do
		present[fishData.id] = true
		local existing = fishById[fishData.id]
		if existing == nil then
			addFish(fishData)
		else
			existing.data = fishData -- обновилась статистика (заработок, возраст)
			existing.receivedAt = os.clock()
			applyLook(existing)
		end
	end

	for id, _ in pairs(fishById) do
		if not present[id] then
			removeFish(id)
		end
	end

	refreshSelection()
	if onTanksChanged then
		onTanksChanged()
	end
	safely("tutorial refresh", function()
		Tutorial.refreshTarget()
	end)()
end)

-- Возраст выбранной рыбы обновляем раз в секунду
task.spawn(function()
	while true do
		task.wait(1)
		if selectedId ~= nil then
			updateInfo()
		end
	end
end)

-- ===== Выбор аквариума =====
local tanksPanel = makePanel("TanksPanel")
tanksPanel.title.Text = T("tanks_title")
addHint(tanksPanel, T("tanks_hint"))

local function refreshTankButton()
	local def = FishConfig.Tanks[currentTank]
	tankButton.Text = def.emoji .. " " .. Strings.tank(currentTank) .. " ▾"
end

-- Переключение аквариума: цвет воды, видимые рыбы, кнопки, коллекция
local function switchTank(id)
	currentTank = id
	selectedId = nil
	TweenService:Create(tank, TweenInfo.new(0.6), { BackgroundColor3 = FishConfig.Tanks[id].color }):Play()
	applyBackground(id)
	pcall(DecorUi.show, id)
	for _, fish in pairs(fishById) do
		fish.label.Visible = fish.data.tank == currentTank
	end
	refreshTankButton()
	refreshBuyButton()
	refreshSlotsUi()
	refreshCollection()
	refreshSelection()
	safely("tutorial refresh", function()
		Tutorial.refreshTarget()
	end)()
end

local function refreshTanksPanel()
	clearRows(tanksPanel.list)
	for index, id in ipairs(FishConfig.allTanks()) do
		local def = FishConfig.Tanks[id]
		local owned = tankSlots[id] ~= nil
		if def.event ~= nil and not owned then
			continue -- ивентовый аквариум виден, только если он у игрока есть
		end
		local status = if id == currentTank then T("tank_here") elseif owned then T("tank_open") else T("tank_buy", def.price)
		local row = make("TextButton", {
			Size = UDim2.fromScale(1, 0.15),
			BackgroundColor3 = if id == currentTank then COLOR_BUTTON elseif owned then COLOR_ROW else COLOR_MUTED,
			BorderSizePixel = 0,
			Text = def.emoji .. " " .. Strings.tank(id) .. " — " .. status,
			TextScaled = true,
			MinText = 12,
			TextColor3 = WHITE,
			Font = FONT,
			LayoutOrder = index,
			ZIndex = 13,
		}, tanksPanel.list)
		make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, row)
		row.Activated:Connect(function()
			if owned then
				switchTank(id)
				tanksPanel.overlay.Visible = false
			else
				buyTankEvent:FireServer(id) -- только id: цену берёт сервер
			end
		end)
	end
end

onTanksChanged = function()
	if tankSlots[currentTank] == nil then
		switchTank("lagoon") -- например, после сброса прогресса открыта только лагуна
	end
	if tanksPanel.overlay.Visible then
		refreshTanksPanel()
	end
end

tankButton.Activated:Connect(function()
	refreshTanksPanel()
	tanksPanel.overlay.Visible = true
	safely("tutorial tanks", function()
		Tutorial.onTanksOpened()
	end)()
end)
tank.BackgroundColor3 = FishConfig.Tanks[currentTank].color
refreshTankButton()

-- ===== Ежедневная награда =====
local dailyPanel = makePanel("DailyPanel")
local dailyTiles = {} -- [день 1..7] = { frame, stroke, day, amount, mark }
local dailyClaim, dailyStatus

local function formatClock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
end

-- Сколько секунд осталось до следующей награды (по данным сервера + прошедшее время)
function Daily.remaining()
	local state = Daily.state
	if state == nil then
		return 0
	end
	return math.max(0, state.secondsLeft - (os.clock() - Daily.syncedAt))
end

function Daily.build()
	dailyPanel.title.Text = T("daily_title")
	local layout = dailyPanel.list:FindFirstChildOfClass("UIListLayout")
	if layout then
		layout:Destroy()
	end
	dailyPanel.list.Size = UDim2.fromScale(0.9, 0.42)
	make("UIGridLayout", {
		CellSize = UDim2.fromScale(0.23, 0.47),
		CellPadding = UDim2.fromScale(0.02, 0.06),
		FillDirection = Enum.FillDirection.Horizontal,
		FillDirectionMaxCells = 4,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, dailyPanel.list)

	for day = 1, #FishConfig.DailyRewards do
		local frame = make("Frame", {
			Name = "Day" .. day,
			BackgroundColor3 = COLOR_ROW,
			BorderSizePixel = 0,
			LayoutOrder = day,
			ZIndex = 12,
		}, dailyPanel.list)
		make("UICorner", { CornerRadius = UDim.new(0.14, 0) }, frame)
		local stroke = make("UIStroke", { Color = COLOR_GOLD, Thickness = 3, Enabled = false }, frame)
		local dayLabel = make("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.05),
			Size = UDim2.fromScale(0.9, 0.27),
			BackgroundTransparency = 1,
			Text = T("daily_day", day),
			TextScaled = true,
			MinText = 10,
			MaxText = 18,
			TextColor3 = WHITE,
			Font = FONT,
			ZIndex = 13,
		}, frame)
		local amountLabel = make("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.33),
			Size = UDim2.fromScale(0.9, 0.36),
			BackgroundTransparency = 1,
			Text = "💰" .. tostring(FishConfig.DailyRewards[day]),
			TextScaled = true,
			MinText = 10,
			MaxText = 22,
			TextColor3 = COLOR_GOLD,
			Font = FONT,
			ZIndex = 13,
		}, frame)
		local markLabel = make("TextLabel", {
			Position = UDim2.fromScale(0.05, 0.71),
			Size = UDim2.fromScale(0.9, 0.25),
			BackgroundTransparency = 1,
			Text = "",
			TextScaled = true,
			MinText = 10,
			MaxText = 20,
			TextColor3 = COLOR_BUTTON,
			Font = FONT,
			ZIndex = 13,
		}, frame)
		dailyTiles[day] = { frame = frame, stroke = stroke, day = dayLabel, amount = amountLabel, mark = markLabel }
	end

	dailyClaim = make("TextButton", {
		Name = "Claim",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromScale(0.7, 0.12),
		BackgroundColor3 = COLOR_BUTTON,
		BorderSizePixel = 0,
		Text = T("daily_claim"),
		TextScaled = true,
		MinText = 14,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 12,
	}, dailyPanel.card)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, dailyClaim)

	dailyStatus = make("TextLabel", {
		Name = "Status",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.72),
		Size = UDim2.fromScale(0.9, 0.09),
		BackgroundTransparency = 1,
		Text = "",
		TextScaled = true,
		MinText = 12,
		MaxText = 22,
		TextColor3 = COLOR_MUTED,
		Font = FONT,
		ZIndex = 12,
	}, dailyPanel.card)

	dailyClaim.Activated:Connect(function()
		local state = Daily.state
		if state == nil or not state.canClaim or Daily.pending then
			return
		end
		Daily.pending = true
		claimDailyEvent:FireServer() -- без аргументов: день и сумму считает сервер
		Daily.refresh()
		task.delay(3, function()
			if Daily.pending then
				Daily.pending = false -- сервер не ответил: даём нажать снова
				Daily.refresh()
			end
		end)
	end)
end

-- Перерисовывает плитки, кнопку, красную точку и подпись по последнему состоянию
function Daily.refresh()
	local state = Daily.state
	giftDot.Visible = state ~= nil and state.canClaim
	if state == nil or dailyClaim == nil then
		return
	end
	local count = #FishConfig.DailyRewards
	local current = (math.max(state.streak, 1) - 1) % count + 1 -- день серии, которому соответствует state.reward
	for day, tile in pairs(dailyTiles) do
		local isToday = day == current
		local done = day < current or (isToday and not state.canClaim)
		tile.stroke.Enabled = isToday and state.canClaim
		tile.frame.BackgroundColor3 = if done then COLOR_MUTED elseif isToday then COLOR_PANEL else COLOR_ROW
		tile.mark.Text = if done then "✓" else ""
		tile.amount.TextColor3 = if done then WHITE else COLOR_GOLD
		tile.amount.Text = "💰" .. tostring(if isToday then state.reward else FishConfig.DailyRewards[day])
	end

	local active = state.canClaim and not Daily.pending
	dailyClaim.Active = active
	dailyClaim.AutoButtonColor = active
	dailyClaim.BackgroundColor3 = if active then COLOR_BUTTON else COLOR_MUTED
	if state.canClaim then
		dailyStatus.Text = T("daily_today", state.reward)
	else
		dailyStatus.Text = T("daily_next", formatClock(Daily.remaining()))
	end
end

function Daily.open()
	Daily.refresh()
	dailyPanel.overlay.Visible = true
end

-- Один раз за сессию сами показываем панель, если награду можно забрать и обучение уже позади
function Daily.tryAutoShow()
	if Daily.autoShown or Daily.state == nil or not Daily.state.canClaim or not Tutorial.resolved then
		return
	end
	Daily.autoShown = true
	task.spawn(function()
		-- не перебиваем открытие пака и уже открытые окна
		local function busy()
			if revealBusy then
				return true
			end
			for _, child in ipairs(gui:GetChildren()) do
				if child ~= dailyPanel.overlay and child:IsA("GuiButton") and string.sub(child.Name, -5) == "Panel" and child.Visible then
					return true
				end
			end
			return false
		end
		while busy() do
			task.wait(0.5)
		end
		if Daily.state ~= nil and Daily.state.canClaim then
			Daily.open()
		end
	end)
end

giftButton.Activated:Connect(function()
	Daily.open()
end)

dailyStateEvent.OnClientEvent:Connect(safely("DailyState", function(state)
	if typeof(state) ~= "table" then
		return
	end
	local previous = Daily.state
	Daily.state = {
		canClaim = state.canClaim == true,
		streak = tonumber(state.streak) or 1,
		reward = tonumber(state.reward) or 0,
		secondsLeft = tonumber(state.secondsLeft) or 0,
	}
	Daily.syncedAt = os.clock()
	Daily.pending = false
	Daily.refetched = false
	if previous ~= nil and previous.canClaim and not Daily.state.canClaim then
		Sfx.play("reward")
		showToast(T("daily_got", previous.reward), COLOR_BUTTON, 3)
	end
	Daily.refresh()
	Daily.tryAutoShow()
end))

-- Таймер до следующей награды: считаем сами от secondsLeft; когда день сменился — просим свежее состояние
task.spawn(function()
	while true do
		task.wait(0.5)
		local state = Daily.state
		if state ~= nil and not state.canClaim then
			if dailyPanel.overlay.Visible then
				pcall(Daily.refresh)
			end
			if Daily.remaining() <= 0 and not Daily.refetched then
				Daily.refetched = true
				clientReadyEvent:FireServer() -- сервер пришлёт всё состояние заново, в том числе DailyState
			end
		end
	end
end)

pcall(Daily.build)

-- ===== Настройки звука =====
-- Две независимые галочки: «Звуки» (эффекты) и «Музыка». Состояние хранит сервер в профиле игрока (событие Settings).
-- Весь блок в do ... end, чтобы не расходовать лимит локальных переменных главной функции.
do
	local settingsEvent = remotes:WaitForChild("Settings", 10) -- nil, если события нет: настройки работают только до выхода
	local settingsPanel = makePanel("SettingsPanel")
	settingsPanel.title.Text = T("settings_title")
	settingsPanel.list.Size = UDim2.fromScale(0.9, 0.4)
	local toggles = {} -- { sfx = кнопка, music = кнопка }

	local function paint(key, value)
		local button = toggles[key]
		if button ~= nil then
			button.Text = if value then T("settings_on") else T("settings_off")
			button.BackgroundColor3 = if value then COLOR_BUTTON else COLOR_MUTED
		end
	end

	local function save()
		if settingsEvent ~= nil then
			settingsEvent:FireServer({ sfx = Sfx.enabled, music = Sfx.musicEnabled })
		end
	end

	local function addToggleRow(order, key, labelKey, get, set)
		local row = make("Frame", {
			Size = UDim2.fromScale(1, 0.45),
			BackgroundColor3 = COLOR_ROW,
			BorderSizePixel = 0,
			LayoutOrder = order,
			ZIndex = 12,
		}, settingsPanel.list)
		make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, row)
		UIKit.frame(row, "ui_row")
		make("TextLabel", {
			Name = "Title",
			Position = UDim2.fromScale(0.04, 0.2),
			Size = UDim2.fromScale(0.55, 0.6),
			BackgroundTransparency = 1,
			Text = T(labelKey),
			TextScaled = true,
			MinText = 12,
			MaxText = 24,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = WHITE,
			Font = FONT,
			ZIndex = 13,
		}, row)
		local button = make("TextButton", {
			Name = "Toggle",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.96, 0.5),
			Size = UDim2.fromScale(0.3, 0.64),
			BorderSizePixel = 0,
			TextScaled = true,
			MinText = 12,
			MaxText = 22,
			TextColor3 = WHITE,
			Font = FONT,
			ZIndex = 13,
		}, row)
		make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, button)
		toggles[key] = button
		paint(key, get())
		button.Activated:Connect(function()
			set(not get())
			paint(key, get())
			save()
		end)
	end

	addToggleRow(1, "sfx", "settings_sfx", function()
		return Sfx.enabled
	end, function(value)
		Sfx.setEnabled(value)
		if value then
			Sfx.click()
		end
	end)
	addToggleRow(2, "music", "settings_music", function()
		return Sfx.musicEnabled
	end, function(value)
		Sfx.setMusic(value)
	end)

	-- «Пригласить друга»: окно приглашения Roblox (если у игрока оно доступно)
	do
		local SocialService = game:GetService("SocialService")
		local okInvite, canInvite = pcall(function()
			return SocialService:CanSendGameInviteAsync(localPlayer)
		end)
		if okInvite and canInvite then
			local inviteRow = make("Frame", {
				Size = UDim2.fromScale(1, 0.45),
				BackgroundColor3 = COLOR_ROW,
				BorderSizePixel = 0,
				LayoutOrder = 3,
				ZIndex = 12,
			}, settingsPanel.list)
			make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, inviteRow)
			UIKit.frame(inviteRow, "ui_row")
			local invite = make("TextButton", {
				Name = "Invite",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.92, 0.64),
				BackgroundColor3 = COLOR_BUTTON,
				BorderSizePixel = 0,
				Text = T("settings_invite"),
				TextScaled = true,
				MinText = 10,
				MaxText = 22,
				TextColor3 = WHITE,
				Font = FONT,
				ZIndex = 13,
			}, inviteRow)
			make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, invite)
			invite.Activated:Connect(function()
				pcall(function()
					SocialService:PromptGameInvite(localPlayer)
				end)
			end)
		end
	end

	soundButton.Activated:Connect(function()
		settingsPanel.overlay.Visible = true
	end)

	if settingsEvent ~= nil then
		settingsEvent.OnClientEvent:Connect(safely("Settings", function(value)
			if typeof(value) ~= "table" then
				return
			end
			Sfx.setEnabled(value.sfx ~= false)
			Sfx.setMusic(value.music ~= false)
			paint("sfx", Sfx.enabled)
			paint("music", Sfx.musicEnabled)
		end))
	end
end

-- ===== Магазин за Robux =====
-- Клиент только рисует кнопки и открывает окна подтверждения Roblox. Ничего не списывается и не выдаётся здесь:
-- пассы, монеты и стартовый набор выдаёт сервер, а состояние приходит событием ShopState
-- { doubleCoins, nightWatch, secondHall, quickOpen, restricted, starter = секунд до конца предложения }.
-- Пока в FishConfig.Shop все id равны 0, кнопка магазина скрыта. Цену в Robux не показываем: её покажет Roblox.
-- Весь блок в do ... end, чтобы не расходовать лимит локальных переменных главной функции.
do
	local MarketplaceService = game:GetService("MarketplaceService")
	local shopStateEvent = remotes:WaitForChild("ShopState", 10) -- nil, если события нет: остальной интерфейс не страдает

	local Shop = { state = nil, lastPrompt = 0, starterShown = false }
	local shopPanel = makePanel("ShopPanel")
	shopPanel.title.Text = T("shop_title")
	shopPanel.list.Size = UDim2.fromScale(0.9, 0.7)
	ListKit.scroll(shopPanel)
	local shopButton = iconButton("ShopButton", "🛒", 0.725)

	-- Маленький значок «×2» у монет (на нижнем крае, чтобы не закрывать число)
	local doubleBadge = make("TextLabel", {
		Name = "DoubleBadge",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromScale(0.2, 0.42),
		BackgroundColor3 = COLOR_GOLD,
		BorderSizePixel = 0,
		Text = "×2",
		TextScaled = true,
		MinText = 9,
		MaxText = 18,
		TextColor3 = Color3.fromRGB(60, 40, 0),
		Font = FONT,
		Visible = false,
		ZIndex = 5,
	}, coinsLabel)
	make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, doubleBadge)

	-- Пассы: у каждого свой id в FishConfig.Shop, название и описание в Strings
	local PASS_ROWS = {
		{ key = "nightWatch", cfg = FishConfig.Shop.NightWatch, title = "shop_night_title", desc = "shop_night_desc",
			theme = { skin = "ui_banner_night", icon = "ui_icon_night", bg = Color3.fromRGB(63, 81, 181), title = Color3.fromRGB(255, 241, 168), desc = Color3.fromRGB(220, 226, 255), ribbon = "shop_tag_night" } },
		{ key = "secondHall", cfg = FishConfig.Shop.SecondHall, title = "shop_hall_title", desc = "shop_hall_desc",
			theme = { skin = "ui_banner_hall", icon = "ui_icon_hall", bg = Color3.fromRGB(142, 92, 196), title = Color3.fromRGB(255, 255, 255), desc = Color3.fromRGB(240, 226, 255), ribbon = "shop_tag_hall" } },
		{ key = "quickOpen", cfg = FishConfig.Shop.QuickOpen, title = "shop_quick_title", desc = "shop_quick_desc",
			theme = { skin = "ui_banner_quick", icon = "ui_icon_quick", bg = Color3.fromRGB(232, 97, 60), title = Color3.fromRGB(255, 225, 74), desc = Color3.fromRGB(255, 236, 224), ribbon = "shop_tag_quick" } },
	}
	local function configuredPass(cfg)
		return cfg ~= nil and (tonumber(cfg.passId) or 0) > 0
	end

	-- Товары «монеты», у которых id уже настроен
	local function activeProducts()
		local result = {}
		local products = FishConfig.Shop and FishConfig.Shop.Products
		for _, product in ipairs(products or {}) do
			if (tonumber(product.productId) or 0) > 0 then
				table.insert(result, product)
			end
		end
		return result
	end

	-- Пока сервер не прислал состояние или он сообщил об ограничении платного рандома, магазин скрыт
	local function isRestricted()
		return Shop.state == nil or Shop.state.restricted ~= false
	end

	local function owned(key)
		return Shop.state ~= nil and Shop.state.owned[key] == true
	end

	-- Сколько секунд ещё действует предложение стартового набора (nil, если его нет)
	local function starterSecondsLeft()
		local state = Shop.state
		if state == nil or state.starterLeft == nil then
			return nil
		end
		local left = state.starterLeft - (os.clock() - state.receivedAt)
		return if left > 0 then left else nil
	end

	local function isConfigured()
		if isRestricted() then
			return false
		end
		if configuredPass(FishConfig.Shop.DoubleCoins) or #activeProducts() > 0 or starterSecondsLeft() ~= nil then
			return true
		end
		for _, row in ipairs(PASS_ROWS) do
			if configuredPass(row.cfg) then
				return true
			end
		end
		return false
	end

	-- Форма слова по числу: ru — 1 / 2-4 / 5+, en — 1 / остальные (ключи prefix_1, prefix_2, prefix_5)
	local function pluralKey(prefix, n)
		if Strings.language() == "ru" then
			local last, last2 = n % 10, n % 100
			if last2 >= 11 and last2 <= 14 then
				return prefix .. "_5"
			elseif last == 1 then
				return prefix .. "_1"
			elseif last >= 2 and last <= 4 then
				return prefix .. "_2"
			end
			return prefix .. "_5"
		end
		return prefix .. (if n == 1 then "_1" else "_5")
	end

	-- 3600 -> «1 час» / «1 hour», 28800 -> «8 часов» / «8 hours»
	local function durationText(seconds)
		seconds = tonumber(seconds) or 0
		if seconds >= 3600 and seconds % 3600 == 0 then
			local hours = seconds // 3600
			return T(pluralKey("dur_h", hours), hours)
		elseif seconds >= 60 and seconds % 60 == 0 then
			local minutes = seconds // 60
			return T(pluralKey("dur_m", minutes), minutes)
		end
		return T("dur_s", seconds)
	end

	-- Открывает окно покупки Roblox. Любая ошибка (в том числе в самом вызове) не роняет интерфейс.
	local function prompt(label, fn)
		local now = os.clock()
		if now - Shop.lastPrompt < 1 then
			return -- защита от двойного нажатия
		end
		Shop.lastPrompt = now
		local ok, err = pcall(fn)
		if not ok then
			warn("[Ataraxia] " .. label .. ": " .. tostring(err))
			showToast(T("shop_error"), COLOR_WARN, 3)
		end
	end

	-- Строка магазина: слева название и описание, справа кнопка «Купить» (или «Куплено», если owned).
	-- opts (необязательно): banner — золотой баннер с лентой; icon — картинка слева (монета); ribbonText — текст ленты;
	-- parent — куда вставить строку (по умолчанию список магазина).
	local function addShopRow(order, fraction, titleText, descText, isOwned, onBuy, opts)
		opts = opts or {}
		-- theme — цветной баннер пасса: { skin, icon, bg, title, desc, ribbon (ключ Strings) }
		local theme = opts.theme
		if theme then
			opts.banner = true
			opts.icon = opts.icon or theme.icon
			opts.ribbonText = opts.ribbonText or (if theme.ribbon then T(theme.ribbon) else nil)
		end
		local banner = opts.banner == true
		local parent = opts.parent or shopPanel.list
		local row = make("Frame", {
			Size = ListKit.rowSize(parent, fraction),
			BackgroundColor3 = if theme then theme.bg elseif banner then COLOR_GOLD else COLOR_ROW,
			BorderSizePixel = 0,
			LayoutOrder = order,
			ZIndex = 12,
		}, parent)
		make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, row)
		UIKit.frame(row, if theme then theme.skin elseif banner then "ui_banner" else "ui_row")
		local textX = 0.03
		if opts.icon then
			-- иконка слева, текст сдвигается вправо
			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.fromScale(0.03, 0.5)
			icon.Size = UDim2.fromScale(0.1, 0.5)
			icon.ZIndex = 13
			local ratio = Instance.new("UIAspectRatioConstraint")
			ratio.Parent = icon
			if Sprites.apply(icon, opts.icon, false) then
				icon.Parent = row
				textX = 0.15
			else
				icon:Destroy()
			end
		end
		local textW = 0.65 - textX
		local titleColor = if theme then theme.title elseif banner then Color3.fromRGB(60, 40, 0) else COLOR_GOLD
		local descColor = if theme then theme.desc elseif banner then Color3.fromRGB(95, 62, 0) else Color3.fromRGB(190, 220, 230)
		if banner then
			-- лента на верхней кромке баннера
			local ribbon = make("TextLabel", {
				Name = "Ribbon",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(0.97, 0),
				Size = UDim2.fromScale(0.34, 0.26),
				BackgroundColor3 = COLOR_ALERT,
				BorderSizePixel = 0,
				Text = opts.ribbonText or T("shop_best"),
				TextScaled = true,
				MinText = 8,
				MaxText = 16,
				TextColor3 = Color3.fromRGB(255, 241, 193),
				ZIndex = 15,
			}, row)
			UIKit.ticket(ribbon)
		end
		make("TextLabel", {
			Name = "Title",
			Position = UDim2.fromScale(textX, 0.08),
			Size = UDim2.fromScale(textW, 0.38),
			BackgroundTransparency = 1,
			Text = titleText,
			TextScaled = true,
			MinText = 9,
			MaxText = 22,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = titleColor,
			Font = FONT,
			ZIndex = 13,
		}, row)
		make("TextLabel", {
			Name = "Desc",
			Position = UDim2.fromScale(textX, 0.48),
			Size = UDim2.fromScale(textW, 0.46),
			BackgroundTransparency = 1,
			Text = descText,
			TextScaled = true,
			TextWrapped = true,
			MinText = 8,
			MaxText = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextColor3 = descColor,
			Font = FONT,
			ZIndex = 13,
		}, row)
		if isOwned then
			make("TextLabel", {
				Name = "Owned",
				Position = UDim2.fromScale(0.68, 0.2),
				Size = UDim2.fromScale(0.29, 0.6),
				BackgroundTransparency = 1,
				Text = T("shop_owned"),
				TextScaled = true,
				MinText = 10,
				MaxText = 20,
				TextColor3 = COLOR_BUTTON,
				Font = FONT,
				ZIndex = 13,
			}, row)
		else
			local buy = make("TextButton", {
				Name = "Buy",
				Position = UDim2.fromScale(0.68, 0.2),
				Size = UDim2.fromScale(0.29, 0.6),
				BackgroundColor3 = COLOR_BUTTON,
				BorderSizePixel = 0,
				Text = T("shop_buy"),
				TextScaled = true,
				MinText = 10,
				MaxText = 22,
				TextColor3 = WHITE,
				Font = FONT,
				ZIndex = 13,
			}, row)
			make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, buy)
			buy.Activated:Connect(onBuy)
		end
	end

	local function buyPass(cfg)
		return function()
			prompt("PromptGamePassPurchase", function()
				MarketplaceService:PromptGamePassPurchase(localPlayer, cfg.passId)
			end)
		end
	end
	local function buyProduct(productId)
		return function()
			prompt("PromptProductPurchase", function()
				MarketplaceService:PromptProductPurchase(localPlayer, productId)
			end)
		end
	end

	function Shop.refresh()
		clearRows(shopPanel.list)
		shopButton.Visible = isConfigured()
		if isRestricted() then
			return
		end
		local order = 0

		-- Главное предложение: Poseidon's Blessing (доход ×2)
		if configuredPass(FishConfig.Shop.DoubleCoins) then
			order += 1
			addShopRow(order, 0.36, T("shop_double_title"), T("shop_double_desc"), owned("doubleCoins"), buyPass(FishConfig.Shop.DoubleCoins), { banner = true })
		end

		-- Стартовый набор (разовое предложение с реальным таймером)
		local starterLeft = starterSecondsLeft()
		if starterLeft ~= nil then
			order += 1
			addShopRow(order, 0.3, T("shop_starter_title"), T("shop_starter_desc"), false, buyProduct(FishConfig.Shop.StarterPack.productId), { icon = "ui_coin" })
		end

		-- Остальные пассы
		for _, row in ipairs(PASS_ROWS) do
			if configuredPass(row.cfg) then
				order += 1
				addShopRow(order, 0.32, T(row.title), T(row.desc), owned(row.key), buyPass(row.cfg), { theme = row.theme })
			end
		end

		-- Монеты за Robux
		for _, product in ipairs(activeProducts()) do
			order += 1
			local duration = durationText(product.seconds)
			addShopRow(order, 0.28, T("shop_coins_title", duration), T("shop_coins_desc", duration), false, buyProduct(product.productId), { icon = "ui_coin" })
		end
	end

	shopButton.Visible = isConfigured()
	local function openShop()
		Shop.refresh()
		shopPanel.overlay.Visible = true
	end
	shopButton.Activated:Connect(openShop)
	pcall(Shop.refresh)

	-- ===== Предложение стартового набора: одно всплывающее окно за сессию =====
	local starterPanel = makePanel("StarterPanel")
	starterPanel.title.Text = T("shop_starter_title")
	local function openStarterPopup()
		local left = starterSecondsLeft()
		if left == nil or isRestricted() then
			return
		end
		clearRows(starterPanel.list)
		addShopRow(1, 0.55, T("shop_starter_title"), T("shop_starter_desc"), false, buyProduct(FishConfig.Shop.StarterPack.productId), {
			banner = true,
			icon = "ui_coin",
			ribbonText = formatAge(left),
			parent = starterPanel.list,
		})
		starterPanel.overlay.Visible = true
	end

	-- ===== Подсказки внизу экрана =====
	local hintBar = make("TextButton", {
		Name = "HintBar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0.02, 0.805),
		Size = UDim2.fromScale(0.64, 0.055),
		BackgroundColor3 = COLOR_BUTTON,
		BorderSizePixel = 0,
		TextScaled = true,
		MinText = 9,
		TextColor3 = WHITE,
		Font = FONT,
		Visible = false,
		ZIndex = 3,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, hintBar)
	local hintToken = 0
	local function showHint(text, seconds)
		hintToken += 1
		local token = hintToken
		hintBar.Text = text
		hintBar.Visible = true
		task.delay(seconds or 7, function()
			if hintToken == token then
				hintBar.Visible = false
			end
		end)
	end
	hintBar.Activated:Connect(function()
		hintBar.Visible = false
		openShop()
	end)

	-- Монеты и доход в секунду (для подсказки «ещё ~N мин»)
	local coinsValue = 0
	coinsChangedEvent.OnClientEvent:Connect(function(value)
		if typeof(value) == "number" then
			coinsValue = value
		end
	end)
	local function incomePerSecond()
		local total = 0
		for _, fish in pairs(fishById) do
			local data = fish.data
			local age = data.age + (os.clock() - fish.receivedAt)
			local bonus = (setsState[data.tank] and setsState[data.tank].bonus) or 0
			local flow = 1
			local cur = CurrentUi.state and CurrentUi.state.current
			if cur ~= nil and cur.tank == data.tank and cur.left - (os.clock() - CurrentUi.receivedAt) > 0 then
				flow = FishConfig.Currents.INCOME_MULT
			end
			total += math.floor(FishConfig.incomeOf(data.species, data.variant, age, data.mutation) * (1 + bonus) * flow + 0.5)
		end
		local multiplier = if owned("doubleCoins") then FishConfig.Shop.DoubleCoins.mult else 1
		return total * multiplier / FishConfig.INCOME_INTERVAL
	end

	-- Не хватает монет на пак: говорим, сколько ждать, и предлагаем монеты за Robux (если магазин настроен)
	Hints.noCoins = function()
		local pack = FishConfig.Packs[FishConfig.Tanks[currentTank].pack]
		local perSecond = incomePerSecond()
		if coinsValue >= pack.price or perSecond <= 0 then
			return false
		end
		local minutes = math.max(1, math.ceil((pack.price - coinsValue) / perSecond / 60))
		showToast(T("toast_coins_eta", durationText(minutes * 60)))
		if not isRestricted() and #activeProducts() > 0 then
			showHint(T("hint_coins_shop"), 7)
		end
		return true
	end

	-- Офлайн-копилка заполнилась до предела: напоминаем про «Ночного смотрителя»
	Hints.offline = function(_, capped)
		if capped and not isRestricted() and configuredPass(FishConfig.Shop.NightWatch) and not owned("nightWatch") then
			task.delay(1.5, function()
				showHint(T("hint_offline_full"), 9)
			end)
		end
	end

	-- ===== Quick Open: кнопка «×N паков» (только с пассом) =====
	local quickButton = make("TextButton", {
		Name = "QuickOpenButton",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.98, 0.805),
		Size = UDim2.fromScale(0.3, 0.055),
		BackgroundColor3 = COLOR_GOLD,
		BorderSizePixel = 0,
		Text = T("quick_open", FishConfig.Shop.QuickOpen.packs),
		TextScaled = true,
		MinText = 9,
		TextColor3 = Color3.fromRGB(60, 40, 0),
		Font = FONT,
		Visible = false,
		ZIndex = 3,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, quickButton)
	quickButton.Activated:Connect(function()
		if revealBusy then
			return
		end
		openPackEvent:FireServer(FishConfig.Tanks[currentTank].pack, FishConfig.Shop.QuickOpen.packs) -- сервер сам проверит пасс
	end)

	if shopStateEvent ~= nil then
		shopStateEvent.OnClientEvent:Connect(safely("ShopState", function(state)
			if typeof(state) ~= "table" then
				return
			end
			local previous = Shop.state
			local nowOwned = {
				doubleCoins = state.doubleCoins == true,
				nightWatch = state.nightWatch == true,
				secondHall = state.secondHall == true,
				quickOpen = state.quickOpen == true,
			}
			Shop.state = {
				owned = nowOwned,
				restricted = state.restricted ~= false,
				starterLeft = if typeof(state.starter) == "number" then state.starter else nil,
				receivedAt = os.clock(),
			}
			doubleBadge.Visible = nowOwned.doubleCoins
			quickButton.Visible = nowOwned.quickOpen and configuredPass(FishConfig.Shop.QuickOpen)

			-- Только что купили пасс: радуемся
			if previous ~= nil then
				for key, has in pairs(nowOwned) do
					if has and not previous.owned[key] then
						Sfx.play("reward")
						if key == "doubleCoins" then
							showToast(T("shop_unlocked"), COLOR_BUTTON, 3)
						else
							for _, row in ipairs(PASS_ROWS) do
								if row.key == key then
									showToast(T(row.title) .. " ✓", COLOR_BUTTON, 3)
								end
							end
						end
					end
				end
			end

			-- Стартовый набор показываем всплывающим окном не чаще раза за сессию и только если ничего другого не открыто
			if Shop.state.starterLeft ~= nil and not Shop.state.restricted and not Shop.starterShown then
				Shop.starterShown = true
				task.delay(6, function()
					for _, child in ipairs(gui:GetChildren()) do
						if child:IsA("TextButton") and child.Name:match("Panel$") and child.Visible then
							return
						end
					end
					if not revealBusy then
						openStarterPopup()
					end
				end)
			end
			Shop.refresh()
		end))
	end
end

-- ===== Течения =====
-- Сервер раз в 20–40 минут запускает течение в одном аквариуме (доход ×1.5 на 5 минут), после него у пары рыб
-- появляется мутация. Клиент только показывает: плашку с таймером, уведомления и список мутаций в коллекции.
do
	local currentStateEvent = remotes:WaitForChild("CurrentState", 10)
	local chip = make("TextLabel", {
		Name = "CurrentChip",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.745),
		Size = UDim2.fromScale(0.7, 0.05),
		BackgroundColor3 = Color3.fromRGB(0, 120, 150),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		TextScaled = true,
		MinText = 8,
		MaxText = 18,
		TextColor3 = WHITE,
		Font = FONT,
		Visible = false,
		ZIndex = 3,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, chip)

	local function leftSeconds()
		local cur = CurrentUi.state and CurrentUi.state.current
		if cur == nil then
			return nil
		end
		local left = cur.left - (os.clock() - CurrentUi.receivedAt)
		return if left > 0 then left else nil
	end
	local function refreshChip()
		local left = leftSeconds()
		if left == nil then
			chip.Visible = false
			return
		end
		local total = math.ceil(left)
		chip.Text = T("current_chip", Strings.tank(CurrentUi.state.current.tank), string.format("%g", FishConfig.Currents.INCOME_MULT), string.format("%d:%02d", total // 60, total % 60))
		chip.Visible = true
	end
	task.spawn(function()
		while true do
			task.wait(1)
			pcall(refreshChip)
		end
	end)

	if currentStateEvent ~= nil then
		currentStateEvent.OnClientEvent:Connect(safely("CurrentState", function(state)
			if typeof(state) ~= "table" then
				return
			end
			CurrentUi.state = state
			CurrentUi.receivedAt = os.clock()
			refreshChip()
			refreshCollection()
			local event = state.event
			if typeof(event) == "table" then
				if event.kind == "started" then
					Sfx.play("reward")
					showToast(T("toast_current_start", Strings.tank(event.tank), string.format("%g", FishConfig.Currents.INCOME_MULT), formatAge(FishConfig.Currents.DURATION)), Color3.fromRGB(0, 120, 150), 4)
				elseif event.kind == "ended" and typeof(event.mutated) == "table" and #event.mutated > 0 then
					Sfx.play("reveal")
					local first = event.mutated[1]
					local def = FishConfig.Mutations[first.mutation]
					local fish = fishById[first.id]
					local fishName = if fish then Strings.species(fish.data.species) else "?"
					if def then
						showToast(T("toast_mutation", fishName, def.emoji .. " " .. Strings.mutation(first.mutation)), COLOR_GOLD, 4)
					end
				end
			end
		end))
	end
end

-- ===== Ивенты (Хэллоуин и т.п.) =====
-- Сервер присылает { id, left = секунд до конца, candy, tank } или nil (ивента нет). Плашка сверху показывает
-- конфеты и сколько осталось; нажатие переносит в аквариум ивента. Пока открыта карточка рыбы, плашка скрыта.
do
	local eventStateEvent = remotes:WaitForChild("EventState", 10)
	local eventUi = { state = nil, receivedAt = 0, welcomed = false }
	local chip = make("TextButton", {
		Name = "EventChip",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, TANK_ROW_Y + TOP_H + 0.01),
		Size = UDim2.fromScale(0.72, 0.045),
		BackgroundColor3 = Color3.fromRGB(232, 128, 30),
		BorderSizePixel = 0,
		TextScaled = true,
		MinText = 8,
		MaxText = 18,
		TextColor3 = Color3.fromRGB(40, 20, 50),
		Font = FONT,
		Visible = false,
		ZIndex = 3,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, chip)

	local function leftText(seconds)
		seconds = math.max(0, math.floor(seconds))
		if seconds >= 86400 then
			return T("event_left_d", seconds // 86400, (seconds % 86400) // 3600)
		end
		return T("event_left_h", seconds // 3600, (seconds % 3600) // 60)
	end
	local function refresh()
		local state = eventUi.state
		if state == nil then
			chip.Visible = false
			return
		end
		local def = FishConfig.Events[state.id]
		local left = state.left - (os.clock() - eventUi.receivedAt)
		if def == nil or left <= 0 then
			chip.Visible = false
			return
		end
		chip.Text = T("event_chip", def.emoji, Strings.eventName(state.id), def.currency, state.candy, leftText(left))
		chip.Visible = not infoCard.Visible
	end
	infoCard:GetPropertyChangedSignal("Visible"):Connect(refresh)
	chip.Activated:Connect(function()
		local state = eventUi.state
		if state ~= nil and tankSlots[state.tank] ~= nil and currentTank ~= state.tank then
			Sfx.click()
			switchTank(state.tank)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(20)
			pcall(refresh)
		end
	end)
	if eventStateEvent ~= nil then
		eventStateEvent.OnClientEvent:Connect(safely("EventState", function(state)
			eventUi.state = if typeof(state) == "table" then state else nil
			eventUi.receivedAt = os.clock()
			refresh()
			if eventUi.state ~= nil and not eventUi.welcomed then
				eventUi.welcomed = true
				local def = FishConfig.Events[eventUi.state.id]
				if def then
					task.delay(3, function()
						showToast(T("event_welcome", def.emoji, Strings.eventName(eventUi.state.id), Strings.tank(def.tank)), Color3.fromRGB(232, 128, 30), 5)
					end)
				end
			end
			if currentTank == (eventUi.state and eventUi.state.tank) then
				refreshBuyButton()
			end
		end))
	end
end

-- ===== Большой прилив (этап 20) =====
-- Сервер присылает сводку { active, left, nextIn, mult, opened, goal, done, joined, notice }.
-- Плашка видна во время прилива и за SHOW_BEFORE до него; нажатие показывает подсказку о цели.
do
	local tideEvent = remotes:WaitForChild("TideState", 10)
	if tideEvent ~= nil then
		local tideUi = { state = nil, receivedAt = 0 }
		local chip = make("TextButton", {
			Name = "TideChip",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.685),
			Size = UDim2.fromScale(0.8, 0.045),
			BackgroundColor3 = Color3.fromRGB(41, 121, 255),
			BorderSizePixel = 0,
			TextScaled = true,
			MinText = 8,
			MaxText = 18,
			TextColor3 = WHITE,
			Font = FONT,
			Visible = false,
			ZIndex = 3,
		}, gui)
		make("UICorner", { CornerRadius = UDim.new(0.3, 0) }, chip)

		local function clock(seconds)
			seconds = math.max(0, math.floor(seconds))
			return string.format("%d:%02d", seconds // 60, seconds % 60)
		end
		local function refresh()
			local st = tideUi.state
			if st == nil then
				chip.Visible = false
				return
			end
			local passed = os.clock() - tideUi.receivedAt
			if st.active and st.left - passed > 0 then
				local goalText = if st.done then T("tide_goal_done") else T("tide_goal", st.opened or 0, st.goal or 0)
				chip.Text = T("tide_active", tostring(st.mult), clock(st.left - passed)) .. " · " .. goalText
				chip.BackgroundColor3 = if st.done then COLOR_BUTTON else Color3.fromRGB(41, 121, 255)
				chip.Visible = true
			elseif not st.active and st.nextIn - passed > 0 and st.nextIn - passed <= FishConfig.Tide.SHOW_BEFORE then
				chip.Text = T("tide_soon", clock(st.nextIn - passed))
				chip.BackgroundColor3 = COLOR_PANEL
				chip.Visible = true
			else
				chip.Visible = false
			end
		end
		chip.Activated:Connect(function()
			showToast(T("tide_help", tostring(FishConfig.Tide.INCOME_MULT)), COLOR_PANEL, 5)
		end)

		local wasActive = nil
		tideEvent.OnClientEvent:Connect(function(st)
			if typeof(st) ~= "table" then
				return
			end
			tideUi.state = st
			tideUi.receivedAt = os.clock()
			if wasActive == false and st.active then
				showToast(T("toast_tide_start", tostring(st.mult)), Color3.fromRGB(41, 121, 255), 5)
			end
			wasActive = st.active
			local notice = st.notice
			if notice ~= nil then
				if notice.kind == "reward" then
					Sfx.play("reward")
					showToast(T("toast_tide_reward", notice.coins or 0, notice.tickets or 0), COLOR_BUTTON, 5)
				elseif notice.kind == "done" then
					showToast(T("toast_tide_done"), COLOR_PANEL, 4)
				end
			end
			refresh()
		end)
		task.spawn(function()
			while true do
				task.wait(1)
				refresh()
			end
		end)
	end
end

-- ===== Таблицы лидеров (этап 21) =====
-- Окно открывается из списка игроков (кнопка 🏆). Вкладки: лайки за неделю, заказы музея за неделю, коллекция.
do
	local lbAction = remotes:WaitForChild("LeaderboardAction", 10)
	local lbState = remotes:WaitForChild("LeaderboardState", 10)
	if lbAction ~= nil and lbState ~= nil then
		local L = FishConfig.Leaderboards
		local panel = makePanel("LeaderboardPanel")
		panel.title.Text = T("lb_title")
		panel.list.Position = UDim2.fromScale(0.05, 0.23)
		panel.list.Size = UDim2.fromScale(0.9, 0.5)
		ListKit.scroll(panel)
		local hint = addHint(panel, "")
		local current = L.ORDER[1]
		local tabButtons = {}
		local tabsRow = make("Frame", {
			Position = UDim2.fromScale(0.05, 0.125),
			Size = UDim2.fromScale(0.9, 0.08),
			BackgroundTransparency = 1,
			ZIndex = 12,
		}, panel.card)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.02, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, tabsRow)

		-- строка таблицы: высота в пикселях (прокручиваемый список)
		local function lbRow(order, leftText, rightText, color)
			local row = make("Frame", {
				Size = ListKit.rowSize(panel.list, 0.12),
				BackgroundColor3 = COLOR_ROW,
				BorderSizePixel = 0,
				LayoutOrder = order,
				ZIndex = 12,
			}, panel.list)
			make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, row)
			make("TextLabel", {
				Position = UDim2.fromScale(0.03, 0.15),
				Size = UDim2.fromScale(0.68, 0.7),
				BackgroundTransparency = 1,
				Text = leftText,
				TextScaled = true,
				MinText = 9,
				MaxText = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = color,
				Font = FONT,
				ZIndex = 13,
			}, row)
			make("TextLabel", {
				Position = UDim2.fromScale(0.72, 0.15),
				Size = UDim2.fromScale(0.25, 0.7),
				BackgroundTransparency = 1,
				Text = rightText,
				TextScaled = true,
				MinText = 9,
				MaxText = 20,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextColor3 = color,
				Font = FONT,
				ZIndex = 13,
			}, row)
		end

		local function paintTabs()
			for board, button in pairs(tabButtons) do
				button.BackgroundColor3 = if board == current then COLOR_GOLD else COLOR_PANEL
				button.TextColor3 = if board == current then Color3.fromRGB(60, 40, 0) else WHITE
			end
		end
		local function request(board)
			current = board
			paintTabs()
			clearRows(panel.list)
			hint.Text = T("lb_loading")
			lbAction:FireServer(board)
		end
		for index, board in ipairs(L.ORDER) do
			local button = make("TextButton", {
				Size = UDim2.fromScale(0.32, 1),
				BackgroundColor3 = COLOR_PANEL,
				BorderSizePixel = 0,
				Text = L.Boards[board].emoji .. " " .. T("lb_tab_" .. board),
				TextScaled = true,
				MinText = 8,
				MaxText = 18,
				TextColor3 = WHITE,
				Font = FONT,
				LayoutOrder = index,
				ZIndex = 13,
			}, tabsRow)
			make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, button)
			tabButtons[board] = button
			button.Activated:Connect(function()
				request(board)
			end)
		end

		paintTabs()

		lbState.OnClientEvent:Connect(function(message)
			if typeof(message) ~= "table" or message.board ~= current then
				return
			end
			clearRows(panel.list)
			local myId = localPlayer.UserId
			for index, row in ipairs(message.list or {}) do
				local medal = if index == 1 then "🥇" elseif index == 2 then "🥈" elseif index == 3 then "🥉" else tostring(index) .. "."
				local color = if row.userId == myId then COLOR_GOLD else WHITE
				lbRow(index, medal .. " " .. tostring(row.name), Strings.num(row.score or 0), color)
			end
			if #(message.list or {}) == 0 then
				lbRow(1, T("lb_empty"), "", COLOR_MUTED)
			end
			local text = T("lb_me", L.Boards[current].emoji, Strings.num(message.me or 0))
			if message.weekLeft ~= nil then
				local left = message.weekLeft
				text ..= " · " .. T("lb_reset", left // 86400, (left % 86400) // 3600)
			end
			hint.Text = text
		end)

		LeaderboardUi.open = function()
			panel.overlay.Visible = true
			request(current)
		end
	end
end

-- ===== Гости в аквариуме (этап 19) =====
-- Кнопка 👥 рядом с выбором аквариума: список игроков на сервере. Можно открыть чужой аквариум
-- (его фон и рыбы плавают на весь экран), покормить рыб (раз в 10 минут на игрока) и поставить лайк (раз в сутки).
-- Всё проверяет сервер (Social): клиент шлёт только действие и UserId хозяина.
do
	local socialAction = remotes:WaitForChild("SocialAction", 10)
	local socialState = remotes:WaitForChild("SocialState", 10)
	if socialAction ~= nil and socialState ~= nil then
		local SocialService = game:GetService("SocialService")
		local visit = { view = nil, receivedAt = 0, fish = {}, token = 0 }

		tankButton.Size = UDim2.fromScale(0.6, TOP_H) -- место под кнопку гостей
		local guestsButton = make("TextButton", {
			Name = "GuestsButton",
			Position = UDim2.fromScale(0.63, TANK_ROW_Y),
			Size = UDim2.fromScale(0.11, TOP_H),
			BackgroundColor3 = COLOR_PANEL,
			BorderSizePixel = 0,
			Text = "👥",
			TextScaled = true,
			MinText = 14,
			MaxText = 30,
			TextColor3 = WHITE,
			Font = FONT,
			ZIndex = 3,
		}, gui)
		make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, guestsButton)

		-- ----- Список игроков -----
		local playersPanel = makePanel("PlayersPanel")
		playersPanel.title.Text = T("guests_title")
		addHint(playersPanel, T("guests_hint"))
		ListKit.scroll(playersPanel)

		local function listRow(order, leftText, subText, buttonText, onClick)
			local row = make("Frame", {
				Size = ListKit.rowSize(playersPanel.list, 0.2),
				BackgroundColor3 = COLOR_ROW,
				BorderSizePixel = 0,
				LayoutOrder = order,
				ZIndex = 12,
			}, playersPanel.list)
			make("UICorner", { CornerRadius = UDim.new(0.15, 0) }, row)
			UIKit.frame(row, "ui_row")
			make("TextLabel", {
				Position = UDim2.fromScale(0.04, 0.1),
				Size = UDim2.fromScale(0.58, 0.45),
				BackgroundTransparency = 1,
				Text = leftText,
				TextScaled = true,
				MinText = 10,
				MaxText = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = WHITE,
				Font = FONT,
				ZIndex = 13,
			}, row)
			make("TextLabel", {
				Position = UDim2.fromScale(0.04, 0.55),
				Size = UDim2.fromScale(0.58, 0.35),
				BackgroundTransparency = 1,
				Text = subText,
				TextScaled = true,
				MinText = 8,
				MaxText = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = COLOR_MUTED,
				Font = FONT,
				ZIndex = 13,
			}, row)
			local button = make("TextButton", {
				Position = UDim2.fromScale(0.65, 0.18),
				Size = UDim2.fromScale(0.32, 0.64),
				BackgroundColor3 = COLOR_BUTTON,
				BorderSizePixel = 0,
				Text = buttonText,
				TextScaled = true,
				MinText = 9,
				MaxText = 20,
				TextColor3 = WHITE,
				Font = FONT,
				ZIndex = 13,
			}, row)
			make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, button)
			button.Activated:Connect(onClick)
		end

		local function fillList(players)
			clearRows(playersPanel.list)
			table.sort(players, function(a, b)
				return (a.likes or 0) > (b.likes or 0)
			end)
			listRow(0, T("lb_row"), T("lb_row_sub"), T("lb_open"), function()
				playersPanel.overlay.Visible = false
				LeaderboardUi.open()
			end)
			for index, entry in ipairs(players) do
				listRow(index, tostring(entry.name), T("guests_row", entry.likes or 0, entry.fish or 0), T("guests_visit"), function()
					playersPanel.overlay.Visible = false
					socialAction:FireServer("view", entry.userId)
				end)
			end
			if #players == 0 then
				listRow(1, T("guests_empty"), T("guests_empty_sub"), T("guests_invite"), function()
					pcall(function()
						SocialService:PromptGameInvite(localPlayer)
					end)
				end)
			end
		end

		guestsButton.Activated:Connect(function()
			clearRows(playersPanel.list)
			playersPanel.overlay.Visible = true
			socialAction:FireServer("list")
		end)

		-- ----- Чужой аквариум на весь экран -----
		local view = make("Frame", {
			Name = "VisitView",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(20, 110, 140),
			BorderSizePixel = 0,
			Active = true, -- нажатия не проходят к своему аквариуму
			Visible = false,
			ZIndex = 7,
		}, gui)
		local viewBg = make("ImageLabel", {
			Name = "Background",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 7,
		}, view)
		local fishLayer = make("Frame", {
			Name = "Fish",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 8,
		}, view)

		local header = make("Frame", {
			Name = "Header",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, TOP_Y),
			Size = UDim2.fromScale(0.96, 0.15),
			BackgroundColor3 = COLOR_PANEL,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 9,
		}, view)
		make("UICorner", { CornerRadius = UDim.new(0.12, 0) }, header)
		UIKit.frame(header, "ui_panel")
		local nameLabel = make("TextLabel", {
			Position = UDim2.fromScale(0.04, 0.08),
			Size = UDim2.fromScale(0.92, 0.3),
			BackgroundTransparency = 1,
			TextScaled = true,
			MinText = 11,
			MaxText = 24,
			TextColor3 = COLOR_GOLD,
			Font = FONT,
			ZIndex = 10,
		}, header)
		local infoLabel = make("TextLabel", {
			Position = UDim2.fromScale(0.04, 0.38),
			Size = UDim2.fromScale(0.92, 0.2),
			BackgroundTransparency = 1,
			TextScaled = true,
			MinText = 8,
			MaxText = 16,
			TextColor3 = WHITE,
			Font = FONT,
			ZIndex = 10,
		}, header)
		local tabs = make("Frame", {
			Position = UDim2.fromScale(0.03, 0.62),
			Size = UDim2.fromScale(0.94, 0.3),
			BackgroundTransparency = 1,
			ZIndex = 10,
		}, header)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.015, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, tabs)

		local function bottomButton(name, posX, width, color)
			local button = make("TextButton", {
				Name = name,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(posX, 0.985),
				Size = UDim2.fromScale(width, 0.085),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				TextScaled = true,
				MinText = 10,
				MaxText = 24,
				TextColor3 = WHITE,
				Font = FONT,
				ZIndex = 9,
			}, view)
			make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, button)
			return button
		end
		local feedButton = bottomButton("Feed", 0.02, 0.37, COLOR_BUTTON)
		local likeButton = bottomButton("Like", 0.41, 0.3, COLOR_WARN)
		local backButton = bottomButton("Back", 0.73, 0.25, COLOR_PANEL)
		backButton.Text = T("guests_back")

		local function clearFish()
			visit.token += 1
			for _, label in ipairs(visit.fish) do
				label:Destroy()
			end
			visit.fish = {}
		end

		local function swimLoop(label, sprite, species, token)
			local facingRight = true
			while visit.token == token and label.Parent ~= nil do
				local target = randomPoint()
				local from = label.Position
				local dx = target.X.Scale - from.X.Scale
				local dy = target.Y.Scale - from.Y.Scale
				local distance = math.sqrt(dx * dx + dy * dy)
				if sprite ~= nil and dx ~= 0 and (dx > 0) ~= facingRight then
					facingRight = dx > 0
					Sprites.apply(sprite, species, not facingRight)
				end
				local tween = TweenService:Create(label, TweenInfo.new(math.max(distance / FISH_SPEED, 1), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = target })
				tween:Play()
				tween.Completed:Wait()
				task.wait(math.random() * 1.5)
			end
		end

		local function spawnFish(data, token)
			local species = FishConfig.Species[data.species]
			if species == nil then
				return
			end
			local label = make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = FISH_SIZE,
				Position = randomPoint(),
				BackgroundTransparency = 1,
				Text = species.emoji,
				TextScaled = true,
				ZIndex = 8,
			}, fishLayer)
			make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, label)
			make("UISizeConstraint", { MinSize = Vector2.new(40, 40), MaxSize = Vector2.new(96, 96) }, label)
			make("UIScale", { Scale = FishConfig.stageFor(data.age or 0).scale }, label)
			local sprite = make("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 8,
			}, label)
			if Sprites.apply(sprite, data.species, false) then
				label.Text = ""
			else
				sprite:Destroy()
				sprite = nil
			end
			if data.variant ~= nil and data.variant ~= "normal" then
				local variant = FishConfig.variantOf(data.variant)
				local ring = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, label)
				make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
				local stroke = make("UIStroke", { Color = variant.color, Thickness = 3 }, ring)
				if data.variant == "rainbow" then
					task.spawn(function()
						while visit.token == token and label.Parent ~= nil do
							stroke.Color = Color3.fromHSV((os.clock() * 0.3) % 1, 0.6, 1)
							task.wait(0.1)
						end
					end)
				end
			end
			table.insert(visit.fish, label)
			task.spawn(swimLoop, label, sprite, data.species, token)
		end

		local function minutesText(seconds)
			seconds = math.max(0, math.ceil(seconds))
			return string.format("%d:%02d", seconds // 60, seconds % 60)
		end

		-- Кнопки и строка состояния (таймеры считаем на клиенте от момента ответа сервера)
		local function refreshButtons()
			local v = visit.view
			if v == nil then
				return
			end
			local passed = os.clock() - visit.receivedAt
			local feedLeft = (v.feedLeft or 0) - passed
			if feedLeft > 0 then
				feedButton.Text = T("guests_feed_wait", minutesText(feedLeft))
				feedButton.BackgroundColor3 = COLOR_MUTED
			else
				feedButton.Text = T("guests_feed")
				feedButton.BackgroundColor3 = COLOR_BUTTON
			end
			likeButton.Text = if v.canLike then T("guests_like") else T("guests_liked")
			likeButton.BackgroundColor3 = if v.canLike then COLOR_WARN else COLOR_MUTED
			local boostLeft = (v.boostLeft or 0) - passed
			local info = T("guests_likes", v.likes or 0) .. " · " .. T("guests_fish", #v.fish)
			if boostLeft > 0 then
				info ..= " · " .. T("guests_boost", minutesText(boostLeft))
			end
			infoLabel.Text = info
		end

		local function showView(v)
			local sameOwner = visit.view ~= nil and visit.view.userId == v.userId and visit.view.tank == v.tank
			visit.view = v
			visit.receivedAt = os.clock()
			nameLabel.Text = T("guests_aquarium", tostring(v.name))
			-- вкладки аквариумов
			for _, child in ipairs(tabs:GetChildren()) do
				if child:IsA("GuiObject") then
					child:Destroy()
				end
			end
			for index, tankId in ipairs(v.tanks or {}) do
				local def = FishConfig.Tanks[tankId]
				if def ~= nil then
					local tab = make("TextButton", {
						Size = UDim2.fromScale(0.15, 1),
						BackgroundColor3 = if tankId == v.tank then COLOR_GOLD else COLOR_PANEL,
						BorderSizePixel = 0,
						Text = def.emoji,
						TextScaled = true,
						MinText = 10,
						MaxText = 24,
						TextColor3 = WHITE,
						LayoutOrder = index,
						ZIndex = 11,
					}, tabs)
					make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, tab)
					tab.Activated:Connect(function()
						if visit.view ~= nil and tankId ~= visit.view.tank then
							socialAction:FireServer("view", visit.view.userId, tankId)
						end
					end)
				end
			end
			-- фон и рыбы (пересоздаём, только если сменился хозяин или аквариум)
			if not sameOwner then
				local def = FishConfig.Tanks[v.tank]
				if def ~= nil then
					view.BackgroundColor3 = def.color
					viewBg.Visible = def.background ~= nil and Sprites.apply(viewBg, def.background, false)
				end
				clearFish()
				if visit.clearDecor ~= nil then
					visit.clearDecor()
				end
				visit.clearDecor = DecorUi.build(view, v.tank, 7)
				local token = visit.token
				for _, data in ipairs(v.fish or {}) do
					spawnFish(data, token)
				end
			end
			refreshButtons()
			view.Visible = true
			-- результат действия
			local notice = v.notice
			if notice ~= nil then
				if notice.kind == "fed" then
					Sfx.play("reward")
					showToast(if (notice.tickets or 0) > 0 then T("guests_fed_tickets", notice.tickets) else T("guests_fed"), COLOR_BUTTON, 3)
				elseif notice.kind == "liked" then
					showToast(T("guests_like_done"), COLOR_WARN, 2)
				elseif notice.kind == "cooldown" then
					showToast(T("guests_feed_cooldown"), nil, 2)
				elseif notice.kind == "already" then
					showToast(T("guests_like_already"), nil, 2)
				end
			end
		end

		local function closeView()
			view.Visible = false
			visit.view = nil
			clearFish()
			if visit.clearDecor ~= nil then
				visit.clearDecor()
				visit.clearDecor = nil
			end
		end

		feedButton.Activated:Connect(function()
			local v = visit.view
			if v ~= nil then
				socialAction:FireServer("feed", v.userId, v.tank)
			end
		end)
		likeButton.Activated:Connect(function()
			local v = visit.view
			if v ~= nil and v.canLike then
				socialAction:FireServer("like", v.userId, v.tank)
			end
		end)
		backButton.Activated:Connect(closeView)

		socialState.OnClientEvent:Connect(function(message)
			if typeof(message) ~= "table" then
				return
			end
			if message.kind == "list" then
				fillList(message.players or {})
			elseif message.kind == "view" and typeof(message.view) == "table" then
				showView(message.view)
			elseif message.kind == "gone" then
				if view.Visible then
					closeView()
				end
				showToast(T("guests_gone"), nil, 3)
			elseif message.kind == "fed" then
				showToast(T("guests_fed_you", tostring(message.by), math.floor((message.boost or 0) * 100 + 0.5), (message.seconds or 0) // 60), COLOR_BUTTON, 5)
			elseif message.kind == "liked" then
				showToast(T("guests_liked_you", tostring(message.by)), COLOR_WARN, 4)
			end
		end)

		-- таймеры на кнопках
		task.spawn(function()
			while true do
				task.wait(1)
				if view.Visible then
					refreshButtons()
				end
			end
		end)
	end
end

-- ===== Обучение =====
local tutorialPlate, tutorialText, tutorialButton
local tutorialHighlight, tutorialPulse, tutorialTarget

local TUTORIAL_KEYS = { "tut_buy", "tut_fish", "tut_tanks" }

function Tutorial.build()
	tutorialPlate = make("Frame", {
		Name = "TutorialPlate",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromScale(0.96, 0.1),
		BackgroundColor3 = COLOR_PANEL,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 8,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0.18, 0) }, tutorialPlate)
	make("UIStroke", { Color = COLOR_GOLD, Thickness = 2 }, tutorialPlate)
	tutorialText = make("TextLabel", {
		Position = UDim2.fromScale(0.03, 0.08),
		Size = UDim2.fromScale(0.67, 0.84),
		BackgroundTransparency = 1,
		TextScaled = true,
		MinText = 11,
		MaxText = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 9,
	}, tutorialPlate)
	tutorialButton = make("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.97, 0.5),
		Size = UDim2.fromScale(0.26, 0.6),
		BackgroundColor3 = COLOR_BUTTON,
		BorderSizePixel = 0,
		TextScaled = true,
		MinText = 11,
		MaxText = 20,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 9,
	}, tutorialPlate)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, tutorialButton)
	tutorialButton.Activated:Connect(function()
		Tutorial.finish()
	end)
end

function Tutorial.clearHighlight()
	if tutorialPulse then
		tutorialPulse:Cancel()
		tutorialPulse = nil
	end
	if tutorialHighlight then
		tutorialHighlight:Destroy()
		tutorialHighlight = nil
	end
	tutorialTarget = nil
end

-- Пульсирующая рамка вокруг элемента (лежит внутри него, поэтому едет вместе с рыбой и не блокирует нажатия)
function Tutorial.highlight(target, round)
	if target == tutorialTarget and tutorialHighlight ~= nil and tutorialHighlight.Parent ~= nil then
		return
	end
	Tutorial.clearHighlight()
	if target == nil or target.Parent == nil then
		return
	end
	tutorialTarget = target
	tutorialHighlight = make("Frame", {
		Name = "TutorialHighlight",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 8, 1, 8),
		BackgroundTransparency = 1,
		Active = false,
		ZIndex = 6,
	}, target)
	make("UICorner", { CornerRadius = UDim.new(if round then 0.5 else 0.2, 0) }, tutorialHighlight)
	local stroke = make("UIStroke", { Color = COLOR_GOLD, Thickness = 2, Transparency = 0 }, tutorialHighlight)
	tutorialPulse = TweenService:Create(
		stroke,
		TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Thickness = 6, Transparency = 0.5 }
	)
	tutorialPulse:Play()
end

-- Самая новая рыба текущего аквариума (её подсвечиваем на шаге 2)
local function newestFishOfCurrentTank()
	local best = nil
	for id, fish in pairs(fishById) do
		if fish.data.tank == currentTank and (best == nil or id > best.id) then
			best = { id = id, fish = fish }
		end
	end
	return best and best.fish or nil
end

local function anyFishCount()
	local total = 0
	for _, count in pairs(tankCounts) do
		total += count
	end
	return total
end

function Tutorial.refreshTarget()
	if not Tutorial.active or tutorialPlate == nil then
		return
	end
	if Tutorial.step == 1 then
		Tutorial.highlight(buyButton, false)
	elseif Tutorial.step == 2 then
		local fish = newestFishOfCurrentTank()
		Tutorial.highlight(fish and fish.label or nil, true)
	else
		Tutorial.highlight(tankButton, false)
	end
end

function Tutorial.show(step)
	Tutorial.step = step
	tutorialText.Text = T(TUTORIAL_KEYS[step])
	tutorialButton.Text = T(if step == 3 then "tut_ok" else "tut_skip")
	tutorialPlate.Visible = true
	Tutorial.refreshTarget()
end

-- Обучение закончено (или пропущено): прячем подсказки и сообщаем серверу ОДИН раз
function Tutorial.finish()
	if not Tutorial.active then
		return
	end
	Tutorial.active = false
	Tutorial.finished = true
	Tutorial.resolved = true
	Tutorial.finishedAt = os.clock()
	if tutorialPlate then
		tutorialPlate.Visible = false
	end
	Tutorial.clearHighlight()
	if not Tutorial.sent then
		Tutorial.sent = true
		tutorialDoneEvent:FireServer()
	end
	Daily.tryAutoShow()
end

-- Сервер сообщил, что обучение ещё не пройдено
function Tutorial.begin()
	if tutorialPlate == nil then
		Tutorial.resolved = true -- интерфейс подсказок не построился: не мешаем игре
		return
	end
	if Tutorial.active then
		-- повторное сообщение (например, после сброса): если рыб не осталось, возвращаемся к шагу 1
		if Tutorial.step >= 2 and anyFishCount() == 0 then
			Tutorial.gotPack = false
			Tutorial.show(1)
		end
		return
	end
	if Tutorial.finished and Tutorial.finishedAt ~= nil and os.clock() - Tutorial.finishedAt < 10 then
		return -- устаревший ответ сервера, пришедший сразу после нашего завершения
	end
	Tutorial.active = true
	Tutorial.finished = false
	Tutorial.resolved = false
	Tutorial.sent = false
	Tutorial.gotPack = false
	Daily.autoShown = false -- после сброса прогресса награда снова доступна
	Tutorial.show(if anyFishCount() > 0 then 2 else 1)
end

function Tutorial.onRevealClosed()
	if Tutorial.active and Tutorial.step == 1 and Tutorial.gotPack then
		Tutorial.show(2)
	end
end

function Tutorial.onFishSelected()
	if Tutorial.active and Tutorial.step == 2 then
		Tutorial.show(3)
	end
end

function Tutorial.onTanksOpened()
	if Tutorial.active and Tutorial.step == 3 then
		Tutorial.finish()
	end
end

pcall(Tutorial.build)

tutorialDoneEvent.OnClientEvent:Connect(safely("TutorialDone", function(done)
	if done == true then
		Tutorial.resolved = true
		Daily.tryAutoShow()
	else
		Tutorial.begin()
	end
end))

-- ===== Декор, пузырьки и золотые пузырьки =====
-- Декор (растения, домики, сундуки) стоит на дне аквариума за рыбами; растения качаются, кристаллы мерцают,
-- жерло пускает пузырьки. На сундук, ракушку, домик и т.п. можно нажать. Обычные пузырьки лопаются от нажатия,
-- а золотой пузырёк (его выпускает сервер раз в несколько минут) приносит монеты.
do
	local SpriteData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SpriteData"))
	local rng = Random.new()

	-- Звук «пуф»: тот же щелчок, но выше и с разной высотой, чтобы не надоедал
	local popSound = make("Sound", { Name = "Sfx_pop", SoundId = "rbxasset://sounds/clickfast.wav", Volume = 0.25 }, gui)
	local function playPop(pitch)
		if not Sfx.enabled then
			return
		end
		pcall(function()
			popSound.PlaybackSpeed = pitch or (1.4 + rng:NextNumber() * 0.5)
			popSound.TimePosition = 0
			popSound:Play()
		end)
	end

	-- Пиксель декора = высота экрана / 240 (как у фона)
	local function unit(frame)
		local h = frame.AbsoluteSize.Y
		if h < 50 then
			h = 800
		end
		return h / 240
	end

	-- Пузырёк, который поднимается от точки и исчезает (для жерла, сундука и т.п.)
	local function puff(parent, x, y, count, color, z)
		for i = 1, count do
			local size = 0.012 + rng:NextNumber() * 0.018
			local b = make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x + (rng:NextNumber() - 0.5) * 0.03, y),
				Size = UDim2.fromScale(size, size),
				BackgroundColor3 = color or WHITE,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				ZIndex = z or 2,
			}, parent)
			make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, b)
			make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, b)
			make("UIStroke", { Color = WHITE, Transparency = 0.4, Thickness = 1 }, b)
			local rise = 0.12 + rng:NextNumber() * 0.14
			local time = 1.6 + rng:NextNumber() * 1.2
			task.delay((i - 1) * 0.12, function()
				local tween = TweenService:Create(b, TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Position = UDim2.fromScale(x + (rng:NextNumber() - 0.5) * 0.06, y - rise),
					BackgroundTransparency = 1,
				})
				tween:Play()
				tween.Completed:Wait()
				b:Destroy()
			end)
		end
	end

	-- ----- Декор -----
	-- Строит декор аквариума tankId внутри parent. interactive = false — без нажатий (в гостях).
	-- Возвращает функцию очистки.
	local function buildDecor(parent, tankId, interactive, z)
		z = z or 2
		local list = FishConfig.Decor and FishConfig.Decor[tankId]
		local alive = true
		local items = {}
		local layer = make("Frame", {
			Name = "Decor",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = z,
		}, parent)

		local function resize()
			local u = unit(parent)
			for _, it in ipairs(items) do
				it.holder.Size = UDim2.fromOffset(it.w * u, it.h * u * 2)
			end
		end

		for index, d in ipairs(list or {}) do
			local data = SpriteData[d.id]
			if data ~= nil then
				-- holder вдвое выше картинки, центр holder — низ картинки: поворот идёт вокруг «корня»
				local holder = make("Frame", {
					Name = d.id,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(d.x, d.y),
					BackgroundTransparency = 1,
					ZIndex = z,
				}, layer)
				local className = if interactive and d.tap ~= nil then "ImageButton" else "ImageLabel"
				local image = Instance.new(className)
				image.Name = "Image"
				image.Size = UDim2.fromScale(1, 0.5)
				image.BackgroundTransparency = 1
				image.ScaleType = Enum.ScaleType.Stretch
				image.ZIndex = z
				if className == "ImageButton" then
					image.AutoButtonColor = false
				end
				if not Sprites.apply(image, d.id, d.flip == true) then
					image:Destroy()
					holder:Destroy()
					continue
				end
				local scale = Instance.new("UIScale")
				scale.Parent = image
				image.Parent = holder
				local it = { holder = holder, image = image, scale = scale, w = data.w, h = data.h, def = d, opened = false }
				table.insert(items, it)

				-- анимации
				if d.anim == "sway" then
					local angle = 2 + rng:NextNumber() * 2
					holder.Rotation = -angle
					task.delay(rng:NextNumber() * 2, function()
						if alive then
							TweenService:Create(holder, TweenInfo.new(2.4 + rng:NextNumber() * 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = angle }):Play()
						end
					end)
				elseif d.anim == "glow" then
					image.ImageColor3 = Color3.fromRGB(175, 180, 200)
					TweenService:Create(image, TweenInfo.new(1.8 + rng:NextNumber(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { ImageColor3 = WHITE }):Play()
				elseif d.anim == "vent" then
					task.spawn(function()
						while alive and holder.Parent ~= nil do
							task.wait(2.5 + rng:NextNumber() * 3)
							if alive and parent.Visible ~= false then
								local u = unit(parent)
								local topY = d.y - (data.h * u) / math.max(parent.AbsoluteSize.Y, 1)
								puff(layer, d.x, topY, 3, nil, z)
							end
						end
					end)
				end

				-- нажатия
				if className == "ImageButton" then
					image.Activated:Connect(function()
						local u = unit(parent)
						local topY = d.y - (data.h * u) / math.max(parent.AbsoluteSize.Y, 1)
						if d.tap == "open" then
							if it.opened then
								return
							end
							it.opened = true
							Sprites.apply(image, d.open, d.flip == true)
							playPop(1.1)
							puff(layer, d.x, topY + 0.02, 6, Color3.fromRGB(255, 236, 140))
							task.delay(3.5, function()
								if alive and image.Parent ~= nil then
									Sprites.apply(image, d.id, d.flip == true)
									it.opened = false
								end
							end)
						else
							playPop()
							scale.Scale = 1
							local up = TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.12 })
							up:Play()
							up.Completed:Once(function()
								TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
							end)
							puff(layer, d.x, topY + 0.01, 3)
						end
					end)
				end
			end
		end
		resize()
		local conn = parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
		return function()
			alive = false
			conn:Disconnect()
			layer:Destroy()
		end
	end

	-- свой аквариум: декор меняется вместе с аквариумом
	local clearOwn = nil
	local shownTank = nil
	function DecorUi.show(tankId)
		if tankId == shownTank then
			return
		end
		shownTank = tankId
		if clearOwn ~= nil then
			clearOwn()
		end
		clearOwn = buildDecor(tank, tankId, true, 1) -- слой фона: рыбы (2) всегда поверх
	end
	DecorUi.build = function(parent, tankId, z)
		return buildDecor(parent, tankId, false, z)
	end
	pcall(DecorUi.show, currentTank)

	-- ----- Обычные пузырьки: поднимаются позади рыб, лопаются от нажатия -----
	local BUBBLE_COUNT = 12
	for index = 1, BUBBLE_COUNT do
		local size = 0.014 + rng:NextNumber() * 0.034 -- доля ширины экрана
		local bubble = make("TextButton", {
			Name = "Bubble" .. index,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(size, size),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			NoSfx = true,
			ZIndex = 1,
		}, tank)
		make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, bubble)
		make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bubble)
		local stroke = make("UIStroke", { Color = WHITE, Transparency = 0.5, Thickness = 1.5 }, bubble)
		local bubbleScale = make("UIScale", { Scale = 1 }, bubble)
		local speed = 0.03 + rng:NextNumber() * 0.05 -- экранов в секунду
		local current = nil -- текущий твин подъёма
		local popped = false

		bubble.Activated:Connect(function()
			if popped then
				return
			end
			popped = true
			if current then
				current:Cancel()
			end
			playPop()
			TweenService:Create(bubbleScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.8 }):Play()
			TweenService:Create(bubble, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.15), { Transparency = 1 }):Play()
		end)

		task.spawn(function()
			local fromY = 0.15 + rng:NextNumber() * 0.9 -- первый подъём начинается где угодно
			while bubble.Parent ~= nil do
				local x = 0.04 + rng:NextNumber() * 0.92
				local drift = (rng:NextNumber() - 0.5) * 0.12
				bubble.Position = UDim2.fromScale(x, fromY)
				current = TweenService:Create(
					bubble,
					TweenInfo.new((fromY + 0.05) / speed, Enum.EasingStyle.Linear),
					{ Position = UDim2.fromScale(math.clamp(x + drift, 0.02, 0.98), -0.05) }
				)
				current:Play()
				current.Completed:Wait()
				task.wait(if popped then 1 + rng:NextNumber() * 3 else rng:NextNumber() * 3)
				-- новый пузырёк снизу
				popped = false
				bubbleScale.Scale = 1
				bubble.BackgroundTransparency = 0.8
				stroke.Transparency = 0.5
				fromY = 1.05
			end
		end)
	end

	-- ----- Золотой пузырёк (выпускает сервер) -----
	local goldEvent = remotes:WaitForChild("GoldBubble", 10)
	local popEvent = remotes:WaitForChild("PopBubble", 10)
	if goldEvent ~= nil and popEvent ~= nil then
		local GOLD = Color3.fromRGB(255, 202, 40)
		local lastPos = UDim2.fromScale(0.5, 0.5)
		local function spawnGold(id, life)
			local x = 0.15 + rng:NextNumber() * 0.7
			local bubble = make("TextButton", {
				Name = "GoldBubble",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x, 0.82),
				Size = UDim2.fromScale(0.11, 0.11),
				BackgroundColor3 = GOLD,
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "✨",
				TextScaled = true,
				MinText = 10,
				MaxText = 30,
				TextColor3 = WHITE,
				NoSfx = true,
				ZIndex = 3, -- над рыбами, чтобы точно можно было нажать
			}, tank)
			make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, bubble)
			make("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bubble)
			make("UIStroke", { Color = Color3.fromRGB(255, 244, 180), Thickness = 2.5 }, bubble)
			local bubbleScale = make("UIScale", { Scale = 1 }, bubble)
			TweenService:Create(bubbleScale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 }):Play()
			local rise = TweenService:Create(bubble, TweenInfo.new(life, Enum.EasingStyle.Linear), { Position = UDim2.fromScale(math.clamp(x + (rng:NextNumber() - 0.5) * 0.2, 0.1, 0.9), 0.22) })
			rise:Play()
			local done = false
			bubble.Activated:Connect(function()
				if done then
					return
				end
				done = true
				rise:Cancel()
				lastPos = bubble.Position
				popEvent:FireServer(id)
				playPop(1.0)
				puff(tank, bubble.Position.X.Scale, bubble.Position.Y.Scale, 6, GOLD)
				bubble:Destroy()
			end)
			rise.Completed:Connect(function()
				if not done then
					done = true
					TweenService:Create(bubble, TweenInfo.new(0.5), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
					task.delay(0.6, function()
						bubble:Destroy()
					end)
				end
			end)
		end

		-- «+N» всплывает над местом, где лопнул пузырёк
		local function floatText(text)
			local label = make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = lastPos,
				Size = UDim2.fromScale(0.4, 0.05),
				BackgroundTransparency = 1,
				Text = text,
				TextScaled = true,
				MinText = 12,
				MaxText = 30,
				TextColor3 = GOLD,
				TextStrokeTransparency = 0.3,
				Font = FONT,
				ZIndex = 4,
			}, tank)
			local tween = TweenService:Create(label, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = lastPos - UDim2.fromScale(0, 0.1),
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			})
			tween:Play()
			tween.Completed:Wait()
			label:Destroy()
		end

		goldEvent.OnClientEvent:Connect(function(message)
			if typeof(message) ~= "table" then
				return
			end
			if typeof(message.id) == "number" then
				spawnGold(message.id, math.clamp(tonumber(message.life) or 15, 5, 30))
			elseif message.coins ~= nil then
				Sfx.play("reward")
				task.spawn(floatText, "+" .. Strings.num(message.coins) .. " 🪙")
			end
		end)
	end
end

-- ===== Панель администратора (видна только админам; права всё равно проверяет сервер) =====
local adminBuilt = false

local function buildAdminPanel()
	if adminBuilt then
		return
	end
	adminBuilt = true

	local panel = makePanel("AdminPanel")
	panel.title.Text = T("adm_title")
	panel.list.Size = UDim2.fromScale(0.9, 0.7)

	local function addButton(order, text, onTap)
		local button = make("TextButton", {
			Size = UDim2.fromScale(1, 0.1),
			BackgroundColor3 = COLOR_ROW,
			BorderSizePixel = 0,
			Text = text,
			TextScaled = true,
			MinText = 12,
			TextColor3 = WHITE,
			Font = FONT,
			LayoutOrder = order,
			ZIndex = 13,
		}, panel.list)
		make("UICorner", { CornerRadius = UDim.new(0.2, 0) }, button)
		button.Activated:Connect(function()
			onTap(button)
		end)
		return button
	end

	addButton(1, T("adm_coins_1k"), function()
		adminCommandEvent:FireServer("coins", 1000)
	end)
	addButton(2, T("adm_coins_100k"), function()
		adminCommandEvent:FireServer("coins", 100000)
	end)
	addButton(3, T("adm_slot"), function()
		local owned = tankSlots[currentTank] or FishConfig.START_SLOTS
		if owned < FishConfig.MAX_SLOTS then
			adminCommandEvent:FireServer("slots", owned + 1, currentTank)
		end
	end)

	-- Выдача рыбы: каждое нажатие выдаёт показанный вид и переключает на следующий
	local variantIndex = 1
	local speciesIndex = 1
	local function fishButtonText()
		local id = FishConfig.SpeciesOrder[speciesIndex]
		return T("adm_give", FishConfig.Species[id].emoji .. " " .. Strings.species(id))
	end
	addButton(4, fishButtonText(), function(button)
		adminCommandEvent:FireServer("fish", FishConfig.SpeciesOrder[speciesIndex], FishConfig.VariantOrder[variantIndex])
		speciesIndex = speciesIndex % #FishConfig.SpeciesOrder + 1
		button.Text = fishButtonText()
	end)

	-- Переключатель варианта для кнопки «Выдать»
	local function variantButtonText()
		return T("adm_variant", Strings.variant(FishConfig.VariantOrder[variantIndex]))
	end
	addButton(5, variantButtonText(), function(button)
		variantIndex = variantIndex % #FishConfig.VariantOrder + 1
		button.Text = variantButtonText()
	end)

	addButton(6, T("adm_age"), function()
		adminCommandEvent:FireServer("age", 3600)
	end)

	addButton(7, T("adm_unlock"), function()
		adminCommandEvent:FireServer("unlock")
	end)

	-- Сброс — только после повторного нажатия в течение 3 секунд
	local resetArmed = false
	local function disarm(button)
		resetArmed = false
		button.Text = T("adm_reset")
		button.BackgroundColor3 = COLOR_ROW
	end
	addButton(8, T("adm_reset"), function(button)
		if not resetArmed then
			resetArmed = true
			button.Text = T("adm_reset_confirm")
			button.BackgroundColor3 = COLOR_WARN
			task.delay(3, function()
				if resetArmed then
					disarm(button)
				end
			end)
			return
		end
		disarm(button)
		adminCommandEvent:FireServer("reset")
	end)

	local openButton = iconButton("AdminButton", "⚙", 0.7)
	openButton.Activated:Connect(function()
		panel.overlay.Visible = true
	end)
end

local function checkAdmin()
	if localPlayer:GetAttribute("IsAdmin") == true then
		buildAdminPanel()
	end
end
localPlayer:GetAttributeChangedSignal("IsAdmin"):Connect(checkAdmin)
checkAdmin()

-- Все обработчики подключены: просим сервер прислать состояние (монеты, рыб, коллекцию, награду)
clientReadyEvent:FireServer()
