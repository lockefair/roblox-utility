local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = require(ReplicatedStorage.Packages.Event)
local NetworkEvent = require(ReplicatedStorage.Packages.Connection.NetworkEvent)
local NetworkValue = require(ReplicatedStorage.Packages.Connection.NetworkValue)

-- Event
-- local event = Event.new()
-- local connection = event:connect(function(...)
-- 	print("The event fired and passed the value:", ...)
-- end)
-- event:fire(1, 2, 3)
-- print(connection.connected)
-- connection:disconnect()
-- print(connection.connected)
-- event:destroy()

-- local re: RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
-- re.OnClientEvent:Connect(function(...)
-- 	print("The remote event:", ...)
-- end)

--- NetworkEvent
print("setup connection")
-- local networkEvent = NetworkEvent.new("MyNetworkEvent", ReplicatedStorage)
-- local connection = networkEvent:connect(function(...)
-- 	print("The server fired the event and passed the values:", ...)
-- end)
-- task.wait(1)
-- networkEvent:fireServer(1, 2, 3)


local networkValue = NetworkValue.new("MyNetworkValue", ReplicatedStorage)
local connection = networkValue:connect(function(value)
	print("The value changed to:", value)
end)