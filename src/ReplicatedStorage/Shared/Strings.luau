-- Strings: тексты интерфейса на двух языках (ru / en). Язык определяется один раз при загрузке модуля.
-- Русские названия видов, аквариумов и т.п. берутся прямо из FishConfig (сервер и тесты используют их же),
-- английские лежат здесь. Если перевода нет — показываем русский вариант, а в крайнем случае сам id.
--
--   Strings.t("ключ", ...)      -- текст интерфейса (если переданы аргументы — string.format; удобнее всего %s)
--   Strings.species(id) / tank(id) / rarity(id) / variant(id) / pack(id)
--   Strings.stage(имя_или_индекс)  -- стадия роста: "Малёк" или 1
--   Strings.setLanguage("ru"|"en") -- только для проверки; в игре язык выбирается сам

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

local FishConfig = require(script.Parent:WaitForChild("FishConfig"))

local Strings = {}

-- Для проверки в Studio можно временно поставить "ru" или "en"; в игре должно быть nil.
local FORCE_LANGUAGE = nil

local RUSSIAN_PREFIXES = { ru = true, uk = true, be = true, kk = true }

local function detectLanguage()
	local localeId = ""
	pcall(function()
		localeId = LocalizationService.RobloxLocaleId
	end)
	if localeId == "" then
		pcall(function()
			localeId = Players.LocalPlayer.LocaleId
		end)
	end
	local prefix = string.lower(string.sub(localeId or "", 1, 2))
	return if RUSSIAN_PREFIXES[prefix] then "ru" else "en"
end

local language = FORCE_LANGUAGE or detectLanguage()

function Strings.language()
	return language
end

function Strings.setLanguage(lang)
	if lang == "ru" or lang == "en" then
		language = lang
	end
end

-- ===== Английские названия из конфига =====
local EN_SPECIES = {
	guppy = "Guppy",
	clown = "Clownfish",
	puffer = "Pufferfish",
	whale = "Whale",
	octopus = "Octopus",
	ember_shrimp = "Ember Shrimp",
	magma_crab = "Magma Crab",
	fire_eel = "Fire Eel",
	caldera_squid = "Caldera Squid",
	magma_dragon = "Magma Dragon",
	penguin = "Penguin",
	seal = "Seal",
	polar_shark = "Polar Shark",
	beluga = "Beluga",
	narwhal = "Narwhal",
	lantern_fish = "Lanternfish",
	jellyfish = "Jellyfish",
	anglerfish = "Anglerfish",
	abyss_ray = "Abyssal Ray",
	leviathan = "Leviathan",
}
local EN_TANKS = {
	lagoon = "Quiet Lagoon",
	volcano = "Volcanic Reef",
	arctic = "Frozen Grotto",
	abyss = "The Abyss",
}
local EN_RARITIES = {
	common = "Common",
	rare = "Rare",
	epic = "Epic",
	legendary = "Legendary",
}
local EN_VARIANTS = {
	normal = "Normal",
	golden = "Golden",
	rainbow = "Rainbow",
}
local EN_PACKS = {
	lagoon = "Lagoon Pack",
	volcano = "Volcano Pack",
	arctic = "Ice Pack",
	abyss = "Abyss Pack",
}
local EN_STAGES = { "Fry", "Juvenile", "Adult" } -- по индексу FishConfig.GrowthStages

-- Название из таблицы конфига для русского, из словаря для английского
local function pick(enTable, configTable, id)
	if language == "en" and enTable[id] then
		return enTable[id]
	end
	local entry = configTable[id]
	if entry and entry.name then
		return entry.name
	end
	return enTable[id] or tostring(id)
end

function Strings.species(id)
	return pick(EN_SPECIES, FishConfig.Species, id)
end

function Strings.tank(id)
	return pick(EN_TANKS, FishConfig.Tanks, id)
end

function Strings.rarity(id)
	return pick(EN_RARITIES, FishConfig.Rarities, id)
end

function Strings.variant(id)
	return pick(EN_VARIANTS, FishConfig.Variants, id or "normal")
end

function Strings.pack(id)
	return pick(EN_PACKS, FishConfig.Packs, id)
end

