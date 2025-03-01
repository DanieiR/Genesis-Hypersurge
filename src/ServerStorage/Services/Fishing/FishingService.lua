local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace") -- Add Workspace service
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Manager = require(ServerStorage.Source.Manager)
local RNGModule = require(ServerStorage.Source.Services.Fishing.RNGModule)
local CurrentBobber = {}
local fishingSFX = SoundService["Sound Effects"].Fishing
local connection
local FishingService = Knit.CreateService({
	Name = "FishingService",
	Client = {
		FishingStarted = Knit.CreateSignal(),
		NoWater = Knit.CreateSignal(),
		FishCaught = Knit.CreateSignal(),
		Cleanup = Knit.CreateSignal(),
		FishingSuccess = Knit.CreateSignal(),
		ThrowBobber = Knit.CreateSignal(),
		ThrowFish = Knit.CreateSignal(),
	},
})
function FishingService:GenerateNumericFishId()
	local timestamp = os.time()
	local randomPart = math.random(100000000, 999999999) -- 9-digit random
	return tonumber(tostring(timestamp) .. tostring(randomPart))
end
function FishingService:StartFishing(player)
	local profile = Manager.Profiles[player]
	if not profile then
		return
	end

	-- Create DEEP COPY of fish template
	local baseFish = RNGModule.GetRandomFish()
	local caughtFish = table.clone(baseFish)
	caughtFish.ID = self:GenerateNumericFishId()
	caughtFish.equipped = false
	caughtFish.locked = false
	caughtFish.weight = math.random(caughtFish.weight, caughtFish.weight + 10)
	-- Store fish in temporary table
	local tempFishStore = { caughtFish }

	-- Create fresh connection each time
	local connection
	connection = self.Client.FishingSuccess:Connect(function(_, success)
		if success and tempFishStore[1] then
			local QuestService = Knit.GetService("QuestService")
			QuestService:OnFishAdded(player, caughtFish)
			Manager.AdjustFishes(player, tempFishStore[1])
			tempFishStore[1] = nil -- Prevent reuse
		end
		connection:Disconnect()
	end)

	task.wait(profile.Data.WaitTime)
	self.Client.FishCaught:Fire(player, caughtFish)
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
	local BobberModel = rod:FindFirstChild("Bobber")
	if BobberModel then
		BobberModel:Destroy()
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
	CurrentBobber[Player] = bobberModel

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
	local EndPoint = character.HumanoidRootPart.CFrame * CFrame.new(0, -10, -20)
	local MidPoint = (StartPos + EndPoint.Position) / 2 + Vector3.new(0, 30, 0)

	local bobberLanded = false
	bobberModel.PrimaryPart.Anchored = true
	character.HumanoidRootPart.Anchored = true
	rope.Length = 2
	rope.Visible = true
	self.Client.ThrowBobber:Fire(Player)
	for Index = 0, 100, 1.5 do
		local t = Index / 100
		local l1 = StartPos:Lerp(MidPoint, t)
		local l2 = MidPoint:Lerp(EndPoint.Position, t)

		local quad = l1:Lerp(l2, t)

		-- Move the dummy part along the trajectory
		dummyPart.Position = quad
		rope.Length = (attachment0.WorldPosition - dummyAttachment.WorldPosition).Magnitude + 1

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		raycastParams.FilterDescendantsInstances = { Workspace.Terrain }

		local rayOrigin = quad
		local rayDirection = Vector3.new(0, -1, 0)
		local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		if raycastResult and raycastResult.Instance.Name == "Terrain" then
			bobberLanded = true
			local waterHitPosition = raycastResult.Position
			local aboveWaterPosition = waterHitPosition + Vector3.new(0, 1, 0) -- 1 stud above the water
			local rotationOffset = CFrame.Angles(0, math.rad(-180), 0)
			local uprightCFrame = CFrame.new(aboveWaterPosition) * rotationOffset
			bobberModel:PivotTo(uprightCFrame)
			bobberModel.PrimaryPart.Anchored = false
			local bodyForce = Instance.new("BodyForce", bobberModel.Bottom)
			bodyForce.Force = Vector3.new(0, bobberModel.PrimaryPart:GetMass() * workspace.Gravity, 0)

			break
		end

		bobberModel:PivotTo(CFrame.new(quad))
		task.wait()
	end
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
		bobberModel.PrimaryPart.Anchored = false
	else
		warn("Bobber did not reach water within the maximum rope length")
		bobberModel:Destroy()
		self.Client.NoWater:Fire(Player)
	end
	dummyPart:Destroy()
