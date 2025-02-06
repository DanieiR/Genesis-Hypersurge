local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local customPromptTemplate = ReplicatedStorage:WaitForChild("ProximityPrompts"):WaitForChild("ShopInteractable")

local activeCustomPrompts = {}

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
