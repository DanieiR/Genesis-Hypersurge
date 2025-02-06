local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Template = {
	Coins = 0,
	Stars = 0,
	Exp = 0,
	Level = 1,

	WaitTime = 5, --The time to wait before fish is hooked and first minigame spawns
	fishes = {},
	quests = {
		currentQuestId = 1,
		progress = 0,
	},
}

export type PlayerData = typeof(Template)

return Template
