-- Telemetry: экономическая аналитика Roblox (Creator Hub -> Analytics -> Economy).
-- Отправляем «получено» (Source) и «потрачено» (Sink) монет. Работает только в опубликованной игре; в Studio события игнорируются.
-- Частый доход рыб копим и шлём раз в минуту одним событием: так просит Roblox, и это дешевле.
-- Любая ошибка аналитики гасится: игра из-за неё ломаться не должна.

local AnalyticsService = game:GetService("AnalyticsService")

local CURRENCY = "Coins"

local Telemetry = {}

Telemetry.TxType = {
	Gameplay = Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
	Shop = Enum.AnalyticsEconomyTransactionType.Shop.Name,
	TimedReward = Enum.AnalyticsEconomyTransactionType.TimedReward.Name,
	IAP = Enum.AnalyticsEconomyTransactionType.IAP.Name,
}

-- Настоящая отправка; в тестах подменяется через _setSender
local function defaultSender(player, flow, amount, balance, txType, sku)
	local flowType = if flow == "source" then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink
	pcall(function()
		AnalyticsService:LogEconomyEvent(player, flowType, CURRENCY, amount, balance, txType, sku)
	end)
end
local sender = defaultSender

local pending = {} -- [player] = { [sku] = накопленная сумма } для доходов, которые шлём пачкой

-- Монеты получены (flow source). balance — баланс после операции.
function Telemetry.source(player, amount, balance, txType, sku)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	sender(player, "source", amount, balance, txType, sku)
end

-- Монеты потрачены (flow sink). amount — положительное число.
function Telemetry.sink(player, amount, balance, txType, sku)
	amount = math.floor(amount)
	if amount <= 0 then
		return
	end
	sender(player, "sink", amount, balance, txType, sku)
end

-- Накопить частый доход (рыбы приносят монеты каждые 5 секунд); отправится при flush
function Telemetry.addIncome(player, sku, amount)
	if amount <= 0 then
		return
	end
	local bucket = pending[player]
	if bucket == nil then
		bucket = {}
		pending[player] = bucket
	end
	bucket[sku] = (bucket[sku] or 0) + amount
end

-- Отправить накопленное игрока (balance — его текущий баланс)
function Telemetry.flush(player, balance)
	local bucket = pending[player]
	if bucket == nil then
		return
	end
	pending[player] = nil
	for sku, amount in pairs(bucket) do
		Telemetry.source(player, amount, balance, Telemetry.TxType.Gameplay, sku)
	end
end

-- Забыть игрока без отправки (на случай, если баланс уже неизвестен)
function Telemetry.forget(player)
	pending[player] = nil
end

function Telemetry.pendingFor(player)
	return pending[player]
end

function Telemetry._setSender(fn)
	sender = fn or defaultSender
end

return Telemetry
