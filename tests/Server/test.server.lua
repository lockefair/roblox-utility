local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkEvent = require(ReplicatedStorage.Packages.Connection.NetworkEvent)
local NetworkRequest = require(ReplicatedStorage.Packages.Connection.NetworkRequest)
local NetworkValue = require(ReplicatedStorage.Packages.Connection.NetworkValue)

game.Players.PlayerAdded:Connect(function(player)
	-- NetworkEvent
	local networkEvent = NetworkEvent.new("NetworkEvent", ReplicatedStorage)
	networkEvent:connect(function(player, ...)
		print("The event fired and passed the values:", player, ...)
	end)
	networkEvent:fireAllClients("Hello from the server!")

	-- NetworkRequest
	local networkRequest = NetworkRequest.new("NetworkRequest", ReplicatedStorage)
	networkRequest:setCallback(function(player)
		return "Hello, client!"
	end)

	-- NetworkValue
	local networkValue = NetworkValue.new("NetworkValue", ReplicatedStorage, 0)
end)