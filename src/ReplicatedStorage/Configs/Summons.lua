local SummonsConfig = {
	Characters = {
		{ Name = "Nani", Rarity = "Common", Weight = 5, SellPrice = 10, isLocked = false, Equipped = false, ID = nil },
		{ Name = "Yoro", Rarity = "Rare", Weight = 5, SellPrice = 10, isLocked = false, Equipped = false, ID = nil },
		{ Name = "Ase", Rarity = "Epic", Weight = 5, SellPrice = 10, isLocked = false, Equipped = false, ID = nil },
		{
			Name = "Lufus",
			Rarity = "Legendary",
			Weight = 5,
			SellPrice = 10,
			isLocked = false,
			Equipped = false,
			ID = nil,
		},
	},
	Costs = {
		Single = 50, -- gems cost for a single summon
		Multi = 500, -- gems cost for a ten summon
	},
}

return SummonsConfig
