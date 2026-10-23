-- FishConfig: каталог рыб и общие настройки. Сервер берёт отсюда цены и доход,
-- клиент — только внешний вид (эмодзи, название). Править баланс нужно ТОЛЬКО здесь.

local FishConfig = {}

-- Как часто (сек) рыбы приносят монеты
FishConfig.INCOME_INTERVAL = 5

-- Редкости: название и цвет (для будущих паков и интерфейса)
FishConfig.Rarities = {
	common = { name = "Обычная", color = Color3.fromRGB(176, 190, 197) },
	rare = { name = "Редкая", color = Color3.fromRGB(79, 195, 247) },
	epic = { name = "Эпическая", color = Color3.fromRGB(186, 104, 200) },
	legendary = { name = "Легендарная", color = Color3.fromRGB(255, 202, 40) },
}

-- Виды рыб.
--   income    — монет за один тик дохода (каждые INCOME_INTERVAL секунд)
--   sellPrice — за сколько можно продать
--   tank      — в каком аквариуме живёт вид (см. FishConfig.Tanks)
FishConfig.Species = {
	-- Тихая лагуна
	guppy = { tank = "lagoon", name = "Гуппи", emoji = "🐟", rarity = "common", income = 1, sellPrice = 5 },
	clown = { tank = "lagoon", name = "Клоун", emoji = "🐠", rarity = "common", income = 2, sellPrice = 8 },
	puffer = { tank = "lagoon", name = "Фугу", emoji = "🐡", rarity = "rare", income = 4, sellPrice = 20 },
	whale = { tank = "lagoon", name = "Кит", emoji = "🐳", rarity = "epic", income = 10, sellPrice = 60 },
	octopus = { tank = "lagoon", name = "Осьминог", emoji = "🐙", rarity = "legendary", income = 25, sellPrice = 150 },
	-- Вулканический риф
	ember_shrimp = { tank = "volcano", name = "Лавовая креветка", emoji = "🦐", rarity = "common", income = 8, sellPrice = 40 },
	magma_crab = { tank = "volcano", name = "Магмовый краб", emoji = "🦀", rarity = "common", income = 12, sellPrice = 55 },
	fire_eel = { tank = "volcano", name = "Огненный угорь", emoji = "🐍", rarity = "rare", income = 32, sellPrice = 160 },
	caldera_squid = { tank = "volcano", name = "Кальмар кальдеры", emoji = "🦑", rarity = "epic", income = 80, sellPrice = 480 },
	magma_dragon = { tank = "volcano", name = "Магмовый дракон", emoji = "🐉", rarity = "legendary", income = 200, sellPrice = 1200 },
	-- Ледяной грот
	penguin = { tank = "arctic", name = "Пингвин", emoji = "🐧", rarity = "common", income = 60, sellPrice = 300 },
	seal = { tank = "arctic", name = "Тюлень", emoji = "🦭", rarity = "common", income = 100, sellPrice = 450 },
	polar_shark = { tank = "arctic", name = "Полярная акула", emoji = "🦈", rarity = "rare", income = 240, sellPrice = 1200 },
	beluga = { tank = "arctic", name = "Белуха", emoji = "🐋", rarity = "epic", income = 600, sellPrice = 3600 },
	narwhal = { tank = "arctic", name = "Нарвал", emoji = "🦄", rarity = "legendary", income = 1500, sellPrice = 9000 },
	-- Бездна
	lantern_fish = { tank = "abyss", name = "Рыба-фонарик", emoji = "🔦", rarity = "common", income = 400, sellPrice = 2400 },
	jellyfish = { tank = "abyss", name = "Медуза", emoji = "🪼", rarity = "common", income = 700, sellPrice = 4200 },
	anglerfish = { tank = "abyss", name = "Удильщик", emoji = "🎣", rarity = "rare", income = 1600, sellPrice = 9600 },
	abyss_ray = { tank = "abyss", name = "Глубинный скат", emoji = "🪽", rarity = "epic", income = 4000, sellPrice = 24000 },
	-- Призрачный пруд (ивент «Хэллоуин»): виды доступны только из Тыквенного пака во время ивента, но остаются навсегда
	pumpkin_fish = { tank = "haunted", name = "Тыквенная рыбка", emoji = "🎃", rarity = "common", income = 15, sellPrice = 60 },
	ghost_guppy = { tank = "haunted", name = "Призрачная гуппи", emoji = "👻", rarity = "common", income = 20, sellPrice = 80 },
	bat_ray = { tank = "haunted", name = "Скат-нетопырь", emoji = "🦇", rarity = "rare", income = 50, sellPrice = 250 },
	bone_fish = { tank = "haunted", name = "Рыба-скелет", emoji = "💀", rarity = "epic", income = 120, sellPrice = 700 },
	jack_angler = { tank = "haunted", name = "Удильщик Джек", emoji = "🕯️", rarity = "legendary", income = 300, sellPrice = 1800 },
	leviathan = { tank = "abyss", name = "Левиафан", emoji = "🐲", rarity = "legendary", income = 10000, sellPrice = 60000 },

	-- ===== Пакет v06: ещё 25 видов (по 5 на аквариум); цифры подобраны рядом с видами той же редкости =====
	-- Тихая лагуна
	mandarin = { tank = "lagoon", name = "Мандаринка", emoji = "🐠", rarity = "rare", income = 5, sellPrice = 25 },
	sun_boxfish = { tank = "lagoon", name = "Солнечный кузовок", emoji = "☀️", rarity = "common", income = 2, sellPrice = 9 },
	reef_pennant = { tank = "lagoon", name = "Рифовый вымпел", emoji = "🎏", rarity = "rare", income = 4, sellPrice = 22 },
	petal_flyingfish = { tank = "lagoon", name = "Летучка-лепесток", emoji = "🌸", rarity = "rare", income = 5, sellPrice = 26 },
	saffron_garden_eel = { tank = "lagoon", name = "Шафрановый садовник", emoji = "🪱", rarity = "rare", income = 6, sellPrice = 30 },
	-- Вулканический риф
	ember_lionfish = { tank = "volcano", name = "Угольная крылатка", emoji = "🔥", rarity = "epic", income = 88, sellPrice = 520 },
	basalt_limpet = { tank = "volcano", name = "Базальтовый колпачок", emoji = "🪨", rarity = "common", income = 9, sellPrice = 45 },
	cinder_horseshoe = { tank = "volcano", name = "Пепельный мечехвост", emoji = "🦀", rarity = "rare", income = 34, sellPrice = 170 },
	kiln_chiton = { tank = "volcano", name = "Печной хитон", emoji = "🐛", rarity = "common", income = 10, sellPrice = 48 },
	kiln_cuttlefish = { tank = "volcano", name = "Печная каракатица", emoji = "🦑", rarity = "rare", income = 36, sellPrice = 180 },
	-- Ледяной грот
	sea_angel = { tank = "arctic", name = "Морской ангел", emoji = "👼", rarity = "rare", income = 250, sellPrice = 1260 },
	frost_icefish = { tank = "arctic", name = "Инеевый белокровник", emoji = "🧊", rarity = "common", income = 70, sellPrice = 340 },
	ice_scallop = { tank = "arctic", name = "Ледяной гребешок", emoji = "🦪", rarity = "rare", income = 260, sellPrice = 1300 },
	rime_lumpsucker = { tank = "arctic", name = "Инеевый пинагор", emoji = "🐟", rarity = "rare", income = 270, sellPrice = 1350 },
	snow_bolster_cucumber = { tank = "arctic", name = "Снежная голотурия", emoji = "🥒", rarity = "common", income = 80, sellPrice = 380 },
	-- Бездна
	dusk_nautilus = { tank = "abyss", name = "Сумеречный наутилус", emoji = "🐚", rarity = "epic", income = 4300, sellPrice = 25800 },
	glass_barreleye = { tank = "abyss", name = "Купологлаз", emoji = "🔮", rarity = "rare", income = 1700, sellPrice = 10200 },
	stilt_fish = { tank = "abyss", name = "Рыба-ходульщик", emoji = "🕷️", rarity = "epic", income = 4600, sellPrice = 27600 },
	velvet_gulper = { tank = "abyss", name = "Бархатный большерот", emoji = "👄", rarity = "epic", income = 4800, sellPrice = 28800 },
	knot_hagfish = { tank = "abyss", name = "Узловая миксина", emoji = "🪢", rarity = "epic", income = 5000, sellPrice = 30000 },
	-- Призрачный пруд
	candle_nudibranch = { tank = "haunted", name = "Свечной слизень", emoji = "🕯️", rarity = "rare", income = 55, sellPrice = 275 },
	shroud_flatfish = { tank = "haunted", name = "Камбала-плащ", emoji = "🪦", rarity = "common", income = 18, sellPrice = 72 },
	phantom_seahorse = { tank = "haunted", name = "Конёк-миротворец", emoji = "🐴", rarity = "epic", income = 140, sellPrice = 800 },
	wake_tunicate = { tank = "haunted", name = "Заупокойная асцидия", emoji = "🍶", rarity = "rare", income = 60, sellPrice = 300 },
	pall_brittle_star = { tank = "haunted", name = "Офиура-плакальщица", emoji = "⭐", rarity = "rare", income = 65, sellPrice = 325 },
}

