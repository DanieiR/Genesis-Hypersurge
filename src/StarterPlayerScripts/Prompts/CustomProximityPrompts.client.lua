local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local customPromptTemplate = ReplicatedStorage:WaitForChild("ProximityPrompts"):WaitForChild("ShopInteractable")
local SoundService = game:GetService("SoundService")
local fishingSFX = SoundService["Sound Effects"].Fishing
local activeCustomPrompts = {}
local npcCooldowns = {} -- Tracks last trigger time per prompt
local COOLDOWN_TIME = 2 -- seconds

local function showCustomPromptSellNPC(prompt, inputType)
	local promptPart = prompt.Parent
	if not promptPart then
		return
	end

	local customPromptGui = customPromptTemplate:Clone()
	customPromptGui.Parent = promptPart
	customPromptGui.Adornee = promptPart
	customPromptGui.Enabled = true

	local mainFrame = customPromptGui:FindFirstChild("Main")
	if mainFrame then
		local interactKeyLabel = mainFrame:FindFirstChild("InteractKey")
		if interactKeyLabel and inputType then
			interactKeyLabel.Text = prompt.KeyboardKeyCode.Name
		end
		-- Ensure a UIScale exists for tweening.
		if not mainFrame:FindFirstChildOfClass("UIScale") then
			local uiscale = Instance.new("UIScale")
			uiscale.Scale = 1
			uiscale.Parent = mainFrame
		end
	end

	activeCustomPrompts[prompt] = customPromptGui
end

local function hideCustomPromptSellNPC(prompt)
	local gui = activeCustomPrompts[prompt]
	if gui then
		gui:Destroy()
		activeCustomPrompts[prompt] = nil
	end
end

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	if prompt.Style == Enum.ProximityPromptStyle.Default then
		return
	end
	if prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name == "Santi" then
		showCustomPromptSellNPC(prompt, inputType)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt, inputType)
	if activeCustomPrompts[prompt] then
		hideCustomPromptSellNPC(prompt)
	end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if prompt.Parent and prompt.Parent.Parent and prompt.Parent.Parent.Name == "Santi" then
		SoundService:PlayLocalSound(fishingSFX.UI_Click)
		-- Check if we're still in cooldown for this prompt.
		if npcCooldowns[prompt] and tick() - npcCooldowns[prompt] < COOLDOWN_TIME then
			return
		end
		npcCooldowns[prompt] = tick()

		-- Tween the prompt GUI if it exists.
		local gui = activeCustomPrompts[prompt]
		if gui then
			local mainFrame = gui:FindFirstChild("Main")
			if mainFrame then
				local uiscale = mainFrame:FindFirstChildOfClass("UIScale")
				if not uiscale then
					uiscale = Instance.new("UIScale")
					uiscale.Scale = 1
					uiscale.Parent = mainFrame
				end
				-- Tween sequence: grow then shrink.
				task.spawn(function()
					local tweenInfoUp = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local tweenUp = TweenService:Create(uiscale, tweenInfoUp, { Scale = 1.2 })
					tweenUp:Play()
					tweenUp.Completed:Wait()

					local tweenInfoDown = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
					local tweenDown = TweenService:Create(uiscale, tweenInfoDown, { Scale = 1 })
					tweenDown:Play()
				end)
			end
		end

		-- Re-enable the prompt after the cooldown period.
		task.delay(COOLDOWN_TIME, function() end)
	end
end)
