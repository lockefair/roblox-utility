local Types = require(script.Types)
local EventConnection = require(script.EventConnection)

--[=[
	@within Event
	@interface EventConnection
	@field Connected boolean
	@field Disconnect () -> ()
	An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `Event:Connect` method.
	This `EventConnection` object can be used to disconnect the callback from the event. A connection doesn't need to be destroyed after being disconnected.
	
	```lua
	print(connection.Connected) -- true
	connection:Disconnect()
	print(connection.Connected) -- false
	```
]=]
export type EventConnection = Types.EventConnection

--[=[
	@within Event
	@prop className string
]=]
export type Event = Types.Event

--[=[
	@class Event
	A signal implementation that wraps Roblox's BindableEvent

	```lua
	local event = Event.new()
	local connection = event:Connect(function(value)
		print("The event fired and passed the value:", value)
	end)
	event:Fire("Hello, world!")
	connection:Disconnect()
	event:Destroy()
	```
]=]
local Event = {}
Event.__index = Event
Event.className = "Event"

--[=[
	@return Event
	Constructs a new `Event` object
]=]
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

--[=[
	Deconstructs the `Event` object
]=]
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

--[=[
	@param callback (...any) -> ()
	@return EventConnection
	Connects a callback to the event which is invoked when
	the event is fired.

	```lua
	local event = Event.new()
	event:Connect(function(value)
		print("The event fired and passed the value:", value)
	end)
	```
]=]
function Event:Connect(callback: (...any) -> ()): Types.EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	local eventConnection = EventConnection.new(self)
	self._Connections[eventConnection] = eventConnection
	self._Callbacks[eventConnection] = callback

	return eventConnection
end

--[=[
	@param eventConnection EventConnection
	Disconnects a callback from the event.

	:::caution
	This is called automatically when an EventConnection is disconnected.
	It's not necessary to call this manually.
	:::
]=]
function Event:Disconnect(eventConnection: Types.EventConnection)
	assert(eventConnection ~= nil and type(eventConnection) == "table" and eventConnection.className == "EventConnection", "eventConnection must be an EventConnection")

	if self._Connections[eventConnection] then
		eventConnection:Destroy()
		self._Connections[eventConnection] = nil
		self._Callbacks[eventConnection] = nil
	end
end

--[=[
	@param ... any
	Fires the event with the given arguments.

	```lua
	local event = Event.new()
	event:Connect(function(value)
		print("The event fired and passed the value:", value)
	end)
	event:Fire("Hello, world!")
	```
]=]
function Event:Fire(...: any)
	self._Value = {...}
	self._BindableEvent:Fire()
end

table.freeze(Event)

return Event