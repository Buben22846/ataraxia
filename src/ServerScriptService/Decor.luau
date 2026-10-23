-- Decor: покупное наполнение аквариумов и его бонус к доходу. Только сервер.
-- profile.decor = { [key] = true } — что куплено (ключи и цены лежат в FishConfig.Decor / FishConfig.DecorItems).
-- Бонус каждого предмета действует на доход своего аквариума и складывается с бонусом наборов коллекции.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Decor = {}

-- Суммарная прибавка аквариума от купленного декора (0.07 = +7%)
function Decor.bonus(profile, tankId)
	local owned = profile.decor
	local keys = FishConfig.DecorKeys[tankId]
	if owned == nil or keys == nil then
		return 0
	end
	local total = 0
	for _, key in ipairs(keys) do
		if owned[key] == true then
			total += FishConfig.DecorItems[key].bonus
		end
	end
	return total
end

-- Купить предмет. Возвращает true или false, причина ("unknown", "owned", "tank", "coins").
-- Монеты списывает здесь же; вызывающий пишет телеметрию и обновляет клиент.
function Decor.buy(profile, key)
	local item = FishConfig.DecorItems[key]
	if item == nil then
		return false, "unknown"
	end
	if profile.decor == nil then
		profile.decor = {}
	end
	if profile.decor[key] == true then
		return false, "owned"
	end
	if profile.tanks[item.tank] == nil then
		return false, "tank" -- аквариума у игрока ещё нет
	end
	if profile.coins < item.price then
		return false, "coins"
	end
	profile.coins -= item.price
	profile.decor[key] = true
	return true, item.price
end

-- Для клиента: { owned = { [key] = true }, bonus = { [tankId] = число } }
function Decor.state(profile)
	local owned = {}
	for key, value in pairs(profile.decor or {}) do
		if value == true and FishConfig.DecorItems[key] ~= nil then
			owned[key] = true
		end
	end
	local bonus = {}
	for tankId in pairs(FishConfig.DecorKeys) do
		bonus[tankId] = Decor.bonus(profile, tankId)
	end
	return { owned = owned, bonus = bonus }
end

return Decor
