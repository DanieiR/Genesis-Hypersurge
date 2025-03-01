local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)
local QuestsConfig = require(ReplicatedStorage.Source.Configs.QuestsConfig)
local ServerStorage = game:GetService("ServerStorage")
local Manager = require(ServerStorage.Source.Manager)
local QuestService = Knit.CreateService({
	Name = "QuestService",
	Client = {
		QuestUpdated = Knit.CreateSignal(), -- (player, quest, progress)
		QuestCompleted = Knit.CreateSignal(), -- (player, quest)
	},
})

-- Player quest state: { currentQuest, progress }
local playerQuestStates = {}

function QuestService:GetCurrentQuest(player)
	return playerQuestStates[player] and playerQuestStates[player].quest
end
function QuestService:LoadPlayerQuest(player)
	local questData = Manager:GetQuestData(player)
	if not questData then
		return
	end

	local quest = QuestsConfig.QuestList[questData.currentQuestId]
	if not quest then
		-- Handle invalid quest ID
		quest = QuestsConfig.QuestList[1]
		Manager:SetCurrentQuest(player, 1)
	end

	return {
		quest = quest,
		progress = questData.progress,
	}
end

function QuestService:UpdateProgress(player, amount)
	local questData = Manager:GetQuestData(player)
	if not questData then
		return
	end

	local newProgress = math.min(questData.progress + amount, QuestsConfig.QuestList[questData.currentQuestId].Required)

	Manager:UpdateQuestProgress(player, newProgress)

	if newProgress >= QuestsConfig.QuestList[questData.currentQuestId].Required then
		self:CompleteQuest(player)
	else
		self.Client.QuestUpdated:Fire(player, QuestsConfig.QuestList[questData.currentQuestId], newProgress)
	end
end

function QuestService:CompleteQuest(player)
	local questData = Manager:GetQuestData(player)
	if not questData then
		return
	end

	local currentQuest = QuestsConfig.QuestList[questData.currentQuestId]

	-- Award rewards
	Manager:AdjustCoins(player, currentQuest.Reward.Coins)
	Manager:AdjustStars(player, currentQuest.Reward.Gems)

	-- Assign next quest
	local nextQuestId = questData.currentQuestId + 1
	if nextQuestId <= #QuestsConfig.QuestList then
		Manager:SetCurrentQuest(player, nextQuestId)
		self.Client.QuestUpdated:Fire(player, QuestsConfig.QuestList[nextQuestId], 0)
	else
		-- Handle final quest completion
		Manager:SetCurrentQuest(player, nil)
	end

	self.Client.QuestCompleted:Fire(player, currentQuest)
end

function QuestService:AssignQuest(player, questId)
	local quest = QuestsConfig.QuestList[questId]
	if not quest then
		return
	end

	playerQuestStates[player] = {
		quest = quest,
		progress = 0,
	}

	self.Client.QuestUpdated:Fire(player, quest, 0)
end

function QuestService:OnFishAdded(player, fish)
	local questData = Manager:GetQuestData(player)
	if not questData then
		return
	end

	local currentQuest = QuestsConfig.QuestList[questData.currentQuestId]

	if currentQuest.Type == "Collection" then
		self:UpdateProgress(player, 1)
	elseif currentQuest.Type == "Specific" and fish.fish == currentQuest.Target then
		self:UpdateProgress(player, 1)
	end
end

-- Connect fishing events
function QuestService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		local questData = Manager:GetQuestData(player)
		while not questData do
			task.wait() -- Wait a frame before checking again
			questData = Manager:GetQuestData(player)
		end

		-- If the data indicates a new player, set the first quest.
		if not questData then
			Manager:SetCurrentQuest(player, 1)
		end

		local state = QuestService:LoadPlayerQuest(player)
		QuestService.Client.QuestUpdated:Fire(player, state.quest, state.progress)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerQuestStates[player] = nil
	end)
end

return QuestService
