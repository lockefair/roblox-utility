local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetworkEvent = require(ReplicatedStorage.Packages.Connection.NetworkEvent)
local NetworkValue = require(ReplicatedStorage.Packages.Connection.NetworkValue)

game.Players.PlayerAdded:Connect(function(player)
	-- local re = Instance.new("RemoteEvent")
	-- re.Parent = ReplicatedStorage
	--re:FireAllClients(4, 5, 6)
	-- task.wait(1)

	--- NetworkEvent
	-- local networkEvent = NetworkEvent.new("MyNetworkEvent", ReplicatedStorage)
	-- networkEvent:fireAllClients(player, 1, 2, 3)
	-- task.wait(1)
	-- networkEvent:destroy()

	local networkValue = NetworkValue.new("MyNetworkValue", ReplicatedStorage, 1)
	task.wait(2)
	networkValue:destroy()
end)