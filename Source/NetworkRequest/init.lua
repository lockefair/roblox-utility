local RunService = game:GetService("RunService")

export type NetworkRequest = {
	className: string,
	new: (name: string, parent: Instance, callback: (...any) -> (...any)?) -> NetworkRequest,
	Destroy: (self: NetworkRequest) -> (),
	SetCallback: (self: NetworkRequest, callback: any) -> (),
	Invoke: (self: NetworkRequest, ...any) -> ()
}

local NetworkRequest = {}
NetworkRequest.__index = NetworkRequest
NetworkRequest.className = "NetworkRequest"

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

function NetworkRequest:Destroy()
	self._Name = nil
	self._Parent = nil
	self._Callback = nil
	if self._RemoteFunction then
		self._RemoteFunction:Destroy()
		self._RemoteFunction = nil
	end
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

function NetworkRequest:SetCallback(callback: (...any) -> (...any))
	assert(callback ~= nil and typeof(callback) == "function", "Callback must be provided")

	if RunService:IsClient() then
		error("Cannot set NetworkRequest callback on the client")
	end

	self._Callback = callback
	self._RemoteFunction.OnServerInvoke = callback
end

function NetworkRequest:Invoke(...: any): ...any
	if RunService:IsServer() then
		error("Cannot Invoke a NetworkRequest on the server")
	end

	return self._RemoteFunction:InvokeServer(...)
end

return NetworkRequest