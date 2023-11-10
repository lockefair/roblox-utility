local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Event = require(script.Parent.Packages.Event)

type NetworkEvent = {
	className: string,
	new: (name: string, parent: Instance) -> NetworkEvent,
	destroy: (self: NetworkEvent) -> (),
	connect: (self: NetworkEvent, callback: (...any) -> ()) -> Event.EventConnection,
	fireServer: (self: NetworkEvent, ...any) -> (),
	fireClient: (self: NetworkEvent, player: Player, ...any) -> (),
	fireFilteredClients: (self: NetworkEvent, predicate: (player: Player) -> boolean, ...any) -> (),
	fireAllClients: (self: NetworkEvent, ...any) -> ()
}

--[=[
	@within NetworkEvent
	@type Self NetworkEvent
]=]
export type Self = NetworkEvent

--[=[
	@within NetworkEvent
	@tag Static
	@prop className string

	Static property that defines the class name of the `NetworkEvent` object
]=]

--[=[
	@class NetworkEvent

	An object that wraps Roblox's `RemoteEvent`. It can be used to fire events between the server and client
	without having to manage `RemoteEvent` lifecycles manually – initialization and deinitialization are handled for you.

	:::note
	Network events are intended to be paired. A `NetworkEvent` object should be initialized on the server first, then on the client,
	otherwise an error will occur.

	Any type of Roblox object such as an Enum, Instance, or others can be passed as a parameter when a `NetworkEvent` is fired,
	as well as Luau types such as numbers, strings, and booleans. `NetworkEvent` shares its limitations with Roblox's `RemoteEvent` class.
	:::

	```lua
	-- Server
	local serverEvent = NetworkEvent.new("MyNetworkEvent", workspace)

	-- Client
	local clientEvent = NetworkEvent.new("MyNetworkEvent", workspace)
	clientEvent:connect(function(...)
		print("The event fired and passed the values:", ...) -- 1, 2, 3
	end)

	-- Server
	serverEvent:fireClient(player, 1, 2, 3)
	```
]=]
local NetworkEvent = {}
NetworkEvent.__index = NetworkEvent
NetworkEvent.className = "NetworkEvent"

--[=[
	@tag Static

	Constructs a new `NetworkEvent` object
]=]
function NetworkEvent.new(name: string, parent: Instance): NetworkEvent
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")

	local self = setmetatable({
		_name = name,
		_parent = parent,
		_event = Event.new(),
		_remoteEvent = nil,
		_remoteEventConnection = nil
	}, NetworkEvent)

	self:_connectRemoteEvent()

	return self
end

--[=[
	Deconstructs the `NetworkEvent` object
]=]
function NetworkEvent:destroy()
	self._name = nil
	self._parent = nil
	self._event:destroy()
	self._event = nil
	if self._remoteEventConnection then
		self._remoteEventConnection:Disconnect()
		self._remoteEventConnection = nil
	end
	if RunService:IsServer() and self._remoteEvent then
		self._remoteEvent:Destroy()
	end
	self._remoteEvent = nil
end

function NetworkEvent:_connectRemoteEvent()
	if RunService:IsServer() then
		local remoteEvent = self._parent:FindFirstChild(self._name)
		if remoteEvent ~= nil then
			error("NetworkEvent can't create a RemoteEvent because an Instance with the name '" .. self._name .. "' already exists in " .. self._parent:GetFullName())
		end

		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = self._name
		remoteEvent.Parent = self._parent

		self._remoteEventConnection = remoteEvent.OnServerEvent:Connect(function(player, ...)
			self._event:fire(player, ...)
		end)

		self._remoteEvent = remoteEvent
	else
		local remoteEvent: RemoteEvent = self._parent:FindFirstChild(self._name)
		if remoteEvent == nil then
			error("NetworkEvent can't find a RemoteEvent with the name '" .. self._name .. "' in " .. self._parent:GetFullName() .. " - A NetworkEvent with matching properties should be initialized on the server first")
		end

		self._remoteEventConnection = remoteEvent.OnClientEvent:Connect(function(...)
			self._event:fire(...)
		end)

		self._remoteEvent = remoteEvent
	end
end

--[=[
	Connects a callback to the `NetworkEvent` which is invoked when
	the event is fired.

	```lua
	clientEvent:connect(function(...)
		print("The event fired and passed the values:", ...)
	end)
	```
]=]
function NetworkEvent:connect(callback: (...any) -> ()): Event.EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	return self._event:connect(callback)
end

--[=[
	@client

	Fires the `NetworkEvent` on the client, passing the given arguments to the server

	```lua
	event:fireServer("Hello, server!")
	```
]=]
function NetworkEvent:fireServer(...: any)
	if RunService:IsServer() then
		error("NetworkEvent:fireServer() called on the server")
	end

	self._remoteEvent:fireServer(...)
end

--[=[
	@server

	Fires the `NetworkEvent` on the server, passing the given arguments to the players client

	```lua
	event:fireClient(player, "Hello, client!")
	```
]=]
function NetworkEvent:fireClient(player: Player, ...: any)
	assert(player ~= nil and player:IsA("Player"), "player must be a Player")

	if RunService:IsClient() then
		error("NetworkEvent:fireClient() called on the client")
	end

	self._remoteEvent:fireClient(player, ...)
end

--[=[
	@server

	Fires the `NetworkEvent` on the server, passing the given arguments to player clients that pass the given predicate check

	```lua
	event:fireFilteredClients(function(player)
		return player.Team == game.Teams.Heroes
	end, "You win!")
	```
]=]
function NetworkEvent:fireFilteredClients(predicate: (player: Player) -> boolean, ...: any)
	assert(predicate ~= nil and type(predicate) == "function", "predicate must be a function")

	if RunService:IsClient() then
		error("NetworkEvent:fireFilteredClients() called on the client")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player) then
			self._remoteEvent:fireClient(player, ...)
		end
	end
end

--[=[
	@server

	Fires the `NetworkEvent` on the server, passing the given arguments to all clients

	```lua
	event:fireAllClients(1, 2, 3)
	```
]=]
function NetworkEvent:fireAllClients(...: any)
	if RunService:IsClient() then
		error("NetworkEvent:fireAllClients() called on the client")
	end

	self._remoteEvent:fireAllClients(...)
end

table.freeze(NetworkEvent)

return NetworkEvent