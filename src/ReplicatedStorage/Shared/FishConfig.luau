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
	leviathan = { tank = "abyss", name = "Левиафан", emoji = "🐲", rarity = "legendary", income = 10000, sellPrice = 60000 },
}

-- Порядок видов (для интерфейса коллекции и шансов)
FishConfig.SpeciesOrder = {
	"guppy", "clown", "puffer", "whale", "octopus",
	"ember_shrimp", "magma_crab", "fire_eel", "caldera_squid", "magma_dragon",
	"penguin", "seal", "polar_shark", "beluga", "narwhal",
	"lantern_fish", "jellyfish", "anglerfish", "abyss_ray", "leviathan",
}

-- Аквариумы. У каждого свои рыбы (Species.tank), свой пак и своя цена мест.
--   price         — сколько стоит открыть (0 = есть с самого начала)
--   pack          — id пака этого аквариума (FishConfig.Packs)
--   slotPriceMult — во сколько раз дороже места, чем в лагуне
--   color         — цвет воды (запасной фон)
--   background     — id пиксельного фона в SpriteData
FishConfig.Tanks = {
	lagoon = { name = "Тихая лагуна", emoji = "🌊", price = 0, pack = "lagoon", slotPriceMult = 1, color = Color3.fromRGB(20, 110, 140), background = "bg_lagoon" },
	volcano = { name = "Вулканический риф", emoji = "🌋", price = 5000, pack = "volcano", slotPriceMult = 4, color = Color3.fromRGB(105, 36, 28), background = "bg_volcano" },
	arctic = { name = "Ледяной грот", emoji = "❄️", price = 150000, pack = "arctic", slotPriceMult = 10, color = Color3.fromRGB(64, 120, 165), background = "bg_arctic" },
	abyss = { name = "Бездна", emoji = "🌌", price = 1500000, pack = "abyss", slotPriceMult = 25, color = Color3.fromRGB(12, 22, 52), background = "bg_abyss" },
}
FishConfig.TankOrder = { "lagoon", "volcano", "arctic", "abyss" }

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
FishConfig.Shop = {
	DoubleCoins = { passId = 0, mult = 2 },
	Products = {
		{ key = "coins_1h", productId = 0, seconds = 3600 },
		{ key = "coins_8h", productId = 0, seconds = 28800 },
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

-- Вариант по id (у старых рыб варианта нет — считаем обычной)
function FishConfig.variantOf(variantId)
	return FishConfig.Variants[variantId or "normal"] or FishConfig.Variants.normal
end

-- Общий множитель дохода и цены: стадия роста × вариант
function FishConfig.multiplierOf(variantId, age)
	return FishConfig.stageFor(age).mult * FishConfig.variantOf(variantId).mult
end

-- Доход рыбы за один тик
function FishConfig.incomeOf(speciesId, variantId, age)
	local species = FishConfig.Species[speciesId]
	if species == nil then
		return 0
	end
	return round(species.income * FishConfig.multiplierOf(variantId, age))
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
function FishConfig.offlineTicks(elapsed)
	local capped = math.min(math.max(elapsed, 0), FishConfig.OFFLINE_MAX)
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

return FishConfig
