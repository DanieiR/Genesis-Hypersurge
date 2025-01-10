local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

function start()
	local DataService = Knit.GetService("DataService")
	local StateController = Knit.GetController("StateController")
	DataService.UpdateMoney:Connect(function(money)
		StateController:UpdateMoney(money)
	end)
	DataService.UpdateFishes:Connect(function(fishes: table)
		StateController:UpdateFishes(fishes)
	end)
	DataService.ResetData:Connect(function(data)
		StateController:ResetData(data)
	end)
end

Knit:OnStart():andThen(start)
