local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RodsController = Knit.CreateController({
	Name = "RodsController",
})

local PlayerGUI = Players.LocalPlayer.PlayerGui
local BuyConfirmation = PlayerGUI:WaitForChild("Confirmations").Main.BuyConfirmation
local connection
function RodsController:_ShowConfirmationUI(rod)
	BuyConfirmation.Visible = true
	BuyConfirmation.SellText.Text = "Buy " .. rod.Name .. " For " .. rod.Price.Value .. " Gold?"
	connection = BuyConfirmation.Buttons.Sell.MouseButton1Click:Connect(function()
		BuyConfirmation.Visible = false
		local RodsMarket = Knit.GetService("RodsMarket")
		RodsMarket.InitiateBuyConfirmation:Fire(rod)
		connection:Disconnect()
	end)
	BuyConfirmation.Buttons.Cancel.MouseButton1Click:Connect(function()
		BuyConfirmation.Visible = false
	end)
end

function RodsController:KnitStart()
	local RodsMarket = Knit.GetService("RodsMarket")
	RodsMarket.InitiateBuyConfirmation:Connect(function(rod)
		self:_ShowConfirmationUI(rod)
	end)
end

return RodsController
