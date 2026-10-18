-- Bubbles: золотые пузырьки. Только сервер. Состояние живёт в памяти сервера (на игрока), в профиль не пишется.
-- Сервер сам решает, когда выпустить пузырёк, и выдаёт его id; клиент может только «лопнуть» пузырёк с этим id,
-- пока он жив. Награда считается на сервере от дохода игрока.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Bubbles = {}
local C = FishConfig.Bubbles

-- state = { nextAt, id, expires, counter }
function Bubbles.newState(now, rng)
	rng = rng or Random.new()
	return { nextAt = now + rng:NextInteger(C.GAP_MIN, C.GAP_MAX), id = nil, expires = 0, counter = 0 }
end

-- Пора ли выпустить пузырёк. Возвращает его id и время жизни или nil.
function Bubbles.tick(state, now, rng)
	rng = rng or Random.new()
	if state.id ~= nil and now > state.expires then
		state.id = nil -- не успели нажать
	end
	if state.id == nil and now >= state.nextAt then
		state.counter += 1
		state.id = state.counter
		state.expires = now + C.LIFE
		state.nextAt = now + rng:NextInteger(C.GAP_MIN, C.GAP_MAX)
		return state.id, C.LIFE
	end
	return nil
end

-- Игрок нажал пузырёк id. Возвращает true, если пузырёк настоящий и ещё жив (тогда он исчезает).
-- Небольшой запас по времени (2 с) — на задержку сети.
function Bubbles.claim(state, id, now)
	if state.id == nil or id ~= state.id or now > state.expires + 2 then
		return false
	end
	state.id = nil
	return true
end

function Bubbles.reward(incomePerTick)
	return math.max(C.REWARD_MIN, math.floor(incomePerTick * C.REWARD_TICKS))
end

return Bubbles
