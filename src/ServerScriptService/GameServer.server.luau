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
local DailyReward = require(ServerScriptService:WaitForChild("DailyReward"))
local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local Shop = require(ServerScriptService:WaitForChild("Shop"))
local Telemetry = require(ServerScriptService:WaitForChild("Telemetry"))
local Collection = require(ServerScriptService:WaitForChild("Collection"))
local Merge = require(ServerScriptService:WaitForChild("Merge"))
local Badges = require(ServerScriptService:WaitForChild("Badges"))
local Currents = require(ServerScriptService:WaitForChild("Currents"))
local Visitors = require(ServerScriptService:WaitForChild("Visitors"))

-- ===== НАСТРОЙКИ =====
-- Аквариумы игрока лежат в профиле (profile.tanks[id] = { slots, fish }), максимум мест и цены — в FishConfig.
-- =====================

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local openPackEvent = remotes:WaitForChild("OpenPack")
local packResultEvent = remotes:WaitForChild("PackResult")
local collectionChangedEvent = remotes:WaitForChild("CollectionChanged")
local sellFishEvent = remotes:WaitForChild("SellFish")
local mergeFishEvent = remotes:WaitForChild("MergeFish")
local setsChangedEvent = remotes:WaitForChild("SetsChanged")
local visitorsStateEvent = remotes:WaitForChild("VisitorsState")
local visitorActionEvent = remotes:WaitForChild("VisitorAction")
local coinsChangedEvent = remotes:WaitForChild("CoinsChanged")
local fishChangedEvent = remotes:WaitForChild("FishChanged")
local clientReadyEvent = remotes:WaitForChild("ClientReady")
local buySlotEvent = remotes:WaitForChild("BuySlot")
local adminCommandEvent = remotes:WaitForChild("AdminCommand")
local offlineIncomeEvent = remotes:WaitForChild("OfflineIncome")
local buyTankEvent = remotes:WaitForChild("BuyTank")
local claimDailyEvent = remotes:WaitForChild("ClaimDaily")
local dailyStateEvent = remotes:WaitForChild("DailyState")
local tutorialDoneEvent = remotes:WaitForChild("TutorialDone")
local shopStateEvent = remotes:WaitForChild("ShopState")
local settingsEvent = remotes:WaitForChild("Settings")
local currentStateEvent = remotes:WaitForChild("CurrentState")

-- ===== Покупки за Robux =====
-- Геймпасс «x2 монеты» проверяем у MarketplaceService при входе и после покупки; результат помним на сервере.
local passOwned = {} -- player -> { doubleCoins = true, nightWatch = true, secondHall = true, quickOpen = true }
-- Какой пасс за что отвечает (id берём из FishConfig.Shop; пока id = 0, пасс не продаётся)
local PASSES = {
	doubleCoins = FishConfig.Shop.DoubleCoins,
	nightWatch = FishConfig.Shop.NightWatch,
	secondHall = FishConfig.Shop.SecondHall,
	quickOpen = FishConfig.Shop.QuickOpen,
}
local function owns(player, key)
	local owned = passOwned[player]
	return owned ~= nil and owned[key] == true
end
-- Платный рандом (паки за монеты, а монеты продаются за Robux) ограничен в части стран.
-- Там покупки за Robux скрываем целиком: игрок получает монеты только игрой. Если не удалось узнать — считаем, что ограничено.
local paidRandomRestricted = {} -- player -> true
local function refreshPolicy(player)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if ok and typeof(info) == "table" then
		paidRandomRestricted[player] = info.ArePaidRandomItemsRestricted == true
	else
		paidRandomRestricted[player] = true
	end
end
local function incomeMultiplier(player)
	if owns(player, "doubleCoins") then
		return FishConfig.Shop.DoubleCoins.mult
	end
	return 1
end
-- Лимит накопления дохода в офлайне (с пассом Night Watchman больше)
local function offlineCap(player)
	if owns(player, "nightWatch") and FishConfig.Shop.NightWatch.passId ~= 0 then
		return FishConfig.Shop.NightWatch.offlineMax
	end
	return FishConfig.OFFLINE_MAX
end
-- Сколько гостей в очереди музея (с пассом Second Hall больше)
local function queueSize(player)
	local size = FishConfig.Visitors.QUEUE_SIZE
	if owns(player, "secondHall") and FishConfig.Shop.SecondHall.passId ~= 0 then
		size += FishConfig.Shop.SecondHall.extraQueue
	end
	return size
