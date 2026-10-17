-- GameServer: «мозг» игры на сервере. Данные игрока живут в профиле (PlayerData), здесь только правила игры.
-- Клиенту мы не доверяем: он присылает только намерения (id пака, id рыбы), всё остальное считает сервер.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local PackRoller = require(ServerScriptService:WaitForChild("PackRoller"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))

-- ===== НАСТРОЙКИ =====
-- Число мест в аквариуме хранится в профиле (profile.slots), максимум и цены — в FishConfig.
-- =====================

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

local loaded = {} -- player -> true, когда профиль загружен

local ready = {} -- player -> true, когда клиент подключил обработчики и готов принимать данные

local pendingOffline = {} -- player -> монеты, заработанные в офлайне (покажем при первой отправке состояния)

-- Проверка конфига паков: шансы должны давать в сумме 100%
for packId, pack in pairs(FishConfig.Packs) do
	local sum = 0
	for _, rarity in ipairs(FishConfig.RarityOrder) do
		sum += pack.odds[rarity] or 0
	end
	if math.abs(sum - 100) > 0.001 then
		warn("Шансы пака " .. packId .. " в сумме дают " .. tostring(sum) .. ", а должно быть 100")
	end
end

-- ===== Защита от спама (token bucket): не больше ratePerSec запросов в секунду, всплеск до burst =====
local buckets = {}
local function allow(player, key, ratePerSec, burst)
	local now = os.clock()
	local playerBuckets = buckets[player]
	if not playerBuckets then
		playerBuckets = {}
		buckets[player] = playerBuckets
	end
	local b = playerBuckets[key]
	if not b then
		b = { tokens = burst, last = now }
		playerBuckets[key] = b
	end
	b.tokens = math.min(burst, b.tokens + (now - b.last) * ratePerSec)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

-- Статистика вида в профиле (создаём, если её ещё нет)
local statsFor = Economy.statsFor

-- ===== Права администратора =====
-- В Studio админ — любой тестовый игрок; в опубликованной игре — только владелец и UserId из списка.
local ADMIN_USER_IDS = {
	-- [12345678] = true, -- пример: UserId помощника
}

local function isAdmin(player)
	if RunService:IsStudio() then
		return true
	end
	if ADMIN_USER_IDS[player.UserId] then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

-- ===== Отправка состояния клиенту =====
local function sendCoins(player, profile)
	coinsChangedEvent:FireClient(player, profile.coins)
end

-- Рыбы с их статистикой: id, вид, возраст в секундах, сколько заработала эта рыба
local function sendFish(player, profile)
	local now = os.time()
	local list = {}
	for _, fish in ipairs(profile.fish) do
		table.insert(list, {
			id = fish.id,
			species = fish.species,
			variant = fish.variant or "normal",
			age = math.max(0, now - fish.born),
			earned = fish.earned,
		})
	end
	fishChangedEvent:FireClient(player, list, profile.slots)
end

-- Коллекция: найденные виды в порядке SpeciesOrder со статистикой (сколько раз выпала, сколько заработано)
local function sendCollection(player, profile)
	local list = {}
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		if profile.discovered[id] then
			local stats = statsFor(profile, id)
			table.insert(list, { id = id, pulled = stats.pulled, earned = stats.earned })
		end
	end
	collectionChangedEvent:FireClient(player, list)
end

local function pushState(player)
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	sendCoins(player, profile)
	sendFish(player, profile)
	sendCollection(player, profile)

	local gained = pendingOffline[player]
	if gained then
		pendingOffline[player] = nil
		offlineIncomeEvent:FireClient(player, gained)
	end
end

-- ===== Вход / выход =====
local function onPlayerAdded(player)
	local profile, reason = PlayerData.load(player)
	if profile == nil then
		-- Не даём играть с пустым профилем: его сохранение перезапишет настоящий
		if reason == "locked" then
			player:Kick("Ваши данные ещё сохраняются на другом сервере. Зайдите снова через минуту.")
		elseif reason ~= "left" then
			player:Kick("Не удалось загрузить данные. Прогресс не потерян, зайдите снова.")
		end
		return
	end
	player:SetAttribute("IsAdmin", isAdmin(player)) -- клиент показывает панель, но права всё равно проверяет сервер
	-- Пока игрока не было, рыбы приносили часть дохода
	local now = os.time()
	local gained = Economy.applyOffline(profile, now)
	profile.lastSeen = now
	if gained > 0 then
		pendingOffline[player] = gained
	end
	loaded[player] = true
	if ready[player] then
		pushState(player)
	end
end

local function onPlayerRemoving(player)
	loaded[player] = nil
	ready[player] = nil
	buckets[player] = nil
	pendingOffline[player] = nil
	PlayerData.release(player) -- финальное сохранение и снятие блокировки
end

-- Клиент готов принимать данные: присылаем состояние (если профиль уже загружен)
clientReadyEvent.OnServerEvent:Connect(function(player)
	if not allow(player, "ClientReady", 1, 3) then
		return
	end
	ready[player] = true
	if loaded[player] then
		pushState(player)
	end
end)

