--[[
    FishInventoryController
    Handles player fish inventory UI management including:
    - Inventory population and updates
    - Fish preview viewports
    - Rarity styling and search functionality
    
    Author: @Dan_iDev
    Version: 1.0
    Last Updated: 2024-01-22
    
    Design Notes:
    - Uses Knit MVC framework for Roblox
    - Optimized for dynamic inventory updates
    - Implements viewport-based 3D previews
    - Follows Roblox UI best practices
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--[[
    CONSTANTS
    Centralized configuration for easy maintenance
]]
local FISH_TEMPLATE_NAME = "UniversalTemplate"
local VIEWPORT_FISHES_NAME = "ViewportFishes"
local CAMERA_DISTANCE_MULTIPLIER = 0.8 -- Adjust based on model sizes
local INITIALIZATION_DELAY = 3 -- Seconds before first population

local RARITY_GRADIENTS = {
	Common = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)),
		}),
		Rotation = 0, -- Horizontal gradient
	},
	Rare = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 50, 150)),
		}),
		Rotation = 45, -- Diagonal gradient
	},
	Epic = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 150)),
		}),
		Rotation = -45, -- Inverse diagonal
	},
	Legendary = {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 160, 0)),
		}),
		Rotation = 0, -- Horizontal gold
	},
}
local SELECTED_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 0)),
})

-- Controller initialization
local FishInventoryController = Knit.CreateController({ Name = "FishInventoryController" })

--[[
    Private Methods
]]

function FishInventoryController:_InitializeReferences()
	-- Cache all UI references to minimize FindFirstChild calls
	-- Note: Using WaitForChild to ensure elements exist before access
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")
	self._inventoryScreen = self._playersUI:WaitForChild("Inventory")

	local MainFrame = self._inventoryScreen:WaitForChild("Main")
	local FishMainFrame = MainFrame:WaitForChild("Fish")
	local ScrollingFrameHolder = FishMainFrame:WaitForChild("ScrollingFrameHolder")

	-- Core UI components
	self._fishDetailsFrame = ScrollingFrameHolder:WaitForChild("FishDetails")
	self._fishDetails = self._fishDetailsFrame:WaitForChild("FishInfoText")
	self._fishesScrollingFrame = ScrollingFrameHolder:WaitForChild("IndexScrollingFrame")
	self._fishTemplate = ScrollingFrameHolder:WaitForChild(FISH_TEMPLATE_NAME)
	self._searchTextBox = FishMainFrame:WaitForChild("SearchBar"):WaitForChild("TextBox")

	-- State management
	self._currentTemplate = nil
	self._viewportFishes = ReplicatedStorage:FindFirstChild(VIEWPORT_FISHES_NAME)

	if not self._viewportFishes then
		warn("ViewportFishes container not found in workspace! Viewports will be disabled.")
	end
end

function FishInventoryController:_CreateViewportCamera(fishModel, viewportFrame)
	--[[
        Creates optimized camera setup for model preview
        Args:
            fishModel: The model to preview
            viewportFrame: Target ViewportFrame instance
        
        Design:
            - Camera positioned at 80% of largest model dimension
            - Ensures model remains fully visible
            - Uses PrimaryPart for positioning reference
    ]]
	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	if fishModel.PrimaryPart then
		local objectSize = fishModel.PrimaryPart.Size
		local cameraDistance = math.max(objectSize.X, objectSize.Y, objectSize.Z) * CAMERA_DISTANCE_MULTIPLIER

		camera.CFrame = CFrame.new(
			fishModel.PrimaryPart.Position + Vector3.new(0, 0, cameraDistance),
			fishModel.PrimaryPart.Position
		)
	else
		warn("Fish model missing PrimaryPart: " .. fishModel.Name)
	end

	return camera
end

