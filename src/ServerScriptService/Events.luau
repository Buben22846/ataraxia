-- Events: сезонные ивенты (аквариум ивента и его валюта). Только сервер.
-- Профиль: profile.events[id] = { candy = конфеты, welcomed = получен ли подарок, online = секунд онлайна до следующей конфеты }.
-- Конфеты копятся только пока ивент идёт; после конца ивента его пак не продаётся, а рыбы и аквариум остаются.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Events = {}

-- Активный ивент: id, описание (или nil)
function Events.active(now)
	for id, def in pairs(FishConfig.Events) do
		if now >= def.startsAt and now < def.endsAt then
			return id, def
		end
	end
	return nil
end

-- Данные ивента в профиле (создаём при первом обращении)
function Events.data(profile, id)
	profile.events = profile.events or {}
	local data = profile.events[id]
	if data == nil then
		data = { candy = 0, welcomed = false, online = 0 }
		profile.events[id] = data
	end
	return data
end

-- Вход игрока: выдаём аквариум ивента и приветственные конфеты (один раз). Возвращает id ивента или nil.
function Events.join(profile, now)
	local id, def = Events.active(now)
	if id == nil then
		return nil
	end
	if profile.tanks[def.tank] == nil then
		profile.tanks[def.tank] = FishConfig.newTank()
	end
	local data = Events.data(profile, id)
	if not data.welcomed then
		data.welcomed = true
		data.candy += def.welcome
	end
	return id
end

-- Начислить конфеты (только во время ивента). Возвращает сколько начислено.
function Events.add(profile, amount, now)
	local id = Events.active(now)
	if id == nil or amount <= 0 then
		return 0
	end
	local data = Events.data(profile, id)
	data.candy += amount
	return amount
end

-- Время онлайн: +1 конфета за каждые onlineEvery секунд. Возвращает сколько начислено.
function Events.onlineTick(profile, seconds, now)
	local id, def = Events.active(now)
	if id == nil then
		return 0
	end
	local data = Events.data(profile, id)
	data.online += seconds
	local gained = 0
	while data.online >= def.onlineEvery do
		data.online -= def.onlineEvery
		data.candy += 1
		gained += 1
	end
	return gained
end

-- Награда ивента за гостя музея (половина билетов, не меньше 1)
function Events.museumReward(tickets, now)
	local id, def = Events.active(now)
	if id == nil then
		return 0
	end
	return math.max(1, math.floor(tickets / def.museumDiv))
end

-- Можно ли сейчас купить пак (за конфеты). Возвращает true или false, причина ("over" — ивент кончился, "candy" — мало конфет)
function Events.canBuy(profile, pack, now)
	local tankDef = FishConfig.Tanks[pack.tank]
	local id = Events.active(now)
	if tankDef == nil or tankDef.event == nil or tankDef.event ~= id then
		return false, "over"
	end
	if Events.data(profile, id).candy < pack.price then
		return false, "candy"
	end
	return true
end

function Events.spend(profile, amount, now)
	local id = Events.active(now)
	if id == nil then
		return false
	end
	local data = Events.data(profile, id)
	if data.candy < amount then
		return false
	end
	data.candy -= amount
	return true
end

-- Для клиента: { id, left = секунд до конца, candy } или nil, если ивента нет
function Events.summary(profile, now)
	local id, def = Events.active(now)
	if id == nil then
		return nil
	end
	return { id = id, left = def.endsAt - now, candy = Events.data(profile, id).candy, tank = def.tank }
end

return Events
