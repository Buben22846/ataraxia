-- PlayerData: загрузка и сохранение данных игроков (DataStore). Только сервер.
-- Гарантии: повторы с паузами при ошибках, UpdateAsync вместо Get+Set, блокировка сессии
-- (один сервер владеет данными игрока), автосохранение, финальное сохранение при выходе и закрытии сервера,
-- версионирование схемы. Если данные не загрузились, на реальном сервере игрока кикают
-- (иначе пустой профиль перезапишет настоящий); в Studio играем с временным профилем.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Collection = require(game:GetService("ServerScriptService"):WaitForChild("Collection"))

-- ===== НАСТРОЙКИ =====
-- Studio пишет в отдельное хранилище и никогда не трогает сохранения реальных игроков
local STORE_NAME = if RunService:IsStudio() then "PlayerData_Studio_v1" else "PlayerData_v1"
local CURRENT_VERSION = 6
local START_COINS = 100 -- стартовые монеты нового игрока
local AUTOSAVE_INTERVAL = 60 -- секунд между автосохранениями
local LOCK_TIMEOUT = 150 -- блокировка старше этого считается «мёртвой» (сервер упал)
local LOCK_RETRIES = 3 -- сколько раз ждать, пока другой сервер отпустит данные
local LOCK_RETRY_DELAY = 4
local IS_STUDIO = RunService:IsStudio()
local LOAD_ATTEMPTS = if IS_STUDIO then 2 else 5
local SAVE_ATTEMPTS = if IS_STUDIO then 2 else 5
-- =====================

local PlayerData = {}

local store = nil -- создаётся лениво (в тестах подменяется на заглушку)
local jobId = if game.JobId ~= "" then game.JobId else "studio"
local sessions = {} -- player -> { profile, userId, temp, active, saving }

local function getStore()
	if store == nil then
		store = DataStoreService:GetDataStore(STORE_NAME)
	end
	return store
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Каждый вызов DataStore — через pcall с повторами и экспоненциальной паузой
local function withRetry(attempts, fn)
	local delaySeconds = 1
	for attempt = 1, attempts do
		local ok, err = pcall(fn)
		if ok then
			return true
		end
		warn("[PlayerData] попытка " .. attempt .. "/" .. attempts .. " не удалась: " .. tostring(err))
		if attempt < attempts then
			task.wait(delaySeconds)
			delaySeconds = math.min(delaySeconds * 2, 16)
		end
	end
	return false
end

-- ===== Схема профиля =====
local function newProfile()
	return {
		version = CURRENT_VERSION,
		coins = START_COINS,
		nextFishId = 1,
		-- Аквариумы игрока: [tankId] = { slots = сколько рыб помещается, fish = { {id, species, variant, born, earned}, ... } }
		-- У рыбы: born — время покупки (сек), earned — сколько заработала эта рыба.
		tanks = { lagoon = FishConfig.newTank() },
		discovered = {}, -- { [speciesId] = true }
		seen = {}, -- { ["вид/цвет"] = true }: какие сочетания вида и цвета у игрока когда-либо были (наборы коллекции)
		speciesStats = {}, -- { [speciesId] = { pulled = сколько раз выпала, earned = всего заработано видом } }
		lastSeen = os.time(), -- время последнего сохранения (для дохода в офлайне)
		daily = { lastDay = 0, streak = 0 }, -- ежедневная награда: номер последнего дня (UTC) и серия дней подряд
		tutorialDone = false, -- прошёл ли игрок обучение
		settings = { sfx = true, music = true }, -- настройки звука игрока
		receipts = { list = {}, seen = {} }, -- чеки покупок за Robux (чтобы не выдать товар дважды)
		sessions = 0, -- сколько раз игрок заходил (стартовый набор предлагается со второй сессии)
		starter = { offeredAt = 0, bought = false }, -- стартовый набор: когда предложили и куплен ли
		nextCurrentAt = 0, -- когда начнётся следующее течение (os.time)
		mutSeen = {}, -- { [мутация] = true }: какие мутации у игрока когда-либо были
		events = {}, -- { [id ивента] = { candy, welcomed, online } }
		social = {}, -- гости: лайки, бонус кормления, кого кормил и лайкал (см. Social)
		weekly = { week = 0, orders = 0 }, -- заказы музея за неделю (таблица лидеров)
		setsEarned = {}, -- заработанные ступени наборов коллекции: [tankId][tierId] = true (см. Collection)
		decor = {}, -- купленное наполнение аквариумов: { [key] = true } (см. Decor)
	}
