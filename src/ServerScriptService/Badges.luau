-- Badges: значки за достижения. Только сервер.
-- Badges.earned(profile) — чистая функция: какие значки заслужил профиль (для тестов).
-- Badges.sync(player, profile) — выдаёт новые значки через BadgeService (повторно один значок не выдаётся).
-- Значок с id = 0 в FishConfig.Badges не выдаётся.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))
local Collection = require(script.Parent:WaitForChild("Collection"))
local Visitors = require(script.Parent:WaitForChild("Visitors"))

local Badges = {}

local awarded = {} -- player -> { [ключ] = true }, чтобы не дёргать BadgeService повторно

-- Список ключей значков, которые заслужил профиль
function Badges.earned(profile)
	local list = {}
	local function add(key)
		table.insert(list, key)
	end
	local hasGolden, hasRainbow = false, false
	for key in pairs(profile.seen or {}) do
		if string.find(key, "/golden", 1, true) then
			hasGolden = true
		elseif string.find(key, "/rainbow", 1, true) then
			hasRainbow = true
		end
	end
	if hasGolden then
		add("golden")
	end
	if hasRainbow then
		add("rainbow")
	end
	if next(profile.mutSeen or {}) ~= nil then
		add("mutation")
	end
	for tankId in pairs(profile.tanks) do
		if Collection.bonus(profile, tankId) > 0 then
			add("set")
			break
		end
	end
	if profile.visitors ~= nil and Visitors.rank(profile.visitors.completed or 0) >= 3 then
		add("museum3")
	end
	if profile.tanks.abyss ~= nil then
		add("abyss")
	end
	for speciesId in pairs(profile.discovered or {}) do
		local species = FishConfig.Species[speciesId]
		if species ~= nil and species.tank == "haunted" then
			add("halloween")
			break
		end
	end
	return list
end

function Badges.sync(player, profile)
	local done = awarded[player]
	if done == nil then
		done = {}
		awarded[player] = done
	end
	for _, key in ipairs(Badges.earned(profile)) do
		local badgeId = FishConfig.Badges[key]
		if not done[key] and badgeId ~= nil and badgeId > 0 then
			done[key] = true
			task.spawn(function()
				local ok, err = pcall(function()
					BadgeService:AwardBadge(player.UserId, badgeId)
				end)
				if not ok then
					done[key] = nil -- попробуем ещё раз при следующем обновлении
					warn("[Badges] не удалось выдать значок " .. key .. ": " .. tostring(err))
				end
			end)
		end
	end
end

function Badges.forget(player)
	awarded[player] = nil
end

return Badges
