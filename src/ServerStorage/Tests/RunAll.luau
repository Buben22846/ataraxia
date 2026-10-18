-- RunAll: автотесты логики игры.
-- Запуск: в режиме Play, в командной строке сервера:
--   print(require(game.ServerStorage.Tests.RunAll)())
-- Настоящее хранилище не трогается: PlayerData проверяется на заглушке.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
	local results = {}
	local failed = 0
	local function check(name, cond)
		if not cond then
			failed += 1
		end
		table.insert(results, (if cond then "PASS " else "FAIL ") .. name)
	end

	local FishConfig = require(ReplicatedStorage.Shared.FishConfig)

	-- ===== PlayerData на заглушке хранилища =====
	local M = require(ServerScriptService.PlayerData:Clone())
	local data = {}
	local failNext = 0
	local mock = {}
	function mock:UpdateAsync(key, fn)
		if failNext > 0 then
			failNext -= 1
			error("mock: simulated failure")
		end
		local new = fn(data[key] and table.clone(data[key]) or nil)
		if new ~= nil then
			data[key] = new
		end
		return new
	end
	M._setStore(mock)

	M._setJobId("serverA")
	local p1 = M._claim(1001)
	check("новый игрок: профиль по умолчанию", p1 ~= nil and p1.coins == 100 and p1.tanks.lagoon.slots == FishConfig.START_SLOTS)
	check("новый игрок: блокировка записана", data["Player_1001"].lock.jobId == "serverA")

	p1.coins = 777
	p1.discovered.guppy = true
	check("сохранение записывает данные", M._commit(1001, p1, false) == true and data["Player_1001"].data.coins == 777)

	M._setJobId("serverB")
	local p2, r2 = M._claim(1001)
	check("чужая свежая блокировка: загрузка отказана", p2 == nil and r2 == "locked")
	check(
		"чужая блокировка: сохранение не перезаписывает",
		M._commit(1001, M._newProfile(), false) == false and data["Player_1001"].data.coins == 777
	)

	M._setJobId("serverA")
	check("релиз снимает блокировку", M._commit(1001, p1, true) == true and data["Player_1001"].lock == nil)
	M._setJobId("serverB")
	local p3 = M._claim(1001)
	check("после релиза другой сервер загружает данные", p3 ~= nil and p3.coins == 777 and p3.discovered.guppy == true)

	data["Player_1001"].lock.time = os.time() - 1000
	M._setJobId("serverC")
	check("протухшая блокировка перехватывается", M._claim(1001) ~= nil and data["Player_1001"].lock.jobId == "serverC")

	failNext = 1
	check("повтор после сбоя DataStore", M._claim(1002) ~= nil)
	failNext = 99
	local p6, r6 = M._claim(1003)
	check("все попытки провалены: nil + failed", p6 == nil and r6 == "failed")
	failNext = 0

	data["Player_1004"] = {
		data = {
			version = 1,
			coins = 321,
			nextFishId = 4,
			fish = { { id = 3, species = "guppy", born = 1, earned = 7 } },
			discovered = { guppy = true },
			speciesStats = { guppy = { pulled = 2, earned = 9 } },
		},
	}
	local p7 = M._claim(1004)
	check("миграция v1 -> v5: появились аквариум, места и lastSeen", p7 ~= nil and p7.version == 5 and p7.tanks.lagoon.slots == FishConfig.START_SLOTS and type(p7.lastSeen) == "number")
	check("миграция v1 -> v2: старые данные целы", p7 ~= nil and p7.coins == 321 and #p7.tanks.lagoon.fish == 1 and p7.speciesStats.guppy.pulled == 2)

	data["Player_1005"] = { data = { version = 1, coins = 5 } }
	local p8 = M._claim(1005)
	check("недостающие поля достраиваются", p8 ~= nil and type(p8.tanks) == "table" and type(p8.tanks.lagoon.fish) == "table" and type(p8.speciesStats) == "table" and p8.nextFishId == 1)

	local a, b = M._newProfile(), M._newProfile()
	a.tanks.lagoon.fish[1] = { id = 1 }
	check("новые профили независимы", #b.tanks.lagoon.fish == 0)

	data["Player_1006"] = { data = { version = 2, coins = 5, slots = 6, nextFishId = 1, fish = {}, discovered = {}, speciesStats = {} } }
	local p9 = M._claim(1006)
	check("миграция v2 -> v5: lastSeen появился, данные целы", p9 ~= nil and p9.version == 5 and type(p9.lastSeen) == "number" and p9.tanks.lagoon.slots == 6 and p9.coins == 5)

	-- ===== Рост, варианты, доход =====
	check(
		"стадии роста по возрасту",
		FishConfig.stageFor(0).name == "Малёк"
			and FishConfig.stageFor(599).name == "Малёк"
			and FishConfig.stageFor(600).name == "Подросток"
			and FishConfig.stageFor(1800).name == "Взрослая"
	)
	check(
		"доход растёт с возрастом",
		FishConfig.incomeOf("guppy", "normal", 0) == 1
			and FishConfig.incomeOf("guppy", "normal", 3600) == 2
			and FishConfig.incomeOf("clown", "normal", 700) == 3
	)
	check(
		"варианты умножают доход",
		FishConfig.incomeOf("guppy", "golden", 3600) == 4 and FishConfig.incomeOf("whale", "rainbow", 3600) == 100
	)
	check(
		"цена продажи растёт",
		FishConfig.sellPriceOf("puffer", "normal", 3600) == 40 and FishConfig.sellPriceOf("puffer", "golden", 0) == 40
	)
	check(
		"без варианта = обычная; неизвестный вид = 0",
		FishConfig.incomeOf("guppy", nil, 0) == 1 and FishConfig.incomeOf("nope", "normal", 0) == 0
	)
	do
		local vrng = Random.new(7)
		local VN = 100000
		local vcounts = { normal = 0, golden = 0, rainbow = 0 }
		for _ = 1, VN do
			local id = FishConfig.rollVariant(vrng)
			vcounts[id] = (vcounts[id] or 0) + 1
		end
		local goldenPct = vcounts.golden / VN * 100
		local rainbowPct = vcounts.rainbow / VN * 100
		check(string.format("вариант golden %.2f%% ≈ 11%%", goldenPct), math.abs(goldenPct - 11) < 0.5)
		check(string.format("вариант rainbow %.2f%% ≈ 1%%", rainbowPct), math.abs(rainbowPct - 1) < 0.3)
	end
	check(
		"офлайн: число тиков и потолок",
		FishConfig.offlineTicks(0) == 0
			and FishConfig.offlineTicks(-5) == 0
			and FishConfig.offlineTicks(3600) == 360
			and FishConfig.offlineTicks(1000000) == 720
	)

	local Economy = require(ServerScriptService.Economy)
	local ep = M._newProfile()
	ep.tanks.lagoon.fish = { { id = 1, species = "guppy", variant = "normal", born = os.time() - 3600, earned = 0 } }
	local gained = Economy.applyIncome(ep, 10, os.time())
	check(
		"доход за тики: монеты, рыба, вид",
		gained == 20 and ep.coins == 120 and ep.tanks.lagoon.fish[1].earned == 20 and ep.speciesStats.guppy.earned == 20
	)

	local op = M._newProfile()
	local t0 = os.time()
	op.lastSeen = t0 - 3600
	op.tanks.lagoon.fish = { { id = 1, species = "guppy", born = t0 - 3700, earned = 0 } } -- на момент lastSeen рыбе 100 сек: малёк, доход 1
	check("офлайн-доход: 360 тиков × 1", Economy.applyOffline(op, t0) == 360 and op.coins == 460)
	op.lastSeen = nil
	check("без lastSeen офлайн-дохода нет", Economy.applyOffline(op, t0) == 0)

	-- ===== Аквариумы =====
	data["Player_1007"] = {
		data = {
			version = 3,
			coins = 9,
			slots = 7,
			nextFishId = 3,
			fish = { { id = 2, species = "guppy", born = 1, earned = 4 } },
			discovered = { guppy = true },
			speciesStats = {},
			lastSeen = 5,
		},
	}
	local p10 = M._claim(1007)
	check(
		"миграция v3 -> v5: рыбы и места переехали в лагуну",
		p10 ~= nil and p10.version == 5 and p10.tanks.lagoon.slots == 7 and #p10.tanks.lagoon.fish == 1 and p10.slots == nil and p10.fish == nil
	)

	local tanksOk = true
	for _, tankId in ipairs(FishConfig.TankOrder) do
		local pack = FishConfig.Packs[FishConfig.Tanks[tankId].pack]
		if pack == nil or pack.tank ~= tankId then
			tanksOk = false
		else
			for _, rarity in ipairs(FishConfig.RarityOrder) do
				if (pack.odds[rarity] or 0) > 0 and #FishConfig.speciesOfRarity(rarity, tankId) == 0 then
					tanksOk = false
				end
			end
		end
	end
	check("у каждого аквариума есть пак и виды всех редкостей", tanksOk)
	check(
		"лагуна бесплатна, остальные платные и дорожают",
		FishConfig.Tanks.lagoon.price == 0 and FishConfig.Tanks.volcano.price > 0 and FishConfig.Tanks.arctic.price > FishConfig.Tanks.volcano.price
	)
	check(
		"цена места растёт с аквариумом",
		FishConfig.slotPrice("lagoon", 6) == 500 and FishConfig.slotPrice("volcano", 6) == 2000 and FishConfig.slotPrice("lagoon", 11) == nil
	)
	do
		local roller = require(ServerScriptService.PackRoller)
		local trng = Random.new(3)
		local ownOnly = true
		for _, pack in pairs(FishConfig.Packs) do
			for _ = 1, 2000 do
				local speciesId = roller.roll(pack, trng)
				if FishConfig.Species[speciesId].tank ~= pack.tank then
					ownOnly = false
				end
			end
		end
		check("из пака выпадают только рыбы его аквариума", ownOnly)
	end
	local mp = M._newProfile()
	mp.tanks.volcano = FishConfig.newTank()
	mp.tanks.lagoon.fish = { { id = 1, species = "guppy", born = os.time() - 3600, earned = 0 } }
	mp.tanks.volcano.fish = { { id = 2, species = "magma_crab", born = os.time() - 3600, earned = 0 } }
	check("доход идёт со всех аквариумов", Economy.applyIncome(mp, 1, os.time()) == 2 + 24 and Economy.fishCount(mp) == 2)

	-- ===== Шансы паков =====
	local PackRoller = require(ServerScriptService.PackRoller)
	for packId, pack in pairs(FishConfig.Packs) do
		local rng = Random.new(1)
		local N = 100000
		local counts = {}
		for _ = 1, N do
			local _, rarity = PackRoller.roll(pack, rng)
			counts[rarity] = (counts[rarity] or 0) + 1
		end
		for _, rarity in ipairs(FishConfig.RarityOrder) do
			local expected = pack.odds[rarity] or 0
			local actual = (counts[rarity] or 0) / N * 100
			check(string.format("пак %s: %s %.2f%% ≈ %g%%", packId, rarity, actual, expected), math.abs(actual - expected) < 0.5)
		end
	end

	-- ===== Ежедневная награда =====
	local DailyReward = require(ServerScriptService.DailyReward)
	local day = 20000
	local t0 = day * 86400 + 100
	local dp = { coins = 0, daily = { lastDay = 0, streak = 0 } }
	local st = DailyReward.state(dp, t0)
	check("награда: новому игроку можно забрать, серия 1", st.canClaim and st.streak == 1 and st.reward == FishConfig.DailyRewards[1])
	local got, streak = DailyReward.claim(dp, t0)
	check("награда: первая выдана, монеты зачислены", got == FishConfig.DailyRewards[1] and streak == 1 and dp.coins == got)
	local again = DailyReward.claim(dp, t0 + 3600)
	check("награда: второй раз в тот же день не выдаётся", again == nil and dp.coins == got)
	check("награда: после получения canClaim=false и таймер идёт", DailyReward.state(dp, t0).canClaim == false and DailyReward.state(dp, t0).secondsLeft == 86400 - 100)
	local got2, streak2 = DailyReward.claim(dp, t0 + 86400)
	check("награда: на следующий день серия растёт", streak2 == 2 and got2 == FishConfig.DailyRewards[2])
	local _, streak3 = DailyReward.claim(dp, t0 + 4 * 86400)
	check("награда: пропуск дня сбрасывает серию", streak3 == 1)
	local rp = { coins = 0, daily = { lastDay = day - 1, streak = 7 } }
	local got8, streak8 = DailyReward.claim(rp, t0)
	check("награда: после 7-го дня круг начинается заново", streak8 == 8 and got8 == FishConfig.DailyRewards[1])

	-- ===== Магазин и множитель дохода =====
	local Shop = require(ServerScriptService.Shop)
	local Economy = require(ServerScriptService.Economy)
	local sp = { coins = 0, tanks = { lagoon = { slots = 5, fish = { { id = 1, species = "guppy", variant = "normal", born = 0, earned = 0 } } } }, speciesStats = {} }
	local base = Economy.applyIncome(sp, 1, 0)
	local sp2 = { coins = 0, tanks = { lagoon = { slots = 5, fish = { { id = 1, species = "guppy", variant = "normal", born = 0, earned = 0 } } } }, speciesStats = {} }
	local doubled = Economy.applyIncome(sp2, 1, 0, 2)
	check("множитель x2 удваивает доход", doubled == base * 2 and base > 0)
	check("доход за тик без бонусов считается", Economy.incomePerTick(sp, 0) == base)
	local realProductId = FishConfig.Shop.Products[1].productId -- тест подменяет id и потом возвращает настоящий
	check("id = 0 никогда не считается товаром", Shop.productById(0) == nil)
	FishConfig.Shop.Products[1].productId = 111
	local shopProfile = { coins = 0, tanks = { lagoon = FishConfig.newTank() }, speciesStats = {}, receipts = { list = {}, seen = {} } }
	check("товар: пустой аквариум даёт минимум монет", Shop.coinsFor(shopProfile, FishConfig.Shop.Products[1], 1000) == FishConfig.Shop.MIN_COINS)
	check("товар: первая выдача по чеку", Shop.grant(shopProfile, 111, "p1", 1000) == "granted" and shopProfile.coins == FishConfig.Shop.MIN_COINS)
	check("товар: тот же чек второй раз не даёт монет", Shop.grant(shopProfile, 111, "p1", 1000) == "duplicate" and shopProfile.coins == FishConfig.Shop.MIN_COINS)
	check("товар: неизвестный id не выдаётся", Shop.grant(shopProfile, 999, "p2", 1000) == "unknown")
	FishConfig.Shop.Products[1].productId = realProductId
	for _, product in ipairs(FishConfig.Shop.Products) do
		check("товар " .. product.key .. " находится по своему id", product.productId == 0 or Shop.productById(product.productId) == product)
	end

	-- ===== Слияние и наборы коллекции =====
	local Merge = require(ServerScriptService.Merge)
	local Collection = require(ServerScriptService.Collection)
	local function fishOf(id, species, variant, born)
		return { id = id, species = species, variant = variant, born = born or 0, earned = 0 }
	end
	local function mergeProfile(fish)
		return { coins = 0, nextFishId = 100, tanks = { lagoon = { slots = 10, fish = fish }, volcano = FishConfig.newTank() }, discovered = {}, seen = {}, speciesStats = {} }
	end
	local mp1 = mergeProfile({
		fishOf(1, "guppy", "normal", 0), fishOf(2, "guppy", "normal", 10), fishOf(3, "guppy", "normal", 20),
		fishOf(4, "guppy", "normal", 30), fishOf(5, "guppy", "normal", 40), fishOf(6, "guppy", "normal", 50),
		fishOf(7, "clown", "normal", 0),
	})
	local okM, newM, isNewM = Merge.perform(mp1, 1, 1000)
	check("слияние: 6 одинаковых -> золотая", okM == true and newM.variant == "golden" and newM.species == "guppy" and newM.born == 1000)
	check("слияние: съедено 5, осталась 1 обычная + клоун + новая", #mp1.tanks.lagoon.fish == 3 and newM.id == 100 and mp1.nextFishId == 101)
	check("слияние: уходят выбранная и 4 самые молодые, вторая по возрасту остаётся", (function()
		local left = {}
		for _, f in ipairs(mp1.tanks.lagoon.fish) do
			left[f.id] = true
		end
		return left[2] == true and not left[1] and not left[3] and not left[4] and not left[5] and not left[6]
	end)())
	check("слияние: первый золотой вид отмечен как новый", isNewM == true and mp1.seen["guppy/golden"] == true)
	local okFew, reasonFew = Merge.perform(mp1, 7, 1000)
	check("слияние: одной рыбы мало", okFew == false and reasonFew == "count")
	local okMissing, reasonMissing = Merge.perform(mp1, 9999, 1000)
	check("слияние: чужой/несуществующий id отклоняется", okMissing == false and reasonMissing == "missing")
	local mp2 = mergeProfile({ fishOf(1, "guppy", "normal"), fishOf(2, "guppy", "normal"), fishOf(3, "guppy", "normal"), fishOf(4, "guppy", "normal") })
	local okFour = Merge.perform(mp2, 1, 1000)
	check("слияние: 4 рыб недостаточно, ничего не потеряно", okFour == false and #mp2.tanks.lagoon.fish == 4)
	local mp3 = mergeProfile({})
	for id = 1, 5 do
		table.insert(mp3.tanks.lagoon.fish, fishOf(id, "puffer", "golden"))
	end
	local okR, newR = Merge.perform(mp3, 3, 1000)
	check("слияние: 5 золотых -> радужная", okR == true and newR.variant == "rainbow" and #mp3.tanks.lagoon.fish == 1)
	local mp4 = mergeProfile({})
	for id = 1, 5 do
		table.insert(mp4.tanks.lagoon.fish, fishOf(id, "puffer", "rainbow"))
	end
	local okMax, reasonMax = Merge.perform(mp4, 1, 1000)
	check("слияние: радужные выше не сливаются", okMax == false and reasonMax == "max" and #mp4.tanks.lagoon.fish == 5)
	local mp5 = mergeProfile({ fishOf(1, "guppy", "normal"), fishOf(2, "guppy", "normal"), fishOf(3, "guppy", "normal"), fishOf(4, "guppy", "normal") })
	table.insert(mp5.tanks.volcano.fish, fishOf(5, "guppy", "normal"))
	check("слияние: рыбы из разных аквариумов не смешиваются", Merge.perform(mp5, 1, 1000) == false)
	check("у старого варианта без поля variant — обычная", FishConfig.nextVariant(nil) == "golden" and FishConfig.nextVariant("rainbow") == nil)

	local lagoonSpecies = FishConfig.speciesOfTank("lagoon")
	local cp = { coins = 0, tanks = { lagoon = FishConfig.newTank() }, discovered = {}, seen = {}, speciesStats = {} }
	check("набор: пустая коллекция без бонуса", Collection.bonus(cp, "lagoon") == 0)
	for index = 1, #lagoonSpecies - 1 do
		cp.discovered[lagoonSpecies[index]] = true
	end
	check("набор: 4 из 5 видов бонуса не дают", Collection.bonus(cp, "lagoon") == 0)
	cp.discovered[lagoonSpecies[#lagoonSpecies]] = true
	check("набор: все виды лагуны дают +10%", math.abs(Collection.bonus(cp, "lagoon") - 0.10) < 1e-9)
	check("набор: бонус лагуны не действует на вулкан", Collection.bonus(cp, "volcano") == 0)
	for _, id in ipairs(lagoonSpecies) do
		Collection.mark(cp, id, "golden")
	end
	check("набор: все золотые добавляют +25%", math.abs(Collection.bonus(cp, "lagoon") - 0.35) < 1e-9)
	for _, id in ipairs(lagoonSpecies) do
		Collection.mark(cp, id, "rainbow")
	end
	check("набор: все радужные — итого +85%", math.abs(Collection.bonus(cp, "lagoon") - 0.85) < 1e-9)
	local summary = Collection.summary(cp)
	check("набор: сводка по ступеням", summary.lagoon.tiers[1].done and summary.lagoon.tiers[3].have == #lagoonSpecies and summary.volcano.bonus == 0)
	local ip = { coins = 0, tanks = { lagoon = { slots = 5, fish = { fishOf(1, "octopus", "normal", 0) } } }, discovered = {}, seen = {}, speciesStats = {} }
	local noBonus = Economy.applyIncome(ip, 1, 0)
	ip.discovered = cp.discovered
	local withBonus = Economy.applyIncome(ip, 1, 0)
	check("бонус набора: осьминог 25 -> 28 (+10%, округление), без набора 25", noBonus == 25 and withBonus == 28)
	local sp3 = { coins = 0, tanks = { lagoon = { slots = 5, fish = { fishOf(1, "guppy", "golden", 0), fishOf(2, "clown", "normal", 0) } } }, discovered = {}, seen = {}, speciesStats = {} }
	Collection.sync(sp3)
	check("синхронизация записывает рыб в память", sp3.seen["guppy/golden"] == true and sp3.seen["clown/normal"] == true)

	-- ===== Музей: посетители, заказы, билеты =====
	local Visitors = require(ServerScriptService.Visitors)
	local VC = FishConfig.Visitors
	local function museumProfile(fish)
		return { coins = 0, nextFishId = 1, tanks = { lagoon = { slots = 10, fish = fish or {} } }, discovered = {}, seen = {}, speciesStats = {} }
	end
	local vp = museumProfile()
	local T0 = 1000000
	check("музей: очередь создаётся из 3 заказов", Visitors.refresh(vp, T0, Random.new(1)) == true and #vp.visitors.slots == VC.QUEUE_SIZE)
	local allOrders, distinct, onlyOpenTanks = true, {}, true
	for _, slot in ipairs(vp.visitors.slots) do
		allOrders = allOrders and slot.species ~= nil
		distinct[slot.species] = true
		onlyOpenTanks = onlyOpenTanks and FishConfig.Species[slot.species].tank == "lagoon"
	end
	local distinctCount = 0
	for _ in pairs(distinct) do
		distinctCount += 1
	end
	check("музей: все места заняты, виды разные, только из открытых аквариумов", allOrders and distinctCount == 3 and onlyOpenTanks)
	check("музей: ранг 1 — только обычные/редкие, без золотых, стадия 1", (function()
		for _, slot in ipairs(vp.visitors.slots) do
			local rarity = FishConfig.Species[slot.species].rarity
			if (rarity ~= "common" and rarity ~= "rare") or slot.variant ~= "normal" or slot.stage ~= 1 then
				return false
			end
		end
		return true
	end)())
	check("музей: повторный refresh ничего не меняет", Visitors.refresh(vp, T0 + 1, Random.new(2)) == false)

	local order1 = vp.visitors.slots[1]
	local okNo, whyNo = Visitors.fulfill(vp, order1.id, T0 + 5)
	check("показ без подходящей рыбы отклоняется", okNo == false and whyNo == "nofish" and vp.visitors.tickets == 0)
	table.insert(vp.tanks.lagoon.fish, { id = 1, species = order1.species, variant = "normal", born = T0, earned = 0 })
	local okYes, info = Visitors.fulfill(vp, order1.id, T0 + 10)
	check("показ рыбы даёт билеты, рыба остаётся", okYes == true and info.tickets == order1.tickets and vp.visitors.tickets == order1.tickets and #vp.tanks.lagoon.fish == 1)
	check("показ: заказ выполняется один раз", Visitors.fulfill(vp, order1.id, T0 + 11) == false)
	check("после показа место ждёт нового гостя", vp.visitors.slots[1].species == nil and vp.visitors.slots[1].waitUntil == T0 + 10 + VC.REFILL_DELAY)
	Visitors.refresh(vp, T0 + 20, Random.new(3))
	check("новый гость не приходит раньше срока", vp.visitors.slots[1].species == nil)
	Visitors.refresh(vp, T0 + 10 + VC.REFILL_DELAY, Random.new(3))
	check("через REFILL_DELAY приходит новый гость", vp.visitors.slots[1].species ~= nil)

	-- просроченный заказ заменяется без штрафа
	local ticketsBefore = vp.visitors.tickets
	local expiredId = vp.visitors.slots[2].id
	Visitors.refresh(vp, vp.visitors.slots[2].expires + 1, Random.new(4))
	check("просроченный заказ заменяется новым, билеты не отнимаются", vp.visitors.slots[2].id ~= expiredId and vp.visitors.slots[2].species ~= nil and vp.visitors.tickets == ticketsBefore)

	-- требования: стадия и цвет
	local sp = museumProfile({ { id = 1, species = "guppy", variant = "normal", born = T0, earned = 0 } })
	local needAdult = { species = "guppy", stage = 3, variant = "normal" }
	local needGolden = { species = "guppy", stage = 1, variant = "golden" }
	check("малёк не подходит под заказ «взрослая»", Visitors.matchingFish(sp, needAdult, T0 + 10) == nil)
	check("взрослая рыба подходит", Visitors.matchingFish(sp, needAdult, T0 + 1800) ~= nil)
	check("обычная не подходит под заказ «золотая»", Visitors.matchingFish(sp, needGolden, T0 + 10) == nil)
	sp.tanks.lagoon.fish[1].variant = "rainbow"
	check("радужная подходит под заказ «золотая» (цвет не хуже)", Visitors.matchingFish(sp, needGolden, T0 + 10) ~= nil)

	-- ранг и награда
	check("ранги по порогам выполненных заказов", Visitors.rank(0) == 1 and Visitors.rank(4) == 1 and Visitors.rank(5) == 2 and Visitors.rank(15) == 3 and Visitors.rank(500) == #VC.RankThresholds)
	check("награда растёт с редкостью, стадией и цветом", Visitors.reward("guppy", 1, "normal", 1) == 2 and Visitors.reward("octopus", 3, "golden", 1) > Visitors.reward("octopus", 1, "normal", 1) and Visitors.reward("guppy", 1, "normal", 6) > 2)
	local hp = museumProfile()
	hp.visitors = { tickets = 0, completed = 200, nextId = 1, slots = {} }
	Visitors.refresh(hp, T0, Random.new(7))
	local advancedOk = true
	for _, slot in ipairs(hp.visitors.slots) do
		advancedOk = advancedOk and slot.species ~= nil and slot.stage >= 1 and slot.stage <= 3 and FishConfig.Variants[slot.variant] ~= nil
	end
	check("на высоком ранге заказы валидны", advancedOk)
	local summary = Visitors.summary(vp, T0 + 30)
	check("сводка для клиента: билеты, ранг и 3 строки очереди", summary.tickets == vp.visitors.tickets and summary.rank == 1 and #summary.orders == 3 and summary.nextRankAt == 5)
	check("траты билетов: хватает/не хватает", Visitors.spend(vp, vp.visitors.tickets + 1) == false and Visitors.spend(vp, 1) == true and Visitors.spend(vp, 0) == false)

	-- ===== Магазин 2.0: пассы и стартовый набор =====
	local offlineProfile = function()
		return { coins = 0, lastSeen = 1000, tanks = { lagoon = { slots = 5, fish = { { id = 1, species = "guppy", variant = "normal", born = 0, earned = 0 } } } }, speciesStats = {} }
	end
	local op2 = offlineProfile()
	local normalGain, normalCapped = Economy.applyOffline(op2, 1000 + 24 * 3600, 1)
	local op3 = offlineProfile()
	local longGain, longCapped = Economy.applyOffline(op3, 1000 + 24 * 3600, 1, FishConfig.Shop.NightWatch.offlineMax)
	check("офлайн: обычный лимит 2 часа, копилка заполнена", normalGain == FishConfig.offlineTicks(24 * 3600) * FishConfig.incomeOf("guppy", "normal", 1000) and normalCapped == true)
	check("офлайн: Night Watchman копит в 6 раз дольше (12 часов)", longGain == normalGain * 6 and longCapped == true)
	local op4 = offlineProfile()
	local _, shortCapped = Economy.applyOffline(op4, 1000 + 600, 1, FishConfig.Shop.NightWatch.offlineMax)
	check("офлайн: короткое отсутствие копилку не заполняет", shortCapped == false)

	local starterConfig = FishConfig.Shop.StarterPack
	local realStarterId = starterConfig.productId
	check("стартовый набор: пока id = 0, он не предлагается", (function()
		starterConfig.productId = 0
		return Shop.starterOffer({ sessions = 5, starter = { offeredAt = 0, bought = false } }, T0) == nil
	end)())
	starterConfig.productId = 222
	local stp = { coins = 0, nextFishId = 1, sessions = 1, discovered = {}, tanks = { lagoon = FishConfig.newTank() }, speciesStats = {}, receipts = { list = {}, seen = {} } }
	check("стартовый набор: в первой сессии не показываем", Shop.starterOffer(stp, T0) == nil)
	stp.sessions = 2
	local leftFirst = Shop.starterOffer(stp, T0)
	check("стартовый набор: во второй сессии есть 24 часа", leftFirst == starterConfig.offerHours * 3600)
	check("стартовый набор: таймер не перезапускается", Shop.starterOffer(stp, T0 + 3600) == starterConfig.offerHours * 3600 - 3600)
	check("стартовый набор: по истечении времени пропадает", Shop.starterOffer(stp, T0 + starterConfig.offerHours * 3600 + 1) == nil)
	check("стартовый набор: выдаёт монеты, билеты и известную рыбу", (function()
		local result = Shop.grant(stp, 222, "s1", T0)
		local fish = stp.tanks.lagoon.fish[1]
		return result == "granted"
			and stp.coins >= FishConfig.Shop.MIN_COINS
			and stp.visitors.tickets == starterConfig.tickets
			and fish ~= nil and fish.species == starterConfig.fish.species and fish.variant == starterConfig.fish.variant
			and stp.starter.bought == true
	end)())
	check("стартовый набор: после покупки не предлагается", Shop.starterOffer(stp, T0 + 10) == nil)
	check("стартовый набор: разовый, повторная покупка даёт только монеты", (function()
		local coinsBefore = stp.coins
		Shop.grant(stp, 222, "s2", T0)
		return stp.visitors.tickets == starterConfig.tickets and #stp.tanks.lagoon.fish == 1 and stp.coins > coinsBefore
	end)())
	starterConfig.productId = realStarterId

	local bigQueue = museumProfile()
	Visitors.refresh(bigQueue, T0, Random.new(9), FishConfig.Visitors.QUEUE_SIZE + FishConfig.Shop.SecondHall.extraQueue)
	check("Second Hall: в очереди на 3 места больше", #bigQueue.visitors.slots == 6 and Visitors.summary(bigQueue, T0, 6).orders[6] ~= nil)

	-- ===== Течения и мутации =====
	local Currents = require(ServerScriptService.Currents)
	local CC = FishConfig.Currents
	check("мутация: множитель по id, неизвестная = 1", FishConfig.mutationMult("pearl") == 1.4 and FishConfig.mutationMult(nil) == 1 and FishConfig.mutationMult("nope") == 1)
	check("мутация: доход растёт (кит радужный взрослый 100 -> 140)", FishConfig.incomeOf("whale", "rainbow", 3600, "pearl") == 140)
	check("мутация: выбор по весам даёт только известные", (function()
		local rng = Random.new(5)
		local counts = { bubble = 0, glow = 0, pearl = 0 }
		for _ = 1, 3000 do
			local id = FishConfig.rollMutation(rng)
			if counts[id] == nil then
				return false
			end
			counts[id] += 1
		end
		return counts.bubble > counts.glow and counts.glow > counts.pearl
	end)())

	local function currentProfile(fishCount)
		local profile = { coins = 0, nextFishId = 1, tanks = { lagoon = FishConfig.newTank() }, speciesStats = {}, seen = {} }
		for i = 1, fishCount do
			table.insert(profile.tanks.lagoon.fish, { id = i, species = "whale", variant = "normal", born = 0, earned = 0 })
		end
		profile.nextFishId = fishCount + 1
		return profile
	end
	local cp = currentProfile(3)
	local rngC = Random.new(11)
	Currents.reset(cp, 1000, rngC)
	check("течение: следующее назначено через 20–40 минут", cp.nextCurrentAt >= 1000 + CC.MIN_GAP and cp.nextCurrentAt <= 1000 + CC.MAX_GAP)
	check("течение: раньше срока не начинается", Currents.update(cp, cp.nextCurrentAt - 1, rngC) == nil and cp.current == nil)
	local startAt = cp.nextCurrentAt
	local started = Currents.update(cp, startAt, rngC)
	check("течение: в срок начинается в аквариуме с рыбой", started ~= nil and started.kind == "started" and started.tank == "lagoon" and cp.current.endsAt == startAt + CC.DURATION)
	check("течение: множитель ×1.5 только внутри окна и только в своём аквариуме", Currents.multiplier(cp, "lagoon", startAt + 10) == CC.INCOME_MULT and Currents.multiplier(cp, "lagoon", startAt + CC.DURATION) == 1 and Currents.multiplier(cp, "volcano", startAt + 10) == 1)
	local calm = currentProfile(1)
	local calmGain = Economy.applyIncome(calm, 1, 5000, 1)
	local boosted = currentProfile(1)
	boosted.current = { tank = "lagoon", startedAt = 4000, endsAt = 6000 }
	local boostedGain = Economy.applyIncome(boosted, 1, 5000, 1)
	check("течение: доход аквариума ×1.5", boostedGain == math.floor(calmGain * CC.INCOME_MULT + 0.5))
	check("течение: во время него новое не начинается", Currents.update(cp, startAt + 60, rngC) == nil)
	local summaryDuring = Currents.summary(cp, startAt + 60)
	check("течение: сводка показывает аквариум и остаток времени", summaryDuring.current ~= nil and summaryDuring.current.tank == "lagoon" and summaryDuring.current.left == CC.DURATION - 60)
	local endedEvent = Currents.update(cp, startAt + CC.DURATION, rngC)
	local mutatedCount = 0
	for _, fish in ipairs(cp.tanks.lagoon.fish) do
		if fish.mutation ~= nil then
			mutatedCount += 1
		end
	end
	check("течение: после конца мутации получают ровно две рыбы", endedEvent ~= nil and endedEvent.kind == "ended" and #endedEvent.mutated == CC.MUTATED_FISH and mutatedCount == CC.MUTATED_FISH)
	check("течение: течения нет, следующее назначено", cp.current == nil and cp.nextCurrentAt >= startAt + CC.DURATION + CC.MIN_GAP)
	local firstMutation = endedEvent.mutated[1].mutation
	check("мутации: найденные отмечены в сводке", Currents.summary(cp, startAt).mutations[firstMutation].seen == true and Currents.summary(cp, startAt).mutations[firstMutation].count >= 1)
	local lonely = currentProfile(1)
	lonely.current = { tank = "lagoon", startedAt = 0, endsAt = 10 }
	Currents.update(lonely, 20, Random.new(2))
	check("мутации: с одной рыбой мутирует она одна, повторно не мутирует", lonely.tanks.lagoon.fish[1].mutation ~= nil)
	local emptyTank = currentProfile(0)
	Currents.reset(emptyTank, 0, Random.new(3))
	check("течение: в пустом аквариуме не начинается", Currents.update(emptyTank, emptyTank.nextCurrentAt, Random.new(3)) == nil and emptyTank.current == nil)
	check("доход с мутацией: ×множитель", (function()
		local a = currentProfile(1)
		local b = currentProfile(1)
		b.tanks.lagoon.fish[1].mutation = "pearl"
		return Economy.incomePerTick(b, 5000) == math.floor(FishConfig.incomeOf("whale", "normal", 5000, "pearl") + 0.5) and Economy.incomePerTick(b, 5000) > Economy.incomePerTick(a, 5000)
	end)())
	local mergeProfile = currentProfile(0)
	for i = 1, 5 do
		table.insert(mergeProfile.tanks.lagoon.fish, { id = i, species = "guppy", variant = "normal", born = i, earned = 0, mutation = if i == 2 then "bubble" elseif i == 3 then "glow" else nil })
	end
	mergeProfile.nextFishId = 6
	local mergedOk, mergedFish = Merge.perform(mergeProfile, 1, 100)
	check("слияние: новая рыба наследует лучшую мутацию", mergedOk == true and mergedFish.mutation == "glow")

	-- ===== Короткая запись чисел =====
	local Strings = require(ReplicatedStorage.Shared.Strings)
	check("число: до 1000 без сокращения", Strings.num(0) == "0" and Strings.num(7) == "7" and Strings.num(999) == "999")
	check("число: 1000 -> 1K, 1500 -> 1.5K, 12345 -> 12.3K", Strings.num(1000) == "1K" and Strings.num(1500) == "1.5K" and Strings.num(12345) == "12.3K")
	check("число: 100000 -> 100K, 999999 -> 999K (без 1000K)", Strings.num(100000) == "100K" and Strings.num(999999) == "999K")
	check("число: миллион, миллиард, триллион", Strings.num(1000000) == "1M" and Strings.num(17187818) == "17.1M" and Strings.num(1e9) == "1B" and Strings.num(2.5e12) == "2.5T")
	check("число: отрицательные", Strings.num(-1500) == "-1.5K")
	check("текст с числом от 1000 сокращается, от 999 — нет", Strings.t("coins", 1500) == "1.5K" and Strings.t("coins", 999) == "999")

	-- ===== Экономическая аналитика =====
	local Telemetry = require(ServerScriptService.Telemetry)
	local sent = {}
	Telemetry._setSender(function(_, flow, amount, balance, txType, sku)
		table.insert(sent, { flow = flow, amount = amount, balance = balance, txType = txType, sku = sku })
	end)
	local fakePlayer = {}
	Telemetry.sink(fakePlayer, 50, 10, Telemetry.TxType.Shop, "pack_lagoon")
	Telemetry.source(fakePlayer, 0, 10, Telemetry.TxType.Gameplay, "x")
	check("аналитика: трата отправлена как sink, нулевая сумма пропущена", #sent == 1 and sent[1].flow == "sink" and sent[1].amount == 50 and sent[1].sku == "pack_lagoon")
	Telemetry.addIncome(fakePlayer, "fish_income", 3)
	Telemetry.addIncome(fakePlayer, "fish_income", 4)
	check("аналитика: доход копится без отправки", #sent == 1 and Telemetry.pendingFor(fakePlayer).fish_income == 7)
	Telemetry.flush(fakePlayer, 99)
	check("аналитика: flush шлёт одно событие с суммой и балансом", #sent == 2 and sent[2].flow == "source" and sent[2].amount == 7 and sent[2].balance == 99 and Telemetry.pendingFor(fakePlayer) == nil)
	Telemetry.flush(fakePlayer, 99)
	check("аналитика: повторный flush ничего не шлёт", #sent == 2)
	Telemetry._setSender(nil)

	-- ===== Конфиг =====
	for packId, pack in pairs(FishConfig.Packs) do
		local sum = 0
		for _, rarity in ipairs(FishConfig.RarityOrder) do
			sum += pack.odds[rarity] or 0
		end
		check("пак " .. packId .. ": шансы в сумме 100%", math.abs(sum - 100) < 0.001)
	end
	local speciesOk = true
	for _, id in ipairs(FishConfig.SpeciesOrder) do
		local species = FishConfig.Species[id]
		if species == nil or FishConfig.Rarities[species.rarity] == nil then
			speciesOk = false
		end
	end
	check("у всех видов из SpeciesOrder есть описание и редкость", speciesOk)
	local pricesOk = true
	local last = 0
	for n = FishConfig.START_SLOTS + 1, FishConfig.MAX_SLOTS do
		local price = FishConfig.SlotPrices[n]
		if price == nil or price <= last then
			pricesOk = false
		end
		last = price or last
	end
	check("цены мест заданы и растут", pricesOk)

	table.insert(results, 1, string.format("Итого: %d проверок, провалено %d", #results, failed))
	return table.concat(results, "\n")
end
