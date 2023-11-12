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
	NetworkEvent = require(script.NetworkEvent),
	NetworkRequest = require(script.NetworkRequest),
	NetworkValue = require(script.NetworkValue)
}

return table.freeze(Connection)