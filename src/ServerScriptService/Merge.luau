-- Merge: слияние MERGE_COUNT одинаковых рыб в одну следующего цвета. Только сервер.
-- Клиент присылает лишь id выбранной рыбы: остальных (самых молодых такого же вида и цвета в том же аквариуме),
-- результат и всё прочее выбирает сервер. Выбранная рыба всегда участвует в слиянии.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Collection = require(script.Parent:WaitForChild("Collection"))

local Merge = {}

-- Находит рыбу по id: возвращает tankId, tankData, fish (или nil)
local function find(profile, fishId)
	for tankId, tankData in pairs(profile.tanks) do
		for _, fish in ipairs(tankData.fish) do
			if fish.id == fishId then
				return tankId, tankData, fish
			end
		end
	end
	return nil
end

-- Выполняет слияние. Возвращает true, новаяРыба, новыйЦветВпервые
-- или false, причина ("missing" — рыбы нет, "max" — цвет уже высший, "count" — не хватает одинаковых рыб).
function Merge.perform(profile, fishId, now)
	local _, tankData, selected = find(profile, fishId)
	if selected == nil then
		return false, "missing"
	end
	local variant = selected.variant or "normal"
	local nextVariant = FishConfig.nextVariant(variant)
	if nextVariant == nil then
		return false, "max"
	end

	local others = {}
	for _, fish in ipairs(tankData.fish) do
		if fish ~= selected and fish.species == selected.species and (fish.variant or "normal") == variant then
			table.insert(others, fish)
		end
	end
	local needOthers = FishConfig.MERGE_COUNT - 1
	if #others < needOthers then
		return false, "count"
	end
	-- в слияние идут самые молодые (меньше всего вложено времени роста)
	table.sort(others, function(a, b)
		if a.born ~= b.born then
			return a.born > b.born
		end
		return a.id > b.id
	end)
	local doomed = { [selected] = true }
	for index = 1, needOthers do
		doomed[others[index]] = true
	end
	-- новая рыба наследует лучшую мутацию из слитых
	local bestMutation = nil
	for fish in pairs(doomed) do
		if fish.mutation ~= nil and FishConfig.mutationMult(fish.mutation) > FishConfig.mutationMult(bestMutation) then
			bestMutation = fish.mutation
		end
	end
	for index = #tankData.fish, 1, -1 do
		if doomed[tankData.fish[index]] then
			table.remove(tankData.fish, index)
		end
	end

	local seenBefore = profile.seen ~= nil and profile.seen[Collection.key(selected.species, nextVariant)] == true
	local newFish = {
		id = profile.nextFishId,
		species = selected.species,
		variant = nextVariant,
		born = now,
		earned = 0,
		mutation = bestMutation,
	}
	profile.nextFishId += 1
	table.insert(tankData.fish, newFish)
	Collection.mark(profile, newFish.species, nextVariant)
	return true, newFish, not seenBefore
end

return Merge
