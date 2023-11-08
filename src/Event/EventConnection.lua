local Types = require(script.Parent.Types)

--[=[
	@within EventConnection
	@prop className string
	Static property that defines the class name of the `NetworkEvent` object
]=]

--[=[
	@within EventConnection
	@prop Connected boolean
	Whether or not the `EventConnection` object is connected to the event
]=]
export type EventConnection = Types.EventConnection

--[=[
	@class EventConnection
	An object that represents a connection to an event

	```lua
	local event = Event.new()
	local connection = event:Connect(function(value)
		print("The event fired and passed the value:", value)
	end)
	connection:Disconnect()
	```
]=]
local EventConnection = {}
EventConnection.__index = EventConnection
EventConnection.className = "EventConnection"

--[=[
	@return Event
	@param event Event

	Constructs a new `EventConnection` object

	:::caution
	Do not construct this object manually. Use `Event:Connect` instead.
	:::
]=]
function EventConnection.new(event: Types.Event): Types.EventConnection
	assert(event ~= nil and type(event) == "table" and event.className == "Event", "event must be an Event")

	local self = setmetatable({
		_Event = event,
		Connected = true
	}, EventConnection)

	return self
end

--[=[
	Deconstructs the `EventConnection` object
]=]
function EventConnection:Destroy()
	self._Event = nil
	self.Connected = nil
end

--[=[
	Disconnects the `EventConnection` object from the event and deconstructs it
]=]
function EventConnection:Disconnect()
	if self._Event then
		self._Event:Disconnect(self)
	end
	self.Connected = false
end

table.freeze(EventConnection)

return EventConnection