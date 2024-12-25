local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")

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

Knit:OnStart():andThen(start)

return Manager
