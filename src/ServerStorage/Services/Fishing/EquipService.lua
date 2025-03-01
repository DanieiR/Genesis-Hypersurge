local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local ServerStorage = game:GetService("ServerStorage")
local Manager = require(ServerStorage.Source.Manager)
local Knit = require(ReplicatedStorage.Packages.Knit)
local FishToolsStorage = ReplicatedStorage:WaitForChild("FishTools")
local RodToolStorage = ReplicatedStorage:WaitForChild("RodTools")
local EquipService = Knit.CreateService({
	Name = "EquipService",
	Client = {
		equipFish = Knit.CreateSignal(),
		equipRod = Knit.CreateSignal(),
		equipUnit = Knit.CreateSignal(),
	},
})

-- Add a property to track units folder
EquipService.UnitsFolder = nil

function EquipService:KnitInit()
	-- Create or get the units folder when the service initializes
	self.UnitsFolder = workspace:FindFirstChild("PlayerUnits")
	if not self.UnitsFolder then
		self.UnitsFolder = Instance.new("Folder")
		self.UnitsFolder.Name = "PlayerUnits"
		self.UnitsFolder.Parent = workspace
	end
end

function EquipService:_PerformValidationChecks(player, FishID)
	local profile = Manager.Profiles[player]
	if not profile then
		print("No profile found for player:", player.Name)
		return false
	end
	-- Go through players fishes table and match the fishes name with the FishID if a fish is found return true
	for _, fish in ipairs(profile.Data.fishes) do
		if fish.ID == FishID then
			return true
		end
	end
	return false
end

function EquipService:_PerformValidationChecksUnit(player, Unit)
	local profile = Manager.Profiles[player]
	if not profile then
		print("No profile found for player:", player.Name)
		return false
	end
	-- Go through players fishes table and match the fishes name with the FishID if a fish is found return true
	for _, unit in ipairs(profile.Data.units) do
		if unit.ID == Unit then
			return true
		end
	end
	return false
end

function EquipService:_PerformValidationChecksRod(player, RodName)
	local profile = Manager.Profiles[player]
	if not profile then
		print("No profile found for player:", player.Name)
		return false
	end
	if profile.Data[RodName] and profile.Data[RodName] == true then
		return true
	end
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

function EquipService:_ClearPlayerPreviousRods(player)
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:sub(-3) == "Rod" then
			tool:Destroy()
		end
	end
	for _, tool in ipairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:sub(-3) == "Rod" then
			tool:Destroy()
		end
	end
end

function EquipService:_GivePlayerFishTool(player, FishName, FishID)
	print(player, FishName, FishID)
	local doesPlayerOwnFish = self:_PerformValidationChecks(player, FishID)
	print("Does player own fish:", doesPlayerOwnFish)
	-- Give the player the new fish tool
	if doesPlayerOwnFish then
		self:_ClearPlayerPreviousFishTools(player)
		local FishTool = FishToolsStorage:FindFirstChild(FishName):Clone()
		FishTool.Parent = player.Backpack
		self.Client.equipFish:Fire(player, FishName)
	end
end

function EquipService:_givePlayerRod(player, RodName)
	local doesPlayerOwnRod = self:_PerformValidationChecksRod(player, RodName)
	-- Give the player the new fish tool
	if doesPlayerOwnRod then
		self:_ClearPlayerPreviousRods(player)
		local RodTool = RodToolStorage:FindFirstChild(RodName):Clone()
		RodTool.Parent = player.Backpack
		Manager.GiveRod(player, RodName)
	end
end

function EquipService:_GetPlayerUnitFolder(player)
	-- Get or create a folder for this specific player's units
	local playerFolderName = "Player_" .. player.UserId .. "_Units"
	local playerFolder = self.UnitsFolder:FindFirstChild(playerFolderName)

	if not playerFolder then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = playerFolderName
		playerFolder.Parent = self.UnitsFolder
	end

	return playerFolder
end

function EquipService:_ClearPlayerPreviousUnits(player)
	-- Get player's unit folder
	local playerFolder = self:_GetPlayerUnitFolder(player)

	-- Remove all existing units
	for _, unit in ipairs(playerFolder:GetChildren()) do
		unit:Destroy()
	end
end

function EquipService:_EquipUnit(player, UnitID, UnitName)
	local doesPlayerOwnUnit = self:_PerformValidationChecksUnit(player, UnitID)
	if doesPlayerOwnUnit then
		-- Clear previous units
		self:_ClearPlayerPreviousUnits(player)

		-- Get the player's unit folder
		local playerUnitFolder = self:_GetPlayerUnitFolder(player)

		local unitTemplate = ReplicatedStorage.SummonViewports:FindFirstChild(UnitName)
		if not unitTemplate then
			warn("No unit model found for " .. UnitName)
			return
		end

		local unitModel = unitTemplate:Clone()
		unitModel:SetAttribute("UnitID", UnitID)
		unitModel:SetAttribute("OwnerUserId", player.UserId)

		-- Set parent to the player's unit folder
		unitModel.Parent = playerUnitFolder

		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			unitModel.PrimaryPart.CFrame = player.Character.HumanoidRootPart.CFrame
		end

		self.Client.equipUnit:Fire(player, UnitName, UnitID)

		local unitHumanoid = unitModel:FindFirstChildOfClass("Humanoid")
		if unitHumanoid then
			for _, part in ipairs(unitModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
				end
			end

			spawn(function()
				while unitModel.Parent and player.Character and player.Character:FindFirstChild("HumanoidRootPart") do
					local targetPos = player.Character.HumanoidRootPart.Position - Vector3.new(2, 0, 2)
					unitHumanoid:MoveTo(targetPos)

					unitHumanoid.MoveToFinished:Wait()

					task.wait(0.05)
				end
			end)
		else
			warn("Unit model does not have a Humanoid: " .. UnitName)
		end
	end
end

function EquipService:KnitStart()
	self.Client.equipFish:Connect(function(player, FishName, FishID)
		self:_GivePlayerFishTool(player, FishName, FishID)
	end)
	self.Client.equipRod:Connect(function(player, RodName)
		self:_givePlayerRod(player, RodName)
	end)
	self.Client.equipUnit:Connect(function(player, UnitID, UnitName)
		self:_EquipUnit(player, UnitID, UnitName)
	end)

	-- Handle player leaving to clean up units
	Players.PlayerRemoving:Connect(function(player)
		local playerFolder = self.UnitsFolder:FindFirstChild("Player_" .. player.UserId .. "_Units")
		if playerFolder then
			playerFolder:Destroy()
		end
	end)
end

return EquipService
