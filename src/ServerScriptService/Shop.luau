-- Shop: правила покупок за Robux (геймпасс x2 и товары «монеты»). Чистая логика без Roblox-сервисов,
-- поэтому проверяется тестами. Сами запросы к MarketplaceService делает GameServer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Economy = require(ServerScriptService:WaitForChild("Economy"))

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
	return nil
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
	receipts.seen[purchaseId] = true
	table.insert(receipts.list, purchaseId)
	if #receipts.list > MAX_RECEIPTS then
		local oldest = table.remove(receipts.list, 1)
		receipts.seen[oldest] = nil
	end
	return "granted"
end

return Shop
