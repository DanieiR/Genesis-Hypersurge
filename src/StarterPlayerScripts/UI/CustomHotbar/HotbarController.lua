local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local HotbarController = Knit.CreateController({ Name = "HotbarController" })

-- Constants
local MAX_SLOTS = 5 -- Always show 5 slots regardless of tool count

------------------------------------------------------------
-- Utility: Create a viewport preview for a tool in a slot.
------------------------------------------------------------
function HotbarController:_UpdateSlotViewport(slot, tool)
	local viewport = slot:FindFirstChild("ViewportFrame")
	if viewport then
		viewport:ClearAllChildren()

		if tool then
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local previewFolder = ReplicatedStorage:WaitForChild("ViewportForTools")
			-- Look for a preview model with the same name as the tool.
			local previewModel = previewFolder:FindFirstChild(tool.Name)

			if previewModel then
				local cloneModel = previewModel:Clone()
				cloneModel.Parent = viewport

				-- Create and assign a new Camera for the viewport.
				local cam = Instance.new("Camera")
				cam.FieldOfView = 40
				viewport.CurrentCamera = cam
				cam.Parent = viewport

				local center, size
				if cloneModel:IsA("Model") and cloneModel:GetBoundingBox() then
					center, size = cloneModel:GetBoundingBox()
				elseif cloneModel:IsA("BasePart") then
					center = cloneModel.CFrame
					size = cloneModel.Size
				else
					-- Fallback values if neither applies.
					center = CFrame.new()
					size = Vector3.new(1, 1, 1)
				end

				-- Position the camera at a distance that fits the model.
				local distance = size.Magnitude * 1
				local cameraOffset = Vector3.new(0, size.Y * 0.5, distance)
				cam.CFrame = CFrame.new(center.Position + cameraOffset, center.Position)
			end
		end
	end
end

------------------------------------------------------------
-- Core HotbarController Methods
------------------------------------------------------------

-- Gets all tools from character and backpack, preserving order
function HotbarController:_GetAllToolsByName()
	local toolsByName = {}
	local equippedToolName = nil

	-- First check character for equipped tool
	local character = self._player.Character
	if character then
		local equippedTool = character:FindFirstChildWhichIsA("Tool")
		if equippedTool then
			toolsByName[equippedTool.Name] = equippedTool
			equippedToolName = equippedTool.Name
		end
	end

	-- Then check backpack for unequipped tools
	local backpack = self._player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			toolsByName[tool.Name] = tool
		end
	end

	return toolsByName, equippedToolName
end

-- Builds a stable ordered tool list:
-- Uses the tool name ordering system to maintain consistent positions
function HotbarController:_GetOrderedToolList()
	local tools = {}
	local toolsByName, equippedToolName = self:_GetAllToolsByName()

	-- If we don't have a saved order or this is first load, create initial order
	if not self._savedToolOrder or #self._savedToolOrder == 0 then
		self._savedToolOrder = {}

		-- Put equipped tool first if any
		if equippedToolName then
			table.insert(self._savedToolOrder, equippedToolName)
		end

		-- Add remaining tools
		for toolName, _ in pairs(toolsByName) do
			if toolName ~= equippedToolName then
				table.insert(self._savedToolOrder, toolName)
			end
		end
	else
		-- Update saved order to include any new tools
		local foundTools = {}

		-- First pass: Check which tools from saved order still exist
		for i, toolName in ipairs(self._savedToolOrder) do
			if toolsByName[toolName] then
				foundTools[toolName] = true
			end
		end

		-- Second pass: Add any new tools not in the saved order
		for toolName, _ in pairs(toolsByName) do
			if not foundTools[toolName] then
				table.insert(self._savedToolOrder, toolName)
				foundTools[toolName] = true
			end
		end

		-- Third pass: Remove any tools from saved order that no longer exist
		for i = #self._savedToolOrder, 1, -1 do
			local toolName = self._savedToolOrder[i]
			if not toolsByName[toolName] then
				table.remove(self._savedToolOrder, i)
			end
		end
	end

	-- Build final ordered tools array based on saved order
	for _, toolName in ipairs(self._savedToolOrder) do
		if toolsByName[toolName] then
			table.insert(tools, toolsByName[toolName])
		end
	end

	return tools
end

