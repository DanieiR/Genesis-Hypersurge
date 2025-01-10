local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Add Workspace service
local SoundService = game:GetService("SoundService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Manager = require(ServerStorage.Source.Manager)
local RNGModule = require(ServerStorage.Source.Services.Fishing.RNGModule)
local CurrentBobber
local fishingSFX = SoundService["Sound Effects"].Fishing
local FishingService = Knit.CreateService({
	Name = "FishingService",
	Client = {
		FishingStarted = Knit.CreateSignal(),
		NoWater = Knit.CreateSignal(),
		FishCaught = Knit.CreateSignal(),
		Cleanup = Knit.CreateSignal(),
		FishingSuccess = Knit.CreateSignal(),
	},
})

function FishingService:StartFishing(player)
	local profile = Manager.Profiles[player]
	if not profile then
		print("No profile found for player:", player.Name)
		return
	end
	local WAIT_TIME = profile.Data.WaitTime -- This wait time will be changed depending on the players stats
	local caughtFish = RNGModule.GetRandomFish()
	print("Caught fish:", caughtFish)
	task.wait(WAIT_TIME)
	self.Client.FishCaught:Fire(player, caughtFish) -- Signal that a fish has been caught
	self.Client.FishingSuccess:Connect(function(player, success)
		Manager.AdjustFishes(player, caughtFish)
	end)
end
function FishingService:AttachBobberToLine(Player)
	local character = Player.Character
	local rod = character:FindFirstChildWhichIsA("Tool")
	if not rod then
		warn("Rod not found in character")
		return
	end

	local line = rod:FindFirstChild("Handle"):FindFirstChild("Line")
	if not line then
		warn("Line not found in rod")
		return
	end

	local attachment1 = line:FindFirstChild("Attachment1")
	local attachment0 = line:FindFirstChild("Attachment")
	local rope = attachment0:FindFirstChild("RopeConstraint")

	if not attachment1 or not attachment0 or not rope then
		warn("Missing attachments or rope constraint in line")
		return
	end

	-- Clone the bobber model
	local bobberModel = ReplicatedStorage:FindFirstChild("Bobbers").Bobber:Clone()
	CurrentBobber = bobberModel
	if not bobberModel then
		warn("Bobber model not found in ReplicatedStorage")
		return
	end
	bobberModel.Parent = rod
	bobberModel:SetPrimaryPartCFrame(attachment1.WorldCFrame + Vector3.new(0, 1, 3))

	-- Create an attachment on the bobber for the rope
	local bobberAttachment = Instance.new("Attachment")
	bobberAttachment.Name = "BobberAttachment"
	bobberAttachment.Parent = bobberModel.PrimaryPart
	bobberAttachment.WorldPosition = bobberModel.PrimaryPart.Position

	fishingSFX.ThrowRod2:Play()
	-- Connect the rope to the bobber
	rope.Attachment1 = bobberAttachment

	-- Apply initial forward force
	local rodTipWorldPosition = attachment0.WorldPosition
	local bobberPosition = bobberModel.PrimaryPart.Position
	local direction = (rodTipWorldPosition - bobberPosition).Unit
	local forwardForce = 50 -- Adjust this value
	bobberModel.PrimaryPart:ApplyImpulse(direction * forwardForce)

	-- Adjust rope length until the bobber hits water
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

	local maxRopeLength = 20 -- Maximum length the rope can extend to
	local ropeLengthIncrement = 0.5 -- How much to increase rope length each step
	local currentRopeLength = 0

	while currentRopeLength < maxRopeLength do
		rope.Length = currentRopeLength
		task.wait()

		local rayOrigin = bobberAttachment.WorldPosition
		local rayDirection = Vector3.new(0, -1, 0) -- Cast ray downwards
		local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		if raycastResult then
			-- Bobber is above water, stop increasing rope length
			-- Simulate fishing process here
			fishingSFX.BobberLands:Play()
			print("Fishing started for player:", Player.Name)
			self:StartFishing(Player)
			bobberModel.Bottom.Attachment.splash.Enabled = true
			break
		else
			-- Bobber is not above water, increase rope length
			currentRopeLength = currentRopeLength + ropeLengthIncrement
		end
	end

	if currentRopeLength >= maxRopeLength then
		warn("Bobber did not reach water within the maximum rope length")
		bobberModel:Destroy()
		self.Client.NoWater:Fire(Player)
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bobberModel.PrimaryPart
	weld.Part1 = attachment1.Parent
	weld.Parent = weld.Part0
end

function FishingService:Main(player)
	self:AttachBobberToLine(player)
end
function FishingService:PerformCleanup(player, success)
	if CurrentBobber then
		CurrentBobber:Destroy()
	end
end

function FishingService:KnitStart()
	self.Client.FishingStarted:Connect(function(player)
		self:Main(player)
	end)
	self.Client.Cleanup:Connect(function(player, success)
		self:PerformCleanup(player)
	end)
end

return FishingService
