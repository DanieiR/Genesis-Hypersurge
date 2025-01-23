local ClickingMinigame = {
	numButtons = 10, -- Total number of buttons to spawn
	buttonSpawnInterval = 0.5, -- Interval between button spawns (Note: Minigame will last for numButtons * buttonSpawnInterval seconds)
	neededSuccessCount = 5, -- Number of buttons to click successfully
	tweenDuration = 1, -- Duration of the tween animation for the buttons to click
}

return ClickingMinigame
