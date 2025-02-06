-- QuestsConfig
-- This configuration file contains the list of quests

local QuestsConfig = {
	QuestList = {
		{
			Id = 1,
			Title = "Catch 5 Fish",
			Description = "Catch 5 fish with your rod.",
			Required = 5,
			Reward = { Coins = 100, Stars = 1 },
			Type = "Collection", -- Collection Quest: complete by catching a number of fish
		},
		{
			Id = 2,
			Title = "Catch a Carp",
			Description = "Find and catch a Carp.",
			Required = 1,
			Reward = { Coins = 150, Stars = 2 },
			Type = "Specific", -- Specific Quest: complete by catching a specific type
			Target = "Carp", -- The target name for this quest
		},
		{
			Id = 3,
			Title = "Find the Magic Book",
			Description = "Locate the Magic Book lost on the island.",
			Required = 1, -- For a Lost & Found quest, you need to find one item
			Reward = { Coins = 200, Stars = 3 },
			Type = "LostAndFound", -- Lost & Found Quest: complete by locating a specific item
			Location = "Ancient Library", -- Optional hint; where the item might be found
		},
	},
}

return QuestsConfig
