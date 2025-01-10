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

function StateController:UpdateMoney(money: number)
	PlayerData.Money = money
end
function StateController:UpdateFishes(fishes: table)
	PlayerData.Fishes = fishes
end

function StateController:ResetData(data)
	PlayerData = data
end

function StateController:KnitStart() end

return StateController
