local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Maid = require(ReplicatedStorage.Packages.Maid)

-- Controller initialization
local IndexController = Knit.CreateController({ Name = "IndexController" })

--[[
    Private Methods
]]

function IndexController:_InitializeReferences()
	-- Create a maid for connection cleanup
	self._maid = Maid.new()

	-- Cache all UI references to minimize FindFirstChild calls
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")
	self._IndexMainFrame = self._playersUI:WaitForChild("Index"):WaitForChild("Main")

	--There are multiple areas which show different unlocked fishes for that area, By default Shokan_Rift is the one that is visible first
	self._AreasFrame = self._IndexMainFrame:WaitForChild("Areas")
	self._ShokanRift = self._AreasFrame:WaitForChild("Shokan_Rift")
	self._WisteriaCove = self._AreasFrame:WaitForChild("Wisteria_Cove")
	self._EastWindIsle = self._AreasFrame:WaitForChild("Eastwind_Isle")

	--Variables to select areas (Buttons)
	self._AreaSelectionFrame = self._IndexMainFrame:WaitForChild("AreaSelection")
	self._ButtonScrollingFrameHolder = self._AreaSelectionFrame:WaitForChild("ScrollingFrameHolder")
	self._ButtonScrollingFrameMain = self._ButtonScrollingFrameHolder:WaitForChild("ScrollingFrame")
	self._EastWindIsleButton = self._ButtonScrollingFrameMain:WaitForChild("1")
	self._ShokanRiftButton = self._ButtonScrollingFrameMain:WaitForChild("2")
	self._WisteriaCoveButton = self._ButtonScrollingFrameMain:WaitForChild("3")

	-- Track currently selected area
	self._selectedArea = "Eastwind_Isle" -- Default area
	self._areaButtons = {
		["Eastwind_Isle"] = self._EastWindIsleButton,
		["Shokan_Rift"] = self._ShokanRiftButton,
		["Wisteria_Cove"] = self._WisteriaCoveButton,
	}

	self._areaFrames = {
		["Eastwind_Isle"] = self._EastWindIsle,
		["Shokan_Rift"] = self._ShokanRift,
		["Wisteria_Cove"] = self._WisteriaCove,
	}

	--Variables for fishes frames of the Eastwind Isle area
	self._ClownFishFrame = self._EastWindIsle
		:WaitForChild("ScrollingFrameHolder")
		:WaitForChild("IndexScrollingFrame")
		:WaitForChild("ClownFish")
	self._KoiFrame =
		self._EastWindIsle:WaitForChild("ScrollingFrameHolder"):WaitForChild("IndexScrollingFrame"):WaitForChild("Koi")

	-- Reference to fish models
	self._fishViewportModels = ReplicatedStorage:WaitForChild("ViewportFishes")

	-- Fish details panel references
	self._FishDetailsEastWind = self._EastWindIsle:WaitForChild("ScrollingFrameHolder"):WaitForChild("IndexDetails")
	self._FishDetailsWisteria = self._WisteriaCove:WaitForChild("ScrollingFrameHolder"):WaitForChild("IndexDetails")
	self._FishDetailsShokan = self._ShokanRift:WaitForChild("ScrollingFrameHolder"):WaitForChild("IndexDetails")

	-- Detail panels map
	self._fishDetailsPanels = {
		["Eastwind_Isle"] = self._FishDetailsEastWind,
		["Shokan_Rift"] = self._FishDetailsShokan,
		["Wisteria_Cove"] = self._FishDetailsWisteria,
	}
end

