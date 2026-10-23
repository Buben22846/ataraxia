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
	Collection.recordEarned(profile)
end

-- Закончена ли ступень по списку видов ids (found — по discovered, золотая/радужная — по seen)
local function tierComplete(profile, tier, ids)
	local seen = profile.seen or {}
	local discovered = profile.discovered or {}
	if #ids == 0 then
		return false
	end
	for _, speciesId in ipairs(ids) do
		local got
		if tier.variant == nil then
			got = discovered[speciesId] == true
		else
			got = seen[key(speciesId, tier.variant)] == true
		end
		if not got then
			return false
		end
	end
	return true
end

-- Заработанные ступени: profile.setsEarned[tankId][tierId] = true. Раз заработанная ступень не пропадает,
-- даже если в аквариум добавили новые виды (каталог растёт, а бонус игрока остаётся).
local function isEarned(profile, tankId, tierId)
	local earned = profile.setsEarned
	return earned ~= nil and earned[tankId] ~= nil and earned[tankId][tierId] == true
end

-- Записать ступени, которые сейчас закончены по текущему каталогу (вызывается из sync)
function Collection.recordEarned(profile)
	if profile.setsEarned == nil then
		profile.setsEarned = {}
	end
	for _, tankId in ipairs(FishConfig.allTanks()) do
		local ids = FishConfig.speciesOfTank(tankId)
		for _, tier in ipairs(FishConfig.SetTiers) do
			if tierComplete(profile, tier, ids) then
				if profile.setsEarned[tankId] == nil then
					profile.setsEarned[tankId] = {}
				end
				profile.setsEarned[tankId][tier.id] = true
			end
		end
	end
end

-- Для миграции старого профиля: какие ступени игрок закончил по ИСХОДНЫМ 25 видам (FishConfig.BaselineSpecies).
-- Только эти ступени засчитываем как заработанные; новые виды добавят прогресс сверх этого.
function Collection.baselineEarned(profile)
	local earned = {}
	for _, tankId in ipairs(FishConfig.allTanks()) do
		local ids = {}
		for _, speciesId in ipairs(FishConfig.speciesOfTank(tankId)) do
			if FishConfig.BaselineSpecies[speciesId] then
				table.insert(ids, speciesId)
			end
		end
		for _, tier in ipairs(FishConfig.SetTiers) do
			if tierComplete(profile, tier, ids) then
				if earned[tankId] == nil then
					earned[tankId] = {}
				end
				earned[tankId][tier.id] = true
			end
		end
	end
	return earned
end

-- Прогресс набора аквариума: по ступеням { id, variant, have, need, done, bonus }
-- done = ступень закончена сейчас ИЛИ была заработана раньше (have/need показывают текущий каталог)
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
			done = (#ids > 0 and have == #ids) or isEarned(profile, tankId, tier.id),
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
