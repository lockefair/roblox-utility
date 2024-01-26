local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Event = require(script.Parent.Parent.Event)

type NetworkEvent = {
	className: string,
	new: (name: string, parent: Instance) -> NetworkEvent,
	destroy: (self: NetworkEvent) -> (),
	connect: (self: NetworkEvent, callback: (...any) -> ()) -> EventConnection,
	fireServer: (self: NetworkEvent, ...any) -> (),
	fireClient: (self: NetworkEvent, player: Player, ...any) -> (),
	fireFilteredClients: (self: NetworkEvent, predicate: (player: Player) -> boolean, ...any) -> (),
	fireAllClients: (self: NetworkEvent, ...any) -> ()
}

type _NetworkEvent = NetworkEvent & {
	_name: string,
	_parent: Instance,
	_event: Event.Self,
	_remoteEvent: RemoteEvent?,
	_remoteEventConnection: RBXScriptConnection?
}

--[=[
	@within NetworkEvent
	@interface EventConnection
	@field connected boolean
	@field disconnect () -> ()

	An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `NetworkEvent:connect` method.
	This `EventConnection` object can be used to disconnect the callback from the event.

	```lua
	print(connection.connected) -- true
	connection:disconnect()
	print(connection.connected) -- false
	```
]=]
export type EventConnection = Event.EventConnection

--[=[
	@within NetworkEvent
	@type Self NetworkEvent
]=]
export type Self = NetworkEvent

--[=[
	@within NetworkEvent
	@tag Static
	@prop className string

	Static property that defines the class name `NetworkEvent`
]=]

--[=[
	@class NetworkEvent

	An object that wraps Roblox's remote events. It can be used to fire events between the server and client
	without having to manage remote event instance lifecycles manually – initialization and deinitialization are handled for you.

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
local NetworkEvent: _NetworkEvent = {}
NetworkEvent.__index = NetworkEvent
NetworkEvent.className = "NetworkEvent"

--[=[
	@tag Static

	Constructs a new `NetworkEvent` object. The 'reliable' parameter is defined by the server and ignored by the client.

	@param name string -- The name of the `NetworkEvent` instance which must match on the client and server
	@param parent Instance -- The parent of the `NetworkEvent` instance which must match on the client and server
	@param unreliable boolean? -- Whether or not the event should be reliable. Defaults to `false`
]=]
function NetworkEvent.new(name: string, parent: Instance, unreliable: boolean?): NetworkEvent
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")
	if unreliable ~= nil then
		assert(type(unreliable) == "boolean", "reliable must be a boolean")
	else
		unreliable = false
	end

	local self = setmetatable({
		_name = name,
		_parent = parent,
		_event = Event.new(),
		_remoteEvent = nil,
		_remoteEventConnection = nil
	}, NetworkEvent)

	self:_connectRemoteEvent(unreliable)

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

function NetworkEvent:_connectRemoteEvent(unreliable: boolean)
	if RunService:IsServer() then
		local remoteEvent = self._parent:FindFirstChild(self._name)
		if remoteEvent ~= nil then
			error("NetworkEvent can't create a remote event because an Instance with the name '" .. self._name .. "' already exists in " .. self._parent:GetFullName())
		end

		remoteEvent = if not unreliable then Instance.new("RemoteEvent") else Instance.new("UnreliableRemoteEvent")
		remoteEvent.Name = self._name
		remoteEvent.Parent = self._parent

		self._remoteEventConnection = remoteEvent.OnServerEvent:Connect(function(player, ...)
			self._event:fire(player, ...)
		end)

		self._remoteEvent = remoteEvent
	else
		local remoteEvent: RemoteEvent | UnreliableRemoteEvent = self._parent:WaitForChild(self._name)
		if remoteEvent == nil then
			error("NetworkEvent can't find a remote event with the name '" .. self._name .. "' in " .. self._parent:GetFullName() .. " - A NetworkEvent with matching properties should be initialized on the server first")
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

	@param callback (...any) -> () -- The callback to be called when the event is fired

	:::note
	When connecting on the server, the first argument passed to the callback is always the player that fired the event.
	:::

	```lua
	-- Client
	clientEvent:connect(function(...)
		print("The event fired and passed the values:", ...)
	end)

	-- Server
	serverEvent:connect(function(player, ...)
		print("The event was fired by " .. player .. " and passed the values:", ...)
	end)
	```
]=]
function NetworkEvent:connect(callback: (...any) -> ()): EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	return self._event:connect(callback)
end

--[=[
	@client

	Fires the `NetworkEvent` on the client, passing the given arguments to the server

	@param ... any -- The arguments to pass to the server

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

	@param player Player -- The player to fire the event to
	@param ... any -- The arguments to pass to the client

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

	@param predicate (player: Player) -> boolean -- The predicate to check against each player
	@param ... any -- The arguments to pass to the client

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

	@param ... any -- The arguments to pass to the clients

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

return table.freeze(NetworkEvent)