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

function Manager.AdjustMoney(player: Player, amount: number)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.Money += amount
	player.leaderstats.Money.Value = profile.Data.Money
	DataService.Client.UpdateMoney:Fire(player, profile.Data.Money)
end
function Manager.AdjustFishes(player: Player, fish: string)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	local petsTable = profile.Data.fishes
	table.insert(petsTable, fish)
	print(petsTable)
	DataService.Client.UpdateFishes:Fire(player, profile.Data.fishes)
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
