--[[
    Dialogue Controller Client
    Version: 1.1
    Last Updated: 2024-01-27
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local dialogueSFX = SoundService["Sound Effects"]["NPC Dialogue"]
local DialogueController = Knit.CreateController({
	Name = "DialogueController",
})
local dialogues = {
	"Bring me a legendary fish, and I’ll turn it into the feast of legends. Deal?",
	"Hmph. This fish is mediocre at best—but I can still make magic happen in the kitchen.",
	"A premium fish like this? Now that’s worthy of my cooking.",
}
DialogueController._currentNPC = nil
DialogueController._distanceCheckConnection = nil
local MAX_DIALOGUE_DISTANCE = 15

function DialogueController:_InitializeReferences()
	self._player = Players.LocalPlayer
	self._playersUI = self._player:WaitForChild("PlayerGui")

	local DialogueScreen = self._playersUI:WaitForChild("Dialogue")
	self._Main = DialogueScreen:WaitForChild("Main")
	self._DescriptionText = self._Main:WaitForChild("DescriptionText")
	self._dialogueButtons = self._Main:WaitForChild("Buttons")
	self._NpcName = self._Main:WaitForChild("NPCName"):WaitForChild("NameText")

	self._stateController = Knit.GetController("StateController")
end
function DialogueController:_AnimateEntry()
	-- Cancel any existing tweens
	if self._entryTween then
		self._entryTween:Cancel()
	end

	-- Create bounce tween
	self._entryTween =
		TweenService:Create(self._Main, TweenInfo.new(0.75, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.7, 0),
		})

	self._entryTween:Play()
	self._entryTween.Completed:Wait()
end

function DialogueController:_HideDialogue()
	-- Reset position and visibility
	if self._Main then
		self._Main.Visible = false
		self._Main.Position = UDim2.new(0.5, 0, -1, 0)
	end

	-- Cleanup tweens
	if self._entryTween then
		self._entryTween:Cancel()
		self._entryTween = nil
	end
	if self._textAnimationTask then
		task.cancel(self._textAnimationTask)
		self._textAnimationTask = nil
		dialogueSFX.Dialogue:Stop()
	end

	if self._buttonConnections then
		for _, connection in pairs(self._buttonConnections) do
			connection:Disconnect()
		end
		self._buttonConnections = nil
	end

	if self._distanceCheckConnection then
		self._distanceCheckConnection:Disconnect()
		self._distanceCheckConnection = nil
	end

	if self._buttonConnections then
		for _, connection in pairs(self._buttonConnections) do
			connection:Disconnect()
		end
		self._buttonConnections = nil
	end

	if self._textAnimationConnection then
		self._textAnimationConnection:Disconnect()
		self._textAnimationConnection = nil
	end

	self._currentNPC = nil
end

function DialogueController:_AnimateText(message: string, speed: number)
	local typingSpeed = speed or 0.05
	local punctuationDelay = 0.2
	local currentText = ""
	local npcValid = self._currentNPC and self._currentNPC:IsDescendantOf(workspace)

	-- Reset state
	self._dialogueButtons.Visible = false
	dialogueSFX.Dialogue:Play()

	-- Cancel existing animation
	if self._textAnimationTask then
		task.cancel(self._textAnimationTask)
	end

	self._textAnimationTask = task.spawn(function()
		for i = 1, #message do
			-- Check for early exit conditions
			if not npcValid or not self._Main.Visible then
				break
			end

			local nextChar = message:sub(i, i)
			currentText = currentText .. nextChar
			self._DescriptionText.Text = currentText

			-- Adjust delay for punctuation
			local delayTime = nextChar:match("[%.%,%!%?]") and punctuationDelay or typingSpeed
			task.wait(delayTime)
		end

		-- Final cleanup
		dialogueSFX.Dialogue:Stop()
		if npcValid and self._Main.Visible then
			self._dialogueButtons.Visible = true
		end
	end)
end
function DialogueController:_CheckDistanceFromNPC()
	if not self._currentNPC or not self._currentNPC:IsDescendantOf(workspace) then
		self:_HideDialogue()
		return
	end

	local playerRoot = self._player.Character and self._player.Character:FindFirstChild("HumanoidRootPart")
	local npcRoot = self._currentNPC:FindFirstChild("HumanoidRootPart")

	if not playerRoot or not npcRoot then
		self:_HideDialogue()
		return
	end

	local distance = (playerRoot.Position - npcRoot.Position).Magnitude
	if distance > MAX_DIALOGUE_DISTANCE then
		self:_HideDialogue()
	end
end
function DialogueController:_SetupButtonConnections()
	if self._buttonConnections then
		for _, connection in pairs(self._buttonConnections) do
			connection:Disconnect()
		end
	end
	self._buttonConnections = {}

	local SellingService = Knit.GetService("SellingService")

	-- Sell All Button
	local sellAllButton = self._dialogueButtons.ResponseButton_1
	self._buttonConnections.sellAll = sellAllButton.MouseButton1Click:Connect(function()
		SellingService.SellAllRequest:Fire(self._currentNPC)
		self:_HideDialogue()
	end)

	-- Sell Equipped Button
	local sellEquippedButton = self._dialogueButtons.ResponseButton_2
	self._buttonConnections.sellEquipped = sellEquippedButton.MouseButton1Click:Connect(function()
		SellingService.SellEquippedRequest:Fire(self._currentNPC)
		self:_HideDialogue()
	end)
end

function DialogueController:_DisplayDialogueForSellerNPC(NPC)
	self:_HideDialogue()

	-- Store NPC reference
	self._currentNPC = NPC
	self._currentNPC.AncestryChanged:Connect(function()
		if not NPC:IsDescendantOf(workspace) then
			self:_HideDialogue()
		end
	end)

	-- Update UI
	self._dialogueButtons.ResponseButton_1.ResponseText.Text = "Sell All"
	self._dialogueButtons.ResponseButton_2.ResponseText.Text = "Sell Equipped"
	self._NpcName.Text = "Santi"
	-- Initial hidden state setup
	self._Main.Visible = false
	self._dialogueButtons.Visible = false
	self._Main.Position = UDim2.new(0.5, 0, 1, 0) -- Start below screen
	self._DescriptionText.Text = " "
	-- Show and animate dialogue
	self._Main.Visible = true

	self:_AnimateEntry()

	-- Set up button handlers
	self:_SetupButtonConnections()

	-- Start animated text

	self:_AnimateText(dialogues[math.random(1, 3)], 0.02)

	-- Start distance checking
	self._distanceCheckConnection = RunService.Heartbeat:Connect(function()
		self:_CheckDistanceFromNPC()
	end)
end
function DialogueController:KnitStart()
	self:_InitializeReferences()
	local SellingSerivce = Knit.GetService("SellingService")
	SellingSerivce.InitiateNPCDialogue:Connect(function(NPC)
		self:_DisplayDialogueForSellerNPC(NPC)
	end)
end

return DialogueController
