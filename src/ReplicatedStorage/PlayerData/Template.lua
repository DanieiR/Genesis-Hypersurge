local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Template = {
	Coins = 0,
	Stars = 0,
	WaitTime = 5, --The time to wait before fish is hooked and first minigame spawns
	fishes = {},
}

export type PlayerData = typeof(Template)

return Template