function FishInventoryController:_SetupFishViewport(viewportFrame, fishName)
	--[[
        Creates 3D preview of fish model in specified ViewportFrame
        Safety Checks:
            - Verifies ViewportFishes container exists
            - Validates fish model exists
            - Clears previous viewport content
    ]]
	if not self._viewportFishes then
		return
	end

	local fishModel = self._viewportFishes:FindFirstChild(fishName)
	if not fishModel then
		warn("Fish model not found: " .. fishName)
		return
	end

	-- Clear previous viewport contents
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local clonedModel = fishModel:Clone()
	clonedModel.Parent = worldModel

	self:_CreateViewportCamera(clonedModel, viewportFrame)
end

function FishInventoryController:_ClearInventory()
	-- Efficiently removes all fish templates while preserving other children
	self._currentTemplate = nil
	for _, child in ipairs(self._fishesScrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == FISH_TEMPLATE_NAME then
			child:Destroy()
		end
	end
	self._fishDetails.FishName.Text = "Fish Name"
	self._fishDetails.Rarity.Text = "Common"
	self._fishDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCK"
	self._fishDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIP"
	local worldModel = self._fishDetailsFrame.Background.ViewportFrame:FindFirstChild("WorldModel")
	if worldModel then
		worldModel:Destroy()
	end
end

function FishInventoryController:_CreateFishTemplate(fishData)
	--[[
        Creates and configures a new inventory entry
        Template Lifecycle:
            1. Clone from hidden template
            2. Configure data bindings
            3. Set up interactive elements
            4. Add to scrolling frame
    ]]
	local template = self._fishTemplate:Clone()
	template.Parent = self._fishesScrollingFrame
	if fishData.locked == true then
		template.Locked.Visible = true
		template.IsLocked.Value = true
	else
		template.Locked.Visible = false
		template.IsLocked.Value = false
	end
	if fishData.equipped == true then
		template.EquippedCheckmark.Visible = true
		template.IsEquipped.Value = true
	else
		template.EquippedCheckmark.Visible = false
		template.IsEquipped.Value = false
	end
	template.Visible = true

	-- Data binding
	template.FishName.Text = fishData.fish
	template.FishID.Value = fishData.ID
	template.NumericValue.Text = tostring(fishData.weight) .. " KG"
	template.Rarity.Value = fishData.rarity

	-- Visual setup
	self:_SetupFishViewport(template.ViewportFrame, fishData.fish)
	self:_ApplyRarityStyle(template, fishData.rarity)

	-- Interaction setup
	template.Click.MouseButton1Click:Connect(function()
		if self._currentTemplate then
			self._currentTemplate.SelectionHighlight.Visible = false
		end

		self._currentTemplate = template

		self:_ShowFishDetails(template)
		template.SelectionHighlight.Visible = true
	end)

	return template
end

function FishInventoryController:_ApplyRarityStyle(template, rarity)
	-- Applies gradient styling based on fish rarity
	local gradient = template.Background.UIGradient
	local config = RARITY_GRADIENTS[rarity]

	if config then
		gradient.Color = config.Color
		gradient.Rotation = config.Rotation
	else
		warn("Missing rarity configuration: " .. tostring(rarity))
		-- Fallback to common styling
		gradient.Color = RARITY_GRADIENTS.Common.Color
		gradient.Rotation = RARITY_GRADIENTS.Common.Rotation
	end
end

function FishInventoryController:_ShowFishDetails(template)
	-- Updates detail panel with selected fish information
	self._fishDetails.FishName.Text = template.FishName.Text
	self._fishDetails.Rarity.Text = template.Rarity.Value
	if template.IsLocked.Value == true then
		self._fishDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCKED"
	else
		self._fishDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCK"
	end
	if template.IsEquipped.Value == true then
		self._fishDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIPPED"
	else
		self._fishDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIP"
	end
	-- Preview in detail viewport
	self:_SetupFishViewport(self._fishDetailsFrame.Background.ViewportFrame, template.FishName.Text)
end

function FishInventoryController:_UpdateFishVisibility(searchText)
	--[[
        Filters fish list based on search input
        Optimization:
            - Case-insensitive search
            - Uses string.find instead of match for partial matches
            - Processes all templates in single pass
    ]]
	local searchLower = string.lower(searchText)

	for _, child in ipairs(self._fishesScrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name == FISH_TEMPLATE_NAME then
			child.Visible = string.find(string.lower(child.FishName.Text), searchLower) ~= nil
		end
	end
end

function FishInventoryController:_HandleEquipFish()
	--[[
        Handles fish equipment logic
        Flow:
            1. Fire equip event to server
            2. Listen for confirmation
            3. Update UI checkmarks
            4. Clean up connection
    ]]
	local EquipService = Knit.GetService("EquipService")
	local fishName = self._fishDetails.FishName.Text
	local fishID = self._currentTemplate.FishID.Value
	print(self._currentTemplate.FishID.Value)
	EquipService.equipFish:Fire(fishName, fishID)

	-- Temporary connection for UI feedback
	connection = EquipService.equipFish:Connect(function()
		-- Clear all checkmarks
		for _, template in ipairs(self._fishesScrollingFrame:GetChildren()) do
			if template:IsA("Frame") and template.Name == FISH_TEMPLATE_NAME then
				template.EquippedCheckmark.Visible = false
				template.IsEquipped.Value = false
			end
		end
		local InventoryService = Knit.GetService("InventoryService")
		-- Set new checkmark
		self._currentTemplate.IsEquipped.Value = true
		if self._currentTemplate.IsEquipped.Value == true then
			InventoryService.SetEquippedState:Fire(self._currentTemplate.FishID.Value, true)
			self._fishDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIPPED"
		else
			self._fishDetailsFrame.ButtonHolder.Equip.BtnText.Text = "EQUIP"
		end

		if self._currentTemplate then
			self._currentTemplate.EquippedCheckmark.Visible = true
		end

		connection:Disconnect() -- Prevent memory leaks
	end)
end

--[[
    Knit Lifecycle Methods
    Entry points for framework-controlled execution
]]
function FishInventoryController:_PopulateInventory()
	--[[
        Main inventory refresh handler
        Data Flow:
            1. Get latest fish data from StateController
            2. Clear existing entries
            3. Create new templates
    ]]
	local StateController = Knit.GetController("StateController")
	local fishDataList = StateController.GetData().fishes
	print(fishDataList)
	self:_ClearInventory()

	for _, fishData in ipairs(fishDataList) do
		self:_CreateFishTemplate(fishData)
	end
end
function FishInventoryController:_PopulateInventoryAfterStarted(newFishes)
	local fishDataList = newFishes
	self:_ClearInventory()
	for _, fishData in ipairs(fishDataList) do
		self:_CreateFishTemplate(fishData)
	end
end

function FishInventoryController:KnitStart()
	-- Main initialization sequence
	self:_InitializeReferences()

	-- Initial population with safety delay
	task.wait(INITIALIZATION_DELAY)
	self:_PopulateInventory()

	-- Data update subscriptions
	local DataService = Knit.GetService("DataService")
	DataService.UpdateFishes:Connect(function(newFishes)
		print(newFishes)
		self:_PopulateInventoryAfterStarted(newFishes)
	end)

	-- UI event bindings
	self._searchTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_UpdateFishVisibility(self._searchTextBox.Text)
	end)

	local buttonHolder = self._fishDetailsFrame.ButtonHolder
	buttonHolder.Equip.MouseButton1Click:Connect(function()
		self:_HandleEquipFish()
	end)
	buttonHolder.Lock.MouseButton1Click:Connect(function()
		local InventoryService = Knit.GetService("InventoryService")
		if self._currentTemplate then
			self._currentTemplate.Locked.Visible = not self._currentTemplate.Locked.Visible
			self._currentTemplate.IsLocked.Value = not self._currentTemplate.IsLocked.Value
			if self._currentTemplate.IsLocked.Value == true then
				self._fishDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCKED"
				InventoryService.SetLockState:Fire(self._currentTemplate.FishID.Value, true)
			else
				self._fishDetailsFrame.ButtonHolder.Lock.BtnText.Text = "LOCK"
				InventoryService.SetLockState:Fire(self._currentTemplate.FishID.Value, false)
			end
		end
	end)
end

return FishInventoryController
