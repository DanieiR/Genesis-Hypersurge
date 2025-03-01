--[[
    This script will handle all the UI related effects for when the player starts fishing.
    Author: @Dan_iDev
    Date Created: 12/28/2024
    Date Modified: 1/16/2024
]]

-- Services
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local staterGui = game:GetService("StarterGui")
-- Modules

local AnimationManager =
	require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Modules"):WaitForChild("AnimationsManager"))
local ClickingMinigameConfig = require(ReplicatedStorage.Source.Configs.ClickingMinigame)
-- Variables
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIAssetsFolder = ReplicatedStorage:WaitForChild("UIAssets")
local CastingUIAsset = UIAssetsFolder:WaitForChild("CastingUI")
local notificationsUI = Player:WaitForChild("PlayerGui"):WaitForChild("Notifications")
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
local MinigameUI = ReplicatedStorage.UIAssets.ClickingMinigame
local clickButtonForMinigame = MinigameUI:WaitForChild("Main"):WaitForChild("Clicking").ClickBtn
local MainFrame = nil
local ReelFrame = nil
local GreenBar = nil
local RedBar = nil
local MultiplierText = nil
local Spam = nil
local GreenBarConnection = nil
local RedBarConnection = nil
local heartbeatConnection = nil
local minigameGui = nil
local clickedDuringExclamation = false
local clickConnection
local fishingSFX = SoundService["Sound Effects"].Fishing
local mouseClickEffect = PlayerGui:WaitForChild("Effects"):WaitForChild("Main").Click
function animateToMax()
	if not Bar then
		return
	end
	currentTween = TweenService:Create(Bar, tweenInfoForward, { Size = UDim2.new(1, 0, 2, 0) })
	currentTween:Play()

	currentTween.Completed:Connect(function()
		if isAnimating then
			animateToMin() -- Start animating back to minimum when it reaches the maximum
		end
	end)
end

function animateToMin()
	if not Bar then
		return
	end
	currentTween = TweenService:Create(Bar, tweenInfoBackward, { Size = UDim2.new(1, 0, 0.1, 0) })
	currentTween:Play()

	currentTween.Completed:Connect(function()
		if isAnimating then
			animateToMax() -- Start animating back to maximum when it reaches the minimum
		end
	end)
end

local function startPowerBarAnimation()
	isAnimating = true
	animateToMax()

	-- Update Multiplier text and color using RunService.Heartbeat
	if not heartbeatConnection then
		heartbeatConnection = RunService.Heartbeat:Connect(function()
			if currentCastingUI and MultiplierText and Bar then
				local currentYScale = Bar.Size.Y.Scale
				MultiplierText.Text = string.format("x%.1f", currentYScale / 2 * 10)
				-- Update MultiplierText color based on Bar's Y scale
				if currentYScale > 1.8 then
					MultiplierText.TextColor3 = Color3.fromRGB(0, 255, 0)
				elseif currentYScale > 1.2 then
					MultiplierText.TextColor3 = Color3.fromRGB(0, 68, 255)
				elseif currentYScale > 0.6 then
					MultiplierText.TextColor3 = Color3.fromRGB(255, 255, 0)
				else
					MultiplierText.TextColor3 = Color3.fromRGB(255, 0, 0)
				end
			end
		end)
	end
end
local function stopPowerBarAnimation()
	isAnimating = false
	if currentTween then
		currentTween:Cancel()
	end

	-- Disconnect Heartbeat connection
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
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
	print("Resetting fishing state...") -- Debug print

	isAnimating = false
	isPlayerFishing = false

	-- Cancel any active tweens
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
		print("Cancelled currentTween.") -- Debug print
	end

	-- Destroy the casting UI
	if currentCastingUI then
		currentCastingUI:Destroy()
		currentCastingUI = nil
		Bar = nil -- Ensure Bar is also reset
		print("Destroyed currentCastingUI.") -- Debug print
	end
	if GreenBarConnection then
		GreenBarConnection:Disconnect()
		GreenBarConnection = nil
	end
	if RedBarConnection then
		RedBarConnection:Disconnect()
		RedBarConnection = nil
	end
	-- Destroy the minigame UI
	if minigameGui and minigameGui.Parent then
		minigameGui:Destroy()
		minigameGui = nil
		print("Destroyed minigameGui.") -- Debug print
	end

	if clickConnection then
		clickConnection:Disconnect()
		clickConnection = nil
		print("Disconnected clickConnection.")
	end

	FishingService = Knit.GetService("FishingService")
	FishingService.Cleanup:Fire(false)

	AnimationManager:StopAnimations(Player.Character, 0.2)

	Player.Character.Humanoid.WalkSpeed = 16

	print("Fishing state reset.")
