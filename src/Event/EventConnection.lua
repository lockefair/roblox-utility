local Types = require(script.Parent.Types)

type Event = Types.Event
type EventConnection = Types.EventConnection

--[=[
	@within EventConnection
	@type Self EventConnection
]=]
export type Self = EventConnection

--[=[
	@within EventConnection
	@tag Static
	@prop className string
	Static property that defines the class name of the `EventConnection` object
]=]

--[=[
	@within EventConnection
	@prop connected boolean
	Whether or not the `EventConnection` object is connected to the event
]=]

--[=[
	@class EventConnection

	An object that represents a connection to an event

	```lua
	local event = Event.new()
	local connection = event:connect(function(value)
		print("The event fired and passed the value:", value)
	end)
	connection:disconnect()
	```
]=]
local EventConnection = {}
EventConnection.__index = EventConnection
EventConnection.className = "EventConnection"

--[=[
	@tag Static
	@param event Event -- The event to connect to
	@return EventConnection -- An event connection that can be disconnected

	Constructs a new `EventConnection` object

	:::caution
	Do not construct this object manually. Use `Event:connect` instead
	:::
]=]
function EventConnection.new(event: Event): EventConnection
	assert(event ~= nil and type(event) == "table" and event.className == "Event", "event must be an Event")

	local self = setmetatable({
		_event = event,
		connected = true
	}, EventConnection)

	return self
end

--[=[
	Deconstructs the `EventConnection` object
]=]
function EventConnection:destroy()
	self._event = nil
	self.connected = false
end

--[=[
	Disconnects the `EventConnection` object from the event and deconstructs it
]=]
function EventConnection:disconnect()
	if self._event then
		self._event:disconnect(self)
	end
	self.connected = false
end

return table.freeze(EventConnection)