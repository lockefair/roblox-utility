local Types = require(script.Parent.Types)

export type EventConnection = Types.EventConnection

local EventConnection = {}
EventConnection.__index = EventConnection
EventConnection.className = "EventConnection"

function EventConnection.new(event: Types.Event): Types.EventConnection
	local self = setmetatable({
		_Event = event,
	}, EventConnection)
	return self :: Types.EventConnection
end

function EventConnection:Destroy()
	self._Event = nil
end

function EventConnection:Disconnect()
	if self._Event then
		self._Event:Disconnect(self)
	end
end

table.freeze(EventConnection)

return EventConnection