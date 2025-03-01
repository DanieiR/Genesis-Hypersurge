local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Maid = require(game:GetService("ReplicatedStorage").Packages.Maid)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local SummonsController = Knit.CreateController({ Name = "SummonsController" })

--[[
    Private Methods
]]

--- Initializes UI and service references for the controller.
function SummonsController:_InitializeReferences()
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")

	self._SummonScreen = self._playersUI:WaitForChild("Summon")
	self._MainFrame = self._SummonScreen:WaitForChild("Main")
	local ButtonsFrame = self._MainFrame:WaitForChild("Summon"):WaitForChild("Purchase"):WaitForChild("ButtonHolder")
	self._OpenOneButton = ButtonsFrame:WaitForChild("OpenOne")
	self._OpenTenButton = ButtonsFrame:WaitForChild("OpenTen")
	self._skipRequested = false
	self._SummonDetails = self._playersUI:WaitForChild("SummonDetails"):WaitForChild("Main")
	self._UnitDetailsFrame = self._SummonDetails:WaitForChild("UnitInfoText")
	self._SummonListFrame = self._SummonDetails:WaitForChild("SummonList")
	self._UniversalTemplate = self._SummonListFrame:WaitForChild("UniversalTemplate")

	self._HUD = self._playersUI:WaitForChild("PlayerHUD")
	self._QuestScreen = self._playersUI:WaitForChild("Quests")

	self._SummonService = Knit.GetService("SummonService")

	self._ViewPortModelsFolder = ReplicatedStorage:WaitForChild("SummonViewports")

	-- Initialize blur effect
	self._blurEffect = nil

	-- Initialize maid for cleanup
	self._maid = Maid.new()

	-- Create a separate maid for summon-specific cleanup
	self._summonMaid = Maid.new()
end

--- Creates and applies a blur effect to the player's camera
function SummonsController:_ApplyBlurEffect()
	-- Create the blur effect if it doesn't exist
	if not self._blurEffect then
		self._blurEffect = Instance.new("BlurEffect")
		self._blurEffect.Size = 0
		self._blurEffect.Parent = Lighting

		-- Add to maid for automatic cleanup
		self._summonMaid:GiveTask(function()
			if self._blurEffect then
				self._blurEffect:Destroy()
				self._blurEffect = nil
			end
		end)
	end

	-- Animate the blur effect
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
	local tween = TweenService:Create(self._blurEffect, tweenInfo, { Size = 15 })
	tween:Play()

	-- Add tween to maid for cleanup
	self._summonMaid:GiveTask(function()
		if tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end)

	return tween
end

--- Removes the blur effect from the player's camera
function SummonsController:_RemoveBlurEffect()
	if self._blurEffect then
		-- Animate the blur effect removal
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
		local tween = TweenService:Create(self._blurEffect, tweenInfo, { Size = 0 })

		tween.Completed:Connect(function()
			if self._blurEffect then
				self._blurEffect:Destroy()
				self._blurEffect = nil
			end
		end)

		tween:Play()

		-- Add tween to maid for cleanup
		self._summonMaid:GiveTask(function()
			if tween.PlaybackState == Enum.PlaybackState.Playing then
				tween:Cancel()
			end
		end)

		return tween
	end
	return nil
end

function SummonsController:_SetupSkipListener()
	local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self:_SkipAnimations()
		end
	end)

	-- Add connection to maid for cleanup
	self._maid:GiveTask(connection)
end

function SummonsController:_SkipAnimations()
	self._skipRequested = true
end

--- Connects button events for UI interactions.
function SummonsController:_ConnectButtonEvents()
	local connection1 = self._OpenOneButton.MouseButton1Click:Connect(function()
		print("Open One button clicked")
		self._SummonService.SummonRequest:Fire(1)
	end)

	local connection2 = self._OpenTenButton.MouseButton1Click:Connect(function()
		print("Open Ten button clicked")
		self._SummonService.SummonRequest:Fire(10)
	end)

	-- Add connections to maid for cleanup
	self._maid:GiveTask(connection1)
	self._maid:GiveTask(connection2)
end

--- Starts a continuous spin effect by updating the camera's CFrame each frame.
-- This is used for the full-screen summon viewport.
-- @param camera The Camera instance to update.
-- @param modelCenter The Vector3 center of the summon model.
-- @param cameraDistance The distance from the model's center at which the camera should orbit.
-- @return connection A RenderStepped connection that can be disconnected for cleanup.
function SummonsController:_StartCameraSpin(camera, modelCenter, cameraDistance)
	local spinAngle = 0
	local rotationSpeed = 5 * math.pi / 5
	local connection = RunService.RenderStepped:Connect(function(dt)
		spinAngle = spinAngle + rotationSpeed * dt
		local newPos = modelCenter
			+ Vector3.new(math.sin(spinAngle) * cameraDistance, 0, math.cos(spinAngle) * cameraDistance)
		camera.CFrame = CFrame.new(newPos, modelCenter)
	end)

	-- Add connection to summon maid for cleanup
	self._summonMaid:GiveTask(connection)

	return connection
