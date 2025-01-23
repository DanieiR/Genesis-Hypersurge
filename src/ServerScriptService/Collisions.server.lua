local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local CollisionGroupName = "Player"
PhysicsService:RegisterCollisionGroup(CollisionGroupName)
PhysicsService:CollisionGroupSetCollidable(CollisionGroupName, CollisionGroupName, false)

local function setCollisionGroup(model)
	-- Apply collision group to all existing parts in the model
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = CollisionGroupName
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setCollisionGroup(character)
	end)
	-- If the player already has a character, apply the collision group immediately
	if player.Character then
		setCollisionGroup(player.Character)
	end
end)
