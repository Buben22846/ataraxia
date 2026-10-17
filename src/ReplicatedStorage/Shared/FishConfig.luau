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
FishConfig.Species = {
	guppy = { name = "Гуппи", emoji = "🐟", rarity = "common", income = 1, sellPrice = 5 },
	clown = { name = "Клоун", emoji = "🐠", rarity = "common", income = 2, sellPrice = 8 },
	puffer = { name = "Фугу", emoji = "🐡", rarity = "rare", income = 4, sellPrice = 20 },
	whale = { name = "Кит", emoji = "🐳", rarity = "epic", income = 10, sellPrice = 60 },
	octopus = { name = "Осьминог", emoji = "🐙", rarity = "legendary", income = 25, sellPrice = 150 },
}

-- Порядок видов (для интерфейса коллекции и шансов)
FishConfig.SpeciesOrder = { "guppy", "clown", "puffer", "whale", "octopus" }

-- Порядок редкостей от частой к редкой
FishConfig.RarityOrder = { "common", "rare", "epic", "legendary" }

-- Паки. odds — шансы РЕДКОСТЕЙ в процентах, сумма должна быть 100.
-- Внутри редкости вид выбирается равновероятно. Выпадение считает только сервер (PackRoller).
FishConfig.Packs = {
	common = {
		name = "Обычный пак",
		price = 50,
		odds = { common = 70, rare = 22, epic = 7, legendary = 1 },
	},
}

-- Виды данной редкости (в порядке SpeciesOrder)
function FishConfig.speciesOfRarity(rarity)
	local list = {}
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		if FishConfig.Species[id].rarity == rarity then
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

return FishConfig
