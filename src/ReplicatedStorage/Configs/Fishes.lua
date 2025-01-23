export type FishesTemplate = {
	ID: string,
	Name: string,
	Description: string,
	Type: string,
	Rarity: string,
	SellPrice: number,
	Weight: number,
	Odds: number,
}
--Setup Fishes for the starting area
local Fishes: { [string]: FishesTemplate } = {
	ClownFish = {
		ID = "1",
		Name = "ClownFish", --Name of the fish, (Note: This is the key used to identify the fish, The name here should be same of this fishes model in ReplicatedStorage -> Fishes)
		Description = "This is a clown fish",
		Type = "Small", -- Type can be either small or big, this will be used to determine one or two catch catch/equip animation
		Rarity = "Common", -- Rarity of the fish
		SellPrice = 10, -- The amount of gold/money the fish sells for
		Weight = 50, -- Weight of the fish
		Odds = 1, -- Odds required to catch this fish (1 in x chance) this is the most basic fish so odds are kept at 1, add rarer fishes ABOVE this fish
	},
}

return Fishes
