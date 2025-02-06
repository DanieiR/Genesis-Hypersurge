local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeatherController = Knit.CreateController({
	Name = "WeatherController",
})

-- This function attaches the rain VFX to the player's character.
function WeatherController:ActivateRainVFX()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	if character:FindFirstChild("RainEffect") then
		return
	end

	-- Clone the rain effect from ReplicatedStorage.
	local rainTemplate = ReplicatedStorage:WaitForChild("Fx"):WaitForChild("Rain")
	local rainEffect = rainTemplate:Clone()
	rainEffect.Name = "RainEffect"
	rainEffect.Parent = character

	-- Attach the TopPart to the player's Head.
	local head = character:WaitForChild("Head")
	local topPart = rainEffect:WaitForChild("TopPart")
	-- Position the TopPart 3 studs above the head.
	topPart.CFrame = head.CFrame * CFrame.new(0, 3, 0)
	local topWeld = Instance.new("WeldConstraint")
	topWeld.Part0 = head
	topWeld.Part1 = topPart
	topWeld.Parent = head

	print("Rain VFX activated for", player.Name)
end

-- This function removes the rain VFX from the player's character.
function WeatherController:DeactivateRainVFX()
	local player = Players.LocalPlayer
	local character = player.Character
	if character and character:FindFirstChild("RainEffect") then
		character.RainEffect:Destroy()
		print("Rain VFX deactivated for", player.Name)
	end
end

function WeatherController:OnWeatherChanged(newWeather)
	print("Client Weather changed to:", newWeather)
	if newWeather == "Rain" then
		self:ActivateRainVFX()
	else
		self:DeactivateRainVFX()
	end
end

function WeatherController:KnitStart()
	local WeatherService = Knit.GetService("WeatherService")
	-- Listen to weather changes fired from the server.
	WeatherService.WeatherChanged:Connect(function(newWeather)
		self:OnWeatherChanged(newWeather)
	end)
end

return WeatherController