-- Порядок видов (для интерфейса коллекции и шансов)
FishConfig.SpeciesOrder = {
	"guppy", "clown", "puffer", "whale", "octopus",
	"mandarin", "sun_boxfish", "reef_pennant", "petal_flyingfish", "saffron_garden_eel",
	"ember_shrimp", "magma_crab", "fire_eel", "caldera_squid", "magma_dragon",
	"ember_lionfish", "basalt_limpet", "cinder_horseshoe", "kiln_chiton", "kiln_cuttlefish",
	"penguin", "seal", "polar_shark", "beluga", "narwhal",
	"sea_angel", "frost_icefish", "ice_scallop", "rime_lumpsucker", "snow_bolster_cucumber",
	"lantern_fish", "jellyfish", "anglerfish", "abyss_ray", "leviathan",
	"dusk_nautilus", "glass_barreleye", "stilt_fish", "velvet_gulper", "knot_hagfish",
	"pumpkin_fish", "ghost_guppy", "bat_ray", "bone_fish", "jack_angler",
	"candle_nudibranch", "shroud_flatfish", "phantom_seahorse", "wake_tunicate", "pall_brittle_star",
}

-- Исходные 25 видов (до пакета v06). Нужны, чтобы заработанные наборы коллекции не пропали при росте каталога
-- (см. Collection.baselineEarned и миграцию профиля v5 -> v6). Не менять и не дополнять.
FishConfig.BaselineSpecies = {
	guppy = true, clown = true, puffer = true, whale = true, octopus = true,
	ember_shrimp = true, magma_crab = true, fire_eel = true, caldera_squid = true, magma_dragon = true,
	penguin = true, seal = true, polar_shark = true, beluga = true, narwhal = true,
	lantern_fish = true, jellyfish = true, anglerfish = true, abyss_ray = true, leviathan = true,
	pumpkin_fish = true, ghost_guppy = true, bat_ray = true, bone_fish = true, jack_angler = true,
}

