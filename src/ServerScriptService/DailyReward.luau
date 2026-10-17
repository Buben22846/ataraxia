-- DailyReward: правила ежедневной награды (чистая логика без Roblox-сервисов, поэтому легко тестируется).
-- День считается по UTC: FishConfig.dayOf(время). Данные лежат в profile.daily = { lastDay, streak }.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FishConfig"))

local DailyReward = {}

-- Серия, которая будет у игрока, если он заберёт награду сегодня
local function streakIfClaimed(daily, today)
	if daily.lastDay == today - 1 then
		return daily.streak + 1
	end
	return 1
end

local function rewardFor(streak)
	local rewards = FishConfig.DailyRewards
	return rewards[(streak - 1) % #rewards + 1]
end

-- Состояние для показа клиенту: можно ли забрать, какая серия и награда, сколько секунд до следующего дня
function DailyReward.state(profile, now)
	local today = FishConfig.dayOf(now)
	local daily = profile.daily
	local canClaim = daily.lastDay ~= today
	local streak = if canClaim then streakIfClaimed(daily, today) else daily.streak
	return {
		canClaim = canClaim,
		streak = streak,
		reward = rewardFor(streak),
		secondsLeft = (today + 1) * 86400 - now,
	}
end

-- Забрать награду. Возвращает (получено монет или nil, серия)
function DailyReward.claim(profile, now)
	local today = FishConfig.dayOf(now)
	local daily = profile.daily
	if daily.lastDay == today then
		return nil, daily.streak
	end
	local streak = streakIfClaimed(daily, today)
	local reward = rewardFor(streak)
	daily.lastDay = today
	daily.streak = streak
	profile.coins += reward
	return reward, streak
end

return DailyReward
