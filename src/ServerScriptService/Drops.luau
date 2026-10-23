-- Drops: монетки от золотых и радужных рыб. Только сервер. Состояние живёт в памяти сервера (на игрока).
-- Сервер выбирает рыбу и выдаёт id монетки; клиент может только «подобрать» монетку с этим id, пока она жива.
-- Сумму считает сервер при выпуске (доход рыбы × тики × бонус игрока), клиент её не присылает.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Drops = {}
local C = FishConfig.Drops

-- state = { nextAt, id, expires, amount, counter }
function Drops.newState(now, rng)
	rng = rng or Random.new()
	return { nextAt = now + rng:NextInteger(C.golden.gapMin, C.golden.gapMax), id = nil, expires = 0, amount = 0, counter = 0 }
end

-- Особые рыбы профиля: список { fish, tankId }
local function specialFish(profile)
	local list = {}
	for tankId, tankData in pairs(profile.tanks) do
		for _, fish in ipairs(tankData.fish) do
			if fish.variant == "golden" or fish.variant == "rainbow" then
				table.insert(list, { fish = fish, tankId = tankId })
			end
		end
	end
	return list
end

-- Пора ли выпустить монетку. multiplier — бонус дохода игрока (пасс ×2 и т.п.).
-- Возвращает { id, fishId, tank, life } или nil.
function Drops.tick(state, profile, now, multiplier, rng)
	rng = rng or Random.new()
	if state.id ~= nil and now > state.expires then
		state.id = nil -- не успели нажать
	end
	if state.id ~= nil or now < state.nextAt then
		return nil
	end
	local list = specialFish(profile)
	if #list == 0 then
		state.nextAt = now + C.RETRY
		return nil
	end
	table.sort(list, function(a, b)
		return a.fish.id < b.fish.id -- одинаковый порядок для тестов с фиксированным rng
	end)
	local pick = list[rng:NextInteger(1, #list)]
	local fish, variant = pick.fish, FishConfig.Drops[pick.fish.variant]
	local income = FishConfig.incomeOf(fish.species, fish.variant, math.max(0, now - fish.born), fish.mutation)
	state.counter += 1
	state.id = state.counter
	state.expires = now + C.LIFE
	state.amount = math.max(C.MIN, math.floor(income * variant.ticks * (multiplier or 1)))
	state.nextAt = now + rng:NextInteger(variant.gapMin, variant.gapMax)
	return { id = state.id, fishId = fish.id, tank = pick.tankId, life = C.LIFE }
end

-- Игрок нажал монетку id. Возвращает сумму или nil (чужой id, просрочено, уже подобрана).
-- Небольшой запас по времени (2 с) — на задержку сети.
function Drops.claim(state, id, now)
	if state.id == nil or id ~= state.id or now > state.expires + 2 then
		return nil
	end
	state.id = nil
	return state.amount
end

return Drops
