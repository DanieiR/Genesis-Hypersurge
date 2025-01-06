--[[
    This script will handle all the UI related effects for when the player starts fishing.
    Author: @Dan_iDev
    Date Created: 12/28/2024
    Date Modified: 1/6/2024
]]

-- Services
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Modules

local AnimationManager =
	require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Modules"):WaitForChild("AnimationsManager"))

-- Variables
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIAssetsFolder = ReplicatedStorage:WaitForChild("UIAssets")
local CastingUIAsset = UIAssetsFolder:WaitForChild("CastingUI")
local isPlayerFishing = false
local currentCastingUI = nil
local Bar = nil
local isAnimating = false
local currentTween = nil
local tweenTime = 1
local tweenInfoForward = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, -1, true)
local tweenInfoBackward = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, true)
local FishingService
local cameraPanOutDuration = 0.5
local cameraPanInDuration = 1
local cameraPanOutOffset = 10 -- Adjust this value to control how far the camera pans out

local clickedDuringExclamation = false

function animateToMax()
	if not Bar then
		return
	end
	currentTween = TweenService:Create(Bar, tweenInfoForward, { Size = UDim2.new(1, 0, 2, 0) })
	currentTween:Play()
end

function animateToMin()
	if not Bar then
		return
	end
	currentTween = TweenService:Create(Bar, tweenInfoBackward, { Size = UDim2.new(1, 0, 0.1, 0) })
	currentTween:Play()
end

local function startPowerBarAnimation()
	isAnimating = true
	animateToMax()
end

local function stopPowerBarAnimation()
	isAnimating = false
	if currentTween then
		currentTween:Cancel()
	end
end

local function isRodEquipped()
	local equippedTool = Player.Character:FindFirstChildOfClass("Tool")
	if equippedTool and equippedTool.Name:sub(-3) == "Rod" then
		return true
	end

	return false
end
local function resetState()
	isAnimating = false
	isPlayerFishing = false
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	if currentCastingUI then
		currentCastingUI:Destroy()
		currentCastingUI = nil
	end
	Bar = nil
	FishingService = Knit.GetService("FishingService")
	FishingService.Cleanup:Fire()
	AnimationManager:StopAnimations(Player.Character, 0.2)

	Player.Character.Humanoid.WalkSpeed = 16
end

