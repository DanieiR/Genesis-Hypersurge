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

-- Modified button connection with frame persistence
local function connectButtons()
	for _, button in ipairs(InventoryButtonsFrame:GetChildren()) do
		if button:IsA("ImageButton") and InventoryFrames[button.Name] then
			button.MouseButton1Click:Connect(function()
				local targetFrame = InventoryFrames[button.Name]

				-- Only switch if clicking different button
				if activeFrame ~= targetFrame then
					-- Hide current frame
					if activeFrame then
						activeFrame.Visible = false
					end

					-- Show new frame
					targetFrame.Visible = true
					activeFrame = targetFrame
				end
			end)
		end
	end
end

-- Close button handling (optional - remove if not needed)
for _, button in ipairs(closeButtons) do
	button.MouseButton1Click:Connect(function()
		-- Keep at least one frame visible
		if activeFrame then
			activeFrame.Visible = false
			-- Default to Fish frame when closing
			activeFrame = MainFrame.Fish
			activeFrame.Visible = true
		end
	end)
end

function start()
	task.wait(3)
	connectButtons()

	-- Initialize with default frame
	for _, frame in pairs(InventoryFrames) do
		frame.Visible = (frame == activeFrame)
	end
end

Knit:OnStart():andThen(start)
