local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Manager = require(ServerStorage.Source.Manager)

local InventoryService = Knit.CreateService({
	Name = "InventoryService",
	Client = {
		SetLockState = Knit.CreateSignal(),
		SetEquippedState = Knit.CreateSignal(),
		SetUnitLockState = Knit.CreateSignal(),
	},
})

function InventoryService:SetLockState(player, FishID, lockState)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	for _, fish in ipairs(profile.Data.fishes) do
		if fish.ID == FishID then
			fish.locked = lockState
			print(lockState and "Locked fish" or "Unlocked fish", FishID)
			break
		end
	end
end

function InventoryService:SetEquip(player, FishID, equipState)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	for _, fish in ipairs(profile.Data.fishes) do
		fish.equipped = false
	end

	if equipState then
		for _, fish in ipairs(profile.Data.fishes) do
			if fish.ID == FishID then
				fish.equipped = true
				print("Equipped fish:", FishID)
				break
			end
		end
	end
end
function InventoryService:SetUnitLockState(player, unitID, lockState)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	-- Find and update the unit's lock state
	for _, unit in ipairs(profile.Data.units) do
		if unit.ID == unitID then
			unit.isLocked = lockState
			print(lockState and "Locked unit" or "Unlocked unit", unitID)
			break
		end
	end
end

function InventoryService:KnitStart()
	self.Client.SetLockState:Connect(function(player, FishID, lockState)
		self:SetLockState(player, FishID, lockState)
	end)

	self.Client.SetEquippedState:Connect(function(player, FishID, equipState)
		self:SetEquip(player, FishID, equipState)
	end)
	self.Client.SetUnitLockState:Connect(function(player, unitID, lockState)
		self:SetUnitLockState(player, unitID, lockState)
	end)
end

return InventoryService
