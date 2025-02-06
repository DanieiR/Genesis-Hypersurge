local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")
local Manager = require(ServerStorage.Source.Manager)

local SellingSerivce = Knit.CreateService({
	Name = "SellingService",
	Client = {
		InitiateNPCDialogue = Knit.CreateSignal(),
		SellAllRequest = Knit.CreateSignal(),
		SellEquippedRequest = Knit.CreateSignal(),
	},
})

function SellingSerivce:_InitiateDialogueOnClient(Player: Player, NPC: Model)
	self.Client.InitiateNPCDialogue:Fire(Player, NPC)
end

function SellingSerivce:_SellAllForPlayer(Player: Player)
	local profile = Manager.Profiles[Player]
	if not profile then
		return
	end

	-- Collect all unlockable fish IDs
	local fishIdsToSell = {}
	for _, fish in ipairs(profile.Data.fishes) do
		if not fish.locked then
			table.insert(fishIdsToSell, fish.ID)
		end
	end

	-- Use Manager.SellFishes for atomic operation
	local totalEarnings, soldCount = Manager.SellFishes(Player, fishIdsToSell)

	if soldCount > 0 then
		-- Destroy fish tools if any were equipped
		self:_RemoveFishTools(Player)
		print(`Sold {soldCount} fish(es) for {totalEarnings} coins`)
	end
end
function SellingSerivce:_RemoveFishTools(Player: Player)
	local function cleanTools(container)
		for _, tool in ipairs(container:GetChildren()) do
			if tool:IsA("Tool") and tool:FindFirstChild("IsFishTool") then
				tool:Destroy()
			end
		end
	end

	cleanTools(Player.Backpack)
	cleanTools(Player.Character)
end
function SellingSerivce:_SellEquipped(Player: Player)
	local profile = Manager.Profiles[Player]
	if not profile then
		return
	end

	-- Find equipped fish ID
	local equippedFishId
	for _, fish in ipairs(profile.Data.fishes) do
		if fish.equipped and not fish.locked then
			equippedFishId = fish.ID
			break
		end
	end

	if equippedFishId then
		-- Use Manager.SellFishes for atomic operation
		local totalEarnings = Manager.SellFishes(Player, { equippedFishId })

		if totalEarnings > 0 then
			self:_RemoveFishTools(Player)
			print(`Sold equipped fish for {totalEarnings} coins`)
		end
	end
end

function SellingSerivce:KnitStart()
	self.Client.SellAllRequest:Connect(function(player)
		self:_SellAllForPlayer(player)
	end)
	self.Client.SellEquippedRequest:Connect(function(player)
		self:_SellEquipped(player)
	end)
end

return SellingSerivce
