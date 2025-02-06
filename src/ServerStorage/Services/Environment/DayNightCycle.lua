local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local DayNightCycle = Knit.CreateService({
	Name = "DayNightCycle",
	Client = {},
})

-- Define the rate of change.
-- We want the clock to advance 12 hours over 60 seconds.
-- That is: 12 / 60 = 0.2 hours per second.
local HOURS_PER_SECOND = 12 / 60

function DayNightCycle:StartCycle()
	while true do
		local dt = RunService.Heartbeat:Wait()
		Lighting.ClockTime = (Lighting.ClockTime + dt * HOURS_PER_SECOND) % 24
	end
end

function DayNightCycle:KnitStart()
	spawn(function()
		self:StartCycle()
	end)
end

return DayNightCycle
