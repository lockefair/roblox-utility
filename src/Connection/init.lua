local NetworkEvent = require(script.NetworkEvent)
local NetworkRequest = require(script.NetworkRequest)
local NetworkValue = require(script.NetworkValue)

--[=[
	@within Connection
	@type NetworkEvent NetworkEvent
]=]
export type NetworkEvent = NetworkEvent.Self

--[=[
	@within Connection
	@type NetworkRequest NetworkRequest
]=]
export type NetworkRequest = NetworkRequest.Self

--[=[
	@within Connection
	@type NetworkValue NetworkValue
]=]
export type NetworkValue = NetworkValue.Self

--[=[
	@class Connection

	The `Connection` package provides access the following network modules.

	- [NetworkEvent](/api/NetworkEvent)
	- [NetworkRequest](/api/NetworkRequest)
	- [NetworkValue](/api/NetworkValue)

	To begin using the package, require it and access the various modules through the returned table.

	```lua
	local Connection = require(Packages.Connection)
	local NetworkEvent = Connection.NetworkEvent
	local NetworkRequest = Connection.NetworkRequest
	local NetworkValue = Connection.NetworkValue
	```
]=]
local Connection = {
	NetworkEvent = NetworkEvent,
	NetworkRequest = NetworkRequest,
	NetworkValue = NetworkValue
}

return table.freeze(Connection)