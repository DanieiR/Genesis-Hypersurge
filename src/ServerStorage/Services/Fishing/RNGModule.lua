-- Fishes RNG Module
local FishRNG = {}

function FishRNG.GetRandomFish(hasGamepass)
	-- Define the fish with their base odds (1 in X)
	local fishes = {
		{ fish = "Fish", odds = 10 }, -- 1 in 10 chance
		{ fish = "Fish", odds = 5 }, -- 1 in 5 chance
		{ fish = "Fish", odds = 1 }, -- Guaranteed
	}

	-- Adjust odds if the player has the gamepass if gamepasses are added in the future (x2 chance of getting rarer fish)
	if hasGamepass then
		for _, item in ipairs(fishes) do
			-- Decrease the odds number to increase the chance
			item.odds = math.max(1, math.floor(item.odds / 2))
		end
	end

	-- Iterate over the fishes
	for _, item in ipairs(fishes) do
		local odds = item.odds
		local randomValue = math.random(1, odds)
		if randomValue == 1 then
			return item.fish
		end
	end

	return nil
end

return FishRNG