end

local function PlayCatchAnimation(caughtFish)
	-- Disconnect any active bar connections
	if GreenBarConnection then
		GreenBarConnection:Disconnect()
		GreenBarConnection = nil
	end
	if RedBarConnection then
		RedBarConnection:Disconnect()
		RedBarConnection = nil
	end

	-- Get the caught fish model
	local caughtFishModel = ReplicatedStorage.Fishes:FindFirstChild(caughtFish.fish)
	if not caughtFishModel then
		warn("Fish model not found:", caughtFish.fish)
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

	-- Fire fishing and EXP update events
	local fishingService = Knit.GetService("FishingService")
	fishingService.FishingSuccess:Fire(caughtFish)
	local LevelService = Knit.GetService("LevelService")
	LevelService.UpdatePlayerExp:Fire(caughtFish)
	local bobber = rod:FindFirstChild("Bobber")

	SoundService:PlayLocalSound(fishingSFX.FishCaught_Ding)
	SoundService:PlayLocalSound(fishingSFX.FishCaught_Water)
	FishingService.ThrowFish:Fire(caughtFish)
	SoundService:PlayLocalSound(fishingSFX.FishShow)

	-- Display a fishing notification
	task.spawn(function()
		notificationsUI.Main.Fishing.FishingNotificationText.Text = "You caught a 1 in "
			.. caughtFish.odds
			.. " "
			.. caughtFish.fish
			.. " at "
			.. caughtFish.weight
			.. "kg!"
		notificationsUI.Main.Visible = true
	end)

	-- Clone the fish model for the left hand
	local clonedFishHand = caughtFishModel:Clone()
	clonedFishHand.Parent = Workspace
	clonedFishHand:SetPrimaryPartCFrame(CFrame.new(0, -100, 0)) -- Initially off-screen

	-- Find the left arm and grip attachment
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

	-- ** Camera Manipulation: Tween from Left to Right **

	local camera = workspace.CurrentCamera
	-- Save the original camera settings for later reset.
	local originalCameraCFrame = camera.CFrame
	local originalCameraFieldOfView = camera.FieldOfView

	-- Define offsets relative to the player's local space.
	local leftOffset = Vector3.new(5, 3, -10) -- 5 studs to the left, 3 studs up, 10 studs behind
	local rightOffset = Vector3.new(-5, 3, -10) -- 5 studs to the right, 3 studs up, 10 studs behind

	-- Define a common look-at point near the player.
	local lookAtPosition = rootPart.Position + rootPart.CFrame.LookVector * 2 + Vector3.new(0, 2, 0)

	-- Convert local offsets to world positions.
	local leftCameraPosition = rootPart.Position + rootPart.CFrame:VectorToWorldSpace(leftOffset)
	local rightCameraPosition = rootPart.Position + rootPart.CFrame:VectorToWorldSpace(rightOffset)

	-- Tween settings
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	-- First: Tween the camera to the left position.
	local tweenToLeft = TweenService:Create(camera, tweenInfo, {
		CFrame = CFrame.new(leftCameraPosition, lookAtPosition),
		FieldOfView = 30, -- Adjust zoom as needed
	})
	tweenToLeft:Play()

	-- When the tween-to-left completes, start the catch animation and tween the camera to the right.
	tweenToLeft.Completed:Connect(function()
		-- Play the catch animation on the player's character.
		local CatchTrack = AnimationManager:PlayAnimation(Player.Character, "FishingRod_Catch")
		task.wait(0.5)
		local tweenInfoRight = TweenInfo.new(
			1, -- Duration in seconds
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut
		)
		-- Now tween the camera from the left position to the right position.
		local tweenToRight = TweenService:Create(camera, tweenInfoRight, {
			CFrame = CFrame.new(rightCameraPosition, lookAtPosition),
			FieldOfView = 30,
		})
		tweenToRight:Play()

		local animationDuration = CatchTrack.Length
		local handAttachmentTime = animationDuration * 0.2
		task.delay(handAttachmentTime, function()
			if not clonedFishHand or not clonedFishHand.Parent then
				return
			end
			-- Position the cloned fish relative to the left grip attachment.
			clonedFishHand:SetPrimaryPartCFrame(leftGripAttachment.WorldCFrame)
			-- Weld the fish to the left arm.
			local weld = Instance.new("Weld")
			weld.Part0 = leftArm
			weld.Part1 = clonedFishHand.PrimaryPart
			weld.C0 = leftGripAttachment.CFrame * CFrame.Angles(math.rad(-90), 0, math.rad(90))
			weld.Parent = leftArm
			-- Ensure the fish is not anchored or colliding.
			clonedFishHand.PrimaryPart.Anchored = false
			clonedFishHand.PrimaryPart.CanCollide = false
			for _, v in pairs(clonedFishHand:GetDescendants()) do
				if v:IsA("BasePart") then
					v.Anchored = false
					v.CanCollide = false
				end
			end
		end)
		FishingService = Knit.GetService("FishingService")
		FishingService.Cleanup:Fire(true)
		-- Wait for the catch animation to finish.
		CatchTrack.Ended:Wait()

		-- Reset the camera to its original state.
		local resetCameraTween = TweenService:Create(camera, tweenInfo, {
			CFrame = originalCameraCFrame,
			FieldOfView = originalCameraFieldOfView,
		})
		resetCameraTween:Play()

		-- Play subsequent animations and cleanup.
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
		task.wait(0.3)
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
		isPlayerFishing = false
		Player.Character.Humanoid.WalkSpeed = 16
		clonedFishHand:Destroy()
		Player.IsFishing.Value = false
		task.wait(3)
		notificationsUI.Main.Visible = false
	end)
