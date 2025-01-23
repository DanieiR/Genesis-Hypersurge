--[[
    UI Buttons with Loading Safeguards
    Author: @Dan_iDev
    Version: 1.0.1
]]

-- Services
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")

-- Enhanced UI waiting function
local function waitForUIElement(parent, childName, timeout)
	timeout = timeout or 5 -- Default 5 second timeout
	local element = parent:FindFirstChild(childName)

	if not element then
		local startTime = os.clock()
		repeat
			task.wait()
			element = parent:FindFirstChild(childName)
		until element or (os.clock() - startTime) > timeout
	end

	if not element then
		warn("UI element not found:", parent:GetFullName() .. "/" .. childName)
	end

	return element
end

-- Initialize UI with proper waiting
local function initializeUI()
	local player = Players.LocalPlayer
	local PlayersUI = player:WaitForChild("PlayerGui")

	-- Wait for core HUD elements
	local HUDScreen = waitForUIElement(PlayersUI, "PlayerHUD")
	local MainFrame = waitForUIElement(HUDScreen, "Main")
	local ButtonsFrame = waitForUIElement(MainFrame, "Buttons")

	-- Wait for individual frames
	local FramesTable = {
		["Items"] = waitForUIElement(waitForUIElement(PlayersUI, "Inventory"), "Main"),
		["Index"] = waitForUIElement(waitForUIElement(PlayersUI, "Index"), "Main"),
		["Units"] = waitForUIElement(waitForUIElement(PlayersUI, "Units"), "Main"),
		["Shop"] = waitForUIElement(waitForUIElement(PlayersUI, "RobuxShop"), "Main"),
		["Settings"] = waitForUIElement(waitForUIElement(PlayersUI, "Settings"), "Main"),
		["Summon"] = waitForUIElement(waitForUIElement(PlayersUI, "Summon"), "Main"),
	}

	return ButtonsFrame, FramesTable
end

local function connectButtons(ButtonsFrame, FramesTable)
	for _, button in ipairs(ButtonsFrame:GetChildren()) do
		if button:IsA("ImageButton") and FramesTable[button.Name] then
			button.MouseButton1Click:Connect(function()
				local targetFrame = FramesTable[button.Name]

				if activeFrame and activeFrame ~= targetFrame then
					activeFrame.Visible = false
					activeFrame = nil
				end

				targetFrame.Visible = not targetFrame.Visible
				activeFrame = targetFrame.Visible and targetFrame or nil
			end)
		end
	end
end

function start()
	local success, ButtonsFrame, FramesTable = pcall(initializeUI)
	if success then
		connectButtons(ButtonsFrame, FramesTable)
	else
		warn("Failed to initialize UI elements")
	end
end

Knit:OnStart():andThen(function()
	task.wait(1)
	start()
end)