-- Sets up a viewport frame with a fish model
function IndexController:_SetupFishViewport(frame, fishName)
	-- Find the ViewportFrame within the fish frame
	local viewportFrame = frame:FindFirstChild("ViewportFrame")
	if not viewportFrame then
		warn("ViewportFrame not found in", frame:GetFullName())
		return
	end

	-- Clear existing content
	viewportFrame:ClearAllChildren()

	-- Get the fish model
	local fishModel = self._fishViewportModels:FindFirstChild(fishName)
	if not fishModel then
		warn("Fish model not found:", fishName)
		return
	end

	-- Create a WorldModel to house the fish model
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	-- Clone the fish model into the WorldModel
	local clonedFishModel = fishModel:Clone()
	clonedFishModel.Parent = worldModel

	-- Create and set up camera
	self:_CreateViewportCamera(clonedFishModel, viewportFrame)
end

-- Create an optimized camera for the fish viewport
function IndexController:_CreateViewportCamera(fishModel, viewportFrame)
	-- Create new camera
	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	-- Determine optimal camera position based on fish model
	if fishModel.PrimaryPart then
		local fishCFrame = fishModel.PrimaryPart.CFrame
		local fishSize = fishModel.PrimaryPart.Size

		-- Adjust based on fish type
		if fishModel.Name == "ClownFish" or fishModel.Name == "Koi" or fishModel.Name == "YinYangKoi" then
			local objectSize = fishSize
			local cameraDistance = math.max(objectSize.X, objectSize.Y, objectSize.Z) * 0.8

			camera.CFrame = CFrame.new(
				fishModel.PrimaryPart.Position + Vector3.new(0, 0, cameraDistance),
				fishModel.PrimaryPart.Position
			)
		else
			local objectSize = fishSize
			local cameraDistance = math.max(objectSize.X, objectSize.Y, objectSize.Z) * 2

			local cameraPosition = fishModel.PrimaryPart.Position + Vector3.new(-0.5, 0, cameraDistance)
			camera.CFrame = CFrame.new(cameraPosition, fishModel.PrimaryPart.Position)
		end
	else
		warn("Fish model missing PrimaryPart:", fishModel.Name)
	end
end

-- Setup fish click handlers to show details
function IndexController:_SetupFishClicks()
	-- Setup ClownFish click
	self._maid:GiveTask(self._ClownFishFrame.Click.MouseButton1Click:Connect(function()
		self:_ShowFishDetails("ClownFish")
	end))

	-- Setup Koi click
	self._maid:GiveTask(self._KoiFrame.Click.MouseButton1Click:Connect(function()
		self:_ShowFishDetails("Koi")
	end))
end

-- Show detailed info for selected fish
function IndexController:_ShowFishDetails(fishName)
	-- Get fish data
	local fishData = self:_GetFishData(fishName)
	if not fishData then
		return
	end

	-- Get the current details panel based on selected area
	local detailsPanel = self._fishDetailsPanels[self._selectedArea]
	if not detailsPanel then
		warn("Details panel not found for area:", self._selectedArea)
		return
	end

	-- Update the details panel UI using the new structure
	local infoNamesRarity = detailsPanel:FindFirstChild("FishInfoNamesRarity")
	local infoAreaOdds = detailsPanel:FindFirstChild("FishInfoAreaOdds")

	if infoNamesRarity then
		local fishNameLabel = infoNamesRarity:FindFirstChild("FishName")
		local rarityLabel = infoNamesRarity:FindFirstChild("Rarity")

		if fishNameLabel then
			fishNameLabel.Text = fishName
		end

		if rarityLabel then
			rarityLabel.Text = fishData.rarity
		end
	else
		warn("FishInfoNamesRarity frame not found in details panel")
	end

	if infoAreaOdds then
		local areaLabel = infoAreaOdds:FindFirstChild("Area")
		local oddsLabel = infoAreaOdds:FindFirstChild("Odds")

		if areaLabel then
			areaLabel.Text = "Area: " .. fishData.area
		end

		if oddsLabel then
			oddsLabel.Text = "1 in " .. fishData.odds
		end
	else
		warn("FishInfoAreaOdds frame not found in details panel")
	end

	-- Set the description text if exists
	local description = detailsPanel:FindFirstChild("Description")
	if description then
		description.Text = fishData.description
	end

	-- Set up the viewport in the details panel
	local detailsViewport = detailsPanel:FindFirstChild("ViewportFrame")
	if detailsViewport then
		self:_SetupFishViewport(detailsPanel, fishName)
	end
