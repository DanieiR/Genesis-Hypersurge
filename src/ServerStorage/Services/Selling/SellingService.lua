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
		SellFromSellMode = Knit.CreateSignal(),
		SellUnitsFromSellMode = Knit.CreateSignal(),
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
function SellingSerivce:_SellClicked(Player: Player, fishes)
	print("Reach")
	local profile = Manager.Profiles[Player]
	if not profile then
		return
	end

	-- Collect all unlockable fish IDs
	local fishIdsToSell = {}
	for _, fish in ipairs(fishes) do
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
function SellingSerivce:SellUnits(Player: Player, units)
	local profile = Manager.Profiles[Player]
	if not profile then
		return
	end

	-- Collect all unlockable fish IDs
	local unitIdsToSell = {}
	for _, Unit in ipairs(units) do
		if not Unit.isLocked then
			table.insert(unitIdsToSell, Unit.ID)
		end
	end
	print(unitIdsToSell)
	-- Use Manager.SellFishes for atomic operation
	local totalEarnings, soldCount = Manager.SellUnits(Player, unitIdsToSell)

	print(`Sold {soldCount} unit(s) for {totalEarnings} coins`)
end

function SellingSerivce:KnitStart()
	self.Client.SellAllRequest:Connect(function(player)
		self:_SellAllForPlayer(player)
	end)
	self.Client.SellEquippedRequest:Connect(function(player)
		self:_SellEquipped(player)
	end)
	self.Client.SellFromSellMode:Connect(function(player, ID)
		self:_SellClicked(player, ID)
	end)
	self.Client.SellUnitsFromSellMode:Connect(function(player, ID)
		self:SellUnits(player, ID)
	end)
end

return SellingSerivce
