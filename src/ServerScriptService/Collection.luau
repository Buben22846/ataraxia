-- Collection: наборы коллекции и бонусы к доходу. Только сервер.
-- profile.seen — какие сочетания «вид/цвет» у игрока когда-либо были: seen["guppy/golden"] = true.
-- Это вечная память: рыбу можно продать или слить, а запись остаётся, и собранный набор не пропадает.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Collection = {}

local function key(speciesId, variantId)
	return speciesId .. "/" .. (variantId or "normal")
end
Collection.key = key

-- Запомнить, что такая рыба у игрока была
function Collection.mark(profile, speciesId, variantId)
	if profile.seen == nil then
		profile.seen = {}
	end
	profile.seen[key(speciesId, variantId)] = true
end

-- Дописать в память всех рыб, которые сейчас плавают в аквариумах (старые профили, админ-выдача и т.п.).
-- Только добавляет, ничего не стирает.
function Collection.sync(profile)
	if profile.seen == nil then
		profile.seen = {}
	end
	for _, tankData in pairs(profile.tanks) do
		for _, fish in ipairs(tankData.fish) do
			profile.seen[key(fish.species, fish.variant)] = true
		end
	end
end

-- Прогресс набора аквариума: по ступеням { id, variant, have, need, done, bonus }
function Collection.tankProgress(profile, tankId)
	local ids = FishConfig.speciesOfTank(tankId)
	local seen = profile.seen or {}
	local discovered = profile.discovered or {}
	local result = {}
	for _, tier in ipairs(FishConfig.SetTiers) do
		local have = 0
		for _, speciesId in ipairs(ids) do
			local got
			if tier.variant == nil then
				got = discovered[speciesId] == true
			else
				got = seen[key(speciesId, tier.variant)] == true
			end
			if got then
				have += 1
			end
		end
		table.insert(result, {
			id = tier.id,
			variant = tier.variant,
			have = have,
			need = #ids,
			done = #ids > 0 and have == #ids,
			bonus = tier.bonus,
		})
	end
	return result
end

-- Суммарная прибавка к доходу рыб аквариума (0.10 = +10%)
function Collection.bonus(profile, tankId)
	local total = 0
	for _, tier in ipairs(Collection.tankProgress(profile, tankId)) do
		if tier.done then
			total += tier.bonus
		end
	end
	return total
end

-- Всё для клиента: { [tankId] = { bonus = число, tiers = { {id, have, need, done, bonus}, ... } } }
function Collection.summary(profile)
	local result = {}
	for _, tankId in ipairs(FishConfig.allTanks()) do
		local tiers = Collection.tankProgress(profile, tankId)
		local bonus = 0
		for _, tier in ipairs(tiers) do
			if tier.done then
				bonus += tier.bonus
			end
		end
		result[tankId] = { bonus = bonus, tiers = tiers }
	end
	return result
end

return Collection