end

--- Creates and returns a ViewportFrame displaying the summon model along with a tween popout effect.
-- This function is used for the full-screen summon viewport.
-- @param summonData A table containing summon info
-- @return A table with keys:
--         ViewportFrame: The created ViewportFrame.
--         SpinConnection: The RenderStepped connection for the spin effect (assigned after tween completes).
function SummonsController:_CreateSummonViewport(summonData)
	local summonName = summonData.Name
	local modelTemplate = self._ViewPortModelsFolder:FindFirstChild(summonName)
	if not modelTemplate then
		warn("No model found for summon: " .. tostring(summonName))
		return nil
	end

	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Name = "SummonViewport"
	viewportFrame.Size = UDim2.new(0, 0, 0, 0)
	viewportFrame.BackgroundTransparency = 1
	viewportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	viewportFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	viewportFrame.Parent = self._SummonScreen

	-- Add viewport to summon maid for cleanup
	self._summonMaid:GiveTask(viewportFrame)

	local camera = Instance.new("Camera")
	viewportFrame.CurrentCamera = camera

	local summonModel = modelTemplate:Clone()
	summonModel.Parent = viewportFrame

	local modelCFrame, modelSize = summonModel:GetBoundingBox()
	local modelCenter = modelCFrame.Position
	local maxDimension = math.max(modelSize.X, modelSize.Y, modelSize.Z)
	local cameraDistance = maxDimension * 1.5

	local initialPos = modelCenter + Vector3.new(0, 0, -cameraDistance)
	camera.CFrame = CFrame.new(initialPos, modelCenter)

	local viewportData = { ViewportFrame = viewportFrame, SpinConnection = nil }

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(viewportFrame, tweenInfo, { Size = UDim2.new(0.2, 0, 1, 0) })

	-- Add tween to summon maid for cleanup
	self._summonMaid:GiveTask(function()
		if tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end)

	tween.Completed:Connect(function()
		viewportData.SpinConnection = self:_StartCameraSpin(camera, modelCenter, cameraDistance)
	end)
	tween:Play()

	return viewportData
end

--- Sets up a summon viewport inside a provided ViewportFrame (from the UniversalTemplate).
-- This is used to populate the SummonList. Note: No spinning effect is applied here.
-- @param summonData A table containing summon info.
-- @param viewportFrame The pre-existing ViewportFrame from the template.
-- @return A table with key:
--         ViewportFrame: The provided frame (now populated with the summon model).
function SummonsController:_SetupViewportInFrame(summonData, viewportFrame)
	local summonName = summonData.Name
	local modelTemplate = self._ViewPortModelsFolder:FindFirstChild(summonName)
	if not modelTemplate then
		warn("No model found for summon: " .. tostring(summonName))
		return nil
	end

	local summonModel = modelTemplate:Clone()
	summonModel.Parent = viewportFrame

	if summonModel.Head then
		local camera = Instance.new("Camera")
		camera.Parent = viewportFrame
		viewportFrame.CurrentCamera = camera
		local objectSize = summonModel.Head.Size
		local cameraDistance = math.max(objectSize.X, objectSize.Y, objectSize.Z) * 1.2

		local lookVector = summonModel.Head.CFrame.LookVector

		local cameraPosition = summonModel.Head.Position + lookVector * cameraDistance

		camera.CFrame = CFrame.new(cameraPosition, summonModel.Head.Position)
	end

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(viewportFrame, tweenInfo, { Size = UDim2.new(1, 0, 1, 0) })

	-- Add tween to summon maid for cleanup
	self._summonMaid:GiveTask(function()
		if tween.PlaybackState == Enum.PlaybackState.Playing then
			tween:Cancel()
		end
	end)

	tween:Play()

	return { ViewportFrame = viewportFrame, SpinConnection = nil }
end

