local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Add Workspace service

local Knit = require(ReplicatedStorage.Packages.Knit)
local Manager = require(ServerStorage.Source.Manager)

local FishingService = Knit.CreateService({
	Name = "FishingService",
	Client = {
		FishingStarted = Knit.CreateSignal(),
	},
})

function FishingService:CheckIfNearWater(player)
	local character = player.Character
	if not character then
		return false
	end

	local FishingRod = character:FindFirstChildOfClass("Tool")
	if not FishingRod or FishingRod.Name:sub(-3) ~= "Rod" then
		return false
	end
	local Handle = FishingRod.Handle
	if not Handle then
		return false
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

	local rayOrigin = Handle.Position
	local rayDirection = Vector3.new(0, -10, 0) -- Check 10 studs down
	local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		print(raycastResult)
		local hitPart = raycastResult.Instance
		if
			hitPart and hitPart.Name == "Water"
			or (hitPart == Workspace.Terrain and raycastResult.Material == Enum.Material.Water)
		then
			print("Water detected below the fishing rod for player:", player.Name)
			return true -- Water detected
		end
	end

	print("No water detected below the fishing rod for player:", player.Name)
	return false -- No water detected
end

function FishingService:Main(player)
	local hasWater = self:CheckIfNearWater(player)
	if not hasWater then
		return
	end
	-- Simulate fishing process here
	print("Fishing started for player:", player.Name)
end

function FishingService:KnitStart()
	self.Client.FishingStarted:Connect(function(player)
		self:Main(player)
	end)
end

return FishingService
