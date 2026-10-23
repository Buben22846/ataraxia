-- Social: гости в аквариуме — кормление и лайки между игроками одного сервера. Только сервер.
-- Профиль: profile.social = {
--   likes, likesWeek, week     — сколько лайков получено всего и за текущую неделю (номер недели week);
--   boostUntil                 — до какого времени (os.time) действует бонус кормления;
--   fedAt = { [userId] = t }   — когда этот игрок последний раз кормил чужой аквариум (по хозяевам);
--   likedDay = { [userId] = d } — в какой день (UTC) игрок лайкнул хозяина;
--   rewardDay, rewards         — сколько раз за день (rewardDay) гость получил билеты за кормление.
-- }
-- Ключи userId — строки: DataStore не сохраняет таблицы с «дырявыми» числовыми ключами.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local Social = {}
local S = FishConfig.Social

-- Номер дня UTC и номер недели (неделя начинается в понедельник 00:00 UTC; 1970-01-05 — понедельник)
function Social.day(now)
	return now // 86400
end
function Social.week(now)
	return (now - 4 * 86400) // (7 * 86400)
end

function Social.ensure(profile, now)
	local s = profile.social
	if s == nil then
		s = {}
		profile.social = s
	end
	s.likes = s.likes or 0
	s.likesWeek = s.likesWeek or 0
	s.week = s.week or 0
	s.boostUntil = s.boostUntil or 0
	s.fedAt = s.fedAt or {}
	s.likedDay = s.likedDay or {}
	s.rewardDay = s.rewardDay or 0
	s.rewards = s.rewards or 0
	if now ~= nil then
		local week = Social.week(now)
		if s.week ~= week then
			s.week = week
			s.likesWeek = 0
		end
	end
	return s
end

-- Убираем старые записи, чтобы профиль не разрастался
function Social.prune(profile, now)
	local s = Social.ensure(profile, now)
	for key, at in pairs(s.fedAt) do
		if now - at >= S.FEED_COOLDOWN then
			s.fedAt[key] = nil
		end
	end
	local today = Social.day(now)
	for key, day in pairs(s.likedDay) do
		if day ~= today then
			s.likedDay[key] = nil
		end
	end
end

-- Множитель дохода от кормления (1 или 1 + BOOST)
function Social.multiplier(profile, at)
	local s = profile.social
	if s ~= nil and (s.boostUntil or 0) > at then
		return 1 + S.BOOST
	end
	return 1
end

-- Сколько секунд ещё ждать, чтобы покормить хозяина ownerId (0 — можно сейчас)
function Social.feedLeft(guest, ownerId, now)
	local s = Social.ensure(guest, now)
	local at = s.fedAt[tostring(ownerId)]
	if at == nil then
		return 0
	end
	return math.max(0, at + S.FEED_COOLDOWN - now)
end

function Social.canLike(guest, ownerId, now)
	local s = Social.ensure(guest, now)
	return s.likedDay[tostring(ownerId)] ~= Social.day(now)
end

-- Покормить рыб хозяина. guestId/ownerId — UserId. Возвращает true, { tickets } или false, причина ("self" / "cooldown").
function Social.feed(guest, guestId, owner, ownerId, now)
	if guestId == ownerId then
		return false, "self"
	end
	if Social.feedLeft(guest, ownerId, now) > 0 then
		return false, "cooldown"
	end
	local gs = Social.ensure(guest, now)
	local os_ = Social.ensure(owner, now)
	gs.fedAt[tostring(ownerId)] = now
	os_.boostUntil = now + S.BOOST_TIME -- повторное кормление продлевает бонус, но не складывает
	local today = Social.day(now)
	if gs.rewardDay ~= today then
		gs.rewardDay = today
		gs.rewards = 0
	end
	local tickets = 0
	if gs.rewards < S.FEED_REWARDS_PER_DAY then
		gs.rewards += 1
		tickets = S.FEED_TICKETS
		local v = guest.visitors
		if v == nil then
			v = { tickets = 0, completed = 0, nextId = 1, slots = {} }
			guest.visitors = v
		end
		v.tickets = (v.tickets or 0) + tickets
	end
	return true, { tickets = tickets }
end

-- Лайк аквариуму. Возвращает true или false, причина ("self" / "already").
function Social.like(guest, guestId, owner, ownerId, now)
	if guestId == ownerId then
		return false, "self"
	end
	if not Social.canLike(guest, ownerId, now) then
		return false, "already"
	end
	local gs = Social.ensure(guest, now)
	local os_ = Social.ensure(owner, now)
	gs.likedDay[tostring(ownerId)] = Social.day(now)
	os_.likes += 1
	os_.likesWeek += 1
	return true
end

-- Что видит гость в чужом аквариуме: открытые аквариумы, рыбы выбранного, лайки, бонус и что можно сделать
function Social.view(guest, owner, ownerId, tankId, now)
	local tanks = {}
	for _, id in ipairs(FishConfig.allTanks()) do
		if owner.tanks[id] ~= nil then
			table.insert(tanks, id)
		end
	end
	if tankId == nil or owner.tanks[tankId] == nil then
		tankId = tanks[1]
	end
	local fish = {}
	local tankData = owner.tanks[tankId]
	if tankData ~= nil then
		for _, f in ipairs(tankData.fish) do
			if #fish >= S.VIEW_FISH_MAX then
				break
			end
			table.insert(fish, {
				species = f.species,
				variant = f.variant or "normal",
				mutation = f.mutation,
				age = math.max(0, now - f.born),
			})
		end
	end
	local os_ = Social.ensure(owner, now)
	return {
		userId = ownerId,
		tanks = tanks,
		tank = tankId,
		fish = fish,
		decor = owner.decor or {},
		likes = os_.likes,
		boostLeft = math.max(0, os_.boostUntil - now),
		feedLeft = Social.feedLeft(guest, ownerId, now),
		canLike = Social.canLike(guest, ownerId, now),
	}
end

return Social