-- Стадия роста: принимает индекс, русское имя из FishConfig или саму таблицу стадии
function Strings.stage(nameOrIndex)
	local index = nil
	if type(nameOrIndex) == "table" then
		nameOrIndex = nameOrIndex.name
	end
	if type(nameOrIndex) == "number" then
		index = nameOrIndex
	else
		for i, stage in ipairs(FishConfig.GrowthStages) do
			if stage.name == nameOrIndex then
				index = i
				break
			end
		end
	end
	if index == nil then
		return tostring(nameOrIndex)
	end
	local stage = FishConfig.GrowthStages[index]
	if language == "en" and EN_STAGES[index] then
		return EN_STAGES[index]
	end
	return if stage then stage.name else (EN_STAGES[index] or tostring(index))
end

-- ===== Тексты интерфейса =====
-- Формулировки подобраны так, чтобы подставляемые названия не требовали склонения.
local TEXT = {
	ru = {
		-- Главный экран
		coins = "Монеты: %s",
		buy_pack = "%s (%s)",
		odds = "Шансы",
		collection = "Коллекция %s/%s",
		slots_max = "Мест: максимум",
		slot_buy = "+место (%s)",
		close = "Закрыть",

		-- Уведомления
		toast_full = "Аквариум полон: продайте рыбу или купите место",
		toast_coins = "Не хватает монет",
		toast_offline = "Пока вас не было: +%s 💰",

		-- Коллекция и шансы
		coll_hint = "×N — сколько раз выпала · 💰 — всего заработала",
		coll_title = "%s: %s/%s (всего %s/%s)",
		unknown_fish = "❓ ???",
		variant_hint = "Вариант: %s",
		odds_title = "Шансы: %s",

		-- Карточка открытия пака
		new_in_collection = "НОВАЯ В КОЛЛЕКЦИИ!",
		great = "Отлично",

		-- Карточка рыбы
		info_income = "Доход: +%s за %s · Продажа: %s",
		info_stats = "%s ×%s · Возраст: %s · 💰%s",
		age_s = "%sс",
		age_ms = "%sм %sс",
		age_hm = "%sч %sм",
		sell = "%s: продать (+%s)",

		-- Аквариумы
		tanks_title = "Аквариумы",
		tanks_hint = "У каждого аквариума свои рыбы и пак · доход идёт со всех сразу",
		tank_here = "сейчас здесь",
		tank_open = "открыть",
		tank_buy = "купить за %s",

		-- Обучение
		tut_buy = "Нажми на кнопку покупки пака",
		tut_fish = "Рыбы сами приносят монеты и растут. Нажми на рыбу, чтобы увидеть статистику или продать",
		tut_tanks = "Копи монеты: покупай больше рыб, места и новые аквариумы (кнопка сверху)",
		tut_skip = "Пропустить",
		tut_ok = "Понятно",

		-- Ежедневная награда
		daily_title = "Ежедневная награда",
		daily_day = "День %s",
		daily_claim = "Забрать",
		daily_today = "Награда сегодня: +%s 💰",
		daily_next = "Следующая награда через %s",
		daily_done = "Забрано",
		daily_got = "Награда получена: +%s 💰",

		-- Магазин за Robux (цену показывает окно Roblox)
		shop_title = "Магазин",
		shop_double_title = "Двойной доход ×2",
		shop_double_desc = "Все рыбы приносят вдвое больше монет, и онлайн, и пока вас нет",
		shop_owned = "Куплено",
		shop_best = "ВЫГОДНО",
		shop_buy = "Купить",
		shop_coins_title = "Монеты: %s дохода",
		shop_coins_desc = "Монеты, равные вашему текущему доходу за %s",
		shop_unlocked = "Двойной доход включён! ×2",
		shop_error = "Не удалось открыть покупку",
		settings_title = "Настройки",
		settings_sfx = "Звуки",
		settings_music = "Музыка",
		settings_on = "Вкл",
		settings_off = "Выкл",
		dur_h_1 = "%s час",
		dur_h_2 = "%s часа",
		dur_h_5 = "%s часов",
		dur_m_1 = "%s минута",
		dur_m_2 = "%s минуты",
		dur_m_5 = "%s минут",
		dur_s = "%s сек.",

		-- Звук
		sound_toggle = "Звук",

		-- Панель администратора
		adm_title = "Админ-панель (тест)",
		adm_coins_1k = "+1 000 монет",
		adm_coins_100k = "+100 000 монет",
		adm_slot = "+1 место в аквариуме",
		adm_give = "Выдать: %s",
		adm_variant = "Вариант выдачи: %s",
		adm_age = "Состарить рыб на 1 час",
		adm_unlock = "Открыть все аквариумы",
		adm_reset = "Сбросить прогресс",
		adm_reset_confirm = "Точно? Нажмите ещё раз",
	},

	en = {
		coins = "Coins: %s",
		buy_pack = "%s (%s)",
		odds = "Odds",
		collection = "Collection %s/%s",
		slots_max = "Slots: max",
		slot_buy = "+slot (%s)",
		close = "Close",

		toast_full = "Tank is full: sell a fish or buy a slot",
		toast_coins = "Not enough coins",
		toast_offline = "While you were away: +%s 💰",

		coll_hint = "×N = times pulled · 💰 = total earned",
		coll_title = "%s: %s/%s (total %s/%s)",
		unknown_fish = "❓ ???",
		variant_hint = "Variant: %s",
		odds_title = "Odds: %s",

		new_in_collection = "NEW IN COLLECTION!",
		great = "Nice!",

		info_income = "Income: +%s per %s · Sell: %s",
		info_stats = "%s ×%s · Age: %s · 💰%s",
		age_s = "%ss",
		age_ms = "%sm %ss",
		age_hm = "%sh %sm",
		sell = "Sell %s (+%s)",

		tanks_title = "Tanks",
		tanks_hint = "Each tank has its own fish and pack · income comes from all tanks at once",
		tank_here = "you are here",
		tank_open = "open",
		tank_buy = "buy for %s",

		tut_buy = "Tap the pack button to get your first fish",
		tut_fish = "Fish earn coins and grow on their own. Tap a fish to see its stats or sell it",
		tut_tanks = "Save coins to buy more fish, slots and new tanks (button at the top)",
		tut_skip = "Skip",
		tut_ok = "Got it",

		daily_title = "Daily reward",
		daily_day = "Day %s",
		daily_claim = "Claim",
		daily_today = "Today's reward: +%s 💰",
		daily_next = "Next reward in %s",
		daily_done = "Claimed",
		daily_got = "Reward claimed: +%s 💰",

		shop_title = "Shop",
		shop_double_title = "Double Coins ×2",
		shop_double_desc = "All fish earn twice as many coins, both online and while you're away",
		shop_owned = "Owned",
		shop_best = "BEST VALUE",
		shop_buy = "Buy",
		shop_coins_title = "Coins: %s of income",
		shop_coins_desc = "Coins equal to %s of your current income",
		shop_unlocked = "Double Coins unlocked! ×2",
		shop_error = "Couldn't open the purchase",
		settings_title = "Settings",
		settings_sfx = "Sounds",
		settings_music = "Music",
		settings_on = "On",
		settings_off = "Off",
		dur_h_1 = "%s hour",
		dur_h_2 = "%s hours",
		dur_h_5 = "%s hours",
		dur_m_1 = "%s minute",
		dur_m_2 = "%s minutes",
		dur_m_5 = "%s minutes",
		dur_s = "%s sec",

		sound_toggle = "Sound",

		adm_title = "Admin panel (test)",
		adm_coins_1k = "+1,000 coins",
		adm_coins_100k = "+100,000 coins",
		adm_slot = "+1 tank slot",
		adm_give = "Give: %s",
		adm_variant = "Give variant: %s",
		adm_age = "Age fish by 1 hour",
		adm_unlock = "Unlock all tanks",
		adm_reset = "Reset progress",
		adm_reset_confirm = "Sure? Tap again",
	},
}

-- Текст по ключу; если переданы аргументы — подставляет их через string.format
function Strings.t(key, ...)
	local text = TEXT[language][key] or TEXT.en[key] or TEXT.ru[key]
	if text == nil then
		return tostring(key)
	end
	if select("#", ...) == 0 then
		return text
	end
	local ok, result = pcall(string.format, text, ...)
	return if ok then result else text
end

return Strings
