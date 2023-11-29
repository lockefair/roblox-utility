local RunService = game:GetService("RunService")

type NetworkRequest = {
	className: string,
	new: (name: string, parent: Instance, callback: (player: Player, ...any) -> (...any)?) -> NetworkRequest,
	destroy: (self: NetworkRequest) -> (),
	setCallback: (self: NetworkRequest, callback: (player: Player, ...any) -> (...any)?) -> (),
	invoke: (self: NetworkRequest, ...any) -> ()
}

type _NetworkRequest = {
	_name: string,
	_parent: Instance,
	_callback: (player: Player, ...any) -> (...any)?,
	_remoteFunction: RemoteFunction?
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

	Static property that defines the class name `NetworkRequest`.
]=]

--[=[
	@class NetworkRequest

	An object that wraps Roblox's `RemoteFunction`. It can be used on the client to request data from the server
	without having to manage `RemoteFunction` lifecycles manually – initialization and deinitialization are handled for you.

	:::note
	Network requests are intended to be paired. A `NetworkRequest` instance should be initialized on the server first, then on the client,
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
local NetworkRequest: _NetworkRequest = {}
NetworkRequest.__index = NetworkRequest
NetworkRequest.className = "NetworkRequest"

--[=[
	@tag Static

	Constructs a new `NetworkRequest` object.

	@param name string -- The name of the `NetworkRequest` instance which must match on the client and server
	@param parent Instance -- The parent of the `NetworkRequest` instance which must match on the client and server
	@param callback (player: Player, ...any) -> (...any)? -- The callback to be called when the request is invoked
]=]
function NetworkRequest.new(name: string, parent: Instance, callback: (player: Player, ...any) -> (...any)?): NetworkRequest
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
	Deconstructs the `NetworkRequest` object.
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

	Sets the callback for the `NetworkRequest` which is called when the request is invoked. The callback can
	be set to nil.

	@param callback (player: Player, ...any) -> (...any)? -- The callback to be called when the request is invoked

	```lua
	local serverRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	serverRequest:setCallback(function(player, value)
		print("The client passed the value:", value)
		return "Thank you, Client!"
	end
	```
]=]
function NetworkRequest:setCallback(callback: (player: Player, ...any) -> (...any)?)
	assert(callback ~= nil and typeof(callback) == "function", "Callback must be provided")

	if RunService:IsClient() then
		error("Cannot connect to NetworkRequest callback on the client")
	end

	self._callback = callback
	self._remoteFunction.OnServerInvoke = callback
end

--[=[
	@client

	Invokes the `NetworkRequest` on the server and returns the response.

	@param ... any -- The arguments to pass to the server

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