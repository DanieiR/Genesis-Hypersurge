--[[
This script will handle all the Fishing animations for the client.
Author: Dan_iDev
Date Created: 12/31/2024
Date Modified: 1/3/2024
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local AnimationManager =
	require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Modules"):WaitForChild("AnimationsManager"))

-- Local Variables
local player = Players.LocalPlayer
local character = nil

local animations = {
	["FishingRod_Equip"] = 129326447568059,
	["FishingRod_EquipIdle"] = 140407661960913,
	["FishingRod_Throw"] = 79780231544605,
	["FishingRod_Hold"] = 123045284933073,
	["FishingRod_Idle"] = 91317673046419,
	["FishingRod_Catch"] = 134968993757108,
}

-- Function to handle tool equipping
local function onToolEquipped(tool)
	if tool.Name:sub(-3) == "Rod" then
		AnimationManager:PlayAnimation(character, "FishingRod_Equip")
		task.wait(0.3)
		AnimationManager:PlayAnimation(character, "FishingRod_EquipIdle", true)
	end
end

-- Function to handle tool unequipping
local function onToolUnequipped(tool)
	if tool.Name:sub(-3) == "Rod" then
		AnimationManager:StopAnimations(character, 0.2)
	end
end

-- Function to setup character
local function setupCharacter(newCharacter)
	character = newCharacter
	-- Load animations for the character
	AnimationManager:LoadAnimations(character, animations)

	-- Connect to the Equipped event for each tool the player has
	for _, tool in pairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			onToolEquipped(tool)
		end
	end

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child.Equipped:Connect(function()
				onToolEquipped(child)
			end)
			child.Unequipped:Connect(function()
				onToolUnequipped(child)
			end)
		end
	end)
end

-- Character setup
local function onCharacterAdded(newCharacter)
	setupCharacter(newCharacter)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