end
-- Сколько паков открывает кнопка «пачкой» (1 без пасса Quick Open)
local function quickPacks(player)
	if owns(player, "quickOpen") and FishConfig.Shop.QuickOpen.passId ~= 0 then
		return FishConfig.Shop.QuickOpen.packs
	end
	return 1
end
local function sendShopState(player)
	local profile = PlayerData.get(player)
	shopStateEvent:FireClient(player, {
		doubleCoins = owns(player, "doubleCoins"),
		nightWatch = owns(player, "nightWatch"),
		secondHall = owns(player, "secondHall"),
		quickOpen = owns(player, "quickOpen"),
		restricted = paidRandomRestricted[player] ~= false,
		starter = if profile ~= nil then Shop.starterOffer(profile, os.time()) else nil, -- секунд до конца предложения или nil
	})
end
local function refreshPasses(player)
	for key, pass in pairs(PASSES) do
		if pass.passId ~= 0 then
			local ok, has = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.passId)
			end)
			if ok and has then
				local owned = passOwned[player]
				if owned == nil then
					owned = {}
					passOwned[player] = owned
				end
				owned[key] = true
			end
		end
	end
end

-- ===== Аналитика: воронка «где игроки бросают игру» (шаги видны в Creator Hub -> Analytics) =====
-- 1 зашёл, 2 открыл первый пак, 3 прошёл обучение, 4 забрал ежедневную награду, 5 купил второй аквариум.
local FUNNEL_STEPS = { "joined", "first_pack", "tutorial_done", "daily_claimed", "second_tank" }
local funnelSent = {} -- [player] = { [step] = true }, чтобы каждый шаг слать один раз за сессию
local function trackStep(player, step)
	local sent = funnelSent[player]
	if sent == nil then
		sent = {}
		funnelSent[player] = sent
	end
	if sent[step] then
		return
	end
	sent[step] = true
	-- Аналитика не должна ломать игру: любые ошибки гасим
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, FUNNEL_STEPS[step])
	end)
end

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

-- Музей: очередь гостей, билеты, ранг. notice (необязательно) — разовое сообщение клиенту, например награда за заказ.
-- Вызывается и вместе со списком рыб: от рыб зависит, можно ли сейчас выполнить заказ.
local function sendVisitors(player, profile, notice)
	local now = os.time()
	local size = queueSize(player)
	Visitors.refresh(profile, now, nil, size)
	local state = Visitors.summary(profile, now, size)
	state.notice = notice
	visitorsStateEvent:FireClient(player, state)
end

-- Рыбы всех аквариумов со статистикой (id, аквариум, вид, вариант, возраст в секундах, заработок)
-- и число мест в каждом открытом аквариуме: { [tankId] = slots }
-- Течение и мутации: состояние для клиента; event — только что начавшееся/закончившееся течение (для уведомления)
local function sendCurrent(player, profile, event)
	local summary = Currents.summary(profile, os.time())
	summary.event = event
	currentStateEvent:FireClient(player, summary)
end

-- Таблица игроков: сколько рыб и какой ранг музея (видно друзьям на том же сервере)
local function updateLeaderstats(player, profile)
	local stats = player:FindFirstChild("leaderstats")
	if stats == nil then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		for _, name in ipairs({ "Fish", "Museum" }) do
			local value = Instance.new("IntValue")
			value.Name = name
			value.Parent = stats
		end
		stats.Parent = player
	end
	local fish = stats:FindFirstChild("Fish")
	local museum = stats:FindFirstChild("Museum")
	if fish then
		fish.Value = Economy.fishCount(profile)
	end
	if museum then
		museum.Value = Visitors.rank(if profile.visitors then profile.visitors.completed or 0 else 0)
	end
end

local function sendFish(player, profile, event)
	local now = os.time()
	local list = {}
	local tanksInfo = {}
	for tankId, tankData in pairs(profile.tanks) do
		tanksInfo[tankId] = tankData.slots
		for _, fish in ipairs(tankData.fish) do
			table.insert(list, {
				id = fish.id,
				tank = tankId,
				species = fish.species,
				variant = fish.variant or "normal",
				age = math.max(0, now - fish.born),
				earned = fish.earned,
				mutation = fish.mutation,
			})
		end
	end
	fishChangedEvent:FireClient(player, list, tanksInfo)
	sendVisitors(player, profile)
	sendCurrent(player, profile, event)
	updateLeaderstats(player, profile)
	Badges.sync(player, profile)
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