local function PlayCatchAnimation(caughtFish)
	local caughtFishModel = ReplicatedStorage.Fishes:FindFirstChild(caughtFish)
	if not caughtFishModel then
		warn("Fish model not found:", caughtFish)
		return
	end

	local character = Player.Character
	local rootPart = character:WaitForChild("HumanoidRootPart")
	local rod = character:FindFirstChildWhichIsA("Tool")

	if not rod then
		warn("Rod not found in character")
		return
	end

	local rodTip = rod:FindFirstChild("Handle").Line
	if not rodTip then
		warn("RodTip not found in rod")
		return
	end
	local bobber = rod:FindFirstChild("Bobber")
	print(bobber)
	-- Clone the fish model for the impulse effect
	local clonedFishImpulse = caughtFishModel:Clone()
	clonedFishImpulse.Parent = Workspace
	clonedFishImpulse:SetPrimaryPartCFrame(bobber.PrimaryPart.CFrame + Vector3.new(0, 1, 3))

	-- Calculate impulse direction
	local direction = (rootPart.Position + Vector3.new(0, 1, 0) - clonedFishImpulse.PrimaryPart.Position).Unit
	local impulseForce = 10

	-- Apply impulse
	clonedFishImpulse.PrimaryPart:ApplyImpulse(direction * impulseForce)

	-- Clone the fish model for the left hand
	local clonedFishHand = caughtFishModel:Clone()
	clonedFishHand.Parent = Workspace
	clonedFishHand:SetPrimaryPartCFrame(CFrame.new(0, -100, 0)) -- Initially position it off-screen

	-- Find the left hand and attachment
	local leftArm = character:FindFirstChild("Left Arm")

	if not leftArm then
		warn("Left arm not found in character")
		return
	end

	local leftGripAttachment = leftArm:FindFirstChild("LeftGripAttachment")

	if not leftGripAttachment then
		warn("LeftGripAttachment not found in Left Arm")
		return
	end
	-- Play the catch animation
	local CatchTrack = AnimationManager:PlayAnimation(Player.Character, "FishingRod_Catch")

	-- Time-based positioning of the fish on the left hand
	local animationDuration = CatchTrack.Length
	local handAttachmentTime = animationDuration * 0.2

	task.delay(handAttachmentTime, function()
		if not clonedFishHand or not clonedFishHand.Parent then
			return
		end

		-- Position relative to the attachment
		clonedFishHand:SetPrimaryPartCFrame(leftGripAttachment.WorldCFrame)

		-- Weld the fish to the left hand
		local weld = Instance.new("Weld")
		weld.Part0 = leftArm
		weld.Part1 = clonedFishHand.PrimaryPart
		weld.C0 = leftGripAttachment.CFrame
		weld.Parent = weld.Part0

		clonedFishHand.PrimaryPart.Anchored = false
		clonedFishHand.PrimaryPart.CanCollide = false
		for i, v in pairs(clonedFishHand:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Anchored = false
				v.CanCollide = false
			end
		end
	end)
	FishingService = Knit.GetService("FishingService")
	FishingService.Cleanup:Fire()
	CatchTrack.Ended:Wait()
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
	task.wait(0.3)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
	isPlayerFishing = false
	Player.Character.Humanoid.WalkSpeed = 16
	clonedFishHand:Destroy()
	task.wait(3)
	clonedFishImpulse:Destroy()
end

local function SimulateFishHooked(caughtFish)
	local hasEquippedRod = isRodEquipped()
	if not hasEquippedRod then
		return
	end

	clickedDuringExclamation = false

	local exclamationUI = ReplicatedStorage.UIAssets.FishingExclamation:Clone()
	exclamationUI.Parent = Player.Character.Head

	local camera = Workspace.CurrentCamera
	local originalCameraCFrame = camera.CFrame
	local panOutGoal = originalCameraCFrame * CFrame.new(0, 0, cameraPanOutOffset)

	local panOutTweenInfo =
		TweenInfo.new(cameraPanOutDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)

	local panInTweenInfo = TweenInfo.new(cameraPanInDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)

	local panOutTween = TweenService:Create(camera, panOutTweenInfo, { CFrame = panOutGoal })
	local panInTween = TweenService:Create(camera, panInTweenInfo, { CFrame = originalCameraCFrame })

	panOutTween:Play()

	panOutTween.Completed:Connect(function()
		panInTween:Play()
	end)

	local clickConnection
	clickConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if exclamationUI and exclamationUI.Parent then
				clickedDuringExclamation = true
				clickConnection:Disconnect()
			end
		end
	end)
	task.wait(0.2)
	exclamationUI.Icon.Visible = false
	task.wait(0.2)
	exclamationUI.Icon.Visible = true
	task.wait(1)
	exclamationUI:Destroy()

	if clickedDuringExclamation then
		PlayCatchAnimation(caughtFish)
	else
		FishingService = Knit.GetService("FishingService")
		FishingService.Cleanup:Fire()
		AnimationManager:StopAnimations(Player.Character)
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
		task.wait(0.3)
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
		isPlayerFishing = false
		Player.Character.Humanoid.WalkSpeed = 16
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if isPlayerFishing then
		return
	end

	local hasEquippedRod = isRodEquipped()

	if not hasEquippedRod then
		return
	end

	if not currentCastingUI then
		isPlayerFishing = true
		Player.Character.Humanoid.WalkSpeed = 0
		-- Clone and parent the BillboardGui on the first right click down
		currentCastingUI = CastingUIAsset:Clone()
		currentCastingUI.Parent = Player.Character:WaitForChild("Head")
		Bar = currentCastingUI:WaitForChild("Main"):WaitForChild("Bar"):WaitForChild("BarFrame")
		AnimationManager:StopAnimations(Player.Character, 0.2)
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_Hold", false, 0.2)
		startPowerBarAnimation()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local hasEquippedRod = isRodEquipped()

	if not hasEquippedRod then
		return
	end

	if isAnimating and currentCastingUI then
		stopPowerBarAnimation()
		AnimationManager:StopAnimations(Player.Character)
		local track = AnimationManager:PlayAnimation(Player.Character, "FishingRod_Throw")
		task.wait(0.3)
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_Idle", true)
		FishingService.FishingStarted:Fire()
		task.wait(1)
		if currentCastingUI then
			currentCastingUI:Destroy()
			currentCastingUI = nil
		end
	end
end)

local function EndAnimationsIfNoWater()
	local hasEquippedRod = isRodEquipped()
	if not hasEquippedRod then
		return
	end

	task.wait(3)
	AnimationManager:StopAnimations(Player.Character)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
	task.wait(0.3)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
	isPlayerFishing = false
	Player.Character.Humanoid.WalkSpeed = 16
end

function start()
	FishingService = Knit.GetService("FishingService")
	print(FishingService)
	FishingService.NoWater:Connect(function()
		EndAnimationsIfNoWater()
	end)
	FishingService.FishCaught:Connect(function(caughtFish)
		SimulateFishHooked(caughtFish)
	end)
	task.wait(5)
	Player.Character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name:sub(-3) == "Rod" then
			resetState()
		end
	end)
end

Knit:OnStart():andThen(start)
