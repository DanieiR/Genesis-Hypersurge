local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Template = require(ReplicatedStorage.Source.PlayerData.Template)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local IsDataLoaded = false
local StateController = Knit.CreateController({ Name = "StateController" })

local PlayerData: Template.PlayerData

-- Load the player data from the server
local function LoadData()
	if IsDataLoaded then
		return
	end

	while not PlayerData do
		PlayerData = Remotes.GetAllData:InvokeServer()
		task.wait(1)
	end
	IsDataLoaded = true
	print(PlayerData)
end

LoadData()

-- State object to store and retrieve player data

-- Get the player data
function StateController.GetData(): Template.PlayerData
	while not IsDataLoaded do
		task.wait(0.5)
	end
	return PlayerData
end

function StateController:UpdateCoins(coins: number)
	PlayerData.Coins = coins
end
function StateController:UpdateGems(gems: number)
	PlayerData.Gems = gems
end
function StateController:UpdateExp(exp: number)
	PlayerData.Exp = exp
end
function StateController:UpdateLevel(level: number)
	PlayerData.Level = level
end
function StateController:UpdateFishes(fishes: table)
	PlayerData.fishes = fishes
end
function StateController:UpdateRod(rodName)
	PlayerData[rodName] = true
end
function StateController:ResetData(data)
	PlayerData = data
end

function StateController:KnitStart() end

return StateController
