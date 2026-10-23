-- Quests: ежедневные мини-задания (чистая логика без Roblox-сервисов, поэтому легко тестируется).
-- Данные лежат в profile.quests = { day, prog = { coins, feed, pack }, claimed = { [id] = true }, bonus = bool }.
-- День считается по UTC, как у ежедневной награды: FishConfig.dayOf(время). На новый день всё обнуляется.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Quests = {}

-- kind: что считаем (coins — подобранные монетки и золотые пузырьки, feed — кормления, pack — открытые паки)
Quests.List = {
	{ id = "coins", kind = "coins", target = 5, reward = 50 },
	{ id = "feed", kind = "feed", target = 10, reward = 50 },
	{ id = "pack", kind = "pack", target = 1, reward = 100 },
}
Quests.BONUS = 200 -- награда за все три задания

local function newState(day)
	return { day = day, prog = { coins = 0, feed = 0, pack = 0 }, claimed = {}, bonus = false }
end

function Quests.newState(day)
	return newState(day)
end

-- Если наступил новый день — обнулить. Возвращает состояние.
local function fresh(profile, now)
	local today = FishConfig.dayOf(now)
	local q = profile.quests
	if type(q) ~= "table" or q.day ~= today then
		q = newState(today)
		profile.quests = q
	end
	return q
end

function Quests.add(profile, kind, n, now)
	local q = fresh(profile, now)
	for _, def in ipairs(Quests.List) do
		if def.kind == kind then
			q.prog[kind] = math.min(def.target, (q.prog[kind] or 0) + n)
			return true
		end
	end
	return false
end

-- Состояние для клиента: только числа и id, тексты клиент берёт из Strings.
function Quests.state(profile, now)
	local q = fresh(profile, now)
	local list = {}
	local done = 0
	for _, def in ipairs(Quests.List) do
		local progress = q.prog[def.kind] or 0
		local complete = progress >= def.target
		if complete then
			done += 1
		end
		table.insert(list, {
			id = def.id,
			kind = def.kind,
			progress = progress,
			target = def.target,
			reward = def.reward,
			claimed = q.claimed[def.id] == true,
		})
	end
	return {
		list = list,
		done = done,
		total = #Quests.List,
		bonus = Quests.BONUS,
		bonusReady = done == #Quests.List and q.bonus ~= true,
		bonusClaimed = q.bonus == true,
		secondsLeft = (q.day + 1) * 86400 - now,
	}
end

-- Забрать награду за задание (id) или за все три ("bonus"). Возвращает (монеты или nil, причина).
function Quests.claim(profile, id, now)
	local q = fresh(profile, now)
	if id == "bonus" then
		if q.bonus then
			return nil, "claimed"
		end
		for _, def in ipairs(Quests.List) do
			if (q.prog[def.kind] or 0) < def.target then
				return nil, "notDone"
			end
		end
		q.bonus = true
		profile.coins += Quests.BONUS
		return Quests.BONUS
	end
	for _, def in ipairs(Quests.List) do
		if def.id == id then
			if q.claimed[id] then
				return nil, "claimed"
			end
			if (q.prog[def.kind] or 0) < def.target then
				return nil, "notDone"
			end
			q.claimed[id] = true
			profile.coins += def.reward
			return def.reward
		end
	end
	return nil, "unknown"
end

return Quests
