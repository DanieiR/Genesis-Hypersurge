local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Controller initialization
local UnitInventoryController = Knit.CreateController({ Name = "UnitInventoryController" })

--[[
    Private Methods
]]
local UNIT_TEMPLATE_NAME = "UniversalTemplate"
function UnitInventoryController:_InitializeReferences()
	-- Cache all UI references to minimize FindFirstChild calls
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")
	self._inventoryScreen = self._playersUI:WaitForChild("Units")

	local MainFrame = self._inventoryScreen:WaitForChild("Main")
	local UnitsMainFrame = MainFrame:WaitForChild("Units")
	local ScrollingFrameHolder = UnitsMainFrame:WaitForChild("ScrollingFrameHolder")
	self._ScrollingFrameMain = ScrollingFrameHolder:WaitForChild("IndexScrollingFrame")
	self._UnitDetailsFrame = ScrollingFrameHolder:WaitForChild("FishDetails")
	self._viewportUnits = ReplicatedStorage:WaitForChild("SummonViewports")
	self._unitTemplate = ScrollingFrameHolder:WaitForChild(UNIT_TEMPLATE_NAME)
	self._currentTemplate = nil
	self._sellModeButton = UnitsMainFrame:WaitForChild("SellModeBtn")
	self._IsSellModeActive = false
	self._SellButton = UnitsMainFrame:WaitForChild("SellBtn")
	self._CancelButton = UnitsMainFrame:WaitForChild("CancelBtn")
	self._CurrentSellingUnits = {}
	self._AllCurrentUnits = {}
	self._ConfirmationUI = self._playersUI.Confirmations.Main.SellConfirmation
	self._SellText = self._ConfirmationUI.SellText
	self._SellNotificationText = UnitsMainFrame:WaitForChild("SellNotification")
	self._connections = {} -- Table to store connections
	self._ButtonHolder = self._UnitDetailsFrame:WaitForChild("ButtonHolder")
end
function UnitInventoryController:_CreateViewportCamera(unitModel, viewportFrame)
	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	if unitModel.Head then
		local objectSize = unitModel.Head.Size
		local cameraDistance = math.max(objectSize.X, objectSize.Y, objectSize.Z) * 1.2

		local lookVector = unitModel.Head.CFrame.LookVector

		local cameraPosition = unitModel.Head.Position + lookVector * cameraDistance

		camera.CFrame = CFrame.new(cameraPosition, unitModel.Head.Position)
	end

	return camera
end

function UnitInventoryController:_SetupUnitViewport(viewportFrame, unitName)
	if not self._viewportUnits then
		return
	end

	local UnitModel = self._viewportUnits:FindFirstChild(unitName)
	if not UnitModel then
		warn("Unit model not found: " .. unitName)
		return
	end

	-- Clear previous viewport contents
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local clonedModel = UnitModel:Clone()
	clonedModel.Parent = worldModel

	self:_CreateViewportCamera(clonedModel, viewportFrame)
end
function UnitInventoryController:_ShowUnitDetails(template)
	-- Updates detail panel with selected fish information
	self._UnitDetailsFrame.FishInfoText.FishName.Text = template.FishName.Text
	self._UnitDetailsFrame.FishInfoText.Rarity.Text = template.Rarity.Value
	if template.IsLocked.Value == true then
		self._UnitDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCKED"
	else
		self._UnitDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCK"
	end
	if template.IsEquipped.Value == true then
		self._UnitDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIPPED"
	else
		self._UnitDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIP"
	end
	-- Preview in detail viewport
	self:_SetupUnitViewport(self._UnitDetailsFrame.Background.ViewportFrame, template.FishName.Text)
end