-- ===== Открытие пака =====
-- Клиент присылает только id пака. Цену, шансы и результат сервер берёт сам.
openPackEvent.OnServerEvent:Connect(function(player, packId)
	if not allow(player, "OpenPack", 2, 3) then
		return
	end
	if typeof(packId) ~= "string" then
		return
	end
	local pack = FishConfig.Packs[packId]
	if pack == nil then
		return
	end

	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end

	-- Отказы — ДО списания монет
	if #profile.fish >= profile.slots then
		packResultEvent:FireClient(player, { ok = false, reason = "full" })
		return
	end
	if profile.coins < pack.price then
		packResultEvent:FireClient(player, { ok = false, reason = "coins" })
		return
	end

	profile.coins -= pack.price

	local speciesId, rarity = PackRoller.roll(pack)
	local fishId = profile.nextFishId
	profile.nextFishId += 1
	local variant = FishConfig.rollVariant()
	table.insert(profile.fish, { id = fishId, species = speciesId, variant = variant, born = os.time(), earned = 0 })

	local isNew = not profile.discovered[speciesId]
	profile.discovered[speciesId] = true
	statsFor(profile, speciesId).pulled += 1

	print(player.Name, "открыл", packId, "->", speciesId, "монет:", profile.coins, "рыб:", #profile.fish)
	sendCoins(player, profile)
	sendFish(player, profile)
	sendCollection(player, profile)
	packResultEvent:FireClient(player, { ok = true, species = speciesId, rarity = rarity, variant = variant, isNew = isNew })
end)

-- ===== Покупка места в аквариуме =====
-- Аргументов нет: цену следующего места сервер берёт из FishConfig.SlotPrices.
buySlotEvent.OnServerEvent:Connect(function(player)
	if not allow(player, "BuySlot", 2, 3) then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	if profile.slots >= FishConfig.MAX_SLOTS then
		return
	end
	local price = FishConfig.SlotPrices[profile.slots + 1]
	if price == nil then
		return
	end
	if profile.coins < price then
		packResultEvent:FireClient(player, { ok = false, reason = "coins" })
		return
	end

	profile.coins -= price
	profile.slots += 1
	print(player.Name, "купил место, всего мест:", profile.slots, "монет:", profile.coins)
	sendCoins(player, profile)
	sendFish(player, profile) -- вместе со списком рыб уходит число мест
end)

-- ===== Продажа =====
-- Клиент присылает только id рыбы. Цену продажи сервер берёт из FishConfig.
sellFishEvent.OnServerEvent:Connect(function(player, fishId)
	if not allow(player, "SellFish", 4, 6) then
		return
	end

	-- Валидация аргумента: тип -> NaN -> целое число
	if typeof(fishId) ~= "number" then
		return
	end
	if fishId ~= fishId or fishId ~= math.floor(fishId) then
		return
	end

	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end

	for index, fish in ipairs(profile.fish) do
		if fish.id == fishId then
			local price = FishConfig.sellPriceOf(fish.species, fish.variant, os.time() - fish.born)
			table.remove(profile.fish, index)
			profile.coins += price
			sendCoins(player, profile)
			sendFish(player, profile)
			return
		end
	end
	-- рыбы с таким id у игрока нет — молча игнорируем
end)

-- ===== Админ-команды (только Studio и владелец игры) =====
-- Клиент присылает (команда, значение); права и значения сервер проверяет сам.
local MAX_ADMIN_COINS = 1e9
local MAX_ADMIN_AGE = 7 * 24 * 3600

local function isInteger(value)
	return typeof(value) == "number" and value == value and value == math.floor(value)
end

adminCommandEvent.OnServerEvent:Connect(function(player, cmd, value, extra)
	if not isAdmin(player) then
		return
	end
	if not allow(player, "Admin", 4, 6) then
		return
	end
	if typeof(cmd) ~= "string" then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end

	if cmd == "coins" then
		if not isInteger(value) or math.abs(value) > MAX_ADMIN_COINS then
			return
		end
		profile.coins = math.max(0, profile.coins + value)
	elseif cmd == "slots" then
		if not isInteger(value) or value < FishConfig.START_SLOTS or value > FishConfig.MAX_SLOTS then
			return
		end
		profile.slots = value
	elseif cmd == "fish" then
		if typeof(value) ~= "string" or FishConfig.Species[value] == nil then
			return
		end
		if extra ~= nil and (typeof(extra) ~= "string" or FishConfig.Variants[extra] == nil) then
			return
		end
		if #profile.fish >= profile.slots then
			packResultEvent:FireClient(player, { ok = false, reason = "full" })
			return
		end
		local fishId = profile.nextFishId
		profile.nextFishId += 1
		table.insert(profile.fish, { id = fishId, species = value, variant = extra or "normal", born = os.time(), earned = 0 })
		profile.discovered[value] = true
		statsFor(profile, value).pulled += 1
	elseif cmd == "age" then
		if not isInteger(value) or value < 0 or value > MAX_ADMIN_AGE then
			return
		end
		for _, fish in ipairs(profile.fish) do
			fish.born -= value
		end
	elseif cmd == "reset" then
		profile = PlayerData.reset(player)
		if profile == nil then
			return
		end
	else
		return
	end

	print("[Admin]", player.Name, cmd, value)
	pushState(player)
end)

-- ===== Пассивный доход =====
-- Каждая рыба приносит монеты; плюсуем и к статистике рыбы, и к статистике вида
task.spawn(function()
	while true do
		task.wait(FishConfig.INCOME_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = PlayerData.get(player)
			if profile ~= nil and #profile.fish > 0 then
				Economy.applyIncome(profile, 1, os.time())
				if ready[player] then
					sendCoins(player, profile)
					sendFish(player, profile)
					sendCollection(player, profile)
				end
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.spawn(onPlayerAdded, player) -- загрузка данных может длиться, не блокируем событие
end)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Сохраняем всех при закрытии сервера
game:BindToClose(PlayerData.releaseAll)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
