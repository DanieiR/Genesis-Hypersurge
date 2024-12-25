--Sets up all the Services for the Knit Framework
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local ServerStorage = game:GetService("ServerStorage")
for _, v in pairs(ServerStorage.Source:GetDescendants()) do
	if v:IsA("ModuleScript") then
		require(v)
	end
end
Knit.Start():catch(warn)