-- Наборы коллекции: прогресс по ступеням и бонус к доходу каждого аквариума
local function sendSets(player, profile)
	Collection.sync(profile) -- дописываем в память игрока всех рыб, что сейчас в аквариумах
	setsChangedEvent:FireClient(player, Collection.summary(profile))
end

local function pushState(player)
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	sendCoins(player, profile)
	sendFish(player, profile)
	sendCollection(player, profile)
	sendSets(player, profile)

	dailyStateEvent:FireClient(player, DailyReward.state(profile, os.time()))
	tutorialDoneEvent:FireClient(player, profile.tutorialDone)
	sendShopState(player)
	settingsEvent:FireClient(player, profile.settings)

	local offline = pendingOffline[player]
	if offline then
		pendingOffline[player] = nil
		offlineIncomeEvent:FireClient(player, offline.gained, offline.capped) -- capped: копилка заполнилась до предела
	end
end

-- ===== Вход / выход =====
local function onPlayerAdded(player)
	local profile, reason = PlayerData.load(player)
	if profile == nil then
		-- Не даём играть с пустым профилем: его сохранение перезапишет настоящий
		if reason == "locked" then
			player:Kick("Your data is still saving on another server. Please rejoin in a minute. / Ваши данные ещё сохраняются на другом сервере. Зайдите снова через минуту.")
		elseif reason ~= "left" then
			player:Kick("Could not load your data. Your progress is safe, please rejoin. / Не удалось загрузить данные. Прогресс не потерян, зайдите снова.")
		end
		return
	end
	player:SetAttribute("IsAdmin", isAdmin(player)) -- клиент показывает панель, но права всё равно проверяет сервер
	-- Пока игрока не было, рыбы приносили часть дохода
	local now = os.time()
	refreshPasses(player)
	refreshPolicy(player)
	profile.sessions = (profile.sessions or 0) + 1
	Currents.reset(profile, now) -- течения идут только пока игрок в игре
	local gained, capped = Economy.applyOffline(profile, now, incomeMultiplier(player), offlineCap(player))
	profile.lastSeen = now
	if gained > 0 then
		pendingOffline[player] = { gained = gained, capped = capped }
		Telemetry.source(player, gained, profile.coins, Telemetry.TxType.Gameplay, "offline_income")
	end
	loaded[player] = true
	trackStep(player, 1)
	if ready[player] then
		pushState(player)
	end
end

