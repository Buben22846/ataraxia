-- Leaderboards: глобальные таблицы лидеров (OrderedDataStore). Только сервер.
-- Недельные таблицы — отдельное хранилище на каждую неделю ("lb_likes_w2913"), поэтому «сброс» происходит сам.
-- Очки игрока пишем не чаще WRITE_EVERY и только если они изменились; топ читаем раз в READ_EVERY и раздаём из кеша.
-- Любые ошибки хранилища гасим: таблица лидеров не должна ломать игру.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Social = require(script.Parent:WaitForChild("Social"))

local Leaderboards = {}
local L = FishConfig.Leaderboards

local service = DataStoreService
function Leaderboards._setService(mock)
	service = mock or DataStoreService
end

-- Заказы музея за неделю: profile.weekly = { week, orders }
function Leaderboards.weekly(profile, now)
	local w = profile.weekly
	local week = Social.week(now)
	if w == nil or w.week ~= week then
		w = { week = week, orders = 0 }
		profile.weekly = w
	end
	return w
end
function Leaderboards.addOrder(profile, now)
	local w = Leaderboards.weekly(profile, now)
	w.orders += 1
end

-- Очки игрока в таблице board
function Leaderboards.score(profile, board, now)
	if board == "likes" then
		return Social.ensure(profile, now).likesWeek
	elseif board == "museum" then
		return Leaderboards.weekly(profile, now).orders
	elseif board == "collection" then
		local count = 0
		for _ in pairs(profile.seen or {}) do
			count += 1
		end
		return count
	end
	return 0
end

function Leaderboards.storeName(board, now)
	local def = L.Boards[board]
	if def ~= nil and def.weekly then
		return "lb_" .. board .. "_w" .. tostring(Social.week(now))
	end
	return "lb_" .. board
end

-- ===== Запись очков =====
local lastWrite = {} -- [userId] = { at, [board] = score }

function Leaderboards.write(userId, profile, now, force)
	local last = lastWrite[userId]
	if last == nil then
		last = { at = 0 }
		lastWrite[userId] = last
	end
	if not force and now - last.at < L.WRITE_EVERY then
		return
	end
	last.at = now
	for _, board in ipairs(L.ORDER) do
		local score = Leaderboards.score(profile, board, now)
		local key = board .. "@" .. Leaderboards.storeName(board, now)
		if score > 0 and last[key] ~= score then
			local ok = pcall(function()
				service:GetOrderedDataStore(Leaderboards.storeName(board, now)):SetAsync(tostring(userId), score)
			end)
			if ok then
				last[key] = score
			end
		end
	end
end

function Leaderboards.forget(userId)
	lastWrite[userId] = nil
end

-- ===== Чтение топа =====
local cache = {} -- [board] = { at, store, list = { {userId, name, score}, ... } }
local names = {} -- [userId] = отображаемое имя

local function resolveNames(ids)
	local missing = {}
	for _, id in ipairs(ids) do
		if names[id] == nil then
			table.insert(missing, id)
		end
	end
	if #missing > 0 then
		pcall(function()
			for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(missing)) do
				names[info.Id] = info.DisplayName
			end
		end)
	end
end

function Leaderboards.top(board, now)
	if L.Boards[board] == nil then
		return {}
	end
	local store = Leaderboards.storeName(board, now)
	local entry = cache[board]
	if entry ~= nil and entry.store == store and now - entry.at < L.READ_EVERY then
		return entry.list
	end
	local list = {}
	local ok = pcall(function()
		local pages = service:GetOrderedDataStore(store):GetSortedAsync(false, L.TOP)
		for _, item in ipairs(pages:GetCurrentPage()) do
			local id = tonumber(item.key)
			if id ~= nil then
				table.insert(list, { userId = id, score = item.value })
			end
		end
	end)
	if not ok then
		return if entry ~= nil then entry.list else {}
	end
	local ids = {}
	for _, row in ipairs(list) do
		table.insert(ids, row.userId)
	end
	resolveNames(ids)
	for _, row in ipairs(list) do
		row.name = names[row.userId] or ("#" .. tostring(row.userId))
	end
	cache[board] = { at = now, store = store, list = list }
	return list
end

-- Неделя кончается через ... секунд (для подписи «сброс через»)
function Leaderboards.weekLeft(now)
	local week = Social.week(now)
	local nextStart = (week + 1) * 7 * 86400 + 4 * 86400
	return nextStart - now
end

return Leaderboards
