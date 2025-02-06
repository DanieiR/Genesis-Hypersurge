-- Fishes RNG Module
local FishRNG = {}
local FishesConfig = require(game.ReplicatedStorage.Source.Configs.Fishes)
-- Use the fishes data from the Config module
local fishes = {}
for fishName, fishData in pairs(FishesConfig) do
	table.insert(fishes, {
		fish = fishName,
		odds = fishData.Odds,
		type = fishData.Type,
		rarity = fishData.Rarity,
		sellPrice = fishData.SellPrice,
		weight = fishData.Weight,
		description = fishData.Description,
		exp = fishData.Exp,
		ID = fishData.FishID,
		locked = fishData.isLocked,
		equipped = fishData.Equipped,
	})
end
print("Fishes:", fishes)
function FishRNG.GetRandomFish(hasGamepass)
	-- Adjust odds if the player has the gamepass (x2 chance of getting rarer fish)
	if hasGamepass then
		for i, item in ipairs(fishes) do
			-- Decrease the odds number to increase the chance
			fishes[i].odds = math.max(1, math.floor(item.odds / 2))
		end
	end

	-- Iterate over the fishes and determine the outcome
	for _, item in ipairs(fishes) do
		local odds = item.odds
		local randomValue = math.random(1, odds)
		if randomValue == 1 then
			return item -- Return the name of the fish
		end
	end
end

return FishRNG
