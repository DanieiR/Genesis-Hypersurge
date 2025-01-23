local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Add Workspace service
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
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
		ThrowBobber = Knit.CreateSignal(),
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
	bobberModel:SetPrimaryPartCFrame(attachment1.WorldCFrame + Vector3.new(0, 3, 10))

	-- Create an attachment on the bobber for the rope
	local bobberAttachment = Instance.new("Attachment")
	bobberAttachment.Name = "BobberAttachment"
	bobberAttachment.Parent = bobberModel.PrimaryPart
	bobberAttachment.WorldPosition = bobberModel.PrimaryPart.Position
	fishingSFX.ThrowRod2:Play()

	-- Create a dummy part for visual rope extension
	local dummyPart = Instance.new("Part")
	dummyPart.Size = Vector3.new(1, 1, 1)
	dummyPart.Transparency = 1
	dummyPart.CanCollide = false
	dummyPart.Anchored = true
	dummyPart.Parent = workspace
	dummyPart.Position = attachment0.WorldPosition

	-- Create an attachment on the dummy part
	local dummyAttachment = Instance.new("Attachment")
	dummyAttachment.Name = "DummyAttachment"
	dummyAttachment.Parent = dummyPart

	-- Connect the rope to the dummy attachment initially
	rope.Attachment1 = dummyAttachment

	--Use the quadratic bezier curve formula to calculate the trajectory of the bobber
	--(1-t)^2 * P0 + 2 * (1-t) * t * P1 + t^2 * P2
	--Very smooth!
	local StartPos = attachment0.WorldPosition
	local EndPoint = character.HumanoidRootPart.CFrame * CFrame.new(0, -10, -30)
	local MidPoint = (StartPos + EndPoint.Position) / 2 + Vector3.new(0, 30, 0)

	local bobberLanded = false
	bobberModel.PrimaryPart.Anchored = true
	character.HumanoidRootPart.Anchored = true
	rope.Length = 2
	self.Client.ThrowBobber:Fire(Player)
	for Index = 0, 100, 1.5 do
		local t = Index / 100
		local l1 = StartPos:Lerp(MidPoint, t)
		local l2 = MidPoint:Lerp(EndPoint.Position, t)

		local quad = l1:Lerp(l2, t)

		-- Move the dummy part along the trajectory
		dummyPart.Position = quad
		rope.Length = (attachment0.WorldPosition - dummyAttachment.WorldPosition).Magnitude

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

		local rayOrigin = quad
		local rayDirection = Vector3.new(0, -1, 0)
		local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		if raycastResult and raycastResult.Instance.Name == "Terrain" then
			bobberModel.PrimaryPart.Anchored = false
			bobberLanded = true
			local waterHitPosition = raycastResult.Position
			local aboveWaterPosition = waterHitPosition + Vector3.new(0, 1, 0) -- 1 stud above the water
			bobberModel:PivotTo(CFrame.new(aboveWaterPosition))
			for _, part in ipairs(bobberModel:GetChildren()) do
				if part:IsA("BasePart") then
					part.Massless = false
				end
			end
			character.HumanoidRootPart.Anchored = false
			break
		end

		bobberModel:PivotTo(CFrame.new(quad))
		task.wait()
	end
	bobberModel.PrimaryPart.Anchored = false
	character.HumanoidRootPart.Anchored = false
	if bobberLanded then
		-- Connect the rope to the actual bobber attachment
		rope.Attachment1 = bobberAttachment
		rope.Length = (attachment0.WorldPosition - bobberAttachment.WorldPosition).Magnitude

		-- Bobber is above water
		fishingSFX.BobberLands:Play()
		print("Fishing started for player:", Player.Name)
		self:StartFishing(Player)
		bobberModel.Top.Attachment.splash.Enabled = true
	else
		warn("Bobber did not reach water within the maximum rope length")
		bobberModel:Destroy()
		self.Client.NoWater:Fire(Player)
	end
	dummyPart:Destroy()
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
