-- Currents: течения и мутации. Только сервер.
-- Профиль: profile.nextCurrentAt (когда начнётся следующее течение), profile.current = { tank, startedAt, endsAt } или nil,
-- profile.mutSeen = { [мутация] = true }. У рыбы может быть fish.mutation.
-- Течения идут только пока игрок в игре: при входе расписание начинается заново (Currents.reset).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Currents = {}

local C = FishConfig.Currents
local defaultRng = Random.new()

-- Назначает время следующего течения
function Currents.schedule(profile, now, rng)
	rng = rng or defaultRng
	profile.nextCurrentAt = now + rng:NextInteger(C.MIN_GAP, C.MAX_GAP)
end

-- Вход игрока: старое течение сбрасывается, следующее назначается заново
function Currents.reset(profile, now, rng)
	profile.current = nil
	profile.mutSeen = profile.mutSeen or {}
	Currents.schedule(profile, now, rng)
end

-- Во сколько раз течение усиливает доход аквариума tankId в момент at (1, если течения нет)
function Currents.multiplier(profile, tankId, at)
	local current = profile.current
	if current ~= nil and current.tank == tankId and at >= current.startedAt and at < current.endsAt then
		return C.INCOME_MULT
	end
	return 1
end

-- Рыбы аквариума без мутации
local function plainFish(tankData)
	local list = {}
	for _, fish in ipairs(tankData.fish) do
		if fish.mutation == nil then
			table.insert(list, fish)
		end
	end
	return list
end

-- Двигает течения вперёд. Возвращает nil или событие:
-- { kind = "started", tank, endsAt } / { kind = "ended", tank, mutated = { { id, mutation }, ... } }
function Currents.update(profile, now, rng)
	rng = rng or defaultRng
	profile.mutSeen = profile.mutSeen or {}
	local current = profile.current
	if current ~= nil then
		if now < current.endsAt then
			return nil
		end
		local mutated = {}
		local tankData = profile.tanks[current.tank]
		if tankData ~= nil then
			local candidates = plainFish(tankData)
			for _ = 1, C.MUTATED_FISH do
				if #candidates == 0 then
					break
				end
				local fish = table.remove(candidates, rng:NextInteger(1, #candidates))
				fish.mutation = FishConfig.rollMutation(rng)
				profile.mutSeen[fish.mutation] = true
				table.insert(mutated, { id = fish.id, mutation = fish.mutation })
			end
		end
		profile.current = nil
		Currents.schedule(profile, now, rng)
		return { kind = "ended", tank = current.tank, mutated = mutated }
	end

	if now < (profile.nextCurrentAt or 0) then
		return nil
	end
	-- течение бывает в аквариуме, где есть хотя бы одна рыба
	local tanks = {}
	for tankId, tankData in pairs(profile.tanks) do
		if #tankData.fish > 0 then
			table.insert(tanks, tankId)
		end
	end
	table.sort(tanks)
	if #tanks == 0 then
		Currents.schedule(profile, now, rng)
		return nil
	end
	local tankId = tanks[rng:NextInteger(1, #tanks)]
	profile.current = { tank = tankId, startedAt = now, endsAt = now + C.DURATION }
	return { kind = "started", tank = tankId, endsAt = profile.current.endsAt }
end

-- Для клиента: активное течение (сколько секунд осталось) и сводка по мутациям (сколько рыб, находили ли)
function Currents.summary(profile, now)
	local counts = {}
	for _, tankData in pairs(profile.tanks) do
		for _, fish in ipairs(tankData.fish) do
			if fish.mutation ~= nil then
				counts[fish.mutation] = (counts[fish.mutation] or 0) + 1
			end
		end
	end
	local mutations = {}
	local seen = profile.mutSeen or {}
	for _, id in ipairs(FishConfig.MutationOrder) do
		mutations[id] = { count = counts[id] or 0, seen = seen[id] == true or (counts[id] or 0) > 0 }
	end
	local active = nil
	local current = profile.current
	if current ~= nil and now < current.endsAt then
		active = { tank = current.tank, left = current.endsAt - now }
	end
	return { current = active, mutations = mutations }
end

return Currents
