local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Rods = Component.new({
	Tag = "RodBuyable",
	Ancestors = { workspace },
})

function Rods:_InitiateBuying(player, Rod)
	local RodMarket = Knit.GetService("RodsMarket")
	RodMarket:_InitiateConfirmationOnClient(player, Rod)
end

Rods.Started:Connect(function(component)
	component.Instance:WaitForChild("ProximityPrompt").Triggered:Connect(function(plr)
		print(plr.Name .. " Triggered the prompt")
		local Rod = component.Instance.Parent
		Rods:_InitiateBuying(plr, Rod)
	end)
end)

function Rods:Stop() end

return Rods
