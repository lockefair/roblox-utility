local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = require(ReplicatedStorage.Packages.Event)
local NetworkEvent = require(ReplicatedStorage.Packages.Connection.NetworkEvent)
local NetworkRequest = require(ReplicatedStorage.Packages.Connection.NetworkRequest)
local NetworkValue = require(ReplicatedStorage.Packages.Connection.NetworkValue)

-- Event
local event = Event.new()
local connection = event:connect(function(...)
	print("The event fired and passed the value:", ...)
end)
event:fire(1, 2, 3)
print(connection.connected)
connection:disconnect()
print(connection.connected)
event:destroy()

-- NetworkEvent
local networkEvent = NetworkEvent.new("NetworkEvent", ReplicatedStorage)
networkEvent:connect(function(...)
	print("The event fired and passed the value:", ...)
end)
networkEvent:fireServer("Hello from the client!")

-- NetworkRequest
local networkRequest = NetworkRequest.new("NetworkRequest", ReplicatedStorage)
print(networkRequest:invoke())

-- NetworkValue
local networkValue = NetworkValue.new("NetworkValue", ReplicatedStorage)
networkValue:connect(function(value)
	print("The value changed to:", value)
end)