-- Аквариумы. У каждого свои рыбы (Species.tank), свой пак и своя цена мест.
--   price         — сколько стоит открыть (0 = есть с самого начала)
--   pack          — id пака этого аквариума (FishConfig.Packs)
--   slotPriceMult — во сколько раз дороже места, чем в лагуне
--   color         — цвет воды (запасной фон)
--   background     — id пиксельного фона в SpriteData
FishConfig.Tanks = {
	lagoon = { name = "Тихая лагуна", emoji = "🌊", price = 0, pack = "lagoon", slotPriceMult = 1, color = Color3.fromRGB(20, 110, 140), background = "bg_lagoon" },
	volcano = { name = "Вулканический риф", emoji = "🌋", price = 5000, pack = "volcano", slotPriceMult = 4, color = Color3.fromRGB(58, 35, 42), background = "bg_volcano" },
	arctic = { name = "Ледяной грот", emoji = "❄️", price = 4000000, pack = "arctic", slotPriceMult = 10, color = Color3.fromRGB(64, 120, 165), background = "bg_arctic" },
	abyss = { name = "Бездна", emoji = "🌌", price = 100000000, pack = "abyss", slotPriceMult = 25, color = Color3.fromRGB(12, 22, 52), background = "bg_abyss" },
}
FishConfig.TankOrder = { "lagoon", "volcano", "arctic", "abyss" }

-- Ивентовые аквариумы: не покупаются за монеты и не входят в обычную цепочку TankOrder.
-- Выдаются бесплатно, пока идёт их ивент (FishConfig.Events), и остаются у игрока навсегда.
FishConfig.Tanks.haunted = {
	name = "Призрачный пруд",
	emoji = "🎃",
	price = 0,
	event = "halloween",
	pack = "haunted",
	slotPriceMult = 2,
	color = Color3.fromRGB(42, 40, 83),
	background = "bg_haunted",
}
FishConfig.EventTankOrder = { "haunted" }

-- Все аквариумы: обычные по порядку, потом ивентовые
function FishConfig.allTanks()
	local list = table.clone(FishConfig.TankOrder)
	for _, id in ipairs(FishConfig.EventTankOrder) do
		table.insert(list, id)
	end
	return list
end

-- ===== Ивенты =====
-- Время — секунды UTC (os.time). Пока ивент идёт, игрок получает его аквариум и валюту (конфеты),
-- пак ивента продаётся только за неё. Источники валюты: подарок при первом входе (welcome), награда за день (daily),
-- конец течения (current), гость музея (половина билетов, museumDiv), и игра онлайн (+1 каждые onlineEvery секунд).
FishConfig.Events = {
	halloween = {
		name = "Хэллоуин",
		emoji = "🎃",
		currency = "🍬",
		startsAt = 1792281600, -- 18.10.2026 00:00 UTC
		endsAt = 1793664000, -- 03.11.2026 00:00 UTC
		tank = "haunted",
		welcome = 30,
		daily = 10,
		current = 5,
		museumDiv = 2,
		onlineEvery = 300,
	},
}

-- Порядок редкостей от частой к редкой
FishConfig.RarityOrder = { "common", "rare", "epic", "legendary" }

