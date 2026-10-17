-- Visitors: посетители музея, заказы, билеты и репутация. Только сервер.
-- Профиль: profile.visitors = { tickets, completed, nextId, slots = { [1..QUEUE_SIZE] = заказ или { waitUntil } } }.
-- Заказ: { id, species, stage (1..3), variant, tickets, expires }. Пустое место ждёт нового гостя до waitUntil.
-- Рыба при показе не тратится. Невыполненный заказ по истечении срока просто заменяется (без штрафа).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Visitors = {}

local V = FishConfig.Visitors
local defaultRng = Random.new()

-- Относительные веса редкостей при выборе вида для заказа
local RARITY_WEIGHT = { common = 6, rare = 3, epic = 1.5, legendary = 0.5 }

-- Создаёт блок данных (и пустые места очереди), если их ещё нет
-- size — сколько мест в очереди (по умолчанию QUEUE_SIZE; пасс Second Hall добавляет места)
function Visitors.ensure(profile, size)
	size = size or V.QUEUE_SIZE
	local v = profile.visitors
	if v == nil then
		v = { tickets = 0, completed = 0, nextId = 1, slots = {} }
		profile.visitors = v
	end
	v.tickets = v.tickets or 0
	v.completed = v.completed or 0
	v.nextId = v.nextId or 1
	v.slots = v.slots or {}
	for i = 1, size do
		if v.slots[i] == nil then
			v.slots[i] = { waitUntil = 0 }
		end
	end
	return v
end

