local RunService = game:GetService("RunService")

local Event = require(script.Parent.Parent.Event)
local NetworkEvent = require(script.Parent.NetworkEvent)

type Event = Event.Self

type NetworkValue = {
	className: string,
	changed: Event,
	new: (name: string, parent: Instance, value: any?) -> NetworkValue,
	destroy: (self: NetworkValue) -> (),
	getValue: (self: NetworkValue, player: Player?) -> any?,
	setValue: (self: NetworkValue, value: any?, player: Player?) -> ()
}

--[=[
	@within NetworkValue
	@type Self NetworkValue
]=]
export type Self = NetworkValue

--[=[
	@within NetworkValue
	@prop className string
	@tag Static

	Static property that defines the class name of the `NetworkValue` object
]=]

--[=[
	@within NetworkValue
	@prop changed Event

	Defines the `Event` object that is fired when the value of the `NetworkValue` object changes
]=]

--[=[
	@class NetworkValue

	An object that wraps Roblox's `RemoteEvent` and synchronizes values between the server and client. Values can be set by the server and are automatically
	updated on the client. Values can be set for everybody or for a specific player.

	:::note
	Network values are intended to be paired. A `NetworkValue` object should be initialized on the server first, then on the client,
	otherwise an error will occur.

	Any type of Roblox object such as an Enum, Instance, or others can be passed as a parameter when a `NetworkValue` is updated,
	as well as Luau types such as numbers, strings, and booleans. `NetworkValue` shares its limitations with Roblox's `RemoteEvent` class.
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
local NetworkValue = {}
NetworkValue.__index = NetworkValue
NetworkValue.className = "NetworkValue"

--[=[
	@tag Static

	Constructs a new `NetworkValue` object
]=]
function NetworkValue.new(name: string, parent: Instance, value: any?): NetworkValue
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")
	if value then
		assert(typeof(value) == "number" or typeof(value) == "string" or typeof(value) == "boolean", "value must be a number, string, or boolean")
	end

	local self = setmetatable({
		_value = value,
		_playerValues = {},
		_networkEvent = NetworkEvent.new(name, parent),
		_networkEventConnection = nil,
		changed = Event.new(),
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
	self._networkEventConnection:disconnect()
	self._networkEventConnection = nil
	self._networkEvent:destroy()
	self._networkEvent = nil
	self.changed:destroy()
	self.changed = nil
end

function NetworkValue:_connectNetworkEvent()
	if RunService:IsServer() then
		self._networkEventConnection = self._networkEvent:connect(function(player)
			self._networkEvent:fireClient(player, self._value)
		end)
	else
		self._networkEventConnection = self._networkEvent:connect(function(value)
			self._value = value
			self.changed:fire(value)
		end)
		self._networkEvent:fireServer()
	end
end

--[=[
	Returns the value of the `NetworkValue` object. If called on the server and a player is specified, the value for that specific player is returned.

	:::note
	The player parameter is ignored on the client. The value returned is always the value of the `NetworkValue` object on the server,
	wether that is the global value or the value set specifically for the local player.
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
	if player then
		assert(typeof(player) == "Instance" and player:IsA("Player"), "player must be a Player")
	end

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

	Sets the value of the `NetworkValue` object. If a player is specified, the value for that specific player is set.

	```lua
	local healthValue = NetworkValue.new("PlayerHealth", workspace, 100)

	healthValue:setValue(80)
	healthValue:setValue(50, player1)
	```
]=]
function NetworkValue:setValue(value: any?, player: Player?)
	if player then
		assert(typeof(player) == "Instance" and player:IsA("Player"), "player must be a Player")
	end

	if RunService:IsClient() then
		error("NetworkValue:setValue() should only be called on the server")
	end

	if player then
		self._playerValues[player] = value
		self._networkEvent:fireClient(player, value)
	else
		self._value = value
		self._playerValues = {}
		self._networkEvent:fireAllClients(value)
		self.changed:fire(value)
	end
end

return table.freeze(NetworkValue)