local function onPlayerRemoving(player)
	loaded[player] = nil
	ready[player] = nil
	buckets[player] = nil
	pendingOffline[player] = nil
	funnelSent[player] = nil
	passOwned[player] = nil
	Badges.forget(player)
	do
		local leaving = PlayerData.get(player)
		if leaving ~= nil then
			Telemetry.flush(player, leaving.coins)
		end
		Telemetry.forget(player)
	end
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
openPackEvent.OnServerEvent:Connect(function(player, packId, count)
	if not allow(player, "OpenPack", 2, 3) then
		return
	end
	if typeof(packId) ~= "string" then
		return
	end
	-- count необязателен: 1 или (с пассом Quick Open) число паков «пачкой»; всё остальное считаем одним паком
	local times = 1
	if typeof(count) == "number" and count == quickPacks(player) and count > 1 then
		times = count
	end
	local pack = FishConfig.Packs[packId]
	if pack == nil then
		return
	end

	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end

	-- Аквариум пака должен быть открыт
	local tankData = profile.tanks[pack.tank]
	if tankData == nil then
		return
	end

	local opened = 0
	local failReason = nil
	for _ = 1, times do
		-- Отказы — ДО списания монет
		if #tankData.fish >= tankData.slots then
			failReason = "full"
			break
		end
		if profile.coins < pack.price then
			failReason = "coins"
			break
		end

		profile.coins -= pack.price
		Telemetry.sink(player, pack.price, profile.coins, Telemetry.TxType.Shop, "pack_" .. packId)

		local speciesId, rarity = PackRoller.roll(pack)
		local fishId = profile.nextFishId
		profile.nextFishId += 1
		local variant = FishConfig.rollVariant()
		table.insert(tankData.fish, { id = fishId, species = speciesId, variant = variant, born = os.time(), earned = 0 })

		local isNew = not profile.discovered[speciesId]
		profile.discovered[speciesId] = true
		statsFor(profile, speciesId).pulled += 1
		opened += 1

		print(player.Name, "открыл", packId, "->", speciesId, "монет:", profile.coins, "рыб:", #tankData.fish)
		-- fast: результаты «пачки» показываем без долгой анимации
		packResultEvent:FireClient(player, { ok = true, species = speciesId, rarity = rarity, variant = variant, isNew = isNew, fast = times > 1 })
	end

	if opened > 0 then
		sendCoins(player, profile)
		sendFish(player, profile)
		sendCollection(player, profile)
		sendSets(player, profile)
		trackStep(player, 2)
	elseif failReason ~= nil then
		packResultEvent:FireClient(player, { ok = false, reason = failReason })
	end
end)

-- ===== Слияние =====
-- Клиент присылает только id выбранной рыбы; остальных рыб, результат и награду выбирает сервер (см. Merge).
mergeFishEvent.OnServerEvent:Connect(function(player, fishId)
	if not allow(player, "MergeFish", 2, 3) then
		return
	end
	if typeof(fishId) ~= "number" or fishId ~= fishId or fishId ~= math.floor(fishId) then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	local ok, newFish, isNewVariant = Merge.perform(profile, fishId, os.time())
	if not ok then
		if newFish == "count" or newFish == "max" then
			packResultEvent:FireClient(player, { ok = false, reason = "merge" })
		end
		return
	end
	local species = FishConfig.Species[newFish.species]
	print(player.Name, "слил рыб ->", newFish.species, newFish.variant)
	sendFish(player, profile)
	sendCollection(player, profile)
	sendSets(player, profile)
	packResultEvent:FireClient(player, {
		ok = true,
		merged = true,
		species = newFish.species,
		rarity = species.rarity,
		variant = newFish.variant,
		isNew = isNewVariant,
	})
end)

-- ===== Музей: заказы гостей и траты билетов =====
-- Клиент присылает только действие и id: награду, подходящую рыбу, цены и результат сервер определяет сам.
--   ("fulfill", orderId) — показать рыбу гостю; ("shop", "rarepack", tankId) / ("shop", "slot", tankId) — потратить билеты.
visitorActionEvent.OnServerEvent:Connect(function(player, action, a, b)
	if not allow(player, "Visitors", 3, 6) then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end

	if action == "fulfill" then
		if typeof(a) ~= "number" or a ~= a or a ~= math.floor(a) then
			return
		end
		local ok, info = Visitors.fulfill(profile, a, os.time(), queueSize(player))
		if ok then
			print(player.Name, "показал рыбу гостю: +" .. info.tickets, "билетов, ранг", info.rank)
			sendVisitors(player, profile, { kind = "reward", tickets = info.tickets, rank = info.rank, rankUp = info.rankUp })
		else
			sendVisitors(player, profile, { kind = "fail", reason = info })
		end
		return
	end

	if action ~= "shop" or typeof(a) ~= "string" or typeof(b) ~= "string" then
		return
	end
	local item = FishConfig.Visitors.Shop[a]
	local tankData = profile.tanks[b]
	if item == nil or tankData == nil then
		return
	end

	if a == "rarepack" then
		if #tankData.fish >= tankData.slots then
			packResultEvent:FireClient(player, { ok = false, reason = "full" })
			return
		end
		if not Visitors.spend(profile, item.price) then
			sendVisitors(player, profile, { kind = "fail", reason = "tickets" })
			return
		end
		local speciesId, rarity = PackRoller.roll({ tank = b, odds = item.odds })
		local variant = FishConfig.rollVariant()
		table.insert(tankData.fish, { id = profile.nextFishId, species = speciesId, variant = variant, born = os.time(), earned = 0 })
		profile.nextFishId += 1
		local isNew = not profile.discovered[speciesId]
		profile.discovered[speciesId] = true
		statsFor(profile, speciesId).pulled += 1
		print(player.Name, "открыл пак за билеты ->", speciesId, variant)
		sendFish(player, profile)
		sendCollection(player, profile)
		sendSets(player, profile)
		packResultEvent:FireClient(player, { ok = true, species = speciesId, rarity = rarity, variant = variant, isNew = isNew })
	elseif a == "slot" then
		-- дополнительные места сверх лимита монетных мест: только когда монетные места куплены все
		local extra = tankData.slots - FishConfig.MAX_SLOTS
		if extra < 0 or extra >= item.maxBonus then
			sendVisitors(player, profile, { kind = "fail", reason = "slotlimit" })
			return
		end
		if not Visitors.spend(profile, item.price * (extra + 1)) then
			sendVisitors(player, profile, { kind = "fail", reason = "tickets" })
			return
		end
		tankData.slots += 1
		print(player.Name, "купил за билеты место в", b, "всего мест:", tankData.slots)
		sendFish(player, profile)
	end
end)

-- ===== Ежедневная награда =====
-- Клиент присылает только намерение «забрать»: день, серию и сумму считает сервер.
claimDailyEvent.OnServerEvent:Connect(function(player)
	if not allow(player, "ClaimDaily", 1, 2) then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	local reward = DailyReward.claim(profile, os.time())
	if reward == nil then
		return
	end
	Telemetry.source(player, reward, profile.coins, Telemetry.TxType.TimedReward, "daily_reward")
	trackStep(player, 4)
	sendCoins(player, profile)
	dailyStateEvent:FireClient(player, DailyReward.state(profile, os.time()))
end)

-- ===== Обучение пройдено (клиент сообщает один раз; на экономику это не влияет) =====
tutorialDoneEvent.OnServerEvent:Connect(function(player)
	if not allow(player, "TutorialDone", 1, 2) then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil or profile.tutorialDone then
		return
	end
	profile.tutorialDone = true
	trackStep(player, 3)
end)

-- ===== Настройки звука (клиент присылает две галочки; ничего, кроме true/false, не принимаем) =====
settingsEvent.OnServerEvent:Connect(function(player, value)
	if not allow(player, "Settings", 2, 4) then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil or typeof(value) ~= "table" then
		return
	end
	if typeof(value.sfx) ~= "boolean" or typeof(value.music) ~= "boolean" then
		return
	end
	profile.settings = { sfx = value.sfx, music = value.music }
end)

-- ===== Покупка места в аквариуме =====
-- Клиент присылает только id аквариума: цену следующего места сервер берёт из FishConfig.
buySlotEvent.OnServerEvent:Connect(function(player, tankId)
	if not allow(player, "BuySlot", 2, 3) then
		return
	end
	if typeof(tankId) ~= "string" then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	local tankData = profile.tanks[tankId]
	if tankData == nil or tankData.slots >= FishConfig.MAX_SLOTS then
		return
	end
	local price = FishConfig.slotPrice(tankId, tankData.slots + 1)
	if price == nil then
		return
	end
	if profile.coins < price then
		packResultEvent:FireClient(player, { ok = false, reason = "coins" })
		return
	end

	profile.coins -= price
	Telemetry.sink(player, price, profile.coins, Telemetry.TxType.Shop, "slot_" .. tankId)
	tankData.slots += 1
	print(player.Name, "купил место в", tankId, "всего мест:", tankData.slots, "монет:", profile.coins)
	sendCoins(player, profile)
	sendFish(player, profile) -- вместе со списком рыб уходит число мест
end)

-- ===== Покупка нового аквариума =====
-- Клиент присылает только id аквариума; цену берёт сервер.
buyTankEvent.OnServerEvent:Connect(function(player, tankId)
	if not allow(player, "BuyTank", 2, 3) then
		return
	end
	if typeof(tankId) ~= "string" then
		return
	end
	local def = FishConfig.Tanks[tankId]
	if def == nil then
		return
	end
	local profile = PlayerData.get(player)
	if profile == nil or profile.tanks[tankId] ~= nil then
		return
	end
	if profile.coins < def.price then
		packResultEvent:FireClient(player, { ok = false, reason = "coins" })
		return
	end

	profile.coins -= def.price
	Telemetry.sink(player, def.price, profile.coins, Telemetry.TxType.Shop, "tank_" .. tankId)
	profile.tanks[tankId] = FishConfig.newTank()
	print(player.Name, "открыл аквариум", tankId, "монет:", profile.coins)
	trackStep(player, 5)
	sendCoins(player, profile)
	sendFish(player, profile)
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

	for _, tankData in pairs(profile.tanks) do
		for index, fish in ipairs(tankData.fish) do
			if fish.id == fishId then
				local price = FishConfig.sellPriceOf(fish.species, fish.variant, os.time() - fish.born)
				table.remove(tankData.fish, index)
				profile.coins += price
				Telemetry.source(player, price, profile.coins, Telemetry.TxType.Shop, "sell_fish")
				sendCoins(player, profile)
				sendFish(player, profile)
				return
			end
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
		local tankData = profile.tanks[if typeof(extra) == "string" then extra else "lagoon"]
		if tankData == nil then
			return
		end
		tankData.slots = value
	elseif cmd == "fish" then
		if typeof(value) ~= "string" or FishConfig.Species[value] == nil then
			return
		end
		if extra ~= nil and (typeof(extra) ~= "string" or FishConfig.Variants[extra] == nil) then
			return
		end
		local tankId = FishConfig.Species[value].tank
		local tankData = profile.tanks[tankId]
		if tankData == nil then
			tankData = FishConfig.newTank()
			profile.tanks[tankId] = tankData
		end
		if #tankData.fish >= tankData.slots then
			packResultEvent:FireClient(player, { ok = false, reason = "full" })
			return
		end
		local fishId = profile.nextFishId
		profile.nextFishId += 1
		table.insert(tankData.fish, { id = fishId, species = value, variant = extra or "normal", born = os.time(), earned = 0 })
		profile.discovered[value] = true
		statsFor(profile, value).pulled += 1
	elseif cmd == "age" then
		if not isInteger(value) or value < 0 or value > MAX_ADMIN_AGE then
			return
		end
		for _, tankData in pairs(profile.tanks) do
			for _, fish in ipairs(tankData.fish) do
				fish.born -= value
			end
		end
	elseif cmd == "unlock" then
		for _, tankId in ipairs(FishConfig.TankOrder) do
			if profile.tanks[tankId] == nil then
				profile.tanks[tankId] = FishConfig.newTank()
			end
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

-- ===== Обработка покупок за Robux =====
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased or passId == 0 then
		return
	end
	for key, pass in pairs(PASSES) do
		if pass.passId == passId then
			local owned = passOwned[player]
			if owned == nil then
				owned = {}
				passOwned[player] = owned
			end
			owned[key] = true
			sendShopState(player)
			local profile = PlayerData.get(player)
			if profile ~= nil then
				sendVisitors(player, profile) -- Second Hall сразу добавляет места в очереди
			end
		end
	end
end)

-- Товары «монеты»: выдаём по чеку один раз. Пока профиль не загружен, чек не подтверждаем (Roblox повторит позже).
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local coinsBefore = profile.coins
	local result = Shop.grant(profile, receiptInfo.ProductId, tostring(receiptInfo.PurchaseId), os.time())
	if result == "unknown" then
		warn("[Shop] неизвестный товар", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if result == "granted" then
		local product = Shop.productById(receiptInfo.ProductId)
		Telemetry.source(player, profile.coins - coinsBefore, profile.coins, Telemetry.TxType.IAP, product and product.key or "coin_product")
		-- Сразу сохраняем: деньги за Robux не должны потеряться при сбое сервера
		task.spawn(PlayerData.save, player)
		sendCoins(player, profile)
		sendFish(player, profile) -- стартовый набор добавляет рыбу и билеты
		sendCollection(player, profile)
		sendSets(player, profile)
		sendShopState(player) -- предложение стартового набора после покупки исчезает
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ===== Аналитика: раз в минуту отправляем накопленный доход рыб =====
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = PlayerData.get(player)
			if profile ~= nil then
				Telemetry.flush(player, profile.coins)
			end
		end
	end
end)

-- ===== Пассивный доход =====
-- Каждая рыба приносит монеты; плюсуем и к статистике рыбы, и к статистике вида
task.spawn(function()
	while true do
		task.wait(FishConfig.INCOME_INTERVAL)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = PlayerData.get(player)
			if profile ~= nil and Economy.fishCount(profile) > 0 then
				local event = Currents.update(profile, os.time())
				local earned = Economy.applyIncome(profile, 1, os.time(), incomeMultiplier(player))
				Telemetry.addIncome(player, "fish_income", earned)
				if ready[player] then
					sendCoins(player, profile)
					sendFish(player, profile, event)
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
