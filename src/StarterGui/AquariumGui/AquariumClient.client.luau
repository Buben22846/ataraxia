-- AquariumClient: показывает монеты, рыб, окна паков и коллекции; отправляет запросы серверу.
-- Клиент только рисует и просит; все решения (деньги, выпадение, продажа) принимает сервер.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local gui = script.Parent

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

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

-- ===== НАСТРОЙКИ =====
local FISH_SIZE = UDim2.fromScale(0.16, 0.1) -- высоту задаёт UIAspectRatioConstraint (квадрат по ширине)
local FISH_SPEED = 0.1
local FISH_ZINDEX = 2 -- выше фона (1), ниже кнопок и монет (3)
local MIN_X, MAX_X = 0.14, 0.86
local MIN_Y, MAX_Y = 0.36, 0.68 -- верх занят карточкой статистики выбранной рыбы
local PACK_ID = "common" -- какой пак продаёт главная кнопка

local WHITE = Color3.fromRGB(255, 255, 255)
local COLOR_PANEL = Color3.fromRGB(10, 70, 95)
local COLOR_ROW = Color3.fromRGB(8, 52, 72)
local COLOR_BUTTON = Color3.fromRGB(38, 166, 154)
local COLOR_MUTED = Color3.fromRGB(120, 144, 156)
local COLOR_GOLD = Color3.fromRGB(255, 202, 40)
local COLOR_WARN = Color3.fromRGB(231, 111, 81)
local FONT = Enum.Font.GothamBold
-- =====================

-- Создаёт объект, задаёт свойства и в конце помещает в родителя
local function make(className, props, parent)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

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
		local pool = FishConfig.speciesOfRarity(rarity)
		for _, id in ipairs(pool) do
			result[id] = (pack.odds[rarity] or 0) / #pool
		end
	end
	return result
end

local pack = FishConfig.Packs[PACK_ID]
local totalSpecies = #FishConfig.SpeciesOrder
local discovered = {} -- id вида -> true (собранные виды, присылает сервер)
local revealBusy = false -- идёт анимация открытия пака
local pendingReveals = {} -- очередь результатов, если они пришли во время анимации

-- ===== Монеты и покупка пака =====
buyButton.Text = pack.name .. " (" .. tostring(pack.price) .. ")"

buyButton.Activated:Connect(function()
	if revealBusy then
		return
	end
	openPackEvent:FireServer(PACK_ID) -- отправляем только id пака
end)

coinsChangedEvent.OnClientEvent:Connect(function(newCoins)
	coinsLabel.Text = "Монеты: " .. tostring(newCoins)
end)

-- Вторичные кнопки над главной
local function makeSecondaryButton(name, text, posX)
	local button = make("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(posX, 0.845),
		Size = UDim2.fromScale(0.29, 0.07),
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		Text = text,
		TextScaled = true,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 3,
	}, gui)
	return button
end

local collectionButton = makeSecondaryButton("CollectionButton", "", 0.05)
local oddsButton = makeSecondaryButton("OddsButton", "Шансы", 0.36)
local expandButton = makeSecondaryButton("ExpandButton", "", 0.67)

-- Счётчик рыб и мест (рядом с монетами) и кнопка покупки следующего места
local fishCountLabel = make("TextLabel", {
	Name = "FishCountLabel",
	Position = UDim2.fromScale(0.31, 0.063),
	Size = UDim2.fromScale(0.15, 0.08),
	BackgroundColor3 = COLOR_PANEL,
	BorderSizePixel = 0,
	Text = "",
	TextScaled = true,
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 3,
}, gui)

local slots = FishConfig.START_SLOTS -- сколько рыб помещается (присылает сервер)
local fishTotal = 0 -- сколько рыб сейчас

local function refreshSlotsUi()
	fishCountLabel.Text = "🐟 " .. tostring(fishTotal) .. "/" .. tostring(slots)
	local nextPrice = FishConfig.SlotPrices[slots + 1]
	if nextPrice == nil or slots >= FishConfig.MAX_SLOTS then
		expandButton.Text = "Мест: максимум"
		expandButton.BackgroundColor3 = COLOR_MUTED
	else
		expandButton.Text = "+место (" .. tostring(nextPrice) .. ")"
		expandButton.BackgroundColor3 = COLOR_BUTTON
	end
end

expandButton.Activated:Connect(function()
	if slots < FishConfig.MAX_SLOTS then
		buySlotEvent:FireServer() -- без аргументов: цену берёт сервер
	end
end)
refreshSlotsUi()

-- ===== Уведомление («Аквариум полон», «Не хватает монет») =====
local toast = make("TextLabel", {
	Name = "ToastLabel",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.17),
	Size = UDim2.fromScale(0.7, 0.06),
	BackgroundColor3 = COLOR_WARN,
	BorderSizePixel = 0,
	TextScaled = true,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 15,
}, gui)
local toastToken = 0

