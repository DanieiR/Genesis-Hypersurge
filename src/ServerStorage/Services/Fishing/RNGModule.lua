--[[
    Fish RNG Module
    Handles random fish selection with luck-based probability adjustments
    
    Last Updated: 2025-03-01
]]

local FishRNG = {}
local FishesConfig = require(game.ReplicatedStorage.Source.Configs.Fishes)
local PlayerStats = require(game.ReplicatedStorage.Source.Configs.PlayerStats)
local ServerStorage = game:GetService("ServerStorage")
local Manager = require(ServerStorage.Source.Manager)

-- Define the desired order in an array (from rarest to most common):
local fishOrder = { "YinYangKoi", "Koi", "JellyFish", "ClownFish" }

-- Pre-process fish data for efficiency
local fishes = {}
for _, fishName in ipairs(fishOrder) do
	local fishData = FishesConfig[fishName]
	if fishData then
		table.insert(fishes, {
			fish = fishData.Name,
			odds = fishData.Odds,
			type = fishData.Type,
			rarity = fishData.Rarity,
			sellPrice = fishData.SellPrice,
			weight = fishData.Weight,
			description = fishData.Description,
			exp = fishData.Exp,
			ID = fishData.ID,
			locked = fishData.isLocked,
			equipped = fishData.Equipped,
		})
	end
end

--[[
    GetRandomFish - Returns a randomly selected fish based on probability
    
    @param player (Player) - The player who is fishing (for luck calculation)
    @param hasGamepass (boolean) - Whether the player has a gamepass for better odds
    
    @return (table) - The selected fish data or nil if no fish was caught
]]
function FishRNG.GetRandomFish(player, hasGamepass)
	-- Create a copy of the fish data to modify without affecting the original
	local fishesWithAdjustedOdds = table.clone(fishes)

	-- Apply luck multiplier if player is provided
	local luckMultiplier = 1
	if player then
		local playerStats = Manager.GetPlayerStats(player)
		if playerStats then
			luckMultiplier = PlayerStats.CalculateLuckEffect(playerStats.Luck)
		end
	end

	-- Apply gamepass multiplier if applicable
	local gamepassMultiplier = hasGamepass and 2 or 1

	-- Combine multipliers and apply to fish odds
	local totalMultiplier = luckMultiplier * gamepassMultiplier

	-- Store original odds values before adjusting
	local originalOdds = {}
	for i, item in ipairs(fishesWithAdjustedOdds) do
		originalOdds[i] = item.odds
	end

	-- Adjust odds based on multipliers (lower odds = higher chance)
	for i, item in ipairs(fishesWithAdjustedOdds) do
		local adjustedOdds = math.max(1, math.ceil(item.odds / totalMultiplier))
		fishesWithAdjustedOdds[i].odds = adjustedOdds
	end

	-- Debug info
	if player then
		local playerStats = Manager.GetPlayerStats(player)
		if playerStats then
			print("Player Luck:", playerStats.Luck, "| Multiplier:", luckMultiplier)
		end
	end

	-- Iterate over the fishes and determine the outcome
	for i, adjustedFish in ipairs(fishesWithAdjustedOdds) do
		local odds = adjustedFish.odds
		local randomValue = math.random(1, odds)
		if randomValue == 1 then
			-- Create a deep copy of the fish data
			local fishCopy = table.clone(fishes[i])

			-- Add some randomness to the weight
			fishCopy.weight = math.random(fishCopy.weight, fishCopy.weight + 10)

			-- Ensure the original odds value is preserved
			fishCopy.odds = originalOdds[i]

			return fishCopy -- Return fish with original odds value
		end
	end

	local commonFish = table.clone(fishes[#fishes]) -- Use original fish with original odds
	commonFish.weight = math.random(commonFish.weight, commonFish.weight + 10)
	return commonFish
end

return FishRNG
