local RunService = game:GetService("RunService")

--[=[
	@within NetworkRequest
	@prop className string
]=]
export type NetworkRequest = {
	className: string,
	new: (name: string, parent: Instance, callback: (...any) -> (...any)?) -> NetworkRequest,
	Destroy: (self: NetworkRequest) -> (),
	Connect: (self: NetworkRequest, callback: any) -> (),
	Invoke: (self: NetworkRequest, ...any) -> ()
}

--[=[
	@class NetworkRequest
	An object that wraps Roblox's `RemoteFunction`. It can be used on the client to request data from the server
	without having to manage `RemoteFunction` lifecycles manually – initialization and deinitialization are handled for you.

	:::note
	Network requests are intended to be paired. A `NetworkRequest` object should be initialized on the server first, then on the client,
	otherwise an error will occur.

	Any type of Roblox object such as an Enum, Instance, or others can be passed as a parameter when a RemoteFunction is invoked,
	as well as Luau types such as numbers, strings, and booleans. `NetworkRequest` shares its limitations with Roblox's `RemoteFunction` class.
	:::

	```lua
	-- Server
	local serverRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	serverRequest:Connect(function(player, _)
		print("The client is requesting a response")
		return "Hello, Client!"
	end

	-- Client
	local clientRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	local value = clientRequest:Invoke()
	print("The server responded with:", value) -- Hello, Client!
	```
]=]
local NetworkRequest = {}
NetworkRequest.__index = NetworkRequest
NetworkRequest.className = "NetworkRequest"

--[=[
	@return NetworkEvent
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
		_Name = name,
		_Parent = parent,
		_Callback = callback,
		_RemoteFunction = nil
	}, NetworkRequest)

	self:_SetupRemoteFunction()

	return self
end

--[=[
	Deconstructs the `NetworkRequest` object
]=]
function NetworkRequest:Destroy()
	self._Name = nil
	self._Parent = nil
	self._Callback = nil
	if RunService:IsServer() and self._RemoteFunction then
		self._RemoteFunction:Destroy()
	end
	self._RemoteFunction = nil
end

function NetworkRequest:_SetupRemoteFunction()
	if RunService:IsServer() then
		local remoteFunction = self._Parent:FindFirstChild(self._Name)
		if remoteFunction ~= nil then
			error("NetworkEvent can't create a RemoteEvent because an Instance with the name '" .. self._Name .. "' already exists in " .. self._Parent:GetFullName())
		end

		remoteFunction = Instance.new("RemoteFunction")
		remoteFunction.Name = self._Name
		remoteFunction.Parent = self._Parent

		remoteFunction.OnServerInvoke = self._Callback

		self._RemoteFunction = remoteFunction
	else
		local remoteFunction: RemoteFunction = self._Parent:FindFirstChild(self._Name)
		if remoteFunction == nil then
			error("NetworkRequest " .. self._Name .. " not found in " .. self._Parent:GetFullName() .. "- A NetworkRequest with matching properties should be initialized on the server first")
		end

		self._RemoteFunction = remoteFunction
	end
end

--[=[
	@server
	Connects a callback to the `NetworkRequest` which is invoked when
	the request is invoked.

	```lua
	local serverRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	serverRequest:Connect(function(player, value)
		print("The client passed the value:", value)
		return "Thank you, Client!"
	end
	```
]=]
function NetworkRequest:Connect(callback: (...any) -> (...any))
	assert(callback ~= nil and typeof(callback) == "function", "Callback must be provided")

	if RunService:IsClient() then
		error("Cannot set NetworkRequest callback on the client")
	end

	self._Callback = callback
	self._RemoteFunction.OnServerInvoke = callback
end

--[=[
	@client
	Invokes the `NetworkRequest` on the server and returns the response.

	```lua
	local clientRequest = NetworkRequest.new("MyNetworkRequest", workspace)
	local value = clientRequest:Invoke()
	print("The server responded with:", value)
	```
]=]
function NetworkRequest:Invoke(...: any): ...any
	if RunService:IsServer() then
		error("Cannot Invoke a NetworkRequest on the server")
	end

	return self._RemoteFunction:InvokeServer(...)
end

return NetworkRequest