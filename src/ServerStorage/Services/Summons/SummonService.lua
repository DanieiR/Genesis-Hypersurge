-- File: ServerStorage/Source/SummonService.lua
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local SummonsConfig = require(game:GetService("ReplicatedStorage").Source.Configs.Summons)
local Manager = require(game:GetService("ServerStorage").Source.Manager)

local SummonService = Knit.CreateService({
	Name = "SummonService",
	Client = {
		SummonResult = Knit.CreateSignal(),
		NotEnoughGems = Knit.CreateSignal(),
		SummonRequest = Knit.CreateSignal(),
	},
})
local lastTimestamp = 0
local counter = 0
local function cloneCharacter(character)
	local clone = {}
	for k, v in pairs(character) do
		clone[k] = v
	end
	return clone
end

function SummonService:GenerateNumericUnitId()
	local timestamp = os.time()
	if timestamp == lastTimestamp then
		counter = counter + 1
	else
		lastTimestamp = timestamp
		counter = 0
	end
	local randomPart = math.random(1000, 9999)
	return tonumber(tostring(timestamp) .. tostring(counter) .. tostring(randomPart))
end

-- Private function to select a random character based on their weights
function SummonService:_GetRandomSummon()
	local totalWeight = 0
	for _, character in ipairs(SummonsConfig.Characters) do
		totalWeight = totalWeight + character.Weight
	end

	local rand = math.random() * totalWeight
	local cumulative = 0

	for _, character in ipairs(SummonsConfig.Characters) do
		cumulative = cumulative + character.Weight
		if rand <= cumulative then
			local newCharacter = cloneCharacter(character)
			newCharacter.ID = self:GenerateNumericUnitId()
			return newCharacter
		end
	end

	-- Fallback in case of rounding errors
	local fallback = cloneCharacter(SummonsConfig.Characters[#SummonsConfig.Characters])
	fallback.ID = self:GenerateNumericUnitId()
	return fallback
end

function SummonService:RequestSummon(player, summonCount)
	local profile = Manager.Profiles[player]

	local cost
	if summonCount == 1 then
		cost = 0
	elseif summonCount == 10 then
		cost = 0
	else
		cost = 0 * summonCount
	end

	if profile.Data.Gems < cost then
		print("Not Enough Gems")
		self.Client.NotEnoughGems:Fire(player)
		return
	end

	Manager.AdjustStars(player, -cost)

	local results = {}
	for i = 1, summonCount do
		local character = self:_GetRandomSummon()
		Manager.AdjustUnits(player, character)
		table.insert(results, character)
	end
	self.Client.SummonResult:Fire(player, results)
end
function SummonService:KnitStart()
	self.Client.SummonRequest:Connect(function(player, SummonCount)
		self:RequestSummon(player, SummonCount)
	end)
end
return SummonService
