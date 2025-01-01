--[[
    This script will handle all the UI related effects for when the player starts fishing.
    Author: @Dan_iDev
    Date Created: 12/28/2024
    Date Modified: 12/31/2024
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
-- Modules
local AnimationManager =
	require(ReplicatedStorage:WaitForChild("Source"):WaitForChild("Modules"):WaitForChild("AnimationsManager"))
-- Variables
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UIAssetsFolder = ReplicatedStorage:WaitForChild("UIAssets")
local CastingUIAsset = UIAssetsFolder:WaitForChild("CastingUI")

local currentCastingUI = nil
local Bar = nil
local isAnimating = false
local currentTween = nil
local tweenTime = 1

local tweenInfoForward = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)

local tweenInfoBackward = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)

function animateToMax()
	if not Bar then
		return
	end
	currentTween = TweenService:Create(Bar, tweenInfoForward, { Size = UDim2.new(1, 0, 2, 0) })
	currentTween:Play()
	currentTween.Completed:Wait()
	if isAnimating then
		animateToMin()
	end
end

function animateToMin()
	if not Bar then
		return
	end
	currentTween = TweenService:Create(Bar, tweenInfoBackward, { Size = UDim2.new(1, 0, 0.1, 0) })
	currentTween:Play()
	currentTween.Completed:Wait()
	if isAnimating then
		animateToMax()
	end
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

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local hasEquippedRod = isRodEquipped()
	if not hasEquippedRod then
		return
	end
	if not currentCastingUI then
		-- Clone and parent the BillboardGui on the first click
		currentCastingUI = CastingUIAsset:Clone()
		currentCastingUI.Parent = Player.Character:WaitForChild("Head")
		Bar = currentCastingUI:WaitForChild("Main"):WaitForChild("Bar"):WaitForChild("BarFrame")
		AnimationManager:StopAnimations(Player.Character, 0.2)
		AnimationManager:PlayAnimation(Player.Character, "FishingRod_Hold", false, 0.2)
		startPowerBarAnimation()
	else
		if isAnimating then
			stopPowerBarAnimation()
			AnimationManager:StopAnimations(Player.Character, 0.2)
			local track = AnimationManager:PlayAnimation(Player.Character, "FishingRod_Throw")
			track.Ended:Wait()
			AnimationManager:PlayAnimation(Player.Character, "FishingRod_Idle", true, 0.2)
			task.wait(1)
			if currentCastingUI then
				currentCastingUI:Destroy()
				currentCastingUI = nil
			end
		else
			startPowerBarAnimation()
		end
	end
end)
