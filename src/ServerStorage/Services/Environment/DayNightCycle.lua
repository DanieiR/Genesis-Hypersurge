local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)

local DayNightCycle = Knit.CreateService({
	Name = "DayNightCycle",
	Client = {},
})

-- For a full cycle (24 hours) in 30 minutes (1800 seconds):
local HOURS_PER_SECOND = 24 / 1800 -- ≈ 0.01333 hours per second

function DayNightCycle:StartCycle()
	while true do
		local dt = RunService.Heartbeat:Wait()
		Lighting.ClockTime = (Lighting.ClockTime + dt * HOURS_PER_SECOND) % 24
	end
end

function DayNightCycle:KnitStart()
	task.spawn(function()
		self:StartCycle()
	end)
end

return DayNightCycle
