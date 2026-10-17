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
	check("новый игрок: профиль по умолчанию", p1 ~= nil and p1.coins == 100 and p1.slots == FishConfig.START_SLOTS)
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
	check("миграция v1 -> v2: появились места", p7 ~= nil and p7.version == 2 and p7.slots == FishConfig.START_SLOTS)
	check("миграция v1 -> v2: старые данные целы", p7 ~= nil and p7.coins == 321 and #p7.fish == 1 and p7.speciesStats.guppy.pulled == 2)

	data["Player_1005"] = { data = { version = 1, coins = 5 } }
	local p8 = M._claim(1005)
	check("недостающие поля достраиваются", p8 ~= nil and type(p8.fish) == "table" and type(p8.speciesStats) == "table" and p8.nextFishId == 1)

	local a, b = M._newProfile(), M._newProfile()
	a.fish[1] = { id = 1 }
	check("новые профили независимы", #b.fish == 0)

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