-- Паки. odds — шансы РЕДКОСТЕЙ в процентах, сумма должна быть 100.
-- Внутри редкости вид выбирается равновероятно. Выпадение считает только сервер (PackRoller).
-- tank — аквариум, виды которого выпадают из пака (и в который попадает рыба).
FishConfig.Packs = {
	lagoon = {
		name = "Пак лагуны",
		tank = "lagoon",
		price = 50,
		odds = { common = 70, rare = 22, epic = 7, legendary = 1 },
	},
	volcano = {
		name = "Пак вулкана",
		tank = "volcano",
		price = 400,
		odds = { common = 70, rare = 22, epic = 7, legendary = 1 },
	},
	arctic = {
		name = "Пак льда",
		tank = "arctic",
		price = 3000,
		odds = { common = 70, rare = 22, epic = 7, legendary = 1 },
	},
	haunted = {
		name = "Тыквенный пак",
		tank = "haunted",
		price = 10,
		currency = "candy", -- покупается за конфеты ивента, не за монеты
		odds = { common = 70, rare = 22, epic = 7, legendary = 1 },
	},
	abyss = {
		name = "Пак бездны",
		tank = "abyss",
		price = 22000,
		odds = { common = 70, rare = 22, epic = 7, legendary = 1 },
	},
}

-- Виды данной редкости (в порядке SpeciesOrder); tankId необязателен — тогда только виды этого аквариума
function FishConfig.speciesOfRarity(rarity, tankId)
	local list = {}
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		local species = FishConfig.Species[id]
		if species.rarity == rarity and (tankId == nil or species.tank == tankId) then
			table.insert(list, id)
		end
	end
	return list
end

-- Все виды аквариума (в порядке SpeciesOrder)
function FishConfig.speciesOfTank(tankId)
	local list = {}
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		if FishConfig.Species[id].tank == tankId then
			table.insert(list, id)
		end
	end
	return list
end

-- ===== Рост рыб =====
-- Рыба растёт со временем: чем она старше, тем больше дохода и цена продажи.
--   from  — с какого возраста (сек) начинается стадия
--   mult  — множитель дохода и цены продажи
--   scale — размер рыбы на экране
FishConfig.GrowthStages = {
	{ name = "Малёк", from = 0, mult = 1, scale = 0.8 },
	{ name = "Подросток", from = 600, mult = 1.5, scale = 0.9 },
	{ name = "Взрослая", from = 1800, mult = 2, scale = 1 },
}

-- ===== Цветовые варианты =====
-- Вариант определяется при выпадении из пака. weight — относительный шанс (сумма = 100, то есть проценты).
FishConfig.Variants = {
	normal = { name = "Обычная", mult = 1, weight = 88 },
	golden = { name = "Золотая", mult = 2, weight = 11, emoji = "✨", color = Color3.fromRGB(255, 202, 40) },
	rainbow = { name = "Радужная", mult = 5, weight = 1, emoji = "🌈", color = Color3.fromRGB(240, 98, 146) },
}
FishConfig.VariantOrder = { "normal", "golden", "rainbow" }

-- ===== Магазин за Robux =====
-- ВАЖНО: id создаются в Creator Hub (Monetization -> Passes / Developer Products). Пока id = 0, товар не продаётся
-- и кнопка магазина скрыта. Шансы паков за Robux НЕ продаём: все паки только за монеты.
--   DoubleCoins.mult — во сколько раз растёт весь доход (и онлайн, и офлайн)
--   Products[i].seconds — товар даёт монеты, равные столькому времени текущего дохода (но не меньше MIN_COINS),
--   поэтому он честен и в начале игры, и в конце.
--   NightWatch  — пасс Night Watchman: лимит дохода в офлайне растёт с OFFLINE_MAX до offlineMax секунд
--   SecondHall  — пасс Second Hall: в очереди музея на extraQueue гостей больше
--   QuickOpen   — пасс Quick Open: кнопка «×packs» открывает несколько паков сразу и без долгой анимации
--   StarterPack — разовый товар, который предлагается во второй сессии на offerHours часов (реальный таймер): монеты за
--                 seconds секунд дохода, билеты музея и заранее известная рыба fish. Никакого рандома.
-- Пока passId / productId = 0, соответствующий товар не продаётся и не показывается.
FishConfig.Shop = {
	DoubleCoins = { passId = 2040116972, mult = 2 }, -- Poseidon's Blessing
	NightWatch = { passId = 2037201398, offlineMax = 12 * 3600 }, -- Night Watchman
	SecondHall = { passId = 2039841310, extraQueue = 3 }, -- Second Hall
	QuickOpen = { passId = 2037243513, packs = 3 }, -- Quick Open
	StarterPack = {
		key = "starter",
		productId = 3719356682, -- Starter Pack
		seconds = 2 * 3600,
		tickets = 10,
		fish = { species = "puffer", variant = "golden", tank = "lagoon" },
		offerHours = 24,
	},
	Products = {
		{ key = "coins_1h", productId = 3719343518, seconds = 3600 }, -- Gift of Nereus (25 R$)
		{ key = "coins_8h", productId = 3719343283, seconds = 28800 }, -- Handful of Pearls (50 R$)
	},
	MIN_COINS = 500,
}

-- ===== Ежедневная награда =====
-- Заходишь каждый день подряд — награда растёт (7 дней по кругу). Пропустил день — серия начинается заново.
FishConfig.DailyRewards = { 100, 200, 350, 600, 1000, 1800, 4000 }

