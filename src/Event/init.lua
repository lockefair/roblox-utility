local Types = require(script.Types)
local EventConnection = require(script.EventConnection)

type Event = Types.Event

--[=[
	@within Event
	@interface EventConnection
	@field connected boolean
	@field disconnect () -> ()

	An interface that respresents a connection to an event. An object which conforms to this interface is returned by the `Event:connect` method.
	This `EventConnection` object can be used to disconnect the callback from the event.

	```lua
	print(connection.connected) -- true
	connection:disconnect()
	print(connection.connected) -- false
	```
]=]
export type EventConnection = Types.EventConnection

--[=[
	@within Event
	@type Self Event
]=]
export type Self = Event

--[=[
	@within Event
	@tag Static
	@prop className string

	Static property that defines the class name of the `NetworkEvent` object
]=]

--[=[
	@class Event

	A signal implementation that wraps Roblox's BindableEvent

	```lua
	local event = Event.new()
	local connection = event:connect(function(value)
		print("The event fired and passed the value:", value)
	end)
	event:fire("Hello, world!")
	connection:disconnect()
	event:destroy()
	```
]=]
local Event = {}
Event.__index = Event
Event.className = "Event"

--[=[
	@tag Static

	Constructs a new `Event` object
]=]
function Event.new(): Event
	local self = setmetatable({
		_bindableEvent = Instance.new("BindableEvent"),
		_bindableEventConnection = nil,
		_connections = {},
		_callbacks = {},
		_value = nil
	}, Event)

	self:_connectBindableEvent()

	return self
end

--[=[
	Deconstructs the `Event` object
]=]
function Event:destroy()
	for _, connection in pairs(self._connections) do
		connection:destroy()
	end
	self._connections = nil
	self._callbacks = nil
	self._value = nil
	self._bindableEventConnection:disconnect()
	self._bindableEventConnection = nil
	self._bindableEvent:Destroy()
	self._bindableEvent = nil
end

function Event:_connectBindableEvent()
	self._bindableEventConnection = self._bindableEvent.Event:Connect(function()
		for _, connection in pairs(self._connections) do
			local callback = self._callbacks[connection]
			callback(table.unpack(self._value))
		end
	end)
end

--[=[
	Connects a callback to the event which is invoked when
	the event is fired.

	```lua
	local event = Event.new()
	event:connect(function(...)
		print("The event fired and passed the values:", ...)
	end)
	event:fire(1, 2, 3)
	```
]=]
function Event:connect(callback: (...any) -> ()): EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	local eventConnection = EventConnection.new(self)
	self._connections[eventConnection] = eventConnection
	self._callbacks[eventConnection] = callback

	return eventConnection
end

--[=[
	Disconnects a callback from the event.

	:::caution
	This is called automatically when an EventConnection is disconnected.
	It's not necessary to call this manually.
	:::
]=]
function Event:disconnect(eventConnection: EventConnection)
	assert(eventConnection ~= nil and type(eventConnection) == "table" and eventConnection.className == "EventConnection", "eventConnection must be an EventConnection")

	if self._connections[eventConnection] then
		eventConnection:destroy()
		self._connections[eventConnection] = nil
		self._callbacks[eventConnection] = nil
	end
end

--[=[
	Fires the event with the given arguments.

	```lua
	event:fire("Hello, world!")
	```
]=]
function Event:fire(...: any)
	self._value = {...}
	self._bindableEvent:Fire()
end

table.freeze(Event)

return Event