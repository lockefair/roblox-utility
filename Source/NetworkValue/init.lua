local RunService = game:GetService("RunService")

local Event = require(script.Parent.Event)
local NetworkEvent = require(script.Parent.NetworkEvent)

export type NetworkValue = {
	className: string,
	ValueChanged: Event.Event,
	new: (name: string, parent: Instance, value: any?) -> NetworkValue,
	Destroy: (self: NetworkValue) -> (),
	GetValue: (self: NetworkValue, player: Player?) -> any?,
	SetValue: (self: NetworkValue, value: any?, player: Player?) -> ()
}

local NetworkValue = {}
NetworkValue.__index = NetworkValue
NetworkValue.className = "NetworkValue"

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