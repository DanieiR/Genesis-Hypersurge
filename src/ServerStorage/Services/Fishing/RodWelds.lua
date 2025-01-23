local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local Knit = require(ReplicatedStorage.Packages.Knit)

local RodWelds = Knit.CreateService({
	Name = "RodWelds",
	Client = {
		weldBobberToRod = Knit.CreateSignal(),
	},
})

-- Use a table to store bobbers for each player
local currentBobbers = {}
local hipWelds = {}
-- Helper function to find the torso or UpperTorso
local function findTorso(character)
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	if not torso then
		warn("Could not find Torso or UpperTorso in character!")
	end
	return torso
end
local function weldToTorso(character, bobber)
	local torso = character:FindFirstChild("Torso")
	if not torso then
		return
	end

	local weld = Instance.new("Weld")
	weld.Part0 = torso
	weld.Part1 = bobber.PrimaryPart
	weld.C0 = CFrame.new(-0.7, -0.8, 0.50) * CFrame.Angles(0, math.rad(-90), 0)
	weld.Parent = bobber

	return weld
end

-- Function to create and configure the WeldConstraint
local function createWeldConstraint(torso, handle)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = torso
	weldConstraint.Part1 = handle
	weldConstraint.Parent = handle
	return weldConstraint
end

-- Function to create and configure the Weld for positioning
local function createPositioningWeld(torso, handle)
	local weld = Instance.new("Weld")
	weld.Part0 = torso
	weld.Part1 = handle
	weld.Parent = handle
	-- Adjust C0 for R6 (your adjusted values)
	weld.C0 = CFrame.new(1, -1, 0.55) * CFrame.Angles(math.rad(-90), math.rad(50), math.rad(90))
	return weld
end

-- Function to process a found tool and create welds
local function weldHandleToCharacter(character, tool)
	-- Find the handle
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		warn("Tool " .. tool.Name .. " does not have a Handle part!")
		return
	end
	local rope = handle:FindFirstChild("Line").Attachment.RopeConstraint
	rope.Visible = false
	-- Clone the handle
	local clonedHandle = handle:Clone()
	clonedHandle.Name = "ClonedRodHandle"
	clonedHandle.Parent = character

	-- Find the character's torso
	local torso = findTorso(character)
	if not torso then
		return
	end

	-- Create the WeldConstraint
	createWeldConstraint(torso, clonedHandle)

	-- Create the positioning Weld
	createPositioningWeld(torso, clonedHandle)

	return clonedHandle
end

-- Function to remove the cloned handle
local function removeClonedHandle(character)
	local clonedHandle = character:FindFirstChild("ClonedRodHandle")
	if clonedHandle then
		clonedHandle:Destroy()
	end
end

function RodWelds:addBobberToRod(player, RodTool: Tool)
	local LinePart = RodTool:FindFirstChild("Handle"):FindFirstChild("Line")
	if not LinePart then
		warn("Line not found in rod")
		return
	end
	local Attachment1 = LinePart:FindFirstChild("Attachment1")
	local Attachment0 = LinePart:FindFirstChild("Attachment")
	local Rope = Attachment0:FindFirstChild("RopeConstraint")
	Rope.Length = 2
	if not Attachment1 or not Attachment0 or not Rope then
		warn("Missing attachments or rope constraint in line")
		return
	end
	local BobberModel = ReplicatedStorage:WaitForChild("Bobbers"):WaitForChild("Bobber"):Clone()

	-- Store the bobber in the table using the player as the key
	currentBobbers[player] = BobberModel

	if not BobberModel then
		warn("Bobber model not found in ReplicatedStorage")
		return
	end
	BobberModel.Parent = RodTool
	BobberModel:SetPrimaryPartCFrame(Attachment1.WorldCFrame + Vector3.new(0, 3, 10))
	local BobberAttachment = Instance.new("Attachment")
	BobberAttachment.Name = "BobberAttachment"
	BobberAttachment.Parent = BobberModel.PrimaryPart
	BobberAttachment.WorldPosition = BobberModel.PrimaryPart.Position
	Rope.Attachment1 = BobberAttachment
end

-- Function to remove the player's bobber
local function removeBobber(player)
	if currentBobbers[player] then
		currentBobbers[player]:Destroy()
		currentBobbers[player] = nil
	end
end

function RodWelds:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		local function onCharacterAdded(character)
			-- Wait for the character to fully load
			character:WaitForChild("Humanoid")

			-- Check for rod on character added
			for _, tool in ipairs(player.Backpack:GetChildren()) do
				if tool:IsA("Tool") and tool.Name:match("Rod$") then
					weldHandleToCharacter(character, tool)
					local bobber = ReplicatedStorage:WaitForChild("Bobbers"):WaitForChild("Bobber"):Clone()
					bobber.Parent = character
					weldToTorso(character, bobber)
				end
			end

			-- Connect to tool equip and unequip events
			player.Character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and child.Name:match("Rod$") then
					removeClonedHandle(character)
					--self:addBobberToRod(player, child)
				end
			end)

			player.Character.ChildRemoved:Connect(function(child)
				if child:IsA("Tool") and child.Name:match("Rod$") then
					for _, tool in ipairs(StarterPack:GetChildren()) do
						if tool:IsA("Tool") and tool.Name == child.Name then
							weldHandleToCharacter(character, tool)
							removeBobber(player)
						end
					end
				end
			end)
		end

		player.CharacterAdded:Connect(onCharacterAdded)

		-- Call character added in case the player already spawned
		if player.Character then
			onCharacterAdded(player.Character)
		end
	end)
end

return RodWelds
