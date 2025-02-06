local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local QuestController = Knit.CreateController({
	Name = "QuestController",
})

local BAR_TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
function QuestController:UpdateQuestUI(quest, progress)
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Clear existing quest UI
	local container = playerGui.Quests.Main
	for _, child in pairs(container:GetChildren()) do
		if child.Name == "ActiveQuest" then
			child:Destroy()
		end
	end

	-- Clone and setup new quest UI
	local questFrame = container:WaitForChild("QuestTemplate"):Clone()
	questFrame.Name = "ActiveQuest"
	questFrame.Visible = true
	questFrame.Parent = container

	-- Populate UI elements
	questFrame.Info.QuestText.Text = quest.Title
	questFrame.Info.QuestAmountText.Text = `{progress}/{quest.Required}`
	-- Handle max level
	local currentProgress = progress / quest.Required

	-- Animate XP bar
	local tween = TweenService:Create(questFrame.CompletionBar.Bar, BAR_TWEEN_INFO, {
		Size = UDim2.new(currentProgress, 0, 1, 0),
	})
	tween:Play()
	-- Dynamic description handling
	local descriptionText = quest.Description
	if quest.Type == "Specific" then
		descriptionText ..= `\nTarget: {quest.Target}`
	elseif quest.Type == "LostAndFound" then
		descriptionText ..= `\nLocation: {quest.Location}`
	end
	questFrame.Description.DescriptionText.Text = descriptionText
end

function QuestController:ShowRewardPopup(quest)
	-- Implement reward display logic
	print("Quest completed! Rewards:", quest.Reward)
end

function QuestController:KnitStart()
	local QuestService = Knit.GetService("QuestService")

	QuestService.QuestUpdated:Connect(function(quest, progress)
		self:UpdateQuestUI(quest, progress)
	end)

	QuestService.QuestCompleted:Connect(function(quest)
		self:ShowRewardPopup(quest)
	end)
end

return QuestController
