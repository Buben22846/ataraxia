-- Economy: начисление дохода рыб (онлайн и в офлайне). Только сервер.
-- Вынесено из GameServer, чтобы считать одинаково и проверять тестами.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Collection = require(script.Parent:WaitForChild("Collection"))
local Currents = require(script.Parent:WaitForChild("Currents"))

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
-- multiplier (необязателен) — бонус игрока, например x2 по геймпассу; он применяется к каждому доходу.
-- extra (необязателен) — дробный бонус ко всем аквариумам (кормление гостями), считается вместе с наборами и округляется.
function Economy.applyIncome(profile, ticks, at, multiplier, extra)
	multiplier = multiplier or 1
	extra = extra or 1
	local total = 0
	for tankId, tankData in pairs(profile.tanks) do
		local setBonus = (1 + Collection.bonus(profile, tankId)) * Currents.multiplier(profile, tankId, at) * extra -- наборы коллекции × течение × кормление
		for _, fish in ipairs(tankData.fish) do
			-- прибавку наборов округляем для каждой рыбы: монеты всегда целые
			local perTick = math.floor(FishConfig.incomeOf(fish.species, fish.variant, math.max(0, at - fish.born), fish.mutation) * setBonus + 0.5)
			local amount = perTick * ticks * multiplier
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

-- Сколько монет приносят все рыбы за один тик на момент at (с бонусом наборов, без бонуса геймпасса)
function Economy.incomePerTick(profile, at)
	local total = 0
	for tankId, tankData in pairs(profile.tanks) do
		local setBonus = (1 + Collection.bonus(profile, tankId)) * Currents.multiplier(profile, tankId, at)
		for _, fish in ipairs(tankData.fish) do
			total += math.floor(FishConfig.incomeOf(fish.species, fish.variant, math.max(0, at - fish.born), fish.mutation) * setBonus + 0.5)
		end
	end
	return total
end

-- Доход за время, пока игрока не было (от profile.lastSeen до now). Возвращает начисленную сумму.
-- maxSeconds (необязателен) — лимит накопления; пасс Night Watchman даёт больше обычного.
-- Вторым значением возвращает true, если лимит был достигнут (копилка заполнилась).
function Economy.applyOffline(profile, now, multiplier, maxSeconds)
	local last = profile.lastSeen
	if type(last) ~= "number" then
		return 0, false
	end
	local cap = maxSeconds or FishConfig.OFFLINE_MAX
	local capped = (now - last) >= cap
	local ticks = FishConfig.offlineTicks(now - last, cap)
	if ticks <= 0 then
		return 0, false
	end
	return Economy.applyIncome(profile, ticks, last, multiplier), capped
end

return Economy
