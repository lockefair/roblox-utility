local Types = require(script.Types)
local EventConnection = require(script.EventConnection)

export type Event = Types.Event
export type EventConnection = Types.EventConnection

local Event = {}
Event.__index = Event
Event.className = "Event"

function Event.new(): Types.Event
	local self = setmetatable({
		_BindableEvent = Instance.new("BindableEvent"),
		_BindableEventConnection = nil,
		_Connections = {},
		_Callbacks = {},
		_Value = nil
	}, Event)

	self:_ConnectBindableEvent()

	return self
end

function Event:Destroy()
	for _, connection in pairs(self._Connections) do
		connection:Destroy()
	end
	self._Connections = nil
	self._Callbacks = nil
	self._Value = nil
	self._BindableEventConnection:Disconnect()
	self._BindableEventConnection = nil
	self._BindableEvent:Destroy()
	self._BindableEvent = nil
end

function Event:_ConnectBindableEvent()
	self._BindableEventConnection = self._BindableEvent.Event:Connect(function()
		local value = table.unpack(self._Value)
		for _, connection in pairs(self._Connections) do
			local callback = self._Callbacks[connection]
			callback(value)
		end
	end)
end

function Event:Connect(callback: (...any) -> ()): Types.EventConnection
	local eventConnection = EventConnection.new(self)
	self._Connections[eventConnection] = eventConnection
	self._Callbacks[eventConnection] = callback
	return eventConnection
end

function Event:Disconnect(eventConnection: Types.EventConnection)
	if self._Connections[eventConnection] then
		eventConnection:Destroy()
		self._Connections[eventConnection] = nil
		self._Callbacks[eventConnection] = nil
	end
end

function Event:Fire(...: any)
	self._Value = {...}
	self._BindableEvent:Fire()
end

return Event