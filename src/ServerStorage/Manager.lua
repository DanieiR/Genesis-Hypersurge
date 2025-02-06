local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local Template = require(ReplicatedStorage.Source.PlayerData.Template)
local Knit = require(ReplicatedStorage.Packages.Knit)

local DataService

local function start()
	DataService = Knit.GetService("DataService")
end

local Manager = {}

Manager.Profiles = {}

function Manager.AdjustCoins(player: Player, amount: number)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.Coins += amount
	player.leaderstats.Coins.Value = profile.Data.Coins
	DataService.Client.UpdateCoins:Fire(player, profile.Data.Coins)
end
function Manager.AdjustStars(player: Player, amount: number)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.Stars += amount
	player.leaderstats.Stars.Value = profile.Data.Stars
	DataService.Client.UpdateStars:Fire(player, profile.Data.Stars)
end
function Manager.AdjustFishes(player: Player, newFish: table)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	-- Validate fish structure
	if not newFish.ID or type(newFish.ID) ~= "number" then
		warn("Invalid fish data format")
		return
	end

	-- Check for duplicate ID
	for _, existingFish in ipairs(profile.Data.fishes) do
		if existingFish.ID == newFish.ID then
			warn(`Duplicate fish ID {newFish.ID} detected!`)
			return
		end
	end

	-- Create new table reference
	local updatedFishes = table.clone(profile.Data.fishes)
	table.insert(updatedFishes, newFish)

	-- Atomic update
	profile.Data.fishes = updatedFishes
	DataService.Client.UpdateFishes:Fire(player, updatedFishes)

	print(`Added fish {newFish.ID} to {player.Name}. Total: {#updatedFishes}`)
end
function Manager.RemoveFishes(player: Player, fishIdsToRemove: { number })
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	-- Create new table reference for immutability
	local updatedFishes = {}
	local removedCount = 0

	for _, fish in ipairs(profile.Data.fishes) do
		if not table.find(fishIdsToRemove, fish.ID) then
			table.insert(updatedFishes, fish)
		else
			removedCount += 1
		end
	end

	if removedCount > 0 then
		profile.Data.fishes = updatedFishes
		DataService.Client.UpdateFishes:Fire(player, updatedFishes)
		print(`Removed {removedCount} fishes from {player.Name}'s inventory`)
	end

	return removedCount
end

function Manager.SellFishes(player: Player, fishIdsToSell: { number })
	local profile = Manager.Profiles[player]
	if not profile then
		return 0
	end

	-- Calculate total value and validate fish exist
	local totalValue = 0
	local validIds = {}

	-- First pass: validate and calculate
	for _, fish in ipairs(profile.Data.fishes) do
		if table.find(fishIdsToSell, fish.ID) and not fish.locked then
			totalValue += fish.sellPrice
			table.insert(validIds, fish.ID)
		end
	end

	-- Second pass: remove fishes
	local removedCount = Manager.RemoveFishes(player, validIds)

	if removedCount > 0 then
		Manager.AdjustCoins(player, totalValue)
		print(`Sold {removedCount} fishes for {totalValue} coins`)
	end

	return totalValue, removedCount
end
function Manager.AdjustExp(player: Player, exp: number)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.Exp += exp
	DataService.Client.UpdateExp:Fire(player, profile.Data.Exp)
	return profile.Data.Exp
end
function Manager.AdjustLevel(player: Player, level: number)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.Level = level
	DataService.Client.LevelUp:Fire(player, profile.Data.Exp)
end
function Manager:GetQuestData(player)
	local profile = Manager.Profiles[player]
	return profile and profile.Data.quests
end

function Manager:UpdateQuestProgress(player, progress)
	local profile = self.Profiles[player]
	if profile then
		profile.Data.quests.progress = progress
	end
end

function Manager:SetCurrentQuest(player, questId)
	local profile = self.Profiles[player]
	if profile then
		profile.Data.quests.currentQuestId = questId
		profile.Data.quests.progress = 0
	end
end

local function GetAllData(player: Player)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	return profile.Data
end
Remotes.GetAllData.OnServerInvoke = GetAllData
Knit:OnStart():andThen(start)

return Manager
