local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Terrain = game.Workspace.Terrain
local WeatherService = Knit.CreateService({
	Name = "WeatherService",
	Client = {
		WeatherChanged = Knit.CreateSignal(),
	},
})

local WEATHER_EVENTS = { "Clear", "Cloudy", "Rain" }
local currentWeather = "Clear"

local WEATHER_CHANGE_INTERVAL = 360

local function getRandomWeather()
	return WEATHER_EVENTS[math.random(1, #WEATHER_EVENTS)]
end

function WeatherService:StartWeatherCycle()
	while true do
		task.wait(WEATHER_CHANGE_INTERVAL)
		local newWeather = getRandomWeather()
		WeatherService.Client.WeatherChanged:FireAll(newWeather)
		if newWeather ~= currentWeather then
			currentWeather = newWeather
		end
		if newWeather == "Cloudy" then
			game.Workspace.Terrain.Clouds.Cover = 0.7
		elseif newWeather == "Clear" then
			game.Workspace.Terrain.Clouds.Cover = 0
		elseif newWeather == "Rain" then
			game.Workspace.Terrain.Clouds.Cover = 0.72
		end
	end
end

function WeatherService:KnitStart()
	task.spawn(function()
		self:StartWeatherCycle()
	end)
end

return WeatherService
