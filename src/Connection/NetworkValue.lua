local RunService = game:GetService("RunService")

local Event = require(script.Parent.Parent.Event)
local NetworkEvent = require(script.Parent.NetworkEvent)

type NetworkValue = {
	className: string,
	destroying: Event.Self,
	new: (name: string, parent: Instance, value: any?) -> NetworkValue,
	destroy: (self: NetworkValue) -> (),
	connect: (self: NetworkValue, callback: (value: any?) -> ()) -> EventConnection,
	getValue: (self: NetworkValue, player: Player?) -> any?,
	setValue: (self: NetworkValue, value: any?, player: Player?) -> ()
}

type _NetworkValue = NetworkValue & {
	_value: any?,
	_playerValues: {[Player]: any},
	_destroyingConnection: RBXScriptConnection?,
	_networkEventConnection: EventConnection,
	_networkEvent: NetworkEvent.Self,
	_changed: Event.Self
}

--[=[
	@within NetworkValue
	@interface EventConnection
	@field connected boolean
	@field disconnect () -> ()

	An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `NetworkValue:connect` method.
	This `EventConnection` object can be used to disconnect the callback from the event

	```lua
	print(connection.connected) -- true
	connection:disconnect()
	print(connection.connected) -- false
	```
]=]
export type EventConnection = Event.EventConnection

--[=[
	@within NetworkValue
	@type Self NetworkValue
]=]
export type Self = NetworkValue

--[=[
	@within NetworkValue
	@prop className string
	@tag Static

	Static property that defines the class name `NetworkValue`
]=]

--[=[
	@within NetworkValue
	@prop destroying Event

	An event that fires when the `NetworkValue` is destroyed
]=]

--[=[
	@class NetworkValue

	An object that wraps Roblox's remote events and synchronizes values between the server and client. Values can be set by the server and are automatically
	updated on the client. Values can be set for everybody or for a specific player

	:::note
	Network requests are intended to be paired. A `NetworkValue` object should be initialized on the server first and then on the client,
	otherwise, an error will occur. Attempting to call a method on a `NetworkValue` after its server-side counterpart has been destroyed
	will result in a warning

	Any type of Roblox object such as an `Enum`, `Instance`, or others can be passed as a parameter when a `NetworkValue` is fired,
	as well as Luau types such as `number`, `string`, and `boolean`. `NetworkValue` shares its limitations with Roblox's `RemoteEvent` class
	:::

	```lua
	-- Server
	local serverValue = NetworkValue.new("PlayerHealth", workspace, 100)

	-- Client
	local clientValue = NetworkValue.new("PlayerHealth", workspace)

	print("The players health is:", clientValue:getValue()) -- 100
	clientValue.changed:connect(function(value)
		print("The players health changed to:", value)
	end)
	```
]=]
local NetworkValue: _NetworkValue = {}
NetworkValue.__index = NetworkValue
NetworkValue.className = "NetworkValue"

