local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Template = {
	Coins = 0,
	Gems = 0,
	Exp = 0,
	Level = 1,

	WaitTime = 5, --The time to wait before fish is hooked and first minigame spawns
	fishes = {},
	quests = {
		currentQuestId = 1,
		progress = 0,
	},
	units = {},
	currentEquippedRod = "None",
	BasicRod = false,
	TestingRod = true,
	Makeshift_Rod = true,
}

export type PlayerData = typeof(Template)

return Template
