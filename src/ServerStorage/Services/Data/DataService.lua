local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local ProfileService = require(ServerStorage.Source.Services.Data.ProfileService)
local Manager = require(ServerStorage.Source.Manager)

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {
		UpdateCoins = Knit.CreateSignal(),
		UpdateStars = Knit.CreateSignal(),
		UpdateFishes = Knit.CreateSignal(),
		UpdateExp = Knit.CreateSignal(),
		LevelUp = Knit.CreateSignal(),
		ResetData = Knit.CreateSignal(),
	},
})
local ProfileTemplate = require(ReplicatedStorage.Source.PlayerData.Template)

local ProfileStore = ProfileService.GetProfileStore("PlayerData26", ProfileTemplate)

local function giveLeaderStats(player)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local Coins = Instance.new("NumberValue")
	Coins.Parent = leaderstats
	Coins.Name = "Coins"
	local Stars = Instance.new("NumberValue")
	Stars.Parent = leaderstats
	Stars.Name = "Stars"
end

function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			Manager.Profiles[player] = nil
			player:Kick()
		end)
		if player:IsDescendantOf(Players) == true then
			Manager.Profiles[player] = profile
			giveLeaderStats(player)
		else
			profile:Release()
		end
	else
		player:Kick()
	end
end

function DataService:KnitStart()
	print("DataService Started")
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = Manager.Profiles[player]
		if profile ~= nil then
			profile:Release()
		end
	end)
end

function DataService:KnitInit() end

return DataService
