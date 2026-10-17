-- PackRoller: чистая логика выпадения рыбы из пака. Только сервер, без побочных эффектов (удобно тестировать).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local PackRoller = {}

local defaultRng = Random.new()

-- Возвращает id вида и id редкости. rng необязателен (нужен для тестов с фиксированным seed).
function PackRoller.roll(pack, rng)
	rng = rng or defaultRng

	local roll = rng:NextNumber() * 100
	local acc = 0
	local chosenRarity = FishConfig.RarityOrder[1]
	for _, rarity in ipairs(FishConfig.RarityOrder) do
		acc += pack.odds[rarity] or 0
		if roll < acc then
			chosenRarity = rarity
			break
		end
	end

	local pool = FishConfig.speciesOfRarity(chosenRarity, pack.tank)
	if #pool == 0 then
		pool = FishConfig.speciesOfTank(pack.tank) -- защита на случай ошибки в конфиге
	end
	local speciesId = pool[rng:NextInteger(1, #pool)]
	return speciesId, FishConfig.Species[speciesId].rarity
end

return PackRoller