end

local function onMinigameFailed()
	if GreenBarConnection then
		GreenBarConnection:Disconnect()
		GreenBarConnection = nil
	end
	if RedBarConnection then
		RedBarConnection:Disconnect()
		RedBarConnection = nil
	end
	SoundService:PlayLocalSound(fishingSFX.Lose_Minigame)
	FishingService = Knit.GetService("FishingService")
	FishingService.Cleanup:Fire(false)
	AnimationManager:StopAnimations(Player.Character)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
	task.wait(0.3)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
	isPlayerFishing = false
	Player.Character.Humanoid.WalkSpeed = 16
	Player.IsFishing.Value = false
end
local function startSecondMinigame(caughtFish)
	if not isRodEquipped() then
		resetState()
		return
	end
	if minigameGui and minigameGui.Parent then
		minigameGui:Destroy()
	end
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
	SoundService:PlayLocalSound(fishingSFX.Start_Minigame)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Reel", true)
	local reelSound = fishingSFX.FishingReel_Minigame:Clone()
	task.wait(0.2)
	exclamationUI.Icon.Visible = false
	task.wait(0.2)
	exclamationUI.Icon.Visible = true
	task.wait(1)
	exclamationUI:Destroy()

	local playerGui = Player:WaitForChild("PlayerGui")
	minigameGui = MinigameUI:Clone()
	minigameGui.Parent = playerGui

	-- Now set the references to the elements inside the CLONED UI:
	MainFrame = minigameGui:WaitForChild("Main")
	ReelFrame = MainFrame:WaitForChild("Reel")
	GreenBar = ReelFrame:WaitForChild("Bar"):WaitForChild("GreenBar")
	RedBar = ReelFrame:WaitForChild("Bar"):WaitForChild("RedBar")
	Bar = ReelFrame:WaitForChild("Bar")
	Spam = ReelFrame:WaitForChild("Spam")
	local Shadow = MainFrame:WaitForChild("Shadow")
	local YankAmountsFrame = ReelFrame:WaitForChild("YankAmounts")
	local holdImage = ReelFrame:WaitForChild("Hold")
	local isHolding = false
	local spamConnection = nil
	local requiredSpamCount = 5 -- Number of clicks needed at each yank point
	local spamCount = 0
	local isSpamming = false
	local rod = Player.Character:FindFirstChildWhichIsA("Tool")
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
	for _, Particles in ipairs(bobber.Top.FishVFX:GetChildren()) do
		Particles.Enabled = true
	end
	reelSound.Parent = rod.Handle
	reelSound:Play()
	-- Animate the FishVFX attachment in a circle using task.spawn
	task.spawn(function()
		local radius = 2
		local rotationTime = 3
		local startTime = tick()
		local attachment = bobber.Top.FishVFX

		-- Store the original Y offset so it remains constant
		local originalY = attachment.Position.Y
		-- Loop while the attachment exists
		while attachment and attachment.Parent do
			local elapsed = tick() - startTime
			local angle = (elapsed / rotationTime) * (2 * math.pi)
			attachment.Position = Vector3.new(math.cos(angle) * radius, originalY, math.sin(angle) * radius)
			task.wait() -- Wait one frame for smooth animation
		end
	end)

	MainFrame.Clicking.Visible = false

	-- Show the second minigame's UI
	ReelFrame.Visible = false
	MainFrame.Visible = true

	-- Set AnchorPoint for GreenBar
	GreenBar.AnchorPoint = Vector2.new(0.5, 0.05)
	GreenBar.Position = UDim2.new(0.5, 0, 0, 0)
	RedBar.AnchorPoint = Vector2.new(0.5, 0.05)
	RedBar.Position = UDim2.new(0.5, 0, 0, 0)

	local yankPointIndex = 1
	local yankPoints = {
		0.288, -- First Yank Point (Y scale)
		0.556, -- Second Yank Point (Y scale)
		0.823, -- Third Yank Point (Y scale)
		--1.047, -- Complete (Y scale)
	}

	for _, TextLabel in ipairs(YankAmountsFrame:GetDescendants()) do
		if TextLabel:IsA("TextLabel") then
			TextLabel.Text = tostring(requiredSpamCount)
		end
	end
	--Initally tween the ReelFrame to its original position after moving it off-screen
	-- Store original position of ReelFrame and move it off-screen
	local originalReelFramePosition = ReelFrame.Position
	ReelFrame.Position = UDim2.new(1, 5, 0.5, 0) -- Example: Move it off-screen to the right
	ReelFrame.Visible = true
	-- Tween the ReelFrame to its original position
	local reelFrameTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local reelFrameTween = TweenService:Create(ReelFrame, reelFrameTweenInfo, { Position = originalReelFramePosition })
	reelFrameTween:Play()
	ReelFrame.CountDown.Visible = true
	local countDownText = ReelFrame.CountDown.CountDownText
	Shadow.Visible = true
	for i = 1, 3, 1 do
		countDownText.Text = tostring(4 - i)
		task.wait(1)
	end
	Shadow.Visible = false
	ReelFrame.CountDown.Visible = false
	-- Make RedBar visible initially, no need to change its size
	RedBar.Visible = true
	-- Function to handle spam input
	local function onSpamInput(input, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if isSpamming then
				spamCount = spamCount + 1
				local currenTextLabel = YankAmountsFrame:FindFirstChild(tostring(yankPointIndex))
				currenTextLabel.NumberText.Text = tostring(requiredSpamCount - spamCount)
				-- Visual effect: Tilt the Spam ImageLabel
				Spam.Rotation = 10 -- Tilt to the right (in degrees)

				-- Reset the tilt after a short delay
				task.delay(0.1, function()
					Spam.Rotation = -10 -- Tilt to the left
				end)
				task.delay(0.2, function()
					Spam.Rotation = 0
				end)
				if spamCount >= requiredSpamCount then
					-- Spamming successful, move to the next yank point
					isSpamming = false
					Spam.Visible = false
					holdImage.Visible = true
					spamCount = 0
					yankPointIndex = yankPointIndex + 1
					tweenGreenBarToNextYankPoint()
				end
			end
		end
	end

	-- Function to wait for spamming at the yank point
	local function waitForSpamming()
		isSpamming = true
		Spam.Visible = true
		holdImage.Visible = false
		spamConnection = UserInputService.InputBegan:Connect(onSpamInput)
	end

	-- Function to handle mouse button input
	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isHolding = true
		end
	end

	local function onInputEnded(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isHolding = false
		end
	end

	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	-- Function to tween the green bar's SIZE to the next yank point
	function tweenGreenBarToNextYankPoint()
		if spamConnection then
			spamConnection:Disconnect()
		end
		holdImage.Visible = true
		while minigameGui and minigameGui.Parent do
			if isHolding then
				local greenBarRiseSpeed = 0.01
				local newGreenBarY = GreenBar.Size.Y.Scale + greenBarRiseSpeed
				GreenBar.Size = UDim2.new(1, 0, newGreenBarY, 0)

				if newGreenBarY >= 1.047 then
					minigameGui:Destroy()
					reelSound:Destroy()

					if spamConnection then
						spamConnection:Disconnect()
					end
					PlayCatchAnimation(caughtFish)
					return
				end
				if yankPoints[yankPointIndex] and newGreenBarY >= yankPoints[yankPointIndex] then
					waitForSpamming()
					break
				end
			end

			task.wait(0.05)
		end
	end
	local function tweenRedBarToNextYankPoint()
		while minigameGui and minigameGui.Parent do
			local redBarRiseSpeed = 0.005
			local newRedBarY = RedBar.Size.Y.Scale + redBarRiseSpeed
			RedBar.Size = UDim2.new(1, 0, newRedBarY, 0)
			-- Check if red bars size is greater than green bar
			if newRedBarY >= GreenBar.Size.Y.Scale then
				minigameGui:Destroy()
				reelSound:Destroy()
				if spamConnection then
					spamConnection:Disconnect()
				end
				onMinigameFailed()
				return
			end
			task.wait(0.05)
		end
	end

	local function startMinigame()
		-- Start tweening the green bar
		task.spawn(function()
			GreenBarConnection = tweenGreenBarToNextYankPoint()
		end)

		task.delay(2, function()
			RedBarConnection = tweenRedBarToNextYankPoint()
		end)
	end
	startMinigame()
end

local function spawnFirstMinigame(caughtFish)
	local minigameRunning = true -- Flag to indicate if the minigame is running
	local minigameDelay = nil -- Variable to hold the task.delay coroutine

	if not isRodEquipped() then
		resetState()
		return
	end

	if minigameGui and minigameGui.Parent then
		minigameGui:Destroy()
	end

	SoundService:PlayLocalSound(fishingSFX.Start_Minigame)
	minigame1finished = false
	local playerGui = Player:WaitForChild("PlayerGui")
	minigameGui = MinigameUI:Clone()
	minigameGui.Parent = playerGui

	local minigameFrame = minigameGui:WaitForChild("Main"):WaitForChild("Clicking")

	-- Get the button's and icon's original sizes and positions (from the TEMPLATE before cloning)
	local NewFishIcon = minigameFrame:WaitForChild("Fish")
	local originalButtonSize = clickButtonForMinigame.Size
	local originalButtonPosition = clickButtonForMinigame.Position
	local originalIconSize = clickButtonForMinigame.Icon.Size
	local originalIconPosition = clickButtonForMinigame.Icon.Position

	-- Configuration
	local numButtons = ClickingMinigameConfig.numButtons -- Total number of moves/buttons
	local buttonSpawnInterval = ClickingMinigameConfig.buttonSpawnInterval
	local minigameDuration = numButtons * buttonSpawnInterval -- Total duration of the minigame
	local neededSuccessCount = ClickingMinigameConfig.neededSuccessCount -- Number of successful clicks needed
	local tweenDuration = ClickingMinigameConfig.tweenDuration -- Duration for tweens
	local currentButtons = {}
	local successCount = 0

	-- Function to get a random position within the middle area of the clicking frame
	local function getRandomPosition()
		local frameWidth = minigameFrame.AbsoluteSize.X
		local frameHeight = minigameFrame.AbsoluteSize.Y

		local middleAreaWidth = frameWidth / 2
		local middleAreaHeight = frameHeight / 2

		local middleAreaX = minigameFrame.AbsolutePosition.X + (frameWidth - middleAreaWidth) / 2
		local middleAreaY = minigameFrame.AbsolutePosition.Y + (frameHeight - middleAreaHeight) / 2

		local randomX = middleAreaX + math.random(0, middleAreaWidth - clickButtonForMinigame.AbsoluteSize.X)
		local randomY = middleAreaY + math.random(0, middleAreaHeight - clickButtonForMinigame.AbsoluteSize.Y)

		return UDim2.new(0, randomX, 0, randomY)
	end

	-- Function to handle a successful button click
	local function onButtonClicked(button)
		if button then
			SoundService:PlayLocalSound(fishingSFX.UI_Click)

			-- Show a quick click effect at the mouse position
			task.spawn(function()
				local originalSize = mouseClickEffect.Size
				local mouse = Player:GetMouse()
				local mouseClickEffectClone = mouseClickEffect:Clone()
				mouseClickEffectClone.Parent = minigameGui
				mouseClickEffectClone.Size = UDim2.new(0, 0, 0, 0)
				mouseClickEffectClone.Position = UDim2.new(0, mouse.X, 0, mouse.Y)

				local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
				local tween = TweenService:Create(mouseClickEffectClone, tweenInfo, { Size = originalSize })
				tween:Play()

				tween.Completed:Connect(function()
					task.wait(0.1)
					if mouseClickEffectClone then
						mouseClickEffectClone:Destroy()
					end
				end)
			end)

			successCount = successCount + 1
			table.remove(currentButtons, table.find(currentButtons, button))
			button:Destroy()

			if successCount >= neededSuccessCount then
				print("Minigame successful!")
				minigame1finished = true
				minigameRunning = false
				if minigameDelay then
					task.cancel(minigameDelay)
					minigameDelay = nil
				end
				minigameGui:Destroy()
				startSecondMinigame(caughtFish)
			end
		end
	end

	-- Function to spawn a button at a specific position (where the fish icon moved)
	local function spawnButtonAtPosition(position)
		local button = clickButtonForMinigame:Clone()
		local icon = button:WaitForChild("Icon")

		button.Position = position
		button.Size = UDim2.new(0, 0, 0, 0) -- Start with size 0 for a "pop in" effect
		icon.Size = UDim2.new(0, 0, 0, 0)
		icon.Position = originalIconPosition

		button.Parent = minigameFrame
		button.Visible = true
		icon.Parent = button
		icon.Visible = true

		table.insert(currentButtons, button)

		local sizeTweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local buttonSizeTween = TweenService:Create(button, sizeTweenInfo, { Size = originalButtonSize })
		buttonSizeTween:Play()
		local iconSizeTween = TweenService:Create(icon, sizeTweenInfo, { Size = originalIconSize })
		iconSizeTween:Play()

		button.MouseButton1Click:Connect(function()
			onButtonClicked(button)
		end)

		-- If the button isn’t clicked, shrink and destroy it after tweening
		buttonSizeTween.Completed:Connect(function()
			if button and button.Parent then
				local shrinkTweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local buttonShrinkTween = TweenService:Create(button, shrinkTweenInfo, { Size = UDim2.new(0, 0, 0, 0) })
				buttonShrinkTween:Play()
				local iconShrinkTween = TweenService:Create(icon, shrinkTweenInfo, { Size = UDim2.new(0, 0, 0, 0) })
				iconShrinkTween:Play()

				buttonShrinkTween.Completed:Connect(function()
					if button and button.Parent then
						table.remove(currentButtons, table.find(currentButtons, button))
						button:Destroy()
					end
				end)
			end
		end)
	end

	-- Function to move the fish icon along the path and then spawn a button at its new location
	local function moveFishIconAndSpawnButton()
		NewFishIcon.Visible = true
		local targetPosition = getRandomPosition()
		local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fishTween = TweenService:Create(NewFishIcon, tweenInfo, { Position = targetPosition })
		fishTween:Play()
		local shakeRotationIntensity = 15
		local shaking = true
		fishTween.Completed:Connect(function()
			shaking = false
			spawnButtonAtPosition(NewFishIcon.Position)
		end)
		spawn(function()
			while shaking do
				local randomRotation = math.random(-shakeRotationIntensity, shakeRotationIntensity)
				NewFishIcon.Rotation = randomRotation
				task.wait(0.05)
			end
			NewFishIcon.Rotation = 0
		end)
	end
	-- End-of-minigame timer
	minigameDelay = task.delay(minigameDuration, function()
		if minigameGui and minigameGui.Parent then
			if successCount < neededSuccessCount and not minigame1finished then
				print("Minigame failed!")
				startSecondMinigame(caughtFish)
				minigame1finished = true
				minigameRunning = false
			end
		end
	end)
	-- Instead of spawning buttons at random locations directly,
	-- move the fish icon and then spawn a button at its destination.
	for i = 1, numButtons do
		if not minigameRunning then
			break
		end
		moveFishIconAndSpawnButton()
		task.wait(buttonSpawnInterval)
	end
end

local function showTextForBar(endedAtPower)
	local ThrowQualityUI = ReplicatedStorage.UIAssets.ThrowQuality:Clone()
	ThrowQualityUI.Parent = Player.Character.Head
	ThrowQualityUI.Main.Background.Visible = true
	ThrowQualityUI.Main.Visible = true
	local VFXFolder = ReplicatedStorage:WaitForChild("Fx")
	local baseCFrame = Player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0.5, 0)
	if endedAtPower > 1.8 then
		ThrowQualityUI.Main["Amazing!"].Visible = true
		SoundService:PlayLocalSound(fishingSFX.Amazing)
		local FX = VFXFolder.Amazing:Clone()
		FX.Parent = Player.Character
		FX:SetPrimaryPartCFrame(baseCFrame * CFrame.Angles(0, math.rad(90), 0))
		task.wait(2)
		FX:Destroy()
	elseif endedAtPower > 1.2 then
		ThrowQualityUI.Main["Great!"].Visible = true
		SoundService:PlayLocalSound(fishingSFX.Great)
		local FX = VFXFolder.Good:Clone()
		FX.Parent = Player.Character
		FX:SetPrimaryPartCFrame(baseCFrame * CFrame.Angles(0, math.rad(90), 0))
		task.wait(2)
		FX:Destroy()
	elseif endedAtPower > 0.6 then
		ThrowQualityUI.Main["Good"].Visible = true
		SoundService:PlayLocalSound(fishingSFX.Okay)
		local FX = VFXFolder.Okay:Clone()
		FX.Parent = Player.Character
		FX:SetPrimaryPartCFrame(baseCFrame * CFrame.Angles(0, math.rad(90), 0))
		task.wait(2)
		FX:Destroy()
	else
		ThrowQualityUI.Main["Bad."].Visible = true
		local FX = VFXFolder.Bad:Clone()
		FX.Parent = Player.Character
		FX:SetPrimaryPartCFrame(baseCFrame * CFrame.Angles(0, math.rad(90), 0))
		task.wait(2)
		FX:Destroy()
		SoundService:PlayLocalSound(fishingSFX.Bad)
	end
	task.wait(1.5)
	ThrowQualityUI:Destroy()
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
		MultiplierText = currentCastingUI:WaitForChild("Main"):WaitForChild("Multiplier")
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
		local endedAtPower = Bar.Size.Y.Scale
		task.spawn(function()
			stopPowerBarAnimation()
		end)
		task.spawn(function()
			showTextForBar(endedAtPower)
		end)
		Player.IsFishing.Value = true
		AnimationManager:StopAnimations(Player.Character)
		local track = AnimationManager:PlayAnimation(Player.Character, "FishingRod_Throw")
		track.Stopped:Wait()
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_Idle", true)
		local fishingService = Knit.GetService("FishingService")
		fishingService.FishingStarted:Fire()
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
	Player.IsFishing.Value = false
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
		--SimulateFishHooked(caughtFish)
		spawnFirstMinigame(caughtFish)
	end)

	local function setupCharacterEvents(character)
		-- Track tool events
		local function trackToolEvents()
			-- Child Removed
			character.ChildRemoved:Connect(function(child)
				if child:IsA("Tool") and child.Name:sub(-3) == "Rod" then
					SoundService:PlayLocalSound(fishingSFX.Equip_Unequip_Rod)
					resetState()
				end
			end)

			-- Child Added
			character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and child.Name:sub(-3) == "Rod" then
					SoundService:PlayLocalSound(fishingSFX.Equip_Unequip_Rod)
				end
			end)
		end

		trackToolEvents()
	end

	if Player.Character then
		setupCharacterEvents(Player.Character)
	end

	Player.CharacterAdded:Connect(setupCharacterEvents)
end

Knit:OnStart():andThen(start)