end
function FishingService:_ThrowFishTowardsPlayer(Player, Fish)
	-- Get the fish model from ReplicatedStorage and clone it
	local caughtFishModel = ReplicatedStorage.Fishes:FindFirstChild(Fish.fish)
	if not caughtFishModel then
		warn("Fish model not found in ReplicatedStorage.Fishes")
		return
	end
	caughtFishModel = caughtFishModel:Clone()
	caughtFishModel.Parent = workspace

	-- Ensure the fish model has a PrimaryPart (or pick a suitable BasePart)
	local primaryPart = caughtFishModel.PrimaryPart or caughtFishModel:FindFirstChildWhichIsA("BasePart")
	if not primaryPart then
		warn("No PrimaryPart or BasePart found in the fish model")
		return
	end
	caughtFishModel.PrimaryPart = primaryPart

	local character = Player.Character
	if not character then
		warn("Player has no character")
		return
	end

	local playerRoot = character:FindFirstChild("HumanoidRootPart")
	if not playerRoot then
		warn("HumanoidRootPart not found in player's character")
		return
	end
	local rod = character:FindFirstChildWhichIsA("Tool")
	if not rod then
		warn("Rod not found in character")
		return
	end
	local bobber = rod:FindFirstChild("Bobber")
	-- Get start and end positions
	local startPos = bobber.Top.Position + Vector3.new(0, 1, 3)
	local endPos = playerRoot.Position
	caughtFishModel:SetPrimaryPartCFrame(bobber.Top.CFrame + Vector3.new(0, 1, 3))
	-- Define a control point for the arc (you can adjust the upward offset as desired)
	local midPoint = (startPos + endPos) / 2 + Vector3.new(0, 30, 0)

	-- Animation parameters
	local duration = 1.5 -- seconds
	local startTime = tick()
	local t = 0
	caughtFishModel.PrimaryPart.Anchored = true
	-- Animate using a quadratic Bezier curve
	while t < 1 do
		t = math.clamp((tick() - startTime) / duration, 0, 1)
		local oneMinusT = 1 - t

		-- Quadratic Bezier interpolation
		local pos = (oneMinusT * oneMinusT * startPos) + (2 * oneMinusT * t * midPoint) + (t * t * endPos)

		-- Update the fish model's position
		caughtFishModel:SetPrimaryPartCFrame(CFrame.new(pos))

		task.wait() -- wait a frame for a smooth update
	end
	caughtFishModel.PrimaryPart.Anchored = false
	task.wait(5)
	caughtFishModel:Destroy()
end

function FishingService:Main(player)
	self:AttachBobberToLine(player)
end

function FishingService:PerformCleanup(player, success)
	if CurrentBobber[player] then
		CurrentBobber[player]:Destroy()
		CurrentBobber[player] = nil
	end
	local character = player.Character
	local rod = character:FindFirstChildWhichIsA("Tool")
	if not rod then
		warn("Rod not found in character")
		return
	end
	--local RodWelds = Knit.GetService("RodWelds")
	--RodWelds:addBobberToRod(player, rod)
end

function FishingService:KnitStart()
	self.Client.FishingStarted:Connect(function(player)
		self:Main(player)
	end)
	self.Client.Cleanup:Connect(function(player, success)
		self:PerformCleanup(player)
	end)
	self.Client.ThrowFish:Connect(function(player, fishModel)
		task.spawn(function()
			self:_ThrowFishTowardsPlayer(player, fishModel)
		end)
	end)
end

return FishingService
