--[[
    CurrencyController
    Handles player currency HUD management including:
    - Currency Management on Client
    
    Author: @Dan_iDev
    Version: 2.1
    Last Updated: 2024-01-29
    
    Updates:
    - Added currency gain tween effects
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RunService = game:GetService("RunService")
local CurrencyController = Knit.CreateController({
	Name = "CurrencyController",
})

-- Helper function for safe UI element retrieval
local function getGuiElement(parent, ...)
	local element = parent
	for _, childName in ipairs({ ... }) do
		element = element:WaitForChild(childName)
		if not element then
			warn("Missing UI element:", childName)
			return nil
		end
	end
	return element
end

-- UI Element References
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local currencyFrame = getGuiElement(playerGui, "PlayerHUD", "Main", "Currency")
local coinsText = getGuiElement(currencyFrame, "Coins", "CurrencyAmount")
local starsText = getGuiElement(currencyFrame, "Stars", "CurrencyAmount")
local coinsIconForTweening = getGuiElement(playerGui, "PlayerHUD", "Main", "CoinsIconForTweens")
local coinsFullImage = getGuiElement(currencyFrame, "Coins")
local starsIconForTweening = getGuiElement(playerGui, "PlayerHUD", "Main", "StarsIconForTweens")
local starsFullImage = getGuiElement(currencyFrame, "Stars")
local COUNT_UP_DURATION = 1.5
local ICON_SCALE_INTENSITY = 1.2
local ICON_SCALE_TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Controller References
local StateController
local DataService

-- Formatting configuration
local CURRENCY_UPDATE_DEBOUNCE = 0.1
local NUMBER_FORMAT = "COMMAS"
local function getRandomPosition(Image)
	local frameWidth = currencyFrame.Parent.AbsoluteSize.X
	local frameHeight = currencyFrame.Parent.AbsoluteSize.Y

	local middleAreaWidth = frameWidth / 2
	local middleAreaHeight = frameHeight / 2

	local middleAreaX = currencyFrame.Parent.AbsolutePosition.X + (frameWidth - middleAreaWidth) / 2
	local middleAreaY = currencyFrame.Parent.AbsolutePosition.Y + (frameHeight - middleAreaHeight) / 2

	local randomX = middleAreaX + math.random(0, middleAreaWidth - Image.AbsoluteSize.X)
	local randomY = middleAreaY + math.random(0, middleAreaHeight - Image.AbsoluteSize.Y)

	return UDim2.new(0, randomX, 0, randomY)
end

function CurrencyController:PlayStarTween(gainedAmount)
	-- Clone the tween template for stars
	local clone = starsIconForTweening:Clone()
	clone.Parent = starsIconForTweening.Parent
	clone.Visible = true

	-- Set up text display
	local amountLabel = clone:FindFirstChild("CurrencyAmount")
	if amountLabel then
		amountLabel.Text = "+" .. self:FormatCurrency(gainedAmount)
	end

	-- Calculate positions: using starsText here
	local mainFrame = playerGui.PlayerHUD.Main
	local targetPosition = UDim2.new(
		starsText.AbsolutePosition.X / mainFrame.AbsoluteSize.X,
		0,
		starsText.AbsolutePosition.Y / mainFrame.AbsoluteSize.Y,
		0
	)

	-- Initial setup
	clone.Position = getRandomPosition(clone)
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.new(0, 100, 0, 100)
	clone.ImageTransparency = 0

	if amountLabel then
		amountLabel.TextTransparency = 0
	end

	-- Create tweens
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenGoals = {
		Position = targetPosition,
		Size = UDim2.new(0, 20, 0, 20),
		ImageTransparency = 1,
	}
	local tween = TweenService:Create(clone, tweenInfo, tweenGoals)
	tween:Play()

	-- Cleanup after tween
	tween.Completed:Connect(function()
		clone:Destroy()
	end)
end

-- Function to animate the star icon scaling
function CurrencyController:AnimateStarIconScale()
	-- Store original size
	local baseSize = starsFullImage.Size
	local scaleFactor = ICON_SCALE_INTENSITY

	-- Calculate scaled size using UDim2.new()
	local scaledSize = UDim2.new(
		baseSize.X.Scale * scaleFactor,
		baseSize.X.Offset * scaleFactor,
		baseSize.Y.Scale * scaleFactor,
		baseSize.Y.Offset * scaleFactor
	)

	-- Cancel any existing star scale tween
	if self.currentScaleTweenStars then
		self.currentScaleTweenStars:Cancel()
	end

	-- Create scale animation for stars
	self.currentScaleTweenStars = TweenService:Create(starsFullImage, ICON_SCALE_TWEEN_INFO, {
		Size = scaledSize,
	})

	-- Chain the scale back animation
	self.currentScaleTweenStars.Completed:Once(function()
		local scaleBackTween = TweenService:Create(starsFullImage, ICON_SCALE_TWEEN_INFO, {
			Size = baseSize,
		})
		scaleBackTween:Play()
	end)

	self.currentScaleTweenStars:Play()
end

function CurrencyController:PlayCoinTween(gainedAmount)
	-- Clone the tween template
	local clone = coinsIconForTweening:Clone()
	clone.Parent = coinsIconForTweening.Parent
	clone.Visible = true

	-- Set up text display
	local amountLabel = clone:FindFirstChild("CurrencyAmount")
	if amountLabel then
		amountLabel.Text = "+" .. self:FormatCurrency(gainedAmount)
	end

	-- Calculate positions
	local mainFrame = playerGui.PlayerHUD.Main
	local targetPosition = UDim2.new(
		coinsText.AbsolutePosition.X / mainFrame.AbsoluteSize.X,
		0,
		coinsText.AbsolutePosition.Y / mainFrame.AbsoluteSize.Y,
		0
	)

	-- Initial setup
	clone.Position = getRandomPosition(clone)
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.new(0, 100, 0, 100)
	clone.ImageTransparency = 0

	if amountLabel then
		amountLabel.TextTransparency = 0
	end

	-- Create tweens
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local tweenGoals = {
		Position = targetPosition,
		Size = UDim2.new(0, 20, 0, 20),
		ImageTransparency = 1,
	}

	local tween = TweenService:Create(clone, tweenInfo, tweenGoals)
	tween:Play()

	-- Cleanup after tween
	tween.Completed:Connect(function()
		clone:Destroy()
	end)
end

function CurrencyController:AnimateIconScale()
	-- Store original size
	local baseSize = coinsFullImage.Size
	local scaleFactor = ICON_SCALE_INTENSITY

	-- Calculate scaled size using UDim2.new()
	local scaledSize = UDim2.new(
		baseSize.X.Scale * scaleFactor,
		baseSize.X.Offset * scaleFactor,
		baseSize.Y.Scale * scaleFactor,
		baseSize.Y.Offset * scaleFactor
	)

	-- Cancel any existing scale tweens
	if self.currentScaleTween then
		self.currentScaleTween:Cancel()
	end

	-- Create scale animation
	self.currentScaleTween = TweenService:Create(coinsFullImage, ICON_SCALE_TWEEN_INFO, {
		Size = scaledSize,
	})

	-- Chain the scale back animation
	self.currentScaleTween.Completed:Once(function()
		local scaleBackTween = TweenService:Create(coinsFullImage, ICON_SCALE_TWEEN_INFO, {
			Size = baseSize,
		})
		scaleBackTween:Play()
	end)

	self.currentScaleTween:Play()
end

function CurrencyController:AnimateCountUp(textElement, startValue, endValue)
	local duration = math.min(COUNT_UP_DURATION, math.abs(endValue - startValue) * 0.01)
	local startTime = os.clock()
	local originalColor = textElement.TextColor3 -- Store original color

	-- Immediately update to final value if difference is small
	if math.abs(endValue - startValue) < 10 then
		textElement.Text = self:FormatCurrency(endValue)
		return
	end

	-- Create animation loop
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local progress = math.min(elapsed / duration, 1)
		local currentValue = math.floor(startValue + (endValue - startValue) * progress)

		-- Update text and color
		textElement.Text = self:FormatCurrency(currentValue)

		-- Color interpolation from red to original
		textElement.TextColor3 = Color3.new(1, 0, 0)

		if progress >= 1 then
			connection:Disconnect()
			textElement.TextColor3 = originalColor
		end
	end)
end

function CurrencyController:FormatCurrency(amount)
	if NUMBER_FORMAT == "COMMAS" then
		return tostring(amount):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
	elseif NUMBER_FORMAT == "ABBREVIATED" then
		local suffixes = { "", "k", "M", "B" }
		local i = 1
		while amount >= 1000 and i < #suffixes do
			amount = amount / 1000
			i += 1
		end
		return string.format("%.1f%s", amount, suffixes[i])
	end
	return tostring(amount)
end

function CurrencyController:UpdateCurrency(currencyType)
	if not self._lastUpdate then
		self._lastUpdate = {}
	end
	local now = os.clock()

	-- Debounce check
	if (self._lastUpdate[currencyType] or 0) + CURRENCY_UPDATE_DEBOUNCE > now then
		return
	end
	self._lastUpdate[currencyType] = now

	-- Controller safety check
	if not StateController or not StateController.GetData then
		warn("StateController not initialized properly")
		return
	end

	-- Get player data with validation
	local playerData = StateController.GetData()
	if not playerData or type(playerData) ~= "table" then
		warn("Player data not available")
		return
	end

	local newAmount = tonumber(playerData[currencyType])
	if not newAmount then
		warn("Invalid currency type:", currencyType)
		return
	end

	-- Get previous amount with fallback
	local lastAmount = self._lastAmounts[currencyType] or 0
	local textElement = currencyType == "Coins" and coinsText or starsText

	-- Validate text element
	if not textElement or not textElement:IsA("TextLabel") then
		warn("Invalid text element for currency:", currencyType)
		return
	end

	-- Update leaderstats immediately
	player.leaderstats:FindFirstChild(currencyType).Value = newAmount

	-- Handle currency changes
	local isGain = newAmount > lastAmount
	local changed = newAmount ~= lastAmount

	if changed then
		if isGain then
			if currencyType == "Coins" then
				local gainedAmount = newAmount - lastAmount
				self:PlayCoinTween(gainedAmount)
				self:AnimateCountUp(textElement, lastAmount, newAmount)
				self:AnimateIconScale()
			elseif currencyType == "Stars" then
				local gainedAmount = newAmount - lastAmount
				self:PlayStarTween(gainedAmount)
				self:AnimateCountUp(textElement, lastAmount, newAmount)
				self:AnimateStarIconScale()
			end
		else
			-- Immediate update for losses
			textElement.Text = self:FormatCurrency(newAmount)
		end

		self._lastAmounts[currencyType] = newAmount
	end
end

function CurrencyController:UpdateCoins()
	self:UpdateCurrency("Coins")
end

function CurrencyController:UpdateStars()
	self:UpdateCurrency("Stars")
end

function CurrencyController:KnitStart()
	StateController = Knit.GetController("StateController")

	-- Wait for data to be available
	repeat
		task.wait()
	until StateController.GetData() ~= nil

	-- Initialize last amounts with proper type validation
	local initialData = StateController.GetData()
	self._lastAmounts = {
		Coins = tonumber(initialData.Coins) or 0,
		Stars = tonumber(initialData.Stars) or 0,
	}

	-- Initial UI update without animation
	coinsText.Text = self:FormatCurrency(self._lastAmounts.Coins)
	starsText.Text = self:FormatCurrency(self._lastAmounts.Stars)

	-- Regular updates
	while task.wait(0.5) do
		self:UpdateCoins()
		self:UpdateStars()
	end
end

function CurrencyController:KnitDestroy()
	-- Clean up connections
	if self._connections then
		for _, connection in ipairs(self._connections) do
			connection:Disconnect()
		end
		self._connections = nil
	end
end

return CurrencyController
