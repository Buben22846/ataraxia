-- Tide: «Большой прилив» — общее для всех серверов событие по расписанию UTC и общая цель сервера. Только сервер.
-- Время прилива одинаково везде: начало каждого периода PERIOD (+OFFSET), длится DURATION.
-- Цель сервера живёт только в памяти сервера (state), профили игроков не меняются, кроме выданной награды.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Tide = {}
local C = FishConfig.Tide

-- Номер текущего периода, его начало и признак «прилив идёт»
function Tide.window(now)
	local index = (now - C.OFFSET) // C.PERIOD
	local startAt = index * C.PERIOD + C.OFFSET
	local active = now - startAt < C.DURATION
	return active, index, startAt
end

function Tide.multiplier(now)
	local active = Tide.window(now)
	return if active then C.INCOME_MULT else 1
end

function Tide.goalFor(players)
	return math.min(C.GOAL_MAX, C.GOAL_BASE + C.GOAL_PER_PLAYER * math.max(1, players))
end

-- Состояние цели сервера. Новый прилив — новое состояние.
function Tide.newState()
	return { index = -1, opened = 0, goal = 0, done = false, participants = {} }
end

-- Обновить состояние под текущее время (players — сколько игроков на сервере). Цель фиксируется в начале прилива,
-- но может вырасти, если игроков стало больше (не уменьшается, чтобы не «дарить» выполнение).
function Tide.sync(state, now, players)
	local active, index = Tide.window(now)
	if state.index ~= index then
		state.index = index
		state.opened = 0
		state.goal = Tide.goalFor(players)
		state.done = false
		state.participants = {}
	elseif active and not state.done then
		state.goal = math.max(state.goal, Tide.goalFor(players))
	end
	return active
end

-- Игрок открыл count паков. Возвращает true, если именно сейчас цель выполнена (раздать награды).
function Tide.onPacks(state, userId, count, now, players)
	if not Tide.sync(state, now, players) or state.done or count <= 0 then
		return false
	end
	state.participants[userId] = true
	state.opened += count
	if state.opened >= state.goal then
		state.done = true
		return true
	end
	return false
end

-- Награда игроку: билеты музея и монеты за REWARD_TICKS тиков дохода (incomePerTick считает вызывающий)
function Tide.reward(profile, incomePerTick)
	local coins = math.max(0, math.floor(incomePerTick * C.REWARD_TICKS))
	profile.coins += coins
	local v = profile.visitors
	if v == nil then
		v = { tickets = 0, completed = 0, nextId = 1, slots = {} }
		profile.visitors = v
	end
	v.tickets = (v.tickets or 0) + C.REWARD_TICKETS
	return { coins = coins, tickets = C.REWARD_TICKETS }
end

-- Что показать клиенту
function Tide.summary(state, userId, now)
	local active, index, startAt = Tide.window(now)
	local same = state.index == index
	return {
		active = active,
		left = if active then startAt + C.DURATION - now else 0,
		nextIn = if active then 0 else startAt + C.PERIOD - now,
		mult = C.INCOME_MULT,
		opened = if same then state.opened else 0,
		goal = if same and state.goal > 0 then state.goal else 0,
		done = same and state.done,
		joined = same and state.participants[userId] == true,
	}
end

return Tide