function HotbarController:_InitializeReferences()
	-- Cache UI references.
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")
	self._HUD = self._playersUI:WaitForChild("PlayerHUD")

	-- The hotbar container holds all slot UIs.
	self._HotBarContainer = self._HUD:WaitForChild("Main"):WaitForChild("HotBar")
	-- The original template slot (used for slot 1).
	self._HotBarTemplate = self._HotBarContainer:WaitForChild("HotBarTemplate")
	self._ToolNameText = self._HotBarTemplate:WaitForChild("ToolName")
	self._ToolNumberText = self._HotBarTemplate:WaitForChild("HotBarNumber"):WaitForChild("NumberText")
	-- Cache the original size of the template slot.
	self._OriginalSlotSize = self._HotBarTemplate.Size

	-- Table to store active slot UIs (slot 1 is the original template).
	self._Slots = {}

	-- Initialize tool ordering
	self._savedToolOrder = {}
end

-- Disable the default Roblox backpack GUI.
function HotbarController:_DisableDefaultBackpack()
	StarterGui:SetCoreGuiEnabled("Backpack", false)
end

-- Updates the hotbar slots UI based on our ordered tool list.
-- Always shows MAX_SLOTS, regardless of how many tools are available.
-- Slot 1 always uses the original template; additional slots are clones.
function HotbarController:_UpdateHotbarSlots()
	local tools = self:_GetOrderedToolList()
	local slotSpacing = 5
	local slotWidth = self._OriginalSlotSize.X.Offset

	-- Create or update slots for each tool and empty slots up to MAX_SLOTS
	for i = 1, MAX_SLOTS do
		local tool = tools[i] -- This will be nil for slots beyond the tool count

		-- Create or get the slot UI element
		if i == 1 then
			-- Use the original template for slot 1.
			if not self._Slots[1] then
				self._Slots[1] = self._HotBarTemplate
				self._HotBarTemplate.Visible = true
			end
			self._Slots[1].Position =
				UDim2.new(0, 0, self._HotBarTemplate.Position.Y.Scale, self._HotBarTemplate.Position.Y.Offset)
		else
			if not self._Slots[i] then
				local newSlot = self._HotBarTemplate:Clone()
				newSlot.Name = "HotBarSlot" .. i
				newSlot.Visible = true
				newSlot.Position = UDim2.new(
					0,
					(i - 1) * (slotWidth + slotSpacing),
					self._HotBarTemplate.Position.Y.Scale,
					self._HotBarTemplate.Position.Y.Offset
				)
				newSlot.Parent = self._HotBarContainer
				self._Slots[i] = newSlot
			else
				self._Slots[i].Position = UDim2.new(
					0,
					(i - 1) * (slotWidth + slotSpacing),
					self._HotBarTemplate.Position.Y.Scale,
					self._HotBarTemplate.Position.Y.Offset
				)
			end
		end

		-- Update the slot's NumberText.
		local numberLabel = self._Slots[i]:FindFirstChild("HotBarNumber")
			and self._Slots[i].HotBarNumber:FindFirstChild("NumberText")
		if numberLabel then
			numberLabel.Text = tostring(i)
		end

		-- Update the ToolName label and visibility of empty slot icon
		local toolNameLabel = self._Slots[i]:FindFirstChild("ToolName")
		local iconImage = self._Slots[i]:FindFirstChild("Icon")

		if toolNameLabel then
			if tool then
				toolNameLabel.Text = tool.Name
				-- Hide the empty slot icon when a tool is present
				if iconImage then
					iconImage.Visible = false
				end
			else
				toolNameLabel.Text = "Empty"
				-- Show the empty slot icon when no tool is present
				if iconImage then
					iconImage.Visible = true
				end
			end
		end

		-- Update the viewport preview.
		self:_UpdateSlotViewport(self._Slots[i], tool)
	end

	-- Remove any extra slots beyond MAX_SLOTS (shouldn't happen but just in case)
	for i = MAX_SLOTS + 1, #self._Slots do
		if self._Slots[i] then
			self._Slots[i]:Destroy()
			self._Slots[i] = nil
		end
	end
end

-- Tween a given slot's size.
-- When equipped is true, tween to 120% size; otherwise, revert.
function HotbarController:_TweenSlotSize(slot, equipped)
	local targetSize
	if equipped then
		targetSize = UDim2.new(
			self._OriginalSlotSize.X.Scale * 1.2,
			self._OriginalSlotSize.X.Offset,
			self._OriginalSlotSize.Y.Scale * 1.2,
			self._OriginalSlotSize.Y.Offset
		)
	else
		targetSize = self._OriginalSlotSize
	end

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(slot, tweenInfo, { Size = targetSize })
	tween:Play()
end

-- Update the hotbar display. The slot corresponding to the equipped tool is tweened larger.
function HotbarController:_UpdateEquippedTool()
	local tools = self:_GetOrderedToolList()
	local equippedTool = nil
	if self._player.Character then
		equippedTool = self._player.Character:FindFirstChildWhichIsA("Tool")
	end

	for i, slot in ipairs(self._Slots) do
		local toolNameLabel = slot:FindFirstChild("ToolName")
		local iconImage = slot:FindFirstChild("Icon")
		local tool = tools[i]

		if toolNameLabel then
			if tool then
				toolNameLabel.Text = tool.Name
				if iconImage then
					iconImage.Visible = false
				end
			else
				toolNameLabel.Text = "Empty"
				if iconImage then
					iconImage.Visible = true
				end
			end
		end

		if tool and equippedTool and tool == equippedTool then
			self:_TweenSlotSize(slot, true)
			slot.Background.EquippedStroke.Enabled = true
		else
			self:_TweenSlotSize(slot, false)
			slot.Background.EquippedStroke.Enabled = false
		end
	end
end

-- Equips or unequips the tool in the given slot.
function HotbarController:_EquipToolBySlot(slotIndex)
	local tools = self:_GetOrderedToolList()
	if slotIndex > #tools then
		return -- Invalid slot - no tool available.
	end
	local tool = tools[slotIndex]
	if not tool then
		return
	end

	local backpack = self._player:WaitForChild("Backpack")
	local character = self._player.Character
	if not character then
		return
	end

	-- If a different tool is already equipped, unequip it first.
	local currentEquipped = character:FindFirstChildWhichIsA("Tool")
	if currentEquipped and currentEquipped ~= tool then
		currentEquipped.Parent = backpack
	end

	if tool.Parent == character then
		-- If the tool is already equipped, try to unequip it.
		local isFishing = false
		local fishingBool = self._player:FindFirstChild("IsFishing")
		if fishingBool then
			isFishing = fishingBool.Value
		end
		if isFishing and string.sub(tool.Name, -3) == "Rod" then
			-- Do not unequip a fishing rod while fishing.
			return
		end
		tool.Parent = backpack
	else
		tool.Parent = character
	end

	self:_UpdateHotbarSlots()
	self:_UpdateEquippedTool()
end

-- Set up tool event connections for the Character and Backpack.
function HotbarController:_SetupToolConnections()
	local function onToolChanged()
		self:_UpdateHotbarSlots()
		self:_UpdateEquippedTool()
	end

	local function onCharacterAdded(character)
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				child.Equipped:Connect(onToolChanged)
				child.Unequipped:Connect(onToolChanged)
			end
		end
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				child.Equipped:Connect(onToolChanged)
				child.Unequipped:Connect(onToolChanged)
				onToolChanged()
			end
		end)
	end

	self._player.CharacterAdded:Connect(onCharacterAdded)
	if self._player.Character then
		onCharacterAdded(self._player.Character)
	end

	local backpack = self._player:WaitForChild("Backpack")
	backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			onToolChanged()
		end
	end)
	backpack.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			onToolChanged()
		end
	end)
end

-- Set up input connections so that number keys toggle equipping/unequipping tools.
function HotbarController:_SetupInputConnections()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.One then
				self:_EquipToolBySlot(1)
			elseif input.KeyCode == Enum.KeyCode.Two then
				self:_EquipToolBySlot(2)
			elseif input.KeyCode == Enum.KeyCode.Three then
				self:_EquipToolBySlot(3)
			elseif input.KeyCode == Enum.KeyCode.Four then
				self:_EquipToolBySlot(4)
			elseif input.KeyCode == Enum.KeyCode.Five then
				self:_EquipToolBySlot(5)
			end
		end
	end)
end

function HotbarController:KnitStart()
	task.wait(5)
	self:_DisableDefaultBackpack()
	self:_InitializeReferences()
	self:_SetupToolConnections()
	self:_SetupInputConnections()
	self:_UpdateHotbarSlots()
	self:_UpdateEquippedTool()
end

return HotbarController
