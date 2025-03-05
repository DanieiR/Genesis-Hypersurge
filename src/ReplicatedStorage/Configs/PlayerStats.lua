--[[
    PlayerStats Configuration
    
    Defines the player stats system for the fishing game.
    Stats affect gameplay mechanics like fishing success rate, reel speed, etc.

]]

export type StatsTemplate = {
	Power: number, -- Affects fishing power (casting distance, hook strength)
	Luck: number, -- Affects rare fish encounter rates
	Speed: number, -- Affects reeling speed and minigame timer
}

-- Starting stats for new players
local PlayerStats: StatsTemplate = {
	Power = 1,
	Luck = 1,
	Speed = 1,
}

-- Maximum stat values
PlayerStats.MaxValues = {
	Power = 100,
	Luck = 100,
	Speed = 100,
}

-- Calculate the effect of Power on fishing mechanics
-- Returns a multiplier value
function PlayerStats.CalculatePowerEffect(powerValue: number): number
	return 1 + (powerValue / 100)
end

-- Calculate the effect of Luck on rare fish encounter rates
-- Returns a multiplier value
function PlayerStats.CalculateLuckEffect(luckValue: number): number
	local baseEffect = 1.1

	local scalingEffect = luckValue / 25

	return baseEffect + scalingEffect
end

-- Calculate the effect of Speed on reeling and minigame timers
-- Returns a multiplier value
function PlayerStats.CalculateSpeedEffect(speedValue: number): number
	return 1 + (speedValue / 100)
end

return PlayerStats
