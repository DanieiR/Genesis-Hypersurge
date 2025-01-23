local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local ServerStorage = game:GetService("ServerStorage")
local Manager = require(ServerStorage.Source.Manager)
local Knit = require(ReplicatedStorage.Packages.Knit)
local FishToolsStorage = ReplicatedStorage:WaitForChild("FishTools")
local EquipService = Knit.CreateService({
	Name = "EquipService",
	Client = {
		equipFish = Knit.CreateSignal(),
	},
})

function EquipService:_PerformValidationChecks(player, FishName)
	local profile = Manager.Profiles[player]
	if not profile then
		print("No profile found for player:", player.Name)
		return false
	end
	-- Go through players fishes table and match the fishes name with the FishName if a fish is found return true
	for _, fish in ipairs(profile.Data.fishes) do
		if fish.fish == FishName then
			return true
		end
	end
	return false
end

function EquipService:_ClearPlayerPreviousFishTools(player)
	-- Go through the players tools and check if the tool has a boolvalue called IsFishTool, if it does then delete the tool
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			if tool:FindFirstChild("IsFishTool") then
				tool:Destroy()
			end
		end
	end
	for _, tool in ipairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") then
			if tool:FindFirstChild("IsFishTool") then
				tool:Destroy()
			end
		end
	end
end

function EquipService:_GivePlayerFishTool(player, FishName)
	local doesPlayerOwnFish = self:_PerformValidationChecks(player, FishName)
	print("Does player own fish:", doesPlayerOwnFish)
	-- Give the player the new fish tool
	if doesPlayerOwnFish then
		self:_ClearPlayerPreviousFishTools(player)
		local FishTool = FishToolsStorage:FindFirstChild(FishName):Clone()
		FishTool.Parent = player.Backpack
		self.Client.equipFish:Fire(player, FishName)
	end
end

function EquipService:KnitStart()
	self.Client.equipFish:Connect(function(player, FishName)
		self:_GivePlayerFishTool(player, FishName)
	end)
end

return EquipService
