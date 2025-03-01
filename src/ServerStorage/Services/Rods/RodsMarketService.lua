local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Manager = require(ServerStorage.Source.Manager)

local RodsMarket = Knit.CreateService({
	Name = "RodsMarket",
	Client = {
		InitiateBuyConfirmation = Knit.CreateSignal(),
	},
})

function RodsMarket:_InitiateConfirmationOnClient(player, Rod)
	self.Client.InitiateBuyConfirmation:Fire(player, Rod)
end

function RodsMarket:_HandlePurchase(player, rod)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end
	if profile.Data.Coins >= rod.Price.Value then
		Manager.AdjustCoins(player, -rod.Price.Value)
		Manager.GiveRod(player, rod.Name)
		profile.Data[rod.Name] = true
	end
end

function RodsMarket:KnitStart()
	self.Client.InitiateBuyConfirmation:Connect(function(player, rod)
		self:_HandlePurchase(player, rod)
	end)
end

return RodsMarket
