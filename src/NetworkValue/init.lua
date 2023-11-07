local RunService = game:GetService("RunService")

local Event = require(script.Parent.Event)
local NetworkEvent = require(script.Parent.NetworkEvent)

--[=[
	@within NetworkValue
	@prop className string
]=]
export type NetworkValue = {
	className: string,
	ValueChanged: Event.Event,
	new: (name: string, parent: Instance, value: any?) -> NetworkValue,
	Destroy: (self: NetworkValue) -> (),
	GetValue: (self: NetworkValue, player: Player?) -> any?,
	SetValue: (self: NetworkValue, value: any?, player: Player?) -> ()
}

--[=[
	@class NetworkValue
	An object that wraps Roblox's `RemoteEvent` and synchronizes values between the server and client. Values can be set by the server and are automatically
	updated on the client. Values can be set for everybody or for a specific player.

	:::note
	Network values are intended to be paired. A `NetworkValue` object should be initialized on the server first, then on the client,
	otherwise an error will occur.
	:::

	```lua
	-- Server
	local serverHealthValue = NetworkValue.new("PlayerHealth", workspace, 100)

	-- Client
	local clientHealthValue = NetworkValue.new("PlayerHealth", workspace)

	print("The players health is:", clientHealthValue:GetValue()) -- 100
	clientHealthValue.ValueChanged:Connect(function(value)
		print("The players health changed to:", value)
	end)
	```
]=]
local NetworkValue = {}
NetworkValue.__index = NetworkValue
NetworkValue.className = "NetworkValue"

--[=[
	@return NetworkValue
	Constructs a new `NetworkValue` object
]=]
function NetworkValue.new(name: string, parent: Instance, value: any?): NetworkValue
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")
	if value then
		assert(typeof(value) == "number" or typeof(value) == "string" or typeof(value) == "boolean", "value must be a number, string, or boolean")
	end

	local self = setmetatable({
		_Value = value,
		_PlayerValues = {},
		_NetworkEvent = NetworkEvent.new(name, parent),
		_NetworkEventConnection = nil,
		ValueChanged = Event.new(),
	}, NetworkValue)

	self:_ConnectNetworkEvent()

	return self
end

--[=[
	Deconstructs the `NetworkValue` object
]=]
function NetworkValue:Destroy()
	self._Value = nil
	self._PlayerValues = nil
	self._NetworkEventConnection:Disconnect()
	self._NetworkEventConnection = nil
	self._NetworkEvent:Destroy()
	self._NetworkEvent = nil
	self.ValueChanged:Destroy()
	self.ValueChanged = nil
end

function NetworkValue:_ConnectNetworkEvent()
	if RunService:IsServer() then
		self._NetworkEventConnection = self._NetworkEvent:Connect(function(player)
			self._NetworkEvent:FireClient(player, self._Value)
		end)
	else
		self._NetworkEventConnection = self._NetworkEvent:Connect(function(value)
			self._Value = value
			self.ValueChanged:Fire(value)
		end)
		self._NetworkEvent:FireServer()
	end
end

--[=[
	@param player Player?
	@return any?
	Returns the value of the `NetworkValue` object. If called on the server and a player is specified, the value for that specific player is returned. The player
	parameter is ignored on the client.

	```lua
	-- Server
	local serverHealthValue = NetworkValue.new("PlayerHealth", workspace, 100)

	serverHealthValue:SetValue(80)
	serverHealthValue:SetValue(50, player1)

	serverHealthValue:GetValue() -- 80
	serverHealthValue:GetValue(player1) -- 50

	-- Player1 Client
	local clientHealthValue = NetworkValue.new("PlayerHealth", workspace)
	clientHealthVlaue:GetValue() -- 50

	-- Other Client(s)
	local clientHealthValue = NetworkValue.new("PlayerHealth", workspace)
	clientHealthVlaue:GetValue() -- 80
	```
]=]
function NetworkValue:GetValue(player: Player?): any?
	if player then
		assert(typeof(player) == "Instance" and player:IsA("Player"), "player must be a Player")
	end

	if RunService:IsClient() then
		return self._Value
	elseif player then
		for playerKey, playerValue in pairs(self._PlayerValues) do
			if player == playerKey then
				return playerValue
			end
		end
		return self._Value
	else
		return self._Value
	end
end

--[=[
	@server
	@param value any?
	@param player Player?
	Sets the value of the `NetworkValue` object. If a player is specified, the value for that specific player is set.

	```lua
	local healthValue = NetworkValue.new("PlayerHealth", workspace, 100)

	healthValue:SetValue(80)
	healthValue:SetValue(50, player1)
	```
]=]
function NetworkValue:SetValue(value: any?, player: Player?)
	if player then
		assert(typeof(player) == "Instance" and player:IsA("Player"), "player must be a Player")
	end

	if RunService:IsClient() then
		error("NetworkValue:setValue() should only be called on the server")
	end

	if player then
		self._PlayerValues[player] = value
		self._NetworkEvent:FireClient(player, value)
	else
		self._Value = value
		self._PlayerValues = {}
		self._NetworkEvent:FireAllClients(value)
		self.ValueChanged:Fire(value)
	end
end

return NetworkValue