end

-- Get fish data for a specific fish
function IndexController:_GetFishData(fishName)
	local fishData = {
		["ClownFish"] = {
			rarity = "Common",
			description = "A clownfish, usually found in the coral reefs.",
			odds = 1,
			area = "East Wind Isle",
		},
		["Koi"] = {
			rarity = "Rare",
			description = "A beautiful koi fish with vibrant colors. These fish are known for their gracefulness.",
			odds = 5,
			area = "East Wind Isle",
		},
	}

	return fishData[fishName]
end

-- Initialize all fish viewports
function IndexController:_InitializeFishViewports()
	-- Setup viewports for Eastwind Isle fish
	self:_SetupFishViewport(self._ClownFishFrame, "ClownFish")
	self:_SetupFishViewport(self._KoiFrame, "Koi")

	-- Show details for ClownFish by default
	self:_ShowFishDetails("ClownFish")
end

-- Changes the selected area and updates UI
function IndexController:_SelectArea(areaName)
	if not self._areaFrames[areaName] then
		warn("Invalid area name:", areaName)
		return
	end

	if areaName == self._selectedArea then
		return
	end

	for _, frame in pairs(self._areaFrames) do
		frame.Visible = false
	end
	self._areaFrames[areaName].Visible = true

	self._selectedArea = areaName

	-- Update the completion text in the header
	self:_UpdateCompletionHeader(areaName)
end

-- Update the header to show completion % for the selected area
function IndexController:_UpdateCompletionHeader(areaName)
	local completionHeader = self._IndexMainFrame:FindFirstChild("???% Completed | Eastwind Isle")
	if completionHeader and completionHeader:IsA("TextLabel") then
		-- These would be calculated based on discovered fish
		local completionPercentages = {
			["Eastwind_Isle"] = 40,
			["Shokan_Rift"] = 25,
			["Wisteria_Cove"] = 10,
		}

		local areaDisplayNames = {
			["Eastwind_Isle"] = "Eastwind Isle",
			["Shokan_Rift"] = "Shokan Rift",
			["Wisteria_Cove"] = "Wisteria Cove",
		}

		local percentage = completionPercentages[areaName] or 0
		local displayName = areaDisplayNames[areaName] or areaName

		completionHeader.Text = percentage .. "% Completed | " .. displayName
	end
end

-- Sets up button click listeners
function IndexController:_SetupButtonConnections()
	-- Connect each button to its area selection function
	self._maid:GiveTask(self._EastWindIsleButton.MouseButton1Click:Connect(function()
		self:_SelectArea("Eastwind_Isle")
	end))

	self._maid:GiveTask(self._ShokanRiftButton.MouseButton1Click:Connect(function()
		self:_SelectArea("Shokan_Rift")
	end))

	self._maid:GiveTask(self._WisteriaCoveButton.MouseButton1Click:Connect(function()
		self:_SelectArea("Wisteria_Cove")
	end))
end

-- Initialize the areas display
function IndexController:_InitializeAreasDisplay()
	-- Hide all areas first
	for _, frame in pairs(self._areaFrames) do
		frame.Visible = false
	end

	-- Show the default area
	self._areaFrames[self._selectedArea].Visible = true

	-- Update completion header
	self:_UpdateCompletionHeader(self._selectedArea)
end

function IndexController:KnitStart()
	-- Main initialization sequence
	self:_InitializeReferences()
	self:_SetupButtonConnections()
	self:_SetupFishClicks()
	self:_InitializeAreasDisplay()
	self:_InitializeFishViewports()
end

function IndexController:KnitDestroy()
	if self._maid then
		self._maid:Destroy()
		self._maid = nil
	end
end

return IndexController