local function showToast(text)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.Visible = true
	task.delay(2, function()
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
		Size = UDim2.fromScale(0.88, 0.72),
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		Active = true, -- не пропускает нажатия сквозь карточку
		ZIndex = 11,
	}, overlay)
	make("UICorner", { CornerRadius = UDim.new(0.04, 0) }, card)

	local title = make("TextLabel", {
		Name = "Title",
		Position = UDim2.fromScale(0.05, 0.02),
		Size = UDim2.fromScale(0.9, 0.1),
		BackgroundTransparency = 1,
		TextScaled = true,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 12,
	}, card)

	local list = make("Frame", {
		Name = "List",
		Position = UDim2.fromScale(0.05, 0.14),
		Size = UDim2.fromScale(0.9, 0.62),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, card)
	make("UIListLayout", { Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local close = make("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.96),
		Size = UDim2.fromScale(0.5, 0.11),
		BackgroundColor3 = COLOR_BUTTON,
		BorderSizePixel = 0,
		Text = "Закрыть",
		TextScaled = true,
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

	return { overlay = overlay, title = title, list = list }
end

local function clearRows(list)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
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
		Size = UDim2.fromScale(0.62, 0.7),
		Position = UDim2.fromScale(0.03, 0.15),
		BackgroundTransparency = 1,
		Text = leftText,
		TextColor3 = color,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = FONT,
		ZIndex = 13,
	}, row)
	make("TextLabel", {
		Size = UDim2.fromScale(0.3, 0.7),
		Position = UDim2.fromScale(0.67, 0.15),
		BackgroundTransparency = 1,
		Text = rightText,
		TextColor3 = color,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Font = FONT,
		ZIndex = 13,
	}, row)
end

-- ===== Коллекция =====
local collectionPanel = makePanel("CollectionPanel")
make("TextLabel", {
	Name = "Hint",
	Position = UDim2.fromScale(0.05, 0.775),
	Size = UDim2.fromScale(0.9, 0.06),
	BackgroundTransparency = 1,
	Text = "×N — сколько раз выпала · 💰 — всего заработала",
	TextScaled = true,
	TextColor3 = COLOR_MUTED,
	Font = FONT,
	ZIndex = 12,
}, collectionPanel.overlay.Card)

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
	collectionButton.Text = "Коллекция " .. count .. "/" .. totalSpecies
	collectionPanel.title.Text = "Коллекция: " .. count .. "/" .. totalSpecies

	clearRows(collectionPanel.list)
	for index, id in ipairs(FishConfig.SpeciesOrder) do
		local species = FishConfig.Species[id]
		local rarity = FishConfig.Rarities[species.rarity]
		local entry = discovered[id]
		if entry then
			addRow(
				collectionPanel.list,
				index,
				species.emoji .. " " .. species.name .. " ×" .. tostring(entry.pulled),
				"💰 " .. tostring(entry.earned),
				rarity.color
			)
		else
			addRow(collectionPanel.list, index, "❓ ???", "—", COLOR_MUTED)
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

oddsButton.Activated:Connect(function()
	oddsPanel.title.Text = "Шансы: " .. pack.name
	clearRows(oddsPanel.list)
	local chances = speciesChances(pack)
	for index, id in ipairs(FishConfig.SpeciesOrder) do
		local species = FishConfig.Species[id]
		local rarity = FishConfig.Rarities[species.rarity]
		addRow(
			oddsPanel.list,
			index,
			species.emoji .. " " .. species.name .. " (" .. rarity.name .. ")",
			formatPercent(chances[id] or 0),
			rarity.color
		)
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
	Size = UDim2.fromScale(0.72, 0.5),
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
	TextColor3 = WHITE,
	Font = FONT,
	ZIndex = 22,
}, revealCard)
local revealScale = make("UIScale", { Scale = 1 }, revealEmoji)

local revealName = make("TextLabel", {
	Name = "FishName",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.45),
	Size = UDim2.fromScale(0.9, 0.12),
	BackgroundTransparency = 1,
	TextScaled = true,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 22,
}, revealCard)

local revealRarity = make("TextLabel", {
	Name = "Rarity",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.58),
	Size = UDim2.fromScale(0.7, 0.09),
	BackgroundTransparency = 1,
	TextScaled = true,
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
	Text = "НОВАЯ В КОЛЛЕКЦИИ!",
	TextScaled = true,
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
	Text = "Отлично",
	TextScaled = true,
	TextColor3 = WHITE,
	Font = FONT,
	Visible = false,
	ZIndex = 22,
}, revealCard)
make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, revealClose)

