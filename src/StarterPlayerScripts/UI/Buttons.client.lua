--[[
    This script will handle all the button connections for the UI elements.
    Author: @Dan_iDev
    Date Created: 1/6/2024
    Date Modified: 1/6/2024
]]

-- Services
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Local Variables
local player = Players.LocalPlayer
local PlayersUI = player:WaitForChild("PlayerGui")
local HUDScreen = PlayersUI:WaitForChild("PlayerHUD")
local MainFrame = HUDScreen:WaitForChild("Main")
local ButtonsFrame = MainFrame:WaitForChild("Buttons")
local FramesTable = {
	["Items"] = PlayersUI.Inventory.Main,
	["Index"] = PlayersUI.Index.Main,
	["Units"] = PlayersUI.Units.Main,
	["Shop"] = PlayersUI.RobuxShop.Main,
	["Settings"] = PlayersUI.Settings.Main,
	["Summon"] = PlayersUI.Summon.Main,
}
local activeFrame = nil

-- Functions

local function connectButtons()
	-- Connect the buttons
	for _, button in ipairs(ButtonsFrame:GetChildren()) do
		if button:IsA("ImageButton") and FramesTable[button.Name] then
			button.MouseButton1Click:Connect(function()
				print("Button clicked:", button.Name)
				local targetFrame = FramesTable[button.Name]

				-- If a frame is currently visible and it's not the one we clicked
				if activeFrame and activeFrame ~= targetFrame then
					activeFrame.Visible = false -- Hide the currently active frame
					activeFrame = nil
				end

				-- Toggle visibility of the target frame
				if targetFrame.Visible then
					targetFrame.Visible = false
					activeFrame = nil
				else
					targetFrame.Visible = true
					activeFrame = targetFrame
				end
			end)
		end
	end
end

function start()
	task.wait(3)
	connectButtons()
end

Knit:OnStart():andThen(start)
