local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Controller initialization
local RodInventoryController = Knit.CreateController({ Name = "RodInventoryController" })

--[[
    Private Methods
]]
local lastEquippedFrame = nil
function RodInventoryController:_InitializeReferences()
	-- Cache all UI references to minimize FindFirstChild calls
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")
	self._inventoryScreen = self._playersUI:WaitForChild("Inventory")

	local MainFrame = self._inventoryScreen:WaitForChild("Main")
	local RodMainFrame = MainFrame:WaitForChild("FishingRods")
	local ScrollingFrameHolder = RodMainFrame:WaitForChild("ScrollingFrameHolder")
	self._ScrollingFrameMain = ScrollingFrameHolder:WaitForChild("ScrollingFrame")
	self._BasicRodFrame = self._ScrollingFrameMain:WaitForChild("BasicRod")
	self._ButtonScrollingFrame = RodMainFrame:WaitForChild("ScrollingFrame")
	self._RodInventorySortButtons = {
		Luck = self._ButtonScrollingFrame.LuckBtn,
		Control = self._ButtonScrollingFrame.ControlBtn,
		Best = self._ButtonScrollingFrame.BestBtn,
		LureSpeed = self._ButtonScrollingFrame.LureSpeedBtn,
		Power = self._ButtonScrollingFrame.PowerBtn,
	}
end

function RodInventoryController:_PopulateInventory()
	local StateController = Knit.GetController("StateController")
	local rodDataList = StateController.GetData()

	-- Map rod names to their corresponding UI frames
	local rodFrames = {
		BasicRod = self._BasicRodFrame,
	}

	for rodName, frame in pairs(rodFrames) do
		frame.Visible = rodDataList[rodName] or false
	end
	print(rodDataList.currentEquippedRod)
	if rodDataList.currentEquippedRod == "None" then
		for _, RodFrame in ipairs(self._ScrollingFrameMain:GetChildren()) do
			if RodFrame:IsA("Frame") then
				RodFrame.EquippedCheckmark.Visible = false
			end
		end
	else
		for _, RodFrame in ipairs(self._ScrollingFrameMain:GetChildren()) do
			if RodFrame:IsA("Frame") and RodFrame.Name == rodDataList.currentEquippedRod then
				RodFrame.EquippedCheckmark.Visible = true
				local EquipService = Knit.GetService("EquipService")
				EquipService.equipRod:Fire(RodFrame.Name)
				RodFrame.EquipBtn.BtnText.Text = "Equipped"
				if lastEquippedFrame then
					lastEquippedFrame.EquippedCheckmark.Visible = false
					lastEquippedFrame.EquipBtn.BtnText.Text = "Equip"
				end
				lastEquippedFrame = RodFrame
			end
		end
	end
	-- Set up Equip button connections for each rod frame.
	local connection
	for _, RodFrame in ipairs(self._ScrollingFrameMain:GetChildren()) do
		if RodFrame:IsA("Frame") then
			connection = RodFrame.EquipBtn.MouseButton1Click:Connect(function()
				local EquipService = Knit.GetService("EquipService")
				EquipService.equipRod:Fire(RodFrame.Name)
				RodFrame.EquippedCheckmark.Visible = true
				RodFrame.EquipBtn.BtnText.Text = "Equipped"
				if lastEquippedFrame then
					lastEquippedFrame.EquippedCheckmark.Visible = false
					lastEquippedFrame.EquipBtn.BtnText.Text = "Equip"
				end
				lastEquippedFrame = RodFrame
				connection:Disconnect()
			end)
		end
	end
end

-- New function: Set up event listeners on the sort buttons.
function RodInventoryController:_SetupSortButtons()
	for stat, button in pairs(self._RodInventorySortButtons) do
		button.MouseButton1Click:Connect(function()
			self:SortRodsByStat(stat)
		end)
	end
end

-- New function: Sort rod frames based on the selected stat.
-- For "Best", we sum all stats; otherwise, we sort based on the individual stat.
function RodInventoryController:SortRodsByStat(stat)
	local rodFrames = {}
	for _, rodFrame in ipairs(self._ScrollingFrameMain:GetChildren()) do
		if rodFrame:IsA("Frame") and rodFrame:FindFirstChild("RodValues") then
			table.insert(rodFrames, rodFrame)
		end
	end

	table.sort(rodFrames, function(a, b)
		local aValues = a.RodValues
		local bValues = b.RodValues

		local aStat, bStat = 0, 0

		if stat == "Best" then
			aStat = (aValues:FindFirstChild("Control") and aValues.Control.Value or 0)
				+ (aValues:FindFirstChild("Luck") and aValues.Luck.Value or 0)
				+ (aValues:FindFirstChild("LureSpeed") and aValues.LureSpeed.Value or 0)
				+ (aValues:FindFirstChild("Power") and aValues.Power.Value or 0)
			bStat = (bValues:FindFirstChild("Control") and bValues.Control.Value or 0)
				+ (bValues:FindFirstChild("Luck") and bValues.Luck.Value or 0)
				+ (bValues:FindFirstChild("LureSpeed") and bValues.LureSpeed.Value or 0)
				+ (bValues:FindFirstChild("Power") and bValues.Power.Value or 0)
		else
			aStat = aValues:FindFirstChild(stat) and aValues[stat].Value or 0
			bStat = bValues:FindFirstChild(stat) and bValues[stat].Value or 0
		end

		-- Sort descending (higher stat gets a lower LayoutOrder value).
		return aStat > bStat
	end)

	-- Assign LayoutOrder according to sorted order.
	for i, rodFrame in ipairs(rodFrames) do
		rodFrame.LayoutOrder = i
	end
end

function RodInventoryController:KnitStart()
	-- Main initialization sequence
	self:_InitializeReferences()
	task.wait(5)
	self:_PopulateInventory()
	self:_SetupSortButtons()

	local DataService = Knit.GetService("DataService")
	DataService.UpdateFishes:Connect(function()
		task.wait(5)
		self:_PopulateInventory()
	end)
end

return RodInventoryController
