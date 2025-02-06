local Players = game:GetService("Players")

-- Define allowed player IDs
local Allowed = {
	[25904570] = true,
}

-- Define group information
local GroupId = 35334161 -- Genesis Games: HyperSurge
local RequiredRank = 247 -- Tester Rank

Players.PlayerAdded:Connect(function(player)
	-- Check if the player is in the allowed list
	if Allowed[player.UserId] then
		print(player.Name .. " is allowed (specific ID)")
		return
	end

	-- Check if the player is in the specified group and has the required rank
	if player:IsInGroup(GroupId) then
		local rank = player:GetRankInGroup(GroupId)
		if rank >= RequiredRank then
			print(player.Name .. " is allowed (group and rank)")
			return
		end
	end

	-- If neither condition is met, you can kick the player or handle it otherwise
	print(player.Name .. " is not allowed")
	player:Kick("You are not permitted to join this game.")
end)