--[=[
	@tag Static
	@param name string -- The name of the `NetworkValue` instance which must match on the client and server
	@param parent Instance -- The parent of the `NetworkValue` instance
	@param value any? -- An optional initial value of the `NetworkValue` instance

	Constructs a new `NetworkValue` object
]=]
function NetworkValue.new(name: string, parent: Instance, value: any?): NetworkValue
	assert(name ~= nil and type(name) == "string", "Argument #1 must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "Argument #2 must be an Instance")

	local self = setmetatable({
		_value = value,
		_playerValues = {},
		_destroyingConnection = nil,
		_networkEventConnection = nil,
		_networkEvent = NetworkEvent.new(name, parent),
		_changed = Event.new(),
		destroying = Event.new()
	}, NetworkValue)

	self:_connectNetworkEvent()

	return self
end

--[=[
	Deconstructs the `NetworkValue` object
]=]
function NetworkValue:destroy()
	self._value = nil
	self._playerValues = nil
	if self._destroyingConnection then
		self._destroyingConnection:Disconnect()
		self._destroyingConnection = nil
	end
	if self._networkEventConnection then
		self._networkEventConnection:disconnect()
		self._networkEventConnection = nil
	end
	if self._networkEvent then
		self._networkEvent:destroy()
		self._networkEvent = nil
	end
	if self._changed then
		self._changed:destroy()
		self._changed = nil
	end
	if self.destroying then
		self.destroying:destroy()
		self.destroying = nil
	end
end

function NetworkValue:_connectNetworkEvent()
	if RunService:IsServer() then
		self._networkEventConnection = self._networkEvent:connect(function(player)
			self._networkEvent:fireClient(player, self._value)
		end)
	else
		self._networkEventConnection = self._networkEvent:connect(function(value)
			self._value = value
			self._changed:fire(value)
		end)
		self._networkEvent:fireServer()
	end

	self._destroyingConnection = self._networkEvent.destroying:connect(function()
		self.destroying:fire()
		self:destroy()
	end)
end

--[=[
	@param callback (value: any?, player: Player?) -> () -- The callback to be invoked when the `NetworkValue` object's value changes

	Connects a callback that's invoked when the `NetworkValue` object's value changes. If the `NetworkValue` object is on the server and
	a player is specified, then that value has been set specifically for that player, otherwise, the shared value was set

	```lua
	local healthValue = NetworkValue.new("PlayerHealth", ReplicatedStorage, 100)

	local connection = healthValue:connect(function(value, player)
		print("The players health changed to:", value)
	end)
	```
]=]
function NetworkValue:connect(callback: (value: any?, player: Player?) -> ()): EventConnection
	assert(callback ~= nil and type(callback) == "function", "Argument #1 must be a function")

	return self._changed:connect(callback)
end

--[=[
	@param player Player? -- An optional player to get the value for

	Returns the value of the `NetworkValue` object. If called on the server and a player is specified the value for that specific player is returned

	:::note
	The player parameter is ignored on the client. The value returned is always the value of the `NetworkValue` object on the server,
	wether that is the shared value or the value set specifically for the local player
	:::

	```lua
	-- Server
	serverValue:setValue(80)
	serverValue:setValue(50, player1)

	serverValue:getValue() -- 80
	serverValue:getValue(player1) -- 50

	-- Player1 Client
	clientValue:getValue() -- 50

	-- Other Client(s)
	clientValue:getValue() -- 80
	```
]=]
function NetworkValue:getValue(player: Player?): any?
	assert(player == nil or typeof(player) == "Instance" and player:IsA("Player"), "Argument #1 must be a Player or nil")

	if RunService:IsClient() then
		return self._value
	elseif player then
		for playerKey, playerValue in pairs(self._playerValues) do
			if player == playerKey then
				return playerValue
			end
		end
		return self._value
	else
		return self._value
	end
end

--[=[
	@server
	@param value any? -- The value to set
	@param player Player? -- An optional player to set the value for

	Sets the value of the `NetworkValue` object. If a player is specified, the value for that specific player is set, otherwise, a shared value
	is set for all clients

	```lua
	local healthValue = NetworkValue.new("PlayerHealth", workspace, 100)

	healthValue:setValue(80)
	healthValue:setValue(50, player1)
	```
]=]
function NetworkValue:setValue(value: any?, player: Player?)
	if RunService:IsClient() then
		error("NetworkValue:setValue() should only be called on the server", 2)
	end

	assert(player == nil or typeof(player) == "Instance" and player:IsA("Player"), "Argument #2 must be a Player or nil")

	if player then
		self._playerValues[player] = value
		self._networkEvent:fireClient(player, value)
		self._changed:fire(value, player)
	else
		self._value = value
		table.clear(self._playerValues)
		self._networkEvent:fireAllClients(value)
		self._changed:fire(value)
	end
end

return table.freeze(NetworkValue)