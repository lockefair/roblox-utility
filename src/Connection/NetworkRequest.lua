local RunService = game:GetService("RunService")

type NetworkRequest = {
	className: string,
	new: (name: string, parent: Instance, callback: (...any) -> (...any)?) -> NetworkRequest,
	destroy: (self: NetworkRequest) -> (),
	connect: (self: NetworkRequest, callback: (...any) -> (...any)) -> (),
	invoke: (self: NetworkRequest, ...any) -> ()
}

--[=[
	@within NetworkRequest
	@type Self NetworkRequest
]=]
export type Self = NetworkRequest

--[=[
	@within NetworkRequest
	@prop className string
	@tag Static

	Static property that defines the class name of the `NetworkRequest` object
]=]

--[=[
	@class NetworkRequest

	An object that wraps Roblox's `RemoteFunction`. It can be used on the client to request data from the server
	without having to manage `RemoteFunction` lifecycles manually – initialization and deinitialization are handled for you.

	:::note
	Network requests are intended to be paired. A `NetworkRequest` object should be initialized on the server first, then on the client,
	otherwise an error will occur.

	Any type of Roblox object such as an Enum, Instance, or others can be passed as a parameter when a `NetworkRequest` is invoked,
	as well as Luau types such as numbers, strings, and booleans. `NetworkRequest` shares its limitations with Roblox's `RemoteFunction` class.
	:::

	```lua
	-- Server
	local serverRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	serverRequest:connect(function(player, _)
		print("The client is requesting a response")
		return "Hello, Client!"
	end

	-- Client
	local clientRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	local value = clientRequest:invoke()
	print("The server responded with:", value) -- Hello, Client!
	```
]=]
local NetworkRequest = {}
NetworkRequest.__index = NetworkRequest
NetworkRequest.className = "NetworkRequest"

--[=[
	@tag Static

	Constructs a new `NetworkRequest` object
]=]
function NetworkRequest.new(name: string, parent: Instance, callback: (...any) -> (...any)?): NetworkRequest
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")
	if callback then
		if RunService:IsClient() then
			error("Cannot set NetworkRequest callback on the client")
		end
		assert(typeof(callback) == "function", "callback must be a function")
	end

	local self = setmetatable({
		_name = name,
		_parent = parent,
		_callback = callback,
		_remoteFunction = nil
	}, NetworkRequest)

	self:_setupRemoteFunction()

	return self
end

--[=[
	Deconstructs the `NetworkRequest` object
]=]
function NetworkRequest:destroy()
	self._name = nil
	self._parent = nil
	self._callback = nil
	if RunService:IsServer() and self._remoteFunction then
		self._remoteFunction:Destroy()
	end
	self._remoteFunction = nil
end

function NetworkRequest:_setupRemoteFunction()
	if RunService:IsServer() then
		local remoteFunction = self._parent:FindFirstChild(self._name)
		if remoteFunction ~= nil then
			error("NetworkEvent can't create a RemoteEvent because an Instance with the name '" .. self._name .. "' already exists in " .. self._parent:GetFullName())
		end

		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = self._name
		remoteFunction.Parent = self._parent

		remoteFunction.OnServerInvoke = self._callback

		self._remoteFunction = remoteFunction
	else
		local remoteFunction: RemoteFunction = self._parent:FindFirstChild(self._name)
		if remoteFunction == nil then
			error("NetworkRequest " .. self._name .. " not found in " .. self._parent:GetFullName() .. "- A NetworkRequest with matching properties should be initialized on the server first")
		end

		self._remoteFunction = remoteFunction
	end
end

--[=[
	@server

	Connects a callback to the `NetworkRequest` which is invoked when
	the request is invoked.

	```lua
	local serverRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	serverRequest:connect(function(player, value)
		print("The client passed the value:", value)
		return "Thank you, Client!"
	end
	```
]=]
function NetworkRequest:connect(callback: (...any) -> (...any))
	assert(callback ~= nil and typeof(callback) == "function", "Callback must be provided")

	if RunService:IsClient() then
		error("Cannot set NetworkRequest callback on the client")
	end

	self._callback = callback
	self._remoteFunction.OnServerInvoke = callback
end

--[=[
	@client

	Invokes the `NetworkRequest` on the server and returns the response.

	```lua
	local clientRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	local value = clientRequest:invoke()
	print("The server responded with:", value)
	```
]=]
function NetworkRequest:invoke(...: any): ...any
	if RunService:IsServer() then
		error("Cannot Invoke a NetworkRequest on the server")
	end

	return self._remoteFunction:InvokeServer(...)
end

return table.freeze(NetworkRequest)