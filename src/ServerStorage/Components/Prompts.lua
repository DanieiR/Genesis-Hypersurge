local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Prompts = Component.new({
	Tag = "ProximityPrompts",
	Ancestors = { workspace },
})

function Prompts:_InitiateSelling(player, NPC)
	local SellService = Knit.GetService("SellingService")
	SellService:_InitiateDialogueOnClient(player, NPC)
end

Prompts.Started:Connect(function(component)
	component.Instance:WaitForChild("ProximityPrompt").Triggered:Connect(function(plr)
		print(plr.Name .. " Triggered the prompt")
		local NPCName = component.Instance.Parent.Name
		print(NPCName)
		if NPCName == "Santi" then
			Prompts:_InitiateSelling(plr, component.Instance.Parent)
		end
	end)
end)

function Prompts:Stop() end

return Prompts