-- Номер дня (UTC) для момента времени в секундах
function FishConfig.dayOf(t)
	return math.floor(t / 86400)
end

-- ===== Доход в офлайне =====
-- Пока игрока нет, рыбы приносят OFFLINE_RATE от обычного дохода, но не дольше OFFLINE_MAX секунд.
FishConfig.OFFLINE_RATE = 0.5
FishConfig.OFFLINE_MAX = 2 * 3600

local function round(x)
	return math.floor(x + 0.5)
end

-- Стадия роста по возрасту в секундах
function FishConfig.stageFor(age)
	local result = FishConfig.GrowthStages[1]
	for _, stage in ipairs(FishConfig.GrowthStages) do
		if age >= stage.from then
			result = stage
		end
	end
	return result
end

-- Номер стадии роста (1 — малёк, 2 — подросток, 3 — взрослая) по возрасту в секундах
function FishConfig.stageIndex(age)
	local index = 1
	for i, stage in ipairs(FishConfig.GrowthStages) do
		if age >= stage.from then
			index = i
		end
	end
	return index
end

-- «Ранг» цвета: обычная 1, золотая 2, радужная 3 (для сравнения «не хуже»)
function FishConfig.variantRank(variantId)
	local id = variantId or "normal"
	for i, v in ipairs(FishConfig.VariantOrder) do
		if v == id then
			return i
		end
	end
	return 1
end

-- Вариант по id (у старых рыб варианта нет — считаем обычной)
function FishConfig.variantOf(variantId)
	return FishConfig.Variants[variantId or "normal"] or FishConfig.Variants.normal
end

-- Общий множитель дохода и цены: стадия роста × вариант
function FishConfig.multiplierOf(variantId, age)
	return FishConfig.stageFor(age).mult * FishConfig.variantOf(variantId).mult
end

-- Доход рыбы за один тик
-- mutationId (необязателен) — мутация рыбы, она добавляет свой множитель
function FishConfig.incomeOf(speciesId, variantId, age, mutationId)
	local species = FishConfig.Species[speciesId]
	if species == nil then
		return 0
	end
	return round(species.income * FishConfig.multiplierOf(variantId, age) * FishConfig.mutationMult(mutationId))
end

-- Цена продажи рыбы
function FishConfig.sellPriceOf(speciesId, variantId, age)
	local species = FishConfig.Species[speciesId]
	if species == nil then
		return 0
	end
	return round(species.sellPrice * FishConfig.multiplierOf(variantId, age))
end

-- Выбор варианта по весам. rng — необязательный Random (для тестов).
function FishConfig.rollVariant(rng)
	local total = 0
	for _, id in ipairs(FishConfig.VariantOrder) do
		total += FishConfig.Variants[id].weight
	end
	local r = (if rng then rng:NextNumber() else math.random()) * total
	local acc = 0
	for _, id in ipairs(FishConfig.VariantOrder) do
		acc += FishConfig.Variants[id].weight
		if r < acc then
			return id
		end
	end
	return "normal"
end

-- Сколько тиков дохода засчитать за elapsed секунд отсутствия (целое число)
-- maxSeconds — лимит накопления (по умолчанию OFFLINE_MAX; пасс Night Watchman поднимает его)
function FishConfig.offlineTicks(elapsed, maxSeconds)
	local capped = math.min(math.max(elapsed, 0), maxSeconds or FishConfig.OFFLINE_MAX)
	return math.floor(capped / FishConfig.INCOME_INTERVAL * FishConfig.OFFLINE_RATE)
end

-- Места в аквариуме: сколько даётся на старте, максимум и цена каждого следующего места.
-- Это главный «сток» монет: без него деньги накапливаются без цели.
FishConfig.START_SLOTS = 5
FishConfig.MAX_SLOTS = 10
FishConfig.SlotPrices = { [6] = 500, [7] = 2000, [8] = 8000, [9] = 30000, [10] = 100000 }

-- Цена места номер n в аквариуме tankId (nil, если такого места нет)
function FishConfig.slotPrice(tankId, n)
	local base = FishConfig.SlotPrices[n]
	local tank = FishConfig.Tanks[tankId]
	if base == nil or tank == nil then
		return nil
	end
	return base * tank.slotPriceMult
end

-- Новый пустой аквариум игрока
function FishConfig.newTank()
	return { slots = FishConfig.START_SLOTS, fish = {} }
end

