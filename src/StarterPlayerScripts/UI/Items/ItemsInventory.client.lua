--[[
    This script will handle all the logic for the players Item Inventory.
    Author: @Dan_iDev
    Date Created: 1/13/2024
    Date Modified: 1/13/2024
]]

-- Services
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Local Variables
local player = Players.LocalPlayer
local PlayersUI = player:WaitForChild("PlayerGui")
local InventoryScreen = PlayersUI:WaitForChild("Inventory")
local MainFrame = InventoryScreen:WaitForChild("Main")
local InventoryButtonsFrame = MainFrame:WaitForChild("MainButtons"):WaitForChild("ButtonHolder")
local InventoryFrames = {
	["Rods"] = MainFrame.FishingRods,
	["Fish"] = MainFrame.Fish,
	["Inventory"] = MainFrame.Inventory,
}
local closeButtons = {
	MainFrame.FishingRods:WaitForChild("CloseBtn"),
	MainFrame.Fish:WaitForChild("CloseBtn"),
	MainFrame.Inventory:WaitForChild("CloseBtn"),
}
local activeFrame = MainFrame.Fish

-- Functions
local function connectButtons()
	for _, button in ipairs(InventoryButtonsFrame:GetChildren()) do
		if button:IsA("ImageButton") and InventoryFrames[button.Name] then
			button.MouseButton1Click:Connect(function()
				print("Button clicked:", button.Name)
				local targetFrame = InventoryFrames[button.Name]

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

for _, button in ipairs(closeButtons) do
	button.MouseButton1Click:Connect(function()
		MainFrame.Visible = false
		activeFrame.Visible = false
		activeFrame = MainFrame.Fish
		activeFrame.Visible = true
	end)
end

function start()
	task.wait(3)
	connectButtons()
end

Knit:OnStart():andThen(start)
