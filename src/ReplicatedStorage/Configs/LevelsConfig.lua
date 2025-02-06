export type LevelsTemplate = {
	LevelNumber: number,
	RequiredExp: number,
	Rewards: { [string]: any }?, -- Can contain coins, items, etc.
}

local Levels: { [number]: LevelsTemplate } = {
	[1] = {
		LevelNumber = 1,
		RequiredExp = 100,
		Rewards = {
			{ Type = "Coins", Amount = 50 },
			{ Type = "FishingRod", ItemId = "StarterRod" },
		},
	},
	[2] = {
		LevelNumber = 2,
		RequiredExp = 300,
		Rewards = {
			{ Type = "Coins", Amount = 100 },
			{ Type = "Bobber", ItemId = "GoldenBobber", Quantity = 1 },
		},
	},
	[3] = {
		LevelNumber = 3,
		RequiredExp = 600,
		Rewards = {
			{ Type = "Coins", Amount = 200 },
			{ Type = "Cosmetic", ItemId = "Hat_Fisherman" },
		},
	},
	-- Add subsequent levels following this pattern
}
--Helper function to calculate XP requirements
function Levels.CalculateRequiredExp(level: number)
	-- quadratic progression formula
	return math.floor(100 * (level ^ 1.5))
end
--[[for i = 1, 100 do
	print(`Level {i}: {Levels.CalculateRequiredExp(i)} XP`)
end]]
--
return Levels