end

-- Миграции: [старая версия] = function(data) -> data.
-- v1 -> v2: появились места в аквариуме (slots).
local MIGRATIONS = {
	[1] = function(data)
		data.slots = data.slots or FishConfig.START_SLOTS
		return data
	end,
	-- v2 -> v3: появилось время последнего сохранения (lastSeen) для дохода в офлайне.
	[2] = function(data)
		data.lastSeen = os.time()
		return data
	end,
	-- v3 -> v4: несколько аквариумов; прежние рыбы и места переезжают в «Тихую лагуну».
	[3] = function(data)
		data.tanks = { lagoon = { slots = data.slots or FishConfig.START_SLOTS, fish = data.fish or {} } }
		data.slots = nil
		data.fish = nil
		return data
	end,
	-- v4 -> v5: ежедневная награда и флаг обучения; тот, кто уже играл, обучение не видит.
	[4] = function(data)
		data.daily = { lastDay = 0, streak = 0 }
		data.tutorialDone = true
		return data
	end,
	-- v5 -> v6: каталог вырос с 25 до 50 видов. Ступени наборов, закрытые по прежним 25 видам, остаются заработанными.
	[5] = function(data)
		data.setsEarned = Collection.baselineEarned(data)
		return data
	end,
}

local function migrate(data)
	data.version = data.version or 1
	while data.version < CURRENT_VERSION do
		local step = MIGRATIONS[data.version]
		if not step then
			error("missing migration from v" .. tostring(data.version))
		end
		data = step(data)
		data.version += 1
	end
	-- Страховка: добавляем недостающие поля
	for key, value in pairs(newProfile()) do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function keyFor(userId)
	return "Player_" .. tostring(userId)
end

local function lockIsFresh(old, now)
	return old ~= nil and old.lock ~= nil and old.lock.jobId ~= jobId and now - old.lock.time < LOCK_TIMEOUT
end

-- ===== Загрузка: атомарно занимаем блокировку и читаем профиль =====
-- Возвращает profile или nil, причина ("locked" — данные у другого сервера, "failed" — ошибка DataStore)
local function claim(userId)
	local result = nil
	local lockedByOther = false

	local ok = withRetry(LOAD_ATTEMPTS, function()
		getStore():UpdateAsync(keyFor(userId), function(old)
			result = nil
			lockedByOther = false
			local now = os.time()
			if lockIsFresh(old, now) then
				lockedByOther = true
				return nil -- чужой свежий лок: ничего не меняем
			end
			local data
			if old == nil or old.data == nil then
				data = newProfile()
			else
				data = migrate(deepCopy(old.data))
			end
			result = data
			return { lock = { jobId = jobId, time = now }, data = deepCopy(data) }
		end)
	end)

	if not ok then
		return nil, "failed"
	end
	if lockedByOther then
		return nil, "locked"
	end
	return result
end

