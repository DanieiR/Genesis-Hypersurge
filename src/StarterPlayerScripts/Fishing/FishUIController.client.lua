--[[
    This script will handle all the UI related effects for when the player starts fishing.
    Author: @Dan_iDev
    Date Created: 12/28/2024
    Date Modified: 1/10/2024
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

	-- Disconnect input connections (add more if needed for minigames)
	if clickConnection then
		clickConnection:Disconnect()
		clickConnection = nil
		print("Disconnected clickConnection.") -- Debug print
	end

	FishingService = Knit.GetService("FishingService")
	FishingService.Cleanup:Fire(false) -- Make sure server knows we stopped

	AnimationManager:StopAnimations(Player.Character, 0.2)

	Player.Character.Humanoid.WalkSpeed = 16

	print("Fishing state reset.") -- Debug print
end

local function PlayCatchAnimation(caughtFish)
	if GreenBarConnection then
		GreenBarConnection:Disconnect()
		GreenBarConnection = nil
	end
	if RedBarConnection then
		RedBarConnection:Disconnect()
		RedBarConnection = nil
	end
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
	fishingSFX.FishCaught_Ding:Play()
	fishingSFX.FishCaught_Water:Play()
	-- Clone the fish model for the impulse effect
	local clonedFishImpulse = caughtFishModel:Clone()
	clonedFishImpulse.Parent = Workspace
	clonedFishImpulse:SetPrimaryPartCFrame(bobber.Top.CFrame + Vector3.new(0, 1, 3))

	-- Calculate impulse direction
	local direction = (rootPart.Position + Vector3.new(0, 1, 0) - clonedFishImpulse.PrimaryPart.Position).Unit
	local impulseForce = 10

	-- Apply impulse
	clonedFishImpulse.PrimaryPart:ApplyImpulse(direction * impulseForce)
	fishingSFX.FishShow:Play()
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

	-- ** Camera Manipulation **
	local originalCameraCFrame = workspace.CurrentCamera.CFrame
	local originalCameraFieldOfView = workspace.CurrentCamera.FieldOfView
	local camera = workspace.CurrentCamera

	-- Use the rootPart's CFrame to calculate the offset relative to its facing direction
	local cameraOffset = Vector3.new(0, 3, -15) --  Now negative Z to go behind, relative to facing direction
	local lookAtPosition = rootPart.Position + rootPart.CFrame.LookVector * 2 + Vector3.new(0, 2, 0) -- Look slightly in front and above the rootPart

	-- Calculate the camera's target position based on rootPart's CFrame and offset
	local targetCameraPosition = rootPart.Position + rootPart.CFrame:VectorToWorldSpace(cameraOffset)

	-- Create the target CFrame, making the camera look at the lookAtPosition
	local targetCFrame = CFrame.new(targetCameraPosition, lookAtPosition)
	local targetFieldOfView = 30 -- Adjust for desired zoom level

	local tweenInfo = TweenInfo.new(
		0.5, -- Duration of the tween
		Enum.EasingStyle.Quad, -- Easing style
		Enum.EasingDirection.InOut, -- Easing direction
		0, -- Number of times to repeat
		false, -- Should reverse
		0 -- Delay time
	)

	local cameraTween = TweenService:Create(camera, tweenInfo, {
		CFrame = targetCFrame,
		FieldOfView = targetFieldOfView,
	})

	cameraTween:Play()

	cameraTween:Play()
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
	FishingService.Cleanup:Fire(true)
	CatchTrack.Ended:Wait()

	-- ** Reset Camera **
	local resetCameraTween = TweenService:Create(camera, tweenInfo, {
		CFrame = originalCameraCFrame,
		FieldOfView = originalCameraFieldOfView,
	})
	resetCameraTween:Play()

	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
	task.wait(0.3)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
	isPlayerFishing = false
	Player.Character.Humanoid.WalkSpeed = 16
	clonedFishHand:Destroy()
	task.wait(3)
	clonedFishImpulse:Destroy()
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
	fishingSFX.Lose_Minigame:Play()
	FishingService = Knit.GetService("FishingService")
	FishingService.Cleanup:Fire(false)
	AnimationManager:StopAnimations(Player.Character)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Equip")
	task.wait(0.3)
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_EquipIdle", true)
	isPlayerFishing = false
	Player.Character.Humanoid.WalkSpeed = 16
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
	fishingSFX.Start_Minigame:Play()
	AnimationManager:PlayAnimation(Player.Character, "FishingRod_Reel", true)
	fishingSFX.FishingReel_Minigame:Play()
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
	local YankAmountsFrame = ReelFrame:WaitForChild("YankAmounts")
	local isHolding = false
	local spamConnection = nil
	local requiredSpamCount = 5 -- Number of clicks needed at each yank point
	local spamCount = 0
	local isSpamming = false

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
	for i = 1, 3, 1 do
		countDownText.Text = tostring(4 - i)
		task.wait(1)
	end
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
		while minigameGui and minigameGui.Parent do
			if isHolding then
				local greenBarRiseSpeed = 0.02
				local newGreenBarY = GreenBar.Size.Y.Scale + greenBarRiseSpeed
				GreenBar.Size = UDim2.new(1, 0, newGreenBarY, 0)

				if newGreenBarY >= 1.047 then
					minigameGui:Destroy()
					fishingSFX.FishingReel_Minigame:Stop()
					PlayCatchAnimation(caughtFish)
					return
				end
				if yankPoints[yankPointIndex] and newGreenBarY >= yankPoints[yankPointIndex] then
					waitForSpamming()
					break
				end
			end

			task.wait(0.2)
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
				fishingSFX.FishingReel_Minigame:Stop()
				onMinigameFailed()
				return
			end
			task.wait(0.2)
		end
	end

	local function startMinigame()
		-- Start tweening the green bar
		task.spawn(function()
			GreenBarConnection = tweenGreenBarToNextYankPoint()
		end)

		task.spawn(function()
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
	fishingSFX.Start_Minigame:Play()
	minigame1finished = false
	local playerGui = Player:WaitForChild("PlayerGui")
	minigameGui = MinigameUI:Clone()
	minigameGui.Parent = playerGui

	local minigameFrame = minigameGui:WaitForChild("Main"):WaitForChild("Clicking")

	-- Get the button's and icon's original sizes and positions (from the TEMPLATE before cloning)
	local originalButtonSize = clickButtonForMinigame.Size
	local originalButtonPosition = clickButtonForMinigame.Position
	local originalIconSize = clickButtonForMinigame.Icon.Size
	local originalIconPosition = clickButtonForMinigame.Icon.Position

	-- Configuration
	local numButtons = 10 -- Total number of buttons to spawn

	local buttonSpawnInterval = 0.5
	local minigameDuration = numButtons * buttonSpawnInterval -- Seconds the minigame lasts
	local successCount = 0
	local neededSuccessCount = 5 -- Number of buttons to click successfully
	local currentButtons = {}
	local tweenDuration = 1 -- Adjust the duration of the tween as needed

	-- Function to get a random position within the middle area (halved Clicking frame)
	local function getRandomPosition()
		-- Get the size of the Clicking frame
		local frameWidth = minigameFrame.AbsoluteSize.X
		local frameHeight = minigameFrame.AbsoluteSize.Y

		-- Halve the frame size to define the middle area
		local middleAreaWidth = frameWidth / 2
		local middleAreaHeight = frameHeight / 2

		-- Calculate the top left corner position of the middle area
		local middleAreaX = minigameFrame.AbsolutePosition.X + (frameWidth - middleAreaWidth) / 2
		local middleAreaY = minigameFrame.AbsolutePosition.Y + (frameHeight - middleAreaHeight) / 2

		-- Calculate random position within the middle area
		local randomX = middleAreaX + math.random(0, middleAreaWidth - clickButtonForMinigame.AbsoluteSize.X)
		local randomY = middleAreaY + math.random(0, middleAreaHeight - clickButtonForMinigame.AbsoluteSize.Y)

		return UDim2.new(0, randomX, 0, randomY)
	end

	-- Function to handle button click
	local function onButtonClicked(button)
		if button then
			successCount = successCount + 1
			table.remove(currentButtons, table.find(currentButtons, button)) -- Remove from table
			button:Destroy()

			if successCount >= neededSuccessCount then
				print("Minigame successful!")
				minigame1finished = true
				minigameRunning = false -- Stop spawning buttons
				if minigameDelay then
					task.cancel(minigameDelay) -- Cancel the minigame timer
					minigameDelay = nil
				end
				minigameGui:Destroy()
				startSecondMinigame(caughtFish)
			end
		end
	end

	-- Function to spawn a new button
	local function spawnButton()
		if minigameRunning then
			local button = clickButtonForMinigame:Clone()

			local button = clickButtonForMinigame:Clone()
			local icon = button:WaitForChild("Icon")
			local targetPosition = getRandomPosition()

			-- ** Initial Size and Position **
			button.Size = UDim2.new(0, 0, 0, 0) -- Start with size 0
			button.Position = targetPosition
			icon.Size = UDim2.new(0, 0, 0, 0) -- Start with size 0 for icon too
			icon.Position = originalIconPosition

			button.Parent = minigameFrame
			button.Visible = true
			icon.Parent = button
			icon.Visible = true

			table.insert(currentButtons, button) -- ** Add button to the table **

			-- ** Tween Info **
			local sizeTweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			-- ** Create and Play Tweens for Button **
			local buttonSizeTween = TweenService:Create(button, sizeTweenInfo, { Size = originalButtonSize })
			buttonSizeTween:Play()

			-- ** Create and Play Tweens for Icon **
			local iconSizeTween = TweenService:Create(icon, sizeTweenInfo, { Size = originalIconSize })
			iconSizeTween:Play()

			-- Connect click event
			button.MouseButton1Click:Connect(function()
				onButtonClicked(button)
			end)

			-- Timer to tween the button and icon back to size 0 if not clicked
			buttonSizeTween.Completed:Connect(function()
				if button and button.Parent then
					local shrinkTweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

					-- ** Create and Play Shrink Tweens for Button **
					local buttonShrinkTween =
						TweenService:Create(button, shrinkTweenInfo, { Size = UDim2.new(0, 0, 0, 0) })
					buttonShrinkTween:Play()

					-- ** Create and Play Shrink Tweens for Icon **
					local iconShrinkTween = TweenService:Create(icon, shrinkTweenInfo, { Size = UDim2.new(0, 0, 0, 0) })
					iconShrinkTween:Play()

					buttonShrinkTween.Completed:Connect(function()
						if button and button.Parent then
							table.remove(currentButtons, table.find(currentButtons, button)) -- Remove from table
							button:Destroy()
						end
					end)
				end
			end)
		end
	end

	-- Spawn multiple buttons with slight delays
	for i = 1, numButtons do
		if not minigameRunning then
			break
		end -- Exit the loop if minigame is not running
		spawnButton()
		task.wait(buttonSpawnInterval) -- Wait for a short interval before spawning the next button
	end

	-- Minigame timer
	minigameDelay = task.delay(minigameDuration, function()
		if minigameGui and minigameGui.Parent then
			if successCount < neededSuccessCount and not minigame1finished then
				print("Minigame failed!")
				onMinigameFailed()
				minigame1finished = true
				minigameRunning = false -- Stop spawning buttons
				minigameGui:Destroy()
			end
		end
	end)
end

local function showTextForBar(endedAtPower)
	local ThrowQualityUI = ReplicatedStorage.UIAssets.ThrowQuality:Clone()
	ThrowQualityUI.Parent = Player.Character.Head
	ThrowQualityUI.Main.Background.Visible = true
	ThrowQualityUI.Main.Visible = true
	if endedAtPower > 1.8 then
		ThrowQualityUI.Main["Amazing!"].Visible = true
		fishingSFX.Amazing:Play()
	elseif endedAtPower > 1.2 then
		ThrowQualityUI.Main["Great!"].Visible = true
		fishingSFX.Great:Play()
	elseif endedAtPower > 0.6 then
		ThrowQualityUI.Main["Good"].Visible = true
		fishingSFX.Okay:Play()
	else
		ThrowQualityUI.Main["Bad."].Visible = true
		fishingSFX.Bad:Play()
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
		stopPowerBarAnimation()
		task.spawn(function()
			showTextForBar(endedAtPower)
		end)
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

	task.wait(5)
	Player.Character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child.Name:sub(-3) == "Rod" then
			fishingSFX.Equip_Unequip_Rod:Play()
			resetState()
		end
	end)
	Player.Character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name:sub(-3) == "Rod" then
			fishingSFX.Equip_Unequip_Rod:Play()
		end
	end)
end

Knit:OnStart():andThen(start)
