--[=[
	@class Network

	The Network package provides access the following network-related APIs.

	- [NetworkEvent](/api/NetworkEvent)
	- [NetworkRequest](/api/NetworkRequest)
	- [NetworkValue](/api/NetworkValue)

	To begin using the package, require it and access the APIs through the returned table.

	```lua
	local Network = require(Packages.Network)
	local NetworkEvent = Network.Event
	local NetworkRequest = Network.Request
	local NetworkValue = Network.Value
	```
]=]
local Network = {
	Event = require(script.NetworkEvent),
	Request = require(script.NetworkRequest),
	Value = require(script.NetworkValue)
}

return table.freeze(Network)