-- ===== Музей: посетители и билеты =====
-- В музее всегда ждут QUEUE_SIZE гостей. Каждый просит «показать» рыбу: нужный вид, не младше стадии роста и,
-- возможно, золотого/радужного цвета. Рыба остаётся у игрока, за показ платят билетами. Штрафов нет:
-- заказ, который не выполнили за ORDER_TTL секунд, просто заменяется новым. Гости приходят и пока игрока нет.
--   RankThresholds — сколько выполненных заказов нужно для ранга 1, 2, 3 ... (ранг открывает редких рыб, стадии и цвета)
--   RarityTickets  — базовая награда за вид данной редкости; её множат стадия, цвет и ранг
--   Shop           — траты билетов: пак редких рыб и дополнительные места сверх MAX_SLOTS
-- ===== Течения и мутации =====
-- Раз в MIN_GAP..MAX_GAP секунд (пока игрок в игре) в одном из его аквариумов начинается течение:
-- DURATION секунд доход рыб этого аквариума умножается на INCOME_MULT. Когда течение заканчивается,
-- у MUTATED_FISH рыб этого аквариума (без мутации) появляется постоянная мутация с бонусом к доходу.
FishConfig.Currents = {
	MIN_GAP = 20 * 60,
	MAX_GAP = 40 * 60,
	DURATION = 5 * 60,
	INCOME_MULT = 1.5,
	MUTATED_FISH = 2,
}
FishConfig.MutationOrder = { "bubble", "glow", "pearl" }
FishConfig.Mutations = {
	bubble = { name = "Пузырьковая", emoji = "🫧", mult = 1.10, weight = 60 },
	glow = { name = "Светящаяся", emoji = "💡", mult = 1.20, weight = 30 },
	pearl = { name = "Жемчужная", emoji = "🦪", mult = 1.40, weight = 10 },
}

-- Множитель дохода от мутации (нет мутации или неизвестная — 1)
function FishConfig.mutationMult(mutationId)
	local mutation = FishConfig.Mutations[mutationId or ""]
	return if mutation then mutation.mult else 1
end

-- Выбор мутации по весам. rng — необязательный Random (для тестов).
function FishConfig.rollMutation(rng)
	rng = rng or Random.new()
	local total = 0
	for _, id in ipairs(FishConfig.MutationOrder) do
		total += FishConfig.Mutations[id].weight
	end
	local r = rng:NextNumber() * total
	local acc = 0
	for _, id in ipairs(FishConfig.MutationOrder) do
		acc += FishConfig.Mutations[id].weight
		if r < acc then
			return id
		end
	end
	return FishConfig.MutationOrder[1]
end

-- ===== Значки (Badges) =====
-- id значков создаются в Creator Hub (Creations -> игра -> Badges). Пока id = 0, значок не выдаётся.
--   golden — первая золотая рыба; rainbow — первая радужная; mutation — первая мутация;
--   set — собран любой набор «все виды аквариума»; museum3 — ранг музея 3; abyss — открыта Бездна
FishConfig.Badges = {
	golden = 523630835642282,
	rainbow = 138098649336709,
	mutation = 2901772893513393,
	set = 778650768347445,
	museum3 = 85139715503978,
	abyss = 0,
	halloween = 0, -- «Хэллоуин 2026»: поймана любая рыба Призрачного пруда
}

FishConfig.Visitors = {
	QUEUE_SIZE = 3,
	ORDER_TTL = 45 * 60,
	REFILL_DELAY = 5 * 60,
	RankThresholds = { 0, 5, 15, 35, 70, 120 },
	RarityTickets = { common = 2, rare = 5, epic = 12, legendary = 30 },
	StageMult = { 1, 1.5, 2 },
	VariantMult = { normal = 1, golden = 3, rainbow = 8 },
	RankBonus = 0.05,
	Shop = {
		rarepack = { price = 25, odds = { common = 0, rare = 70, epic = 25, legendary = 5 } },
		slot = { price = 60, maxBonus = 2 }, -- цена умножается на номер дополнительного места (60, 120)
	},
}

-- ===== Слияние =====
-- MERGE_COUNT одинаковых рыб (вид + цвет в одном аквариуме) сливаются в одну рыбу следующего цвета:
-- обычная -> золотая -> радужная. Новая рыба появляется «мальком» (возраст 0), зато занимает одно место вместо пяти.
FishConfig.MERGE_COUNT = 5

-- Следующий цвет после variantId (nil, если выше некуда)
function FishConfig.nextVariant(variantId)
	local current = variantId or "normal"
	for index, id in ipairs(FishConfig.VariantOrder) do
		if id == current then
			return FishConfig.VariantOrder[index + 1]
		end
	end
	return nil
end

-- ===== Наборы коллекции =====
-- Набор аквариума — все его виды. У набора три ступени; каждая собранная ступень даёт постоянную прибавку
-- к доходу рыб ЭТОГО аквариума (прибавки складываются):
--   found   — все виды хотя бы раз выпали (любого цвета)
--   golden  — у вас была золотая рыба каждого вида
--   rainbow — у вас была радужная рыба каждого вида
-- variant = nil означает «любой цвет».
FishConfig.SetTiers = {
	{ id = "found", variant = nil, bonus = 0.10 },
	{ id = "golden", variant = "golden", bonus = 0.25 },
	{ id = "rainbow", variant = "rainbow", bonus = 0.50 },
}