--- Displays multiple summons in sequence on the full-screen viewport and updates the SummonList.
-- For each summon in the 'summons' table, it shows the full-screen viewport (with spinning camera)
-- for a brief period and adds an entry to the SummonList. At the end, the full-screen viewport is cleared,
-- the cloned list entries are destroyed, and UI visibility is restored.
-- @param summons A table of summon data entries.
function SummonsController:_DisplayMultipleSummons(summons)
	-- Clear any previous summon resources
	self._summonMaid:DoCleaning()

	local mainScreen = self._HUD:FindFirstChild("Main")
	if not mainScreen then
		warn("Main screen not found!")
		return
	end

	-- Apply blur effect
	self:_ApplyBlurEffect()

	mainScreen.Visible = false
	self._MainFrame.Visible = false
	self._QuestScreen.Main.Visible = false
	self._UnitDetailsFrame.Visible = true

	local fullScreenViewportData = nil

	local clonedEntries = {}

	for i, summonData in ipairs(summons) do
		self._UnitDetailsFrame.UnitName.Text = summonData.Name
		self._UnitDetailsFrame.Rarity.Text = summonData.Rarity
		self._UnitDetailsFrame.Info.Text = "Click Anywhere To Continue (" .. i .. "/" .. #summons .. ")"

		if fullScreenViewportData then
			if fullScreenViewportData.ViewportFrame and fullScreenViewportData.ViewportFrame.Parent then
				fullScreenViewportData.ViewportFrame:Destroy()
			end
		end

		fullScreenViewportData = self:_CreateSummonViewport(summonData)

		local summonListEntry = self._UniversalTemplate:Clone()
		summonListEntry.Parent = self._SummonListFrame
		summonListEntry.Visible = true

		-- Add entry to summon maid for cleanup
		self._summonMaid:GiveTask(summonListEntry)

		if summonListEntry:FindFirstChild("SummonName") then
			summonListEntry.SummonName.Text = summonData.Name
		end
		local listViewportFrame = summonListEntry:FindFirstChild("ViewportFrame")
		if listViewportFrame then
			self:_SetupViewportInFrame(summonData, listViewportFrame)
		else
			warn("UniversalTemplate is missing a child named 'ViewportFrame'.")
		end

		table.insert(clonedEntries, summonListEntry)

		while not self._skipRequested do
			task.wait(0.1)
		end

		self._skipRequested = false
	end

	-- Remove blur effect
	self:_RemoveBlurEffect()

	mainScreen.Visible = true
	self._MainFrame.Visible = true
	self._QuestScreen.Main.Visible = true
	self._UnitDetailsFrame.Visible = false

	self._skipRequested = false

	self._summonMaid:DoCleaning()
end

--- Handles the SummonResult event by determining whether to display a single summon
-- or multiple summons. For a single summon, it shows the full-screen viewport once.
-- For multiple summons, it cycles through each one on the full-screen viewport and updates the SummonList.
-- Cleans up the full-screen viewport after processing.
-- @param result The result data sent from the server (a table of summon data entries).
function SummonsController:_HandleSummonResult(result)
	-- Clean up any previous summon resources
	self._summonMaid:DoCleaning()

	local mainScreen = self._HUD:FindFirstChild("Main")
	if mainScreen then
		if #result > 1 then
			self:_DisplayMultipleSummons(result)
		else
			local summonData = result[1]
			if summonData then
				-- Apply blur effect
				self:_ApplyBlurEffect()

				local viewportData = self:_CreateSummonViewport(summonData)
				self._UnitDetailsFrame.UnitName.Text = summonData.Name
				self._UnitDetailsFrame.Rarity.Text = summonData.Rarity
				self._UnitDetailsFrame.Info.Text = "Click Anywhere To Continue (" .. "1/1)"
				mainScreen.Visible = false
				self._MainFrame.Visible = false
				self._QuestScreen.Main.Visible = false
				self._UnitDetailsFrame.Visible = true

				local summonListEntry = self._UniversalTemplate:Clone()
				summonListEntry.Parent = self._SummonListFrame
				summonListEntry.Visible = true

				-- Add entry to summon maid for cleanup
				self._summonMaid:GiveTask(summonListEntry)

				if summonListEntry:FindFirstChild("SummonName") then
					summonListEntry.SummonName.Text = summonData.Name
				end
				local listViewportFrame = summonListEntry:FindFirstChild("ViewportFrame")
				if listViewportFrame then
					self:_SetupViewportInFrame(summonData, listViewportFrame)
				else
					warn("UniversalTemplate is missing a child named 'ViewportFrame'.")
				end

				task.delay(5, function()
					-- Remove blur effect
					self:_RemoveBlurEffect()

					mainScreen.Visible = true
					self._MainFrame.Visible = true
					self._QuestScreen.Main.Visible = true
					self._UnitDetailsFrame.Visible = false

					self._summonMaid:DoCleaning()
				end)
			else
				warn("SummonResult did not contain valid summon data.")
				mainScreen.Visible = true
				self._MainFrame.Visible = true
			end
		end
	else
		warn("Main screen not found in PlayerHUD!")
	end
end

function SummonsController:KnitStart()
	-- Main initialization sequence.
	self:_InitializeReferences()
	self:_ConnectButtonEvents()
	self:_SetupSkipListener()

	-- Connect to SummonResult signal
	local connection = self._SummonService.SummonResult:Connect(function(result)
		self:_HandleSummonResult(result)
	end)

	-- Add connection to maid for cleanup
	self._maid:GiveTask(connection)
end

function SummonsController:KnitDestroy()
	-- Clean up all resources when the controller is destroyed
	if self._maid then
		self._maid:Destroy()
		self._maid = nil
	end

	if self._summonMaid then
		self._summonMaid:Destroy()
		self._summonMaid = nil
	end
end

return SummonsController
