local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")
local Manager = require(ServerStorage.Source.Manager)
local LevelConfig = require(ReplicatedStorage.Source.Configs.LevelsConfig)

local LevelService = Knit.CreateService({
	Name = "LevelService",
	Client = {
		UpdatePlayerExp = Knit.CreateSignal(),
	},
})

function LevelService:_ApplyLevelRewards(player, levelData)
	if levelData.Rewards then
		for _, reward in ipairs(levelData.Rewards) do
			if reward.Type == "Coins" then
				Manager.AdjustCoins(player, reward.Amount)
			end
		end
	end
end

function LevelService:_CheckLevelUp(player, newExp)
	local playerData = Manager.Profiles[player]
	if not playerData then
		return
	end

	-- Get current progression data
	local currentLevel = playerData.Data.Level or 1
	local currentExp = newExp
	local levelsGained = 0

	-- Check how many levels we can progress
	while true do
		local requiredExp = LevelConfig[currentLevel] and LevelConfig[currentLevel].RequiredExp

		if not requiredExp or currentExp < requiredExp then
			break
		end

		-- Move to next level
		print(currentLevel)
		currentLevel += 1
		levelsGained += 1
	end

	-- Apply rewards if we gained levels
	if levelsGained > 0 then
		local finalLevel = playerData.Data.Level + levelsGained

		-- Apply rewards for each new level
		for l = playerData.Data.Level + 1, finalLevel do
			local levelData = LevelConfig[l]
			if levelData then
				self:_ApplyLevelRewards(player, levelData)
			end
		end

		-- Update player level
		Manager.AdjustLevel(player, finalLevel)
		return finalLevel
	end

	return playerData.Data.Level
end

function LevelService:_UpdatePlayerExp(player, caughtFish)
	local expGained = caughtFish.exp or 0

	-- Get new EXP total
	local newExp = Manager.AdjustExp(player, expGained)

	-- Check for level progression
	local newLevel = self:_CheckLevelUp(player, newExp)

	-- Get required EXP for CURRENT level (what's needed to reach next level)
	local requiredExp = LevelConfig[newLevel] and LevelConfig[newLevel].RequiredExp

	-- Update client
	self.Client.UpdatePlayerExp:Fire(player, {
		Exp = newExp,
		Level = newLevel,
		RequiredExp = requiredExp,
	})
end

function LevelService:KnitStart()
	self.Client.UpdatePlayerExp:Connect(function(player, caughtFish)
		self:_UpdatePlayerExp(player, caughtFish)
	end)
end

return LevelService
