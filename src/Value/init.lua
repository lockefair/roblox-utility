local Event = require(script.Parent.Event)

type Value<T> = {
	className: string,
	_event: Event.Self,
	_value: T?,
	new: (value: T?) -> Value<T>,
	destroy: (self: Value<T>) -> (),
	observe: (self: Value<T>, callback: (T?) -> ()) -> Event.EventConnection,
	set: (self: Value<T>, value: T?) -> (),
	get: (self: Value<T>) -> T?
}

--[=[
	@within Value
	@interface EventConnection
	@field connected boolean
	@field disconnect () -> ()

	An interface that respresents a connection to a Value. An object which conforms to this interface is returned by the `Value:observe` method.
	This `EventConnection` object can be used to disconnect the callback from the Value

	```lua
	print(connection.connected) -- true
	connection:disconnect()
	print(connection.connected) -- false
	```
]=]
export type EventConnection = Event.EventConnection

--[=[
	@within Value
	@type Self Value
]=]
export type Self<T> = Value<T>

--[=[
	@within Value
	@tag Static
	@prop className string

	Static property that defines the class name of the `Value` object
]=]

--[=[
	@class Value

	A value implementation that can be observed by multiple observers

	```lua
	local value = Value.new(1)
	local connection = Value:observe(function(value)
		print("The value is: ", value)
	end)
	value:set(2)
	connection:disconnect()
	value:destroy()
	```
]=]
local Value = {} :: Value<any>
Value.__index = Value
Value.className = "Value"

--[=[
	@tag Static
	@return Value -- The `Value` object

	Constructs a new `Value` object
]=]
function Value.new<T>(value: T?): Value<T>
	local self = setmetatable({
		_event = Event.new(),
		_value = value
	}, Value)

	return self
end

--[=[
	Deconstructs the `Value` object
]=]
function Value:destroy()
	self._event:destroy()
	self._event = nil
	self._value = nil
end

--[=[
	@param callback (T?) -> () -- The callback to be invoked when the value is changed
	@return EventConnection -- An event connection that can be disconnected

	Connects a callback to the Value which is invoked once upon connection and then whenever the value is changed

	```lua
	local value = Value.new(1)
	value:observe(function(value: number?)
		print("The value is: ", value)
	end)
	```
]=]
function Value:observe<T>(callback: (T?) -> ()): EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	local connection = self._event:connect(callback)

	callback(self._value)

	return connection
end

--[=[
	@param value T? -- The new value

	Sets the new value and updates any observers

	```lua
	local value = Value.new(1)
	value:set(2)
	```
]=]
function Value:set<T>(value: T?)
	self._value = value
	self._event:fire(value)
end

--[=[
	@return T? -- The current value

	Returns the current value

	```lua
	local value = Value.new(1)
	print(value:get()) -- 1
	```
]=]
function Value:get<T>(): T?
	return self._value
end

return Value