-- ===== Сохранение =====
-- release = true: снимаем блокировку (игрок уходит). Иначе обновляем время блокировки.
local function commit(userId, profile, release)
	profile.lastSeen = os.time() -- запоминаем, когда игрок «был здесь» в последний раз
	local lost = false
	local ok = withRetry(SAVE_ATTEMPTS, function()
		getStore():UpdateAsync(keyFor(userId), function(old)
			lost = false
			local now = os.time()
			if lockIsFresh(old, now) then
				lost = true
				return nil -- лок перехвачен другим сервером: не перезаписываем его данные
			end
			return {
				lock = if release then nil else { jobId = jobId, time = now },
				data = deepCopy(profile),
			}
		end)
	end)

	if ok and lost then
		warn("[PlayerData] блокировка перехвачена другим сервером, сохранение пропущено (userId " .. tostring(userId) .. ")")
		return false
	end
	return ok
end

-- ===== Сессии игроков =====

function PlayerData.get(player)
	local session = sessions[player]
	return session and session.profile or nil
end

-- Сбросить прогресс игрока до нового профиля (только для админ-команд).
-- В хранилище попадёт при следующем сохранении.
function PlayerData.reset(player)
	local session = sessions[player]
	if session == nil then
		return nil
	end
	session.profile = newProfile()
	return session.profile
end

-- Сохранить текущий профиль (без снятия блокировки)
function PlayerData.save(player)
	local session = sessions[player]
	if session == nil or session.temp or session.saving then
		return false
	end
	session.saving = true
	local ok = commit(session.userId, session.profile, false)
	session.saving = false
	return ok
end

-- Финальное сохранение и снятие блокировки (игрок вышел или сервер закрывается)
function PlayerData.release(player)
	local session = sessions[player]
	if session == nil then
		return
	end
	session.active = false -- останавливает автосохранение
	while session.saving do
		task.wait() -- дожидаемся текущего автосохранения
	end
	session.saving = true
	if not session.temp then
		commit(session.userId, session.profile, true)
	end
	session.saving = false
	sessions[player] = nil
end

local function startAutosave(player, session)
	task.spawn(function()
		task.wait(10 + (player.UserId % 30)) -- смещение, чтобы игроки не сохранялись одновременно
		while session.active do
			PlayerData.save(player)
			task.wait(AUTOSAVE_INTERVAL)
		end
	end)
end

-- Загрузить игрока. Возвращает profile или nil, причина ("locked" | "failed" | "left").
function PlayerData.load(player)
	local userId = player.UserId
	local profile, reason

	for attempt = 1, LOCK_RETRIES do
		profile, reason = claim(userId)
		if profile ~= nil or reason ~= "locked" then
			break
		end
		if attempt < LOCK_RETRIES then
			task.wait(LOCK_RETRY_DELAY)
		end
	end

	if player.Parent == nil then
		-- игрок ушёл пока грузились данные: отпускаем блокировку
		if profile ~= nil then
			commit(userId, profile, true)
		end
		return nil, "left"
	end

	if profile == nil then
		if reason == "failed" and IS_STUDIO then
			warn("[PlayerData] DataStore недоступен в Studio: играем с временным профилем, без сохранения. Включите Game Settings > Security > Enable Studio Access to API Services.")
			local session = { profile = newProfile(), userId = userId, temp = true, active = true, saving = false }
			sessions[player] = session
			return session.profile
		end
		return nil, reason
	end

	local session = { profile = profile, userId = userId, temp = false, active = true, saving = false }
	sessions[player] = session
	startAutosave(player, session)
	return profile
end

-- При закрытии сервера: сохранить всех параллельно и дождаться (не дольше таймаута)
function PlayerData.releaseAll()
	local list = {}
	for player in pairs(sessions) do
		table.insert(list, player)
	end
	local pending = #list
	for _, player in ipairs(list) do
		task.spawn(function()
			PlayerData.release(player)
			pending -= 1
		end)
	end
	local deadline = os.clock() + (if IS_STUDIO then 8 else 25)
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

-- ===== Только для тестов =====
function PlayerData._setStore(newStore)
	store = newStore
end

function PlayerData._setJobId(newJobId)
	jobId = newJobId
end

PlayerData._claim = claim
PlayerData._commit = commit
PlayerData._newProfile = newProfile

return PlayerData