local function playReveal(result)
	revealBusy = true
	local species = FishConfig.Species[result.species] or FishConfig.Species.guppy
	local rarity = FishConfig.Rarities[result.rarity] or FishConfig.Rarities.common

	revealEmoji.Text = "❓"
	revealEmoji.Rotation = 0
	revealScale.Scale = 1
	revealName.Visible = false
	revealRarity.Visible = false
	revealNew.Visible = false
	revealClose.Visible = false
	revealStroke.Color = COLOR_BUTTON
	reveal.Visible = true

	-- «Трясём» загадочный знак
	local wobble = TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for _ = 1, 4 do
		TweenService:Create(revealEmoji, wobble, { Rotation = -15 }):Play()
		task.wait(0.12)
		TweenService:Create(revealEmoji, wobble, { Rotation = 15 }):Play()
		task.wait(0.12)
	end
	TweenService:Create(revealEmoji, wobble, { Rotation = 0 }):Play()
	task.wait(0.12)

	-- Показываем рыбу
	revealEmoji.Text = species.emoji
	revealScale.Scale = 0.4
	TweenService:Create(revealScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	revealStroke.Color = rarity.color
	revealName.Text = species.name
	revealRarity.Text = rarity.name
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
end

revealClose.Activated:Connect(closeReveal)
reveal.Activated:Connect(closeReveal)

packResultEvent.OnClientEvent:Connect(function(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.ok then
		if revealBusy then
			table.insert(pendingReveals, result)
		else
			task.spawn(playReveal, result)
		end
	elseif result.reason == "full" then
		showToast("Аквариум полон: продайте рыбу или купите место")
	elseif result.reason == "coins" then
		showToast("Не хватает монет")
	end
end)

refreshCollection()

-- ===== Кнопка продажи (появляется при выборе рыбы) =====
local sellButton = Instance.new("TextButton")
sellButton.Name = "SellButton"
sellButton.AnchorPoint = Vector2.new(1, 0)
sellButton.Position = UDim2.fromScale(0.97, 0.04)
sellButton.Size = UDim2.fromScale(0.5, 0.1)
sellButton.BackgroundColor3 = Color3.fromRGB(231, 111, 81)
sellButton.BorderSizePixel = 0
sellButton.TextScaled = true
sellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
sellButton.Font = Enum.Font.GothamBold
sellButton.ZIndex = 3
sellButton.Visible = false
sellButton.Parent = gui

-- ===== Карточка статистики выбранной рыбы =====
local infoCard = make("Frame", {
	Name = "FishInfo",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.155),
	Size = UDim2.fromScale(0.94, 0.15),
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
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = color,
		Font = FONT,
		ZIndex = 5,
	}, infoCard)
end
local infoTitle = infoLine("Title", 0.05, 0.32, WHITE)
local infoIncome = infoLine("Income", 0.38, 0.28, Color3.fromRGB(190, 220, 230))
local infoStats = infoLine("Stats", 0.68, 0.28, Color3.fromRGB(190, 220, 230))

-- ===== Рыбы =====
local fishById = {} -- id -> { label, species, alive, tween }
local selectedId = nil -- id выбранной рыбы или nil

local function randomPoint()
	local x = MIN_X + math.random() * (MAX_X - MIN_X)
	local y = MIN_Y + math.random() * (MAX_Y - MIN_Y)
	return UDim2.fromScale(x, y)
end

-- 75 -> "1м 15с", 4000 -> "1ч 6м"
local function formatAge(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds < 60 then
		return tostring(seconds) .. "с"
	end
	if seconds < 3600 then
		return tostring(seconds // 60) .. "м " .. tostring(seconds % 60) .. "с"
	end
	return tostring(seconds // 3600) .. "ч " .. tostring((seconds % 3600) // 60) .. "м"
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
	local age = fish.data.age + (os.clock() - fish.receivedAt) -- возраст с сервера + прошедшее время
	infoTitle.Text = species.emoji .. " " .. species.name .. " · " .. rarity.name
	infoTitle.TextColor3 = rarity.color
	infoIncome.Text = "Доход: +" .. tostring(species.income) .. " за " .. tostring(FishConfig.INCOME_INTERVAL) .. "с · Продажа: " .. tostring(species.sellPrice)
	infoStats.Text = "Возраст: " .. formatAge(age) .. " · Заработала: 💰" .. tostring(fish.data.earned)
	infoCard.Visible = true
end

-- Обновляет подсветку выбранной рыбы, кнопку продажи и карточку статистики
local function refreshSelection()
	if selectedId ~= nil and fishById[selectedId] == nil then
		selectedId = nil
	end
	for id, fish in pairs(fishById) do
		fish.label.BackgroundTransparency = if id == selectedId then 0.7 else 1
	end
	if selectedId ~= nil then
		local species = fishById[selectedId].species
		sellButton.Text = species.name .. ": продать (+" .. tostring(species.sellPrice) .. ")"
		sellButton.Visible = true
	else
		sellButton.Visible = false
	end
	updateInfo()
end

local function selectFish(id)
	if selectedId == id then
		selectedId = nil -- повторное нажатие снимает выбор
	else
		selectedId = id
	end
	refreshSelection()
end

sellButton.Activated:Connect(function()
	if selectedId ~= nil then
		sellFishEvent:FireServer(selectedId) -- отправляем только id
		selectedId = nil
		refreshSelection()
	end
end)

-- Жизнь одной рыбы: выбрать точку -> доплыть -> пауза -> повторить
local function swim(fish)
	while fish.alive do
		local target = randomPoint()
		local from = fish.label.Position
		local dx = target.X.Scale - from.X.Scale
		local dy = target.Y.Scale - from.Y.Scale
		local distance = math.sqrt(dx * dx + dy * dy)
		local duration = math.max(distance / FISH_SPEED, 1)

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
	label.Parent = tank

	-- Рыба квадратная и не мельчает/не раздувается на разных экранах
	make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, label)
	make("UISizeConstraint", { MinSize = Vector2.new(40, 40), MaxSize = Vector2.new(96, 96) }, label)

	local fish = { label = label, species = species, alive = true, tween = nil, data = fishData, receivedAt = os.clock() }
	fishById[fishData.id] = fish

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

-- Сервер прислал ВЕСЬ список рыб: сверяем с экраном
fishChangedEvent.OnClientEvent:Connect(function(fishList, newSlots)
	local present = {}
	fishTotal = #fishList
	if typeof(newSlots) == "number" then
		slots = newSlots
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
		end
	end

	for id, _ in pairs(fishById) do
		if not present[id] then
			removeFish(id)
		end
	end

	refreshSelection()
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

-- ===== Панель администратора (видна только админам; права всё равно проверяет сервер) =====
local localPlayer = Players.LocalPlayer
local adminBuilt = false

local function buildAdminPanel()
	if adminBuilt then
		return
	end
	adminBuilt = true

	local panel = makePanel("AdminPanel")
	panel.title.Text = "Админ-панель (тест)"

	local function addButton(order, text, onTap)
		local button = make("TextButton", {
			Size = UDim2.fromScale(1, 0.13),
			BackgroundColor3 = COLOR_ROW,
			BorderSizePixel = 0,
			Text = text,
			TextScaled = true,
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

	addButton(1, "+1 000 монет", function()
		adminCommandEvent:FireServer("coins", 1000)
	end)
	addButton(2, "+100 000 монет", function()
		adminCommandEvent:FireServer("coins", 100000)
	end)
	addButton(3, "+1 место в аквариуме", function()
		if slots < FishConfig.MAX_SLOTS then
			adminCommandEvent:FireServer("slots", slots + 1)
		end
	end)

	-- Выдача рыбы: каждое нажатие выдаёт показанный вид и переключает на следующий
	local speciesIndex = 1
	local function fishButtonText()
		local species = FishConfig.Species[FishConfig.SpeciesOrder[speciesIndex]]
		return "Выдать: " .. species.emoji .. " " .. species.name
	end
	addButton(4, fishButtonText(), function(button)
		adminCommandEvent:FireServer("fish", FishConfig.SpeciesOrder[speciesIndex])
		speciesIndex = speciesIndex % #FishConfig.SpeciesOrder + 1
		button.Text = fishButtonText()
	end)

	addButton(5, "Состарить рыб на 1 час", function()
		adminCommandEvent:FireServer("age", 3600)
	end)

	-- Сброс — только после повторного нажатия в течение 3 секунд
	local resetArmed = false
	local function disarm(button)
		resetArmed = false
		button.Text = "Сбросить прогресс"
		button.BackgroundColor3 = COLOR_ROW
	end
	addButton(6, "Сбросить прогресс", function(button)
		if not resetArmed then
			resetArmed = true
			button.Text = "Точно? Нажмите ещё раз"
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

	local openButton = make("TextButton", {
		Name = "AdminButton",
		Position = UDim2.fromScale(0.02, 0.32),
		Size = UDim2.fromScale(0.12, 0.06),
		BackgroundColor3 = COLOR_PANEL,
		BorderSizePixel = 0,
		Text = "⚙",
		TextScaled = true,
		TextColor3 = WHITE,
		Font = FONT,
		ZIndex = 3,
	}, gui)
	make("UIAspectRatioConstraint", { AspectRatio = 1 }, openButton)
	make("UICorner", { CornerRadius = UDim.new(0.25, 0) }, openButton)
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

-- Все обработчики подключены: просим сервер прислать состояние (монеты, рыб, коллекцию)
clientReadyEvent:FireServer()
