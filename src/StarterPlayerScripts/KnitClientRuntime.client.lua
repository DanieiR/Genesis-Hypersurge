--Sets up all the client sided controllers for the game
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local StarterPlayerScripts = game:GetService("StarterPlayer").StarterPlayerScripts
for _, v in pairs(StarterPlayerScripts.Source:GetDescendants()) do
	if v:IsA("ModuleScript") then
		require(v)
	end
end
Knit.Start():catch(warn)
