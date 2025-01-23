--[[
    CurrencyController
    Handles player currency HUD management including:
    - Currency Management on Client
    
    Author: @Dan_iDev
    Version: 2.0
    Last Updated: 2024-01-24
    
    Design Notes:
    - Uses Knit MVC framework for Roblox
    - Implements safety checks and performance optimizations
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")

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

-- Controller References
local StateController
local DataService

-- Formatting configuration
local CURRENCY_UPDATE_DEBOUNCE = 0.1
local NUMBER_FORMAT = "COMMAS"

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

	-- Debounce rapid updates
	if (self._lastUpdate[currencyType] or 0) + CURRENCY_UPDATE_DEBOUNCE > now then
		return
	end
	self._lastUpdate[currencyType] = now

	-- Safety checks
	if not StateController or not StateController.GetData then
		warn("StateController not initialized properly")
		return
	end

	local playerData = StateController.GetData()
	if not playerData then
		warn("Player data not available")
		return
	end

	local newAmount = playerData[currencyType]
	if not newAmount then
		warn("Invalid currency type:", currencyType)
		return
	end

	-- Update appropriate text element
	local textElement = currencyType == "Coins" and coinsText or starsText
	if textElement and textElement:IsA("TextLabel") then
		textElement.Text = self:FormatCurrency(newAmount)
	else
		warn("Invalid text element for currency:", currencyType)
	end
end

-- Maintain individual methods for direct access if needed
function CurrencyController:UpdateCoins()
	self:UpdateCurrency("Coins")
end

function CurrencyController:UpdateStars()
	self:UpdateCurrency("Stars")
end

function CurrencyController:KnitStart()
	-- Get controller references
	StateController = Knit.GetController("StateController")
	DataService = Knit.GetService("DataService")

	task.wait(2)

	-- Initial update
	self:UpdateCoins()
	self:UpdateStars()

	-- Set up event connections
	local currencyEvents = {
		Coins = DataService.UpdateCoins,
		Stars = DataService.UpdateStars,
	}

	self._connections = {}
	for currencyType, event in pairs(currencyEvents) do
		local connection = event:Connect(function()
			self:UpdateCurrency(currencyType)
		end)
		table.insert(self._connections, connection)
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