-- ===== Гости в аквариуме (игроки на одном сервере) =====
-- Покормить чужих рыб можно раз в FEED_COOLDOWN на каждого игрока: хозяин получает +BOOST к доходу на BOOST_TIME,
-- гость — FEED_TICKETS билетов музея (не больше FEED_REWARDS_PER_DAY раз в сутки, чтобы нельзя было фармить).
-- Лайк — раз в сутки (UTC) на каждого игрока. Себя кормить и лайкать нельзя.
FishConfig.Social = {
	FEED_COOLDOWN = 10 * 60,
	BOOST = 0.10,
	BOOST_TIME = 10 * 60,
	FEED_TICKETS = 1,
	FEED_REWARDS_PER_DAY = 20,
	VIEW_FISH_MAX = 40, -- сколько рыб чужого аквариума присылаем за раз
}

-- ===== Большой прилив (общее событие всех серверов) =====
-- Каждый час в одно и то же время (по UTC, одинаково на всех серверах) DURATION секунд доход всех игроков ×INCOME_MULT.
-- Во время прилива у сервера общая цель: вместе открыть паков goal = GOAL_BASE + GOAL_PER_PLAYER × игроков (не больше GOAL_MAX).
-- Каждый, кто открыл хотя бы один пак за прилив, при выполнении цели получает билеты и монеты (REWARD_TICKS тиков своего дохода).
FishConfig.Tide = {
	PERIOD = 60 * 60,
	OFFSET = 0, -- сдвиг начала от ровного часа UTC, секунд
	DURATION = 10 * 60,
	INCOME_MULT = 1.5,
	GOAL_BASE = 5,
	GOAL_PER_PLAYER = 8,
	GOAL_MAX = 80,
	REWARD_TICKETS = 5,
	REWARD_TICKS = 60, -- 60 тиков по 5 с = 5 минут дохода
	SHOW_BEFORE = 10 * 60, -- за сколько до начала показывать плашку
}

-- ===== Таблицы лидеров (этап 21) =====
-- Недельные (сброс в понедельник 00:00 UTC): лайки и заказы музея. Коллекция — за всё время (виды × цвета).
FishConfig.Leaderboards = {
	ORDER = { "likes", "museum", "collection" },
	Boards = {
		likes = { emoji = "❤", weekly = true },
		museum = { emoji = "🏛", weekly = true },
		collection = { emoji = "📖", weekly = false },
	},
	TOP = 50,
	WRITE_EVERY = 120, -- как часто записываем очки игрока, секунд
	READ_EVERY = 180, -- как часто сервер перечитывает топ
}

-- ===== Золотые пузырьки =====
-- Раз в GAP_MIN..GAP_MAX секунд (пока игрок в игре) сервер выпускает золотой пузырёк; он поднимается LIFE секунд.
-- Кто успеет нажать, получает монеты за REWARD_TICKS тиков своего дохода (не меньше REWARD_MIN). Обычные пузырьки
-- просто лопаются (только на клиенте, без награды).
FishConfig.Bubbles = {
	GAP_MIN = 3 * 60,
	GAP_MAX = 5 * 60,
	LIFE = 16,
	REWARD_TICKS = 6,
	REWARD_MIN = 10,
}

-- ===== Монетки от особых рыб =====
-- Золотая и радужная рыба время от времени «выплёвывает» монетку: она появляется над рыбой на LIFE секунд.
-- Кто успеет нажать, получает монеты за ticks тиков дохода ЭТОЙ рыбы (не меньше MIN). Решает и платит сервер.
FishConfig.Drops = {
	LIFE = 25,
	MIN = 5,
	RETRY = 30, -- если особых рыб нет, заглядываем снова через столько секунд
	golden = { gapMin = 50, gapMax = 80, ticks = 6 },
	rainbow = { gapMin = 30, gapMax = 50, ticks = 12 },
}