function UnitInventoryController:_CreateUnitTemplate(unitData)
	local template = self._unitTemplate:Clone()
	template.Parent = self._ScrollingFrameMain
	--[[
	if unitData.locked == true then
		template.Locked.Visible = true
		template.IsLocked.Value = true
	else
		template.Locked.Visible = false
		template.IsLocked.Value = false
	end
	if unitData.equipped == true then
		template.EquippedCheckmark.Visible = true
		template.IsEquipped.Value = true
	else
		template.EquippedCheckmark.Visible = false
		template.IsEquipped.Value = false
	end]]
	--
	template.Visible = true

	-- Data binding
	template.FishName.Text = unitData.Name
	template.FishID.Value = unitData.ID
	template.Rarity.Value = unitData.Rarity

	-- Visual setup
	self:_SetupUnitViewport(template.ViewportFrame, unitData.Name)

	template.Click.MouseButton1Click:Connect(function()
		if not self._IsSellModeActive then
			if self._currentTemplate then
				self._currentTemplate.SelectionHighlight.Visible = false
			end
			self._currentTemplate = template
			self:_ShowUnitDetails(template)
			template.SelectionHighlight.Visible = true
		else
			-- Sell mode active:
			-- Toggle the SellMode visibility
			template.SellMode.Visible = not template.SellMode.Visible
			local sellableUnit = {}
			for _, child in ipairs(self._ScrollingFrameMain:GetChildren()) do
				if child:IsA("Frame") and child.Name == UNIT_TEMPLATE_NAME then
					if child.SellMode.Visible then
						local UnitID = child.FishID.Value
						for _, Unit in ipairs(self._AllCurrentUnits) do
							if Unit.ID == UnitID then
								table.insert(sellableUnit, Unit)
								break
							end
						end
					end
				end
			end
			self._CurrentSellingUnits = sellableUnit
			print(self._CurrentSellingUnits)
			-- Calculate and update the total sell value.
			local totalValue = 0
			for _, Unit in ipairs(self._CurrentSellingUnits) do
				totalValue = totalValue + Unit.SellPrice
			end
			self._SellButton.CurrencyAmountText.Text = tostring(totalValue) .. "$"
		end
	end)

	return template
end

function UnitInventoryController:_ClearInventory()
	for _, child in ipairs(self._ScrollingFrameMain:GetChildren()) do
		if child:IsA("Frame") and child.Name == UNIT_TEMPLATE_NAME then
			child:Destroy()
		end
	end
	self._UnitDetailsFrame.FishInfoText.FishName.Text = "Unit Name"
	self._UnitDetailsFrame.FishInfoText.Rarity.Text = "Common"
	self._UnitDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCK"
	self._UnitDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIP"
	local worldModel = self._UnitDetailsFrame.Background.ViewportFrame:FindFirstChild("WorldModel")
	if worldModel then
		worldModel:Destroy()
	end
end
function UnitInventoryController:_PopulateInventory()
	local StateController = Knit.GetController("StateController")
	local unitDataList = StateController.GetData().units
	self._AllCurrentUnits = unitDataList
	print(unitDataList)
	self:_ClearInventory()

	for _, unitData in ipairs(unitDataList) do
		self:_CreateUnitTemplate(unitData)
	end
end
function UnitInventoryController:_PopulateInventoryAfterStarted(newUnits)
	local UnitDataList = newUnits
	self._AllCurrentUnits = UnitDataList
	self:_ClearInventory()
	for _, fishData in ipairs(UnitDataList) do
		self:_CreateUnitTemplate(fishData)
	end
end
function UnitInventoryController:_setAllSellModes(isVisible)
	for _, child in ipairs(self._ScrollingFrameMain:GetChildren()) do
		if child:IsA("Frame") and child.Name == UNIT_TEMPLATE_NAME then
			child.SellMode.Visible = isVisible
		end
	end
end
function UnitInventoryController:_calculateTotalSellValue(unitList)
	local total = 0
	for _, Unit in ipairs(unitList) do
		total = total + Unit.SellPrice
	end
	return total
end

function UnitInventoryController:_activateSellMode()
	self._IsSellModeActive = true
	self._SellButton.Visible = true
	self._CancelButton.Visible = true
	self:_setAllSellModes(true)
	local sellableUnit = {}
	for _, child in ipairs(self._ScrollingFrameMain:GetChildren()) do
		if child:IsA("Frame") and child.Name == UNIT_TEMPLATE_NAME then
			local UnitID = child.FishID.Value
			for _, Unit in ipairs(self._AllCurrentUnits) do
				if Unit.ID == UnitID then
					table.insert(sellableUnit, Unit)
					break
				end
			end
		end
	end
	self._CurrentSellingUnits = sellableUnit
	local totalValue = self:_calculateTotalSellValue(self._AllCurrentUnits)
	self._SellButton.CurrencyAmountText.Text = tostring(totalValue) .. "$"
end

