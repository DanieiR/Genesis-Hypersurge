local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)
local Knit = require(ReplicatedStorage.Packages.Knit)
local Prompts = Component.new({
	Tag = "ProximityPrompts",
	Ancestors = { workspace },
})

local debounce = {}
local COOLDOWN_TIME = 2 -- Cooldown in seconds

function Prompts:_InitiateSelling(player, NPC)
	local SellService = Knit.GetService("SellingService")
	SellService:_InitiateDialogueOnClient(player, NPC)
end

Prompts.Started:Connect(function(component)
	local prompt = component.Instance:WaitForChild("ProximityPrompt")
	prompt.Triggered:Connect(function(player)
		if debounce[player.UserId] then
			return
		end
		debounce[player.UserId] = true
		task.delay(COOLDOWN_TIME, function()
			debounce[player.UserId] = nil
		end)

		print(player.Name .. " Triggered the prompt")
		local NPCName = component.Instance.Parent.Name
		print(NPCName)
		if NPCName == "Santi" then
			Prompts:_InitiateSelling(player, component.Instance.Parent)
		end
	end)
end)

function Prompts:Stop() end

return Prompts
