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
function Manager.AdjustFishes(player: Player, fish: string)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	profile.Data.fishes = fish
	print("Fishes:", profile.Data.fishes)
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
