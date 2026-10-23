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
	pumpkin_fish = "Pumpkin Fish",
	ghost_guppy = "Ghost Guppy",
	bat_ray = "Bat Ray",
	bone_fish = "Bone Fish",
	jack_angler = "Jack Angler",
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
	haunted = "Haunted Pond",
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
local EN_MUTATIONS = {
	bubble = "Bubbly",
	glow = "Glowing",
	pearl = "Pearly",
}
local EN_PACKS = {
	haunted = "Pumpkin Pack",
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

function Strings.mutation(id)
	return pick(EN_MUTATIONS, FishConfig.Mutations, id)
end

local EN_EVENTS = {
	halloween = "Halloween",
}

function Strings.eventName(id)
	return pick(EN_EVENTS, FishConfig.Events, id)
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
-- Названия предметов декора
local DECOR_RU = {
	decor_kelp = "Ламинария", decor_coral = "Коралл", decor_chest = "Сундук", decor_shell = "Жемчужная раковина",
	decor_anemone = "Актиния", decor_starfish = "Морская звезда", decor_shroomhouse = "Грибной домик",
	decor_vent = "Горячий источник", decor_firecoral = "Огненный коралл", decor_obsidian = "Обсидиан", decor_amphora = "Амфора",
	decor_seagrass = "Морская трава", decor_igloo = "Иглу", decor_icecrystal = "Ледяной кристалл", decor_anchor = "Якорь",
	decor_tubeworm = "Трубчатые черви", decor_arch = "Светящаяся арка", decor_glowshroom = "Светящийся гриб", decor_wreck = "Затонувший корабль",
	decor_deadtree = "Мёртвое дерево", decor_tombstone = "Надгробие", decor_lantern = "Фонарь", decor_barrel = "Бочка",
}
local DECOR_EN = {
	decor_kelp = "Kelp", decor_coral = "Coral", decor_chest = "Treasure Chest", decor_shell = "Pearl Shell",
	decor_anemone = "Anemone", decor_starfish = "Starfish", decor_shroomhouse = "Mushroom House",
	decor_vent = "Hot Vent", decor_firecoral = "Fire Coral", decor_obsidian = "Obsidian", decor_amphora = "Amphora",
	decor_seagrass = "Seagrass", decor_igloo = "Igloo", decor_icecrystal = "Ice Crystal", decor_anchor = "Anchor",
	decor_tubeworm = "Tube Worms", decor_arch = "Glowing Arch", decor_glowshroom = "Glow Mushroom", decor_wreck = "Shipwreck",
	decor_deadtree = "Dead Tree", decor_tombstone = "Tombstone", decor_lantern = "Lantern", decor_barrel = "Barrel",
}
function Strings.decor(id)
	local table_ = if language == "en" then DECOR_EN else DECOR_RU
	return table_[id] or DECOR_EN[id] or tostring(id)
end

local TEXT = {
	ru = {
		-- Главный экран
		coins = "%s",
		buy_pack = "%s (%s)",
		buy_pack_candy = "%s (🍬 %s)",
		toast_candy = "Не хватает конфет 🍬: их дают гости музея, течения, награда за день и игра онлайн",
		toast_event_over = "Ивент закончился: пак больше не продаётся, рыбы остаются у вас",
		event_chip = "%s %s · %s %s · %s",
		event_left_d = "%dд %dч",
		event_left_h = "%dч %dм",
		event_welcome = "%s %s! Открыт аквариум «%s», в подарок конфеты 🍬",
		odds = "❓ Шансы",
		collection = "📖 Индекс %s/%s",
		slots_max = "Мест: максимум",
		slot_buy = "➕ Место (%s)",
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
		tide_active = "🌊 Прилив ×%s %s",
		tide_goal = "цель %s/%s паков",
		tide_goal_done = "цель выполнена!",
		tide_soon = "🌊 Большой прилив через %s",
		tide_help = "Большой прилив: каждый час 10 минут доход ×%s у всех. Откройте паки вместе с сервером, чтобы получить награду",
		toast_tide_start = "🌊 Большой прилив! Доход ×%s",
		toast_tide_reward = "🌊 Сервер выполнил цель! +%s монет и +%s 🎟",
		toast_tide_done = "🌊 Сервер выполнил цель прилива! Откройте пак в следующий раз, чтобы получить награду",
		lb_title = "Лучшие игроки",
		lb_tab_likes = "Лайки",
		lb_tab_museum = "Музей",
		lb_tab_collection = "Коллекция",
		lb_loading = "Загрузка...",
		lb_empty = "Пока никого — станьте первым!",
		lb_me = "Вы: %s %s",
		lb_reset = "сброс через %dд %dч",
		lb_row = "🏆 Лучшие игроки",
		lb_row_sub = "Лайки и музей за неделю, коллекция",
		lb_open = "Открыть",
		guests_title = "Игроки на сервере",
		guests_hint = "Покормите рыб другого игрока: ему +10% дохода, вам билет музея",
		guests_row = "❤ %s · 🐟 %s",
		guests_visit = "В гости",
		guests_empty = "Вы здесь одни",
		guests_empty_sub = "Позовите друга в гости",
		guests_invite = "Позвать",
		guests_back = "↩ Домой",
		guests_aquarium = "🏠 Аквариум: %s",
		guests_likes = "❤ %s",
		guests_fish = "🐟 %d",
		guests_boost = "✨ сытые рыбы %s",
		guests_feed = "🍤 Покормить",
		guests_feed_wait = "🍤 %s",
		guests_like = "❤ Лайк",
		guests_liked = "❤ Завтра",
		guests_fed = "Рыбы сыты и довольны!",
		guests_fed_tickets = "Рыбы сыты! +%d 🎟",
		guests_like_done = "Лайк отправлен ❤",
		guests_feed_cooldown = "Этих рыб уже кормили, загляните позже",
		guests_like_already = "Сегодня вы уже ставили лайк",
		guests_gone = "Игрок вышел из игры",
		guests_fed_you = "%s покормил ваших рыб: +%d%% дохода на %d мин",
		guests_liked_you = "%s поставил лайк вашему аквариуму ❤",
		odds_row = "❓ %s — видов: %d (по %s каждый)",

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
		museum_btn = "🎟 %s",
		museum_title = "Музей · ранг %d · 🎟 %s",
		museum_hint = "Рыба остаётся у вас. Гость, которого не дождались, просто сменится новым",
		museum_rank_next = "Ранг %d. До следующего: %d заказов",
		museum_rank_max = "Высший ранг музея",
		order_show = "Показать",
		order_nofish = "Нет рыбы",
		order_line2 = "%s%s · 🎟 %s · %s",
		order_waiting = "Скоро придёт новый гость · %s",
		museum_shop_pack = "Пак редких рыб · 🎟 %s",
		museum_shop_slot = "Место сверх лимита · 🎟 %s",
		museum_shop_locked = "Сначала купите все места за монеты",
		toast_ticket = "+%s 🎟 за показ рыбы",
		toast_rankup = "Новый ранг музея: %d!",
		toast_tickets_need = "Не хватает билетов",
		toast_slot_limit = "Дополнительные места недоступны",
		toast_order_fail = "Подходящей рыбы нет или заказ уже сменился",
		merge = "Слить %d → %s",
		merge_progress = "Слияние: %d из %d",
		toast_merge_fail = "Нужно 5 одинаковых рыб одного цвета в этом аквариуме",
		set_row = "Набор %s ✨%s 🌈%s",
		set_bonus = "+%d%% дохода",
		current_chip = "🌊 Течение · %s ×%s · %s",
		toast_current_start = "🌊 Течение в аквариуме «%s»: доход ×%s на %s",
		toast_mutation = "✨ Мутация! %s: %s",
		mut_title = "Мутации",
		mut_row = "%s %s ×%s",
		mut_count = "%d шт.",

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
		shop_night_title = "Ночной смотритель",
		shop_night_desc = "Копилка дохода в офлайне вмещает 12 часов вместо 2",
		shop_hall_title = "Второй зал",
		shop_hall_desc = "В музее ждут на 3 гостя больше",
		shop_quick_title = "Быстрое открытие",
		shop_quick_desc = "Открывайте 3 пака за раз, без долгой анимации",
		shop_starter_title = "Стартовый набор",
		shop_starter_desc = "Монеты за 2 часа дохода, 10 билетов и золотая Фугу. Один раз",
		starter_timer = "Предложение закончится через %s",
		quick_open = "×%s паков",
		toast_coins_eta = "Не хватает монет · ещё ~%s",
		hint_coins_shop = "Монеты за 1 час дохода ›",
		hint_offline_full = "Копилка была полна. Ночной смотритель ›",
		shop_owned = "Куплено",
		shop_best = "ВЫГОДНО",
		shop_tag_night = "12 ЧАСОВ",
		shop_tag_hall = "+3 ГОСТЯ",
		shop_tag_quick = "×3 СРАЗУ",
		shop_buy = "Купить",
		shop_coins_title = "Монеты: %s дохода",
		shop_coins_desc = "Монеты, равные вашему текущему доходу за %s",
		shop_unlocked = "Двойной доход включён! ×2",
		shop_error = "Не удалось открыть покупку",
		settings_title = "Настройки",
		settings_invite = "Пригласить друга",
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
		btn_daily = "Награда",
		btn_sound = "Звук",
		btn_shop = "Магазин",
		btn_guests = "Гости",
		decor_tag = "🔒 %s",
		decor_bonus = "+%s%% к доходу этого аквариума",
		decor_buy = "Купить за %s",
		decor_cancel = "Не сейчас",
		decor_bought = "✨ Куплено: %s! +%s%% к доходу",
		decor_need = "Не хватает монет: нужно %s",
		decor_row = "🪴 Декор %s/%s · нажмите на тёмный предмет в аквариуме",
		decor_row_bonus = "+%s%%",
		feed_hint = "Нажмите на воду — бросить корм",
		feed_cooldown = "Рыбы ещё сыты",
		pet_heart = "💗",
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
		coins = "%s",
		buy_pack = "%s (%s)",
		buy_pack_candy = "%s (🍬 %s)",
		toast_candy = "Not enough candy 🍬: get it from museum guests, currents, the daily reward and playing online",
		toast_event_over = "The event is over: the pack is no longer sold, your fish stay with you",
		event_chip = "%s %s · %s %s · %s",
		event_left_d = "%dd %dh",
		event_left_h = "%dh %dm",
		event_welcome = "%s %s! The %s tank is open, and here is some candy 🍬",
		odds = "❓ Odds",
		collection = "📖 Index %s/%s",
		slots_max = "Slots: max",
		slot_buy = "➕ Slot (%s)",
		close = "Close",

		toast_full = "Tank is full: sell a fish or buy a slot",
		toast_coins = "Not enough coins",
		toast_offline = "While you were away: +%s 💰",

		coll_hint = "×N = times pulled · 💰 = total earned",
		coll_title = "%s: %s/%s (total %s/%s)",
		unknown_fish = "❓ ???",
		variant_hint = "Variant: %s",
		odds_title = "Odds: %s",
		tide_active = "🌊 Tide ×%s %s",
		tide_goal = "goal %s/%s packs",
		tide_goal_done = "goal reached!",
		tide_soon = "🌊 Great Tide in %s",
		tide_help = "Great Tide: every hour, 10 minutes of ×%s income for everyone. Open packs together with the server to earn a reward",
		toast_tide_start = "🌊 Great Tide! Income ×%s",
		toast_tide_reward = "🌊 The server reached the goal! +%s coins and +%s 🎟",
		toast_tide_done = "🌊 The server reached the tide goal! Open a pack next time to get the reward",
		lb_title = "Top players",
		lb_tab_likes = "Likes",
		lb_tab_museum = "Museum",
		lb_tab_collection = "Collection",
		lb_loading = "Loading...",
		lb_empty = "No one yet — be the first!",
		lb_me = "You: %s %s",
		lb_reset = "resets in %dd %dh",
		lb_row = "🏆 Top players",
		lb_row_sub = "Weekly likes and museum, collection",
		lb_open = "Open",
		guests_title = "Players on this server",
		guests_hint = "Feed another player's fish: they get +10% income, you get a museum ticket",
		guests_row = "❤ %s · 🐟 %s",
		guests_visit = "Visit",
		guests_empty = "You're alone here",
		guests_empty_sub = "Invite a friend over",
		guests_invite = "Invite",
		guests_back = "↩ Home",
		guests_aquarium = "🏠 %s's aquarium",
		guests_likes = "❤ %s",
		guests_fish = "🐟 %d",
		guests_boost = "✨ well-fed %s",
		guests_feed = "🍤 Feed",
		guests_feed_wait = "🍤 %s",
		guests_like = "❤ Like",
		guests_liked = "❤ Tomorrow",
		guests_fed = "The fish are happy!",
		guests_fed_tickets = "The fish are happy! +%d 🎟",
		guests_like_done = "Like sent ❤",
		guests_feed_cooldown = "These fish were just fed, come back later",
		guests_like_already = "You already liked this aquarium today",
		guests_gone = "The player has left",
		guests_fed_you = "%s fed your fish: +%d%% income for %d min",
		guests_liked_you = "%s liked your aquarium ❤",
		odds_row = "❓ %s — %d species (%s each)",

		new_in_collection = "NEW IN COLLECTION!",
		great = "Nice!",

		info_income = "Income: +%s per %s · Sell: %s",
		info_stats = "%s ×%s · Age: %s · 💰%s",
		age_s = "%ss",
		age_ms = "%sm %ss",
		age_hm = "%sh %sm",
		sell = "Sell %s (+%s)",
		museum_btn = "🎟 %s",
		museum_title = "Museum · rank %d · 🎟 %s",
		museum_hint = "You keep the fish. A guest you didn't wait for is simply replaced by another",
		museum_rank_next = "Rank %d. %d more orders to the next",
		museum_rank_max = "Top museum rank",
		order_show = "Show",
		order_nofish = "No fish",
		order_line2 = "%s%s · 🎟 %s · %s",
		order_waiting = "A new guest arrives soon · %s",
		museum_shop_pack = "Rare fish pack · 🎟 %s",
		museum_shop_slot = "Extra slot · 🎟 %s",
		museum_shop_locked = "Buy all coin slots first",
		toast_ticket = "+%s 🎟 for showing a fish",
		toast_rankup = "New museum rank: %d!",
		toast_tickets_need = "Not enough tickets",
		toast_slot_limit = "Extra slots are unavailable",
		toast_order_fail = "No matching fish, or the order has changed",
		merge = "Merge %d -> %s",
		merge_progress = "Merge: %d of %d",
		toast_merge_fail = "You need 5 identical fish of the same color in this tank",
		set_row = "Set %s ✨%s 🌈%s",
		set_bonus = "+%d%% income",
		current_chip = "🌊 Current · %s ×%s · %s",
		toast_current_start = "🌊 A current is flowing in %s: income ×%s for %s",
		toast_mutation = "✨ Mutation! %s: %s",
		mut_title = "Mutations",
		mut_row = "%s %s ×%s",
		mut_count = "%d pcs.",

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
		shop_night_title = "Night Watchman",
		shop_night_desc = "Offline income storage holds 12 hours instead of 2",
		shop_hall_title = "Second Hall",
		shop_hall_desc = "3 more guests wait in the museum",
		shop_quick_title = "Quick Open",
		shop_quick_desc = "Open 3 packs at once, without the long animation",
		shop_starter_title = "Starter Pack",
		shop_starter_desc = "Coins for 2 hours of income, 10 tickets and a golden Pufferfish. One time only",
		starter_timer = "Offer ends in %s",
		quick_open = "×%s packs",
		toast_coins_eta = "Not enough coins · ~%s more",
		hint_coins_shop = "Coins for 1 hour of income ›",
		hint_offline_full = "The storage was full. Night Watchman ›",
		shop_owned = "Owned",
		shop_best = "BEST VALUE",
		shop_tag_night = "12 HOURS",
		shop_tag_hall = "+3 GUESTS",
		shop_tag_quick = "×3 AT ONCE",
		shop_buy = "Buy",
		shop_coins_title = "Coins: %s of income",
		shop_coins_desc = "Coins equal to %s of your current income",
		shop_unlocked = "Double Coins unlocked! ×2",
		shop_error = "Couldn't open the purchase",
		settings_title = "Settings",
		settings_invite = "Invite a friend",
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
		btn_daily = "Reward",
		btn_sound = "Sound",
		btn_shop = "Shop",
		btn_guests = "Guests",
		decor_tag = "🔒 %s",
		decor_bonus = "+%s%% income in this tank",
		decor_buy = "Buy for %s",
		decor_cancel = "Not now",
		decor_bought = "✨ Bought: %s! +%s%% income",
		decor_need = "Not enough coins: need %s",
		decor_row = "🪴 Decor %s/%s · tap a dark item in the tank",
		decor_row_bonus = "+%s%%",
		feed_hint = "Tap the water to drop food",
		feed_cooldown = "The fish are still full",
		pet_heart = "💗",
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

-- Короткая запись больших чисел: 999 -> "999", 1000 -> "1K", 1500 -> "1.5K", 17187818 -> "17.1M".
-- Суффиксы: K тысяча, M миллион, B миллиард, T триллион, Qa, Qi, Sx. Дробную часть отбрасываем (не округляем),
-- поэтому «1000K» никогда не появляется.
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Strings.num(n)
	local sign = if n < 0 then "-" else ""
	local value = math.abs(n)
	if value < 1000 then
		return sign .. tostring(math.floor(value))
	end
	local index = 0
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local text
	if value >= 100 then
		text = tostring(math.floor(value))
	else
		local decimals = if value >= 10 then 10 else 100
		text = string.format("%.2f", math.floor(value * decimals) / decimals)
		if decimals == 10 then
			text = string.format("%.1f", math.floor(value * 10) / 10)
		end
		text = text:gsub("%.?0+$", "") -- 1.50 -> 1.5, 2.00 -> 2
	end
	return sign .. text .. SUFFIXES[index]
end

-- Текст по ключу; если переданы аргументы — подставляет их через string.format.
-- Числа от 1000 и больше записываются кратко (1.5K, 2M), поэтому в таких местах нужен %s, а не %d.
function Strings.t(key, ...)
	local text = TEXT[language][key] or TEXT.en[key] or TEXT.ru[key]
	if text == nil then
		return tostring(key)
	end
	local count = select("#", ...)
	if count == 0 then
		return text
	end
	local args = table.pack(...)
	for i = 1, count do
		local value = args[i]
		if type(value) == "number" and math.abs(value) >= 1000 then
			args[i] = Strings.num(value)
		end
	end
	local ok, result = pcall(string.format, text, table.unpack(args, 1, count))
	return if ok then result else text
end

return Strings
