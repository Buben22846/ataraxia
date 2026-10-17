-- Shop: правила покупок за Robux (геймпасс x2 и товары «монеты»). Чистая логика без Roblox-сервисов,
-- поэтому проверяется тестами. Сами запросы к MarketplaceService делает GameServer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))
local Visitors = require(ServerScriptService:WaitForChild("Visitors"))

local Shop = {}

local MAX_RECEIPTS = 100 -- сколько последних чеков помним, чтобы не выдать товар дважды

-- Найти товар по id (nil, если такого нет или id = 0)
function Shop.productById(productId)
	if productId == nil or productId == 0 then
		return nil
	end
	for _, product in ipairs(FishConfig.Shop.Products) do
		if product.productId == productId then
			return product
		end
	end
	local starter = FishConfig.Shop.StarterPack
	if starter ~= nil and starter.productId == productId then
		return starter
	end
	return nil
end

-- Сколько секунд ещё действует предложение стартового набора (nil — не предлагаем: не настроен, куплен,
-- ещё первая сессия или время вышло). Время отсчитывается по реальным часам от первого показа и не перезапускается.
function Shop.starterOffer(profile, now)
	local pack = FishConfig.Shop.StarterPack
	if pack == nil or pack.productId == 0 then
		return nil
	end
	local state = profile.starter
	if state == nil then
		state = { offeredAt = 0, bought = false }
		profile.starter = state
	end
	if state.bought or (profile.sessions or 0) < 2 then
		return nil
	end
	if (state.offeredAt or 0) == 0 then
		state.offeredAt = now
	end
	local left = state.offeredAt + pack.offerHours * 3600 - now
	if left <= 0 then
		return nil
	end
	return left
end

-- Что стартовый набор даёт кроме монет: билеты музея и заранее известную рыбу (если в аквариуме есть место)
local function grantStarterExtras(profile, now)
	local pack = FishConfig.Shop.StarterPack
	local visitors = Visitors.ensure(profile)
	visitors.tickets += pack.tickets
	local tankData = profile.tanks[pack.fish.tank]
	if tankData ~= nil and #tankData.fish < tankData.slots then
		table.insert(tankData.fish, {
			id = profile.nextFishId,
			species = pack.fish.species,
			variant = pack.fish.variant,
			born = now,
			earned = 0,
		})
		profile.nextFishId += 1
		profile.discovered[pack.fish.species] = true
	end
end

-- Сколько монет даёт товар: время дохода игрока, но не меньше минимума
function Shop.coinsFor(profile, product, now)
	local perTick = Economy.incomePerTick(profile, now)
	local fromIncome = math.floor(perTick / FishConfig.INCOME_INTERVAL * product.seconds)
	return math.max(fromIncome, FishConfig.Shop.MIN_COINS)
end

-- Выдать товар по чеку. Возвращает "granted", "duplicate" или "unknown".
-- Один и тот же purchaseId второй раз монет не даёт.
function Shop.grant(profile, productId, purchaseId, now)
	local product = Shop.productById(productId)
	if product == nil then
		return "unknown"
	end
	local receipts = profile.receipts
	if receipts == nil then
		receipts = { list = {}, seen = {} }
		profile.receipts = receipts
	end
	if receipts.seen[purchaseId] then
		return "duplicate"
	end
	profile.coins += Shop.coinsFor(profile, product, now)
	if product.key == "starter" then
		local state = profile.starter
		if state == nil then
			state = { offeredAt = 0, bought = false }
			profile.starter = state
		end
		if not state.bought then -- набор разовый: повторная покупка даёт только монеты
			grantStarterExtras(profile, now)
			state.bought = true
		end
	end
	receipts.seen[purchaseId] = true
	table.insert(receipts.list, purchaseId)
	if #receipts.list > MAX_RECEIPTS then
		local oldest = table.remove(receipts.list, 1)
		receipts.seen[oldest] = nil
	end
	return "granted"
end

return Shop
