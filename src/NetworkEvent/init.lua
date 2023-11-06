local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Event = require(script.Parent.Event)

--[=[
	@within NetworkEvent
	@interface EventConnection
	@field Connected boolean
	@field Disconnect () -> ()
	An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `NetworkEvent:Connect` method.
]=]
export type EventConnection = Event.EventConnection

--[=[
	@within NetworkEvent
	@prop className string
]=]
export type NetworkEvent = {
	className: string,
	new: (name: string, parent: Instance) -> NetworkEvent,
	Destroy: (self: NetworkEvent) -> (),
	Connect: (self: NetworkEvent, callback: (...any) -> ()) -> Event.EventConnection,
	FireServer: (self: NetworkEvent, ...any) -> (),
	FireClient: (self: NetworkEvent, player: Player, ...any) -> (),
	FireFilteredClients: (self: NetworkEvent, predicate: (player: Player) -> boolean, ...any) -> (),
	FireAllClients: (self: NetworkEvent, ...any) -> ()
}

--[=[
	@class NetworkEvent
	An object that wraps Roblox's `RemoteEvent`. It can be used to fire events between the server and client
	without having to manage `RemoteEvent` lifecycles manually – initialization and deinitialization are handled for you.

	:::note
	Network events are intended to be paired. A `NetworkEvent` object should be initialized on the server first, then on the client, otherwise an error will occur.
	:::

	```lua
	-- Server
	local serverEvent = NetworkEvent.new("MyNetworkEvent", workspace)

	-- Client
	local clientEvent = NetworkEvent.new("MyNetworkEvent", workspace)
	clientEvent:Connect(function(...)
		print("The event fired and passed the values:", ...) -- 1, 2, 3
	end)

	-- Server
	serverEvent:FireClient(player, 1, 2, 3)
	```
]=]
local NetworkEvent = {}
NetworkEvent.__index = NetworkEvent
NetworkEvent.className = "NetworkEvent"

--[=[
	@return NetworkEvent
	Constructs a new `NetworkEvent` object
]=]
function NetworkEvent.new(name: string, parent: Instance): NetworkEvent
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")

	local self = setmetatable({
		_Name = name,
		_Parent = parent,
		_Event = Event.new(),
		_RemoteEvent = nil,
		_RemoteEventConnection = nil
	}, NetworkEvent)

	self:_ConnectRemoteEvent()

	return self
end

--[=[
	Deconstructs the `NetworkEvent` object
]=]
function NetworkEvent:Destroy()
	self._Name = nil
	self._Parent = nil
	self._Event:Destroy()
	self._Event = nil
	if self._RemoteEventConnection then
		self._RemoteEventConnection:Disconnect()
		self._RemoteEventConnection = nil
	end
	if RunService:IsServer() and self._RemoteEvent then
		self._RemoteEvent:Destroy()
	end
	self._RemoteEvent = nil
end

function NetworkEvent:_ConnectRemoteEvent()
	if RunService:IsServer() then
		local remoteEvent = self._Parent:FindFirstChild(self._Name)
		if remoteEvent ~= nil then
			error("NetworkEvent can't create a RemoteEvent because an Instance with the name '" .. self._Name .. "' already exists in " .. self._Parent:GetFullName())
		end

		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = self._Name
		remoteEvent.Parent = self._Parent

		self._RemoteEventConnection = remoteEvent.OnServerEvent:Connect(function(player, ...)
			self._Event:Fire(player, ...)
		end)

		self._RemoteEvent = remoteEvent
	else
		local remoteEvent: RemoteEvent = self._Parent:FindFirstChild(self._Name)
		if remoteEvent == nil then
			error("NetworkEvent can't find a RemoteEvent with the name '" .. self._Name .. "' in " .. self._Parent:GetFullName() .. " - A NetworkEvent with matching properties should be initialized on the server first")
		end

		self._RemoteEventConnection = remoteEvent.OnClientEvent:Connect(function(...)
			self._Event:Fire(...)
		end)

		self._RemoteEvent = remoteEvent
	end
end

--[=[
	@return EventConnection
	Connects a callback to the `NetworkEvent` which is invoked when
	the event is fired.
]=]
function NetworkEvent:Connect(callback: (...any) -> ()): Event.EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	return self._Event:Connect(callback)
end

--[=[
	@client
	Fires the `NetworkEvent` on the client, passing the given arguments to the server

	```lua
	event:FireServer("Hello, World!")
	```
]=]
function NetworkEvent:FireServer(...: any)
	if RunService:IsServer() then
		error("FireServer(...) called on the server")
	end

	self._RemoteEvent:FireServer(...)
end

--[=[
	@server
	Fires the `NetworkEvent` on the server, passing the given arguments to the players client

	```lua
	event:FireClient(player, "Hello, World!")
	```
]=]
function NetworkEvent:FireClient(player: Player, ...: any)
	assert(player ~= nil and player:IsA("Player"), "player must be a Player")

	if RunService:IsClient() then
		error("FireClient(player, ...) called on the client")
	end

	self._RemoteEvent:FireClient(player, ...)
end

--[=[
	@server
	Fires the `NetworkEvent` on the server, passing the given arguments to player clients that pass the given predicate check

	```lua
	event:FireFilteredClients(function(player)
		return player.Team == game.Teams.Heroes
	end, "Hello, World!")
	```
]=]
function NetworkEvent:FireFilteredClients(predicate: (player: Player) -> boolean, ...: any)
	assert(predicate ~= nil and type(predicate) == "function", "predicate must be a function")

	if RunService:IsClient() then
		error("FireFilteredClients(predicate, ...) called on the client")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player) then
			self._RemoteEvent:FireClient(player, ...)
		end
	end
end

--[=[
	@server
	Fires the `NetworkEvent` on the server, passing the given arguments to all clients

	```lua
	event:FireAllClients("Hello, World!")
	```
]=]
function NetworkEvent:FireAllClients(...: any)
	if RunService:IsClient() then
		error("FireAllClients(...) called on the client")
	end

	self._RemoteEvent:FireAllClients(...)
end

table.freeze(NetworkEvent)

return NetworkEvent