-- Ранг музея по числу выполненных заказов (1 .. #RankThresholds)
function Visitors.rank(completed)
	local rank = 1
	for i, need in ipairs(V.RankThresholds) do
		if completed >= need then
			rank = i
		end
	end
	return rank
end

local function allowedRarity(rarity, rank)
	if rarity == "common" or rarity == "rare" then
		return true
	elseif rarity == "epic" then
		return rank >= 2
	end
	return rank >= 3 -- legendary
end

-- Награда за заказ в билетах
function Visitors.reward(speciesId, stage, variant, rank)
	local species = FishConfig.Species[speciesId]
	local base = V.RarityTickets[species.rarity] or 1
	local value = base * (V.StageMult[stage] or 1) * (V.VariantMult[variant] or 1) * (1 + V.RankBonus * (rank - 1))
	return math.max(1, math.floor(value + 0.5))
end

-- Новый заказ. Виды берём только из открытых аквариумов игрока; вид, который уже просит другой гость, не повторяем.
function Visitors.newOrder(profile, now, rng)
	rng = rng or defaultRng
	local v = Visitors.ensure(profile)
	local rank = Visitors.rank(v.completed)

	local taken = {}
	for _, slot in ipairs(v.slots) do
		if slot.species then
			taken[slot.species] = true
		end
	end

	local candidates, totalWeight = {}, 0
	for _, speciesId in ipairs(FishConfig.SpeciesOrder) do
		local species = FishConfig.Species[speciesId]
		if profile.tanks[species.tank] ~= nil and allowedRarity(species.rarity, rank) and not taken[speciesId] then
			local weight = RARITY_WEIGHT[species.rarity] or 1
			table.insert(candidates, { id = speciesId, weight = weight })
			totalWeight += weight
		end
	end
	local speciesId = "guppy"
	if #candidates > 0 then
		local r = rng:NextNumber() * totalWeight
		local acc = 0
		for _, candidate in ipairs(candidates) do
			acc += candidate.weight
			if r < acc then
				speciesId = candidate.id
				break
			end
		end
	end

	-- стадия: ранг 1 — любая, ранг 2 — иногда подросток, ранг 3+ — бывает и взрослая
	local stage = 1
	local s = rng:NextNumber()
	if rank == 2 then
		stage = if s < 0.5 then 2 else 1
	elseif rank >= 3 then
		stage = if s < 0.3 then 1 elseif s < 0.7 then 2 else 3
	end

	-- цвет: золотой — с ранга 3, радужный — с ранга 5
	local variant = "normal"
	local c = rng:NextNumber()
	if rank >= 5 and c < 0.06 then
		variant = "rainbow"
	elseif rank >= 3 and c < 0.2 then
		variant = "golden"
	end

	local id = v.nextId
	v.nextId += 1
	return {
		id = id,
		species = speciesId,
		stage = stage,
		variant = variant,
		tickets = Visitors.reward(speciesId, stage, variant, rank),
		expires = now + V.ORDER_TTL,
	}
end

-- Обновляет очередь: просроченные заказы заменяются, пустые места заполняются, когда пришло время.
-- Возвращает true, если что-то изменилось.
function Visitors.refresh(profile, now, rng, size)
	size = size or V.QUEUE_SIZE
	local v = Visitors.ensure(profile, size)
	local changed = false
	for i = 1, size do
		local slot = v.slots[i]
		if slot.species then
			if now >= slot.expires then
				v.slots[i] = Visitors.newOrder(profile, now, rng) -- гость ушёл, пришёл другой: без штрафа
				changed = true
			end
		elseif now >= (slot.waitUntil or 0) then
			v.slots[i] = Visitors.newOrder(profile, now, rng)
			changed = true
		end
	end
	return changed
end

-- Рыба игрока, подходящая под заказ (вид совпадает, стадия не младше, цвет не хуже) или nil
function Visitors.matchingFish(profile, order, now)
	local needVariant = FishConfig.variantRank(order.variant)
	for _, tankData in pairs(profile.tanks) do
		for _, fish in ipairs(tankData.fish) do
			if
				fish.species == order.species
				and FishConfig.stageIndex(math.max(0, now - fish.born)) >= order.stage
				and FishConfig.variantRank(fish.variant) >= needVariant
			then
				return fish
			end
		end
	end
	return nil
end

-- Показать рыбу гостю. Возвращает true, { tickets, rank, rankUp } или false, причина ("missing" / "nofish").
function Visitors.fulfill(profile, orderId, now, size)
	size = size or V.QUEUE_SIZE
	local v = Visitors.ensure(profile, size)
	for i = 1, size do
		local order = v.slots[i]
		if order.species and order.id == orderId and now < order.expires then
			if Visitors.matchingFish(profile, order, now) == nil then
				return false, "nofish"
			end
			local oldRank = Visitors.rank(v.completed)
			v.tickets += order.tickets
			v.completed += 1
			v.slots[i] = { waitUntil = now + V.REFILL_DELAY }
			local newRank = Visitors.rank(v.completed)
			return true, { tickets = order.tickets, rank = newRank, rankUp = newRank > oldRank }
		end
	end
	return false, "missing"
end

-- Списать билеты. Возвращает true, если хватило.
function Visitors.spend(profile, amount)
	local v = Visitors.ensure(profile)
	if amount <= 0 or v.tickets < amount then
		return false
	end
	v.tickets -= amount
	return true
end

-- Всё для клиента: билеты, выполнено заказов, ранг, следующий порог и очередь (заказ с флагом ready или ожидание)
function Visitors.summary(profile, now, size)
	size = size or V.QUEUE_SIZE
	local v = Visitors.ensure(profile, size)
	local rank = Visitors.rank(v.completed)
	local orders = {}
	for i = 1, size do
		local slot = v.slots[i]
		if slot.species then
			table.insert(orders, {
				id = slot.id,
				species = slot.species,
				stage = slot.stage,
				variant = slot.variant,
				tickets = slot.tickets,
				left = math.max(0, slot.expires - now),
				ready = Visitors.matchingFish(profile, slot, now) ~= nil,
			})
		else
			table.insert(orders, { waiting = true, left = math.max(0, (slot.waitUntil or 0) - now) })
		end
	end
	return {
		tickets = v.tickets,
		completed = v.completed,
		rank = rank,
		nextRankAt = V.RankThresholds[rank + 1],
		orders = orders,
	}
end

return Visitors
