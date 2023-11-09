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
	connect: (self: Event, callback: (value: any) -> ()) -> EventConnection,
	fire: (self: Event, value: any) -> ()
}

return {}