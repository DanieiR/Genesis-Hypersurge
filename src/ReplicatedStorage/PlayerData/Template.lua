local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Template = {
	Money = 0,
	WaitTime = 5,
}

export type PlayerData = typeof(Template)

return Template