function UnitInventoryController:_deactivateSellMode()
	self._IsSellModeActive = false
	self._SellButton.Visible = false
	self._CancelButton.Visible = false
	local totalValue = self:_calculateTotalSellValue(self._AllCurrentUnits)
	self._SellButton.CurrencyAmountText.Text = tostring(totalValue) .. "$"
	self:_setAllSellModes(false)
end
function UnitInventoryController:_setupConfirmationHandlers()
	if self._confirmationHandlers then
		for _, conn in ipairs(self._confirmationHandlers) do
			conn:Disconnect()
		end
	end
	self._confirmationHandlers = {}

	local sellConn = self._ConfirmationUI.Buttons.Sell.MouseButton1Click:Connect(function()
		self._ConfirmationUI.Visible = false
		local SellService = Knit.GetService("SellingService")
		print(self._CurrentSellingUnits)
		SellService.SellUnitsFromSellMode:Fire(self._CurrentSellingUnits)
		local totalValue = self:_calculateTotalSellValue(self._CurrentSellingUnits)
		self._SellNotificationText.Text = "Sold (x"
			.. #self._CurrentSellingUnits
			.. ") Units For "
			.. totalValue
			.. " Gold!"
		self._SellNotificationText.Visible = true
		task.wait(1)
		self._SellNotificationText.Visible = false
		self:_deactivateSellMode()
		self._currentTemplate = nil
	end)
	table.insert(self._confirmationHandlers, sellConn)

	local cancelConn = self._ConfirmationUI.Buttons.Cancel.MouseButton1Click:Connect(function()
		self._ConfirmationUI.Visible = false
		self:_deactivateSellMode()
	end)
	table.insert(self._confirmationHandlers, cancelConn)
end

function UnitInventoryController:_setupSellButtonHandler()
	if self._sellButtonConn then
		self._sellButtonConn:Disconnect()
	end
	self._sellButtonConn = self._SellButton.MouseButton1Click:Connect(function()
		local totalValue = self:_calculateTotalSellValue(self._CurrentSellingUnits)
		self._ConfirmationUI.Visible = true
		self._SellText.Text = "Sell " .. #self._CurrentSellingUnits .. " units for " .. totalValue .. " Gold?"
		self:_setupConfirmationHandlers()
	end)
	table.insert(self._connections, self._sellButtonConn)
end

-- Sets up the cancel button event handler.
function UnitInventoryController:_setupCancelButtonHandler()
	self._CancelButton.MouseButton1Click:Connect(function()
		self:_deactivateSellMode()
	end)
end

function UnitInventoryController:_handleSellMode()
	print("Initiate Sell Mode..")

	if not self._IsSellModeActive then
		self:_activateSellMode()
	else
		self:_deactivateSellMode()
	end

	self:_setupSellButtonHandler()
	self:_setupCancelButtonHandler()
end

function UnitInventoryController:_handleEquip()
	local EquipService = Knit.GetService("EquipService")
	print(self._UnitDetailsFrame.FishInfoText.FishName.Text)
	EquipService.equipUnit:Fire(self._currentTemplate.FishID.Value, self._UnitDetailsFrame.FishInfoText.FishName.Text)
	connection = EquipService.equipUnit:Connect(function()
		for _, template in ipairs(self._ScrollingFrameMain:GetChildren()) do
			if template:IsA("Frame") and template.Name == UNIT_TEMPLATE_NAME then
				template.EquippedCheckmark.Visible = false
				template.IsEquipped.Value = false
			end
		end
		-- Set new checkmark
		self._currentTemplate.IsEquipped.Value = true
		if self._currentTemplate.IsEquipped.Value == true then
			self._UnitDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIPPED"
		else
			self._UnitDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIP"
		end

		if self._currentTemplate then
			self._currentTemplate.EquippedCheckmark.Visible = true
		end

		connection:Disconnect()
	end)
end

function UnitInventoryController:KnitStart()
	-- Main initialization sequence
	self:_InitializeReferences()
	task.wait(5)
	self:_PopulateInventory()
	local DataService = Knit.GetService("DataService")
	DataService.UpdateUnits:Connect(function(newUnits)
		self:_PopulateInventoryAfterStarted(newUnits)
	end)
	self._sellModeButton.MouseButton1Click:Connect(function()
		self:_handleSellMode()
	end)
	self._ButtonHolder.Equip.MouseButton1Click:Connect(function()
		self:_handleEquip()
	end)
end

return UnitInventoryController
