local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Zone = require(ReplicatedStorage.Source.Configs.Zone)
local ZonesService = Knit.CreateService({
	Name = "ZonesService",
	Client = {},
})

function ZonesService:KnitStart()
	local startingIslandContainer = workspace:WaitForChild("Zones"):WaitForChild("StarterIsland")
	local startingIsland = Zone.new(startingIslandContainer)
	startingIsland.playerEntered:Connect(function(player)
		print(("%s entered the zone "):format(player.Name) .. startingIslandContainer.Name .. "!")
	end)

	startingIsland.playerExited:Connect(function(player)
		print(("%s exited the zone "):format(player.Name) .. startingIslandContainer.Name .. "!")
	end)
end

return ZonesService
