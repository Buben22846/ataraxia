-- Economy: начисление дохода рыб (онлайн и в офлайне). Только сервер.
-- Вынесено из GameServer, чтобы считать одинаково и проверять тестами.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Economy = {}

-- Статистика вида в профиле (создаём, если её ещё нет)
function Economy.statsFor(profile, speciesId)
	local stats = profile.speciesStats[speciesId]
	if stats == nil then
		stats = { pulled = 0, earned = 0 }
		profile.speciesStats[speciesId] = stats
	end
	return stats
end

-- Сколько всего рыб во всех аквариумах игрока
function Economy.fishCount(profile)
	local count = 0
	for _, tankData in pairs(profile.tanks) do
		count += #tankData.fish
	end
	return count
end

-- Начислить доход за `ticks` тиков. Возраст рыб считаем на момент `at` (os.time).
-- Плюсуем к монетам, к заработку рыбы и к статистике вида. Возвращает начисленную сумму.
function Economy.applyIncome(profile, ticks, at)
	local total = 0
	for _, tankData in pairs(profile.tanks) do
		for _, fish in ipairs(tankData.fish) do
			local amount = FishConfig.incomeOf(fish.species, fish.variant, math.max(0, at - fish.born)) * ticks
			if amount > 0 then
				fish.earned += amount
				Economy.statsFor(profile, fish.species).earned += amount
				total += amount
			end
		end
	end
	profile.coins += total
	return total
end

-- Доход за время, пока игрока не было (от profile.lastSeen до now). Возвращает начисленную сумму.
function Economy.applyOffline(profile, now)
	local last = profile.lastSeen
	if type(last) ~= "number" then
		return 0
	end
	local ticks = FishConfig.offlineTicks(now - last)
	if ticks <= 0 then
		return 0
	end
	return Economy.applyIncome(profile, ticks, last)
end

return Economy
