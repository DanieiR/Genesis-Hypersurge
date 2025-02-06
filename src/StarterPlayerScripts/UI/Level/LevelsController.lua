--[[
    Levels Controller Client
    Version: 1.1
    Last Updated: 2024-01-25
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LevelConfig = require(game:GetService("ReplicatedStorage").Source.Configs.LevelsConfig)
local LevelsController = Knit.CreateController({
	Name = "LevelsController",
})

-- Configuration
local BAR_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NUMBER_FORMAT = "%.0f" -- No decimal places
local XP_FORMAT = "Level %d [%s/%s]"

function LevelsController:_InitializeReferences()
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")

	local hud = self._playersUI:WaitForChild("PlayerHUD")
	self._expScreen = hud:WaitForChild("Main"):WaitForChild("XPBar")
	self._bar = self._expScreen:WaitForChild("XPBar"):WaitForChild("Bar")
	self._expStatsText = self._expScreen:WaitForChild("XPStats")

	self._stateController = Knit.GetController("StateController")
end

function LevelsController:_FormatNumber(number)
	-- Format with commas for readability
	return tostring(number):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

function LevelsController:_UpdateExpBar(newExp, newLevel, requiredExp)
	-- Validate inputs
	newExp = tonumber(newExp) or 0
	newLevel = tonumber(newLevel) or 1
	requiredExp = tonumber(requiredExp) or LevelConfig[newLevel].RequiredExp

	-- Handle max level
	local isMaxLevel = not requiredExp
	local currentExp = isMaxLevel and newExp or math.clamp(newExp, 0, requiredExp)

	-- Calculate fill amount
	local fillAmount = isMaxLevel and 1 or (currentExp / requiredExp)
	if fillAmount ~= fillAmount then -- NaN check
		fillAmount = 0
	end

	-- Animate XP bar
	local tween = TweenService:Create(self._bar, BAR_TWEEN_INFO, {
		Size = UDim2.new(fillAmount, 0, 1, 0),
	})
	tween:Play()

	-- Update text display
	local formattedCurrent = self:_FormatNumber(currentExp)
	local formattedRequired = isMaxLevel and "MAX" or self:_FormatNumber(requiredExp)
	self._expStatsText.Text = string.format(XP_FORMAT, newLevel, formattedCurrent, formattedRequired)
end

function LevelsController:KnitStart()
	self:_InitializeReferences()

	-- Get LevelService reference
	local levelService = Knit.GetService("LevelService")

	-- Initial state setup
	local playerData = self._stateController.GetData()
	self:_UpdateExpBar(
		playerData.Exp or 0,
		playerData.Level or 1,
		LevelConfig[playerData.Level] and LevelConfig[playerData.Level].RequiredExp
	)

	-- Connect to LevelService signals
	levelService.UpdatePlayerExp:Connect(function(updateData)
		self:_UpdateExpBar(updateData.Exp, updateData.Level, updateData.RequiredExp)
	end)
end

return LevelsController
