export type EventConnection = {
	className: string,
	connected: boolean,
	new: (event: Event) -> EventConnection,
	destroy: (self: EventConnection) -> (),
	disconnect: (self: EventConnection) -> ()
}

export type Event = {
	className: string,
	new: () -> Event,
	destroy: (self: Event) -> (),
	connect: (self: Event, callback: (...any) -> ()) -> EventConnection,
	fire: (self: Event, ...any) -> ()
}

return table.freeze({})