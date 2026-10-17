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