-- ===== Декор аквариумов =====
-- Картинки из art/src/decor.py (SpriteData), размер в пикселях фона (1 px фона = высота экрана / 240).
-- x — центр по ширине экрана, y — линия дна (низ предмета), доли экрана.
-- anim: "sway" — покачивается (растения), "glow" — мерцает, "vent" — пускает пузырьки.
-- tap: "open" — открывается (sprite открытый в open), "wobble" — подпрыгивает. flip — зеркально.
-- Дно: полоса из картинки, повторяется по ширине; ниже неё — сплошной цвет (под кнопками).
FishConfig.DecorFloor = {
	TOP = 0.795, -- верх полосы дна, доля экрана
	SCALE = 1.2, -- предметы чуть крупнее пикселя фона, чтобы читались на телефоне
	lagoon = { id = "decor_floor_lagoon", color = Color3.fromRGB(201, 173, 110) },
	volcano = { id = "decor_floor_volcano", color = Color3.fromRGB(42, 34, 38) },
	arctic = { id = "decor_floor_arctic", color = Color3.fromRGB(196, 220, 234) },
	abyss = { id = "decor_floor_abyss", color = Color3.fromRGB(21, 26, 54) },
	haunted = { id = "decor_floor_haunted", color = Color3.fromRGB(42, 32, 48) },
}
-- Предметы с полем key — «наполнение», его покупают за монеты: price — цена, bonus — прибавка к доходу ЭТОГО аквариума
-- (0.03 = +3%, складывается с бонусом наборов коллекции). Пока не куплен, предмет виден тенью с ценой.
-- Предметы без key — просто оформление, бесплатно и всегда на месте.
FishConfig.Decor = {
	lagoon = {
		{ id = "decor_kelp", x = 0.05, y = 0.822, anim = "sway" },
		{ id = "decor_coral", x = 0.19, y = 0.812, anim = "sway", key = "lagoon_coral", price = 800, bonus = 0.02 },
		{ id = "decor_chest", x = 0.34, y = 0.817, tap = "open", open = "decor_chest_open", key = "lagoon_chest", price = 3000, bonus = 0.03 },
		{ id = "decor_shell", x = 0.5, y = 0.812, tap = "open", open = "decor_shell_open", key = "lagoon_shell", price = 30000, bonus = 0.04 },
		{ id = "decor_anemone", x = 0.63, y = 0.812, anim = "sway", key = "lagoon_anemone", price = 10000, bonus = 0.03 },
		{ id = "decor_starfish", x = 0.42, y = 0.817, tap = "wobble" },
		{ id = "decor_shroomhouse", x = 0.86, y = 0.822, tap = "wobble", key = "lagoon_shroomhouse", price = 100000, bonus = 0.05 },
		{ id = "decor_kelp", x = 0.97, y = 0.822, anim = "sway", flip = true },
	},
	volcano = {
		{ id = "decor_vent", x = 0.1, y = 0.822, anim = "vent", tap = "wobble", key = "volcano_vent", price = 80000, bonus = 0.03 },
		{ id = "decor_firecoral", x = 0.27, y = 0.812, anim = "sway", key = "volcano_firecoral", price = 20000, bonus = 0.02 },
		{ id = "decor_obsidian", x = 0.5, y = 0.817, key = "volcano_obsidian", price = 300000, bonus = 0.04 },
		{ id = "decor_amphora", x = 0.72, y = 0.812, tap = "wobble", key = "volcano_amphora", price = 1000000, bonus = 0.05 },
		{ id = "decor_firecoral", x = 0.9, y = 0.822, anim = "sway", flip = true },
	},
	arctic = {
		{ id = "decor_seagrass", x = 0.05, y = 0.822, anim = "sway" },
		{ id = "decor_igloo", x = 0.24, y = 0.817, tap = "wobble", key = "arctic_igloo", price = 15000000, bonus = 0.03 },
		{ id = "decor_icecrystal", x = 0.52, y = 0.812, anim = "glow", key = "arctic_icecrystal", price = 50000000, bonus = 0.04 },
		{ id = "decor_anchor", x = 0.76, y = 0.817, tap = "wobble", key = "arctic_anchor", price = 150000000, bonus = 0.05 },
		{ id = "decor_seagrass", x = 0.95, y = 0.822, anim = "sway", flip = true },
	},
	abyss = {
		{ id = "decor_tubeworm", x = 0.07, y = 0.822, anim = "sway" },
		{ id = "decor_arch", x = 0.3, y = 0.822, anim = "glow", key = "abyss_arch", price = 400000000, bonus = 0.04 },
		{ id = "decor_glowshroom", x = 0.58, y = 0.812, anim = "glow", tap = "wobble", key = "abyss_glowshroom", price = 1200000000, bonus = 0.05 },
		{ id = "decor_wreck", x = 0.85, y = 0.822, tap = "wobble", key = "abyss_wreck", price = 4000000000, bonus = 0.06 },
	},
	haunted = {
		{ id = "decor_deadtree", x = 0.09, y = 0.822, key = "haunted_deadtree", price = 60000, bonus = 0.04 },
		{ id = "decor_tombstone", x = 0.3, y = 0.812, tap = "wobble", key = "haunted_tombstone", price = 150000, bonus = 0.04 },
		{ id = "decor_lantern", x = 0.52, y = 0.812, anim = "glow", tap = "wobble", key = "haunted_lantern", price = 5000, bonus = 0.03 },
		{ id = "decor_barrel", x = 0.74, y = 0.817, tap = "wobble", key = "haunted_barrel", price = 20000, bonus = 0.03 },
		{ id = "decor_tombstone", x = 0.92, y = 0.822, flip = true, tap = "wobble" },
	},
}

-- Покупаемое наполнение: key -> { tank, id (картинка), price, bonus }; и список ключей по аквариумам
FishConfig.DecorItems = {}
FishConfig.DecorKeys = {} -- [tankId] = { key, ... } в порядке расстановки
for tankId, list in pairs(FishConfig.Decor) do
	FishConfig.DecorKeys[tankId] = {}
	for _, d in ipairs(list) do
		if d.key ~= nil then
			FishConfig.DecorItems[d.key] = { tank = tankId, id = d.id, price = d.price, bonus = d.bonus }
			table.insert(FishConfig.DecorKeys[tankId], d.key)
		end
	end
end

return FishConfig
