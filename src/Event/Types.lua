export type EventConnection = {
	className: string,
	Connected: boolean,
	new: (event: Event) -> EventConnection,
	Destroy: (self: EventConnection) -> (),
	Disconnect: (self: EventConnection) -> ()
}

export type Event = {
	className: string,
	new: () -> Event,
	Destroy: (self: Event) -> (),
	Connect: (self: Event, callback: (...any) -> ()) -> EventConnection,
	Fire: (self: Event, ...any) -> ()
}

return {}