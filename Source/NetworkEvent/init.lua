local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Event = require(script.Parent.Event)

export type NetworkEvent = {
	className: string,
	new: (name: string, parent: Instance) -> NetworkEvent,
	Destroy: (self: NetworkEvent) -> (),
	Connect: (self: NetworkEvent, callback: (...any) -> ()) -> Event.EventConnection,
	FireServer: (self: NetworkEvent, ...any) -> (),
	FireClient: (self: NetworkEvent, player: Player, ...any) -> (),
	FireFilteredClients: (self: NetworkEvent, predicate: (player: Player) -> boolean, ...any) -> (),
	FireAllClients: (self: NetworkEvent, ...any) -> ()
}

local NetworkEvent = {}
NetworkEvent.__index = NetworkEvent
NetworkEvent.className = "NetworkEvent"

function NetworkEvent.new(name: string, parent: Instance): NetworkEvent
	assert(name ~= nil and type(name) == "string", "name must be a string")
	assert(parent ~= nil and typeof(parent) == "Instance", "parent must be an Instance")

	local self = setmetatable({
		_Name = name,
		_Parent = parent,
		_Event = Event.new(),
		_RemoteEvent = nil,
		_RemoteEventConnection = nil
	}, NetworkEvent)

	self:_ConnectRemoteEvent()

	return self
end

function NetworkEvent:Destroy()
	self._Name = nil
	self._Parent = nil
	self._Event:Destroy()
	self._Event = nil
	if self._RemoteEventConnection then
		self._RemoteEventConnection:Disconnect()
		self._RemoteEventConnection = nil
	end
	if self._RemoteEvent then
		self._RemoteEvent:Destroy()
		self._RemoteEvent = nil
	end
end

function NetworkEvent:_ConnectRemoteEvent()
	if RunService:IsServer() then
		local remoteEvent = self._Parent:FindFirstChild(self._Name)
		if remoteEvent ~= nil then
			error("NetworkEvent can't create a RemoteEvent because an Instance with the name '" .. self._Name .. "' already exists in " .. self._Parent:GetFullName())
		end

		remoteEvent = Instance.new("RemoteEvent")
		remoteEvent.Name = self._Name
		remoteEvent.Parent = self._Parent

		self._RemoteEventConnection = remoteEvent.OnServerEvent:Connect(function(player, ...)
			self._Event:Fire(player, ...)
		end)

		self._RemoteEvent = remoteEvent
	else
		local remoteEvent: RemoteEvent = self._Parent:FindFirstChild(self._Name)
		if remoteEvent == nil then
			error("NetworkEvent can't find a RemoteEvent with the name '" .. self._Name .. "' in " .. self._Parent:GetFullName() .. " - A NetworkEvent with matching properties should be initialized on the server first")
		end

		self._RemoteEventConnection = remoteEvent.OnClientEvent:Connect(function(...)
			self._Event:Fire(...)
		end)

		self._RemoteEvent = remoteEvent
	end
end

function NetworkEvent:Connect(callback: (...any) -> ()): Event.EventConnection
	assert(callback ~= nil and type(callback) == "function", "callback must be a function")

	return self._Event:Connect(callback)
end

function NetworkEvent:FireServer(...: any)
	if RunService:IsServer() then
		error("FireServer(...) called on the server")
	end

	self._RemoteEvent:FireServer(...)
end

function NetworkEvent:FireClient(player: Player, ...: any)
	assert(player ~= nil and player:IsA("Player"), "player must be a Player")

	if RunService:IsClient() then
		error("FireClient(player, ...) called on the client")
	end

	self._RemoteEvent:FireClient(player, ...)
end

function NetworkEvent:FireFilteredClients(predicate: (player: Player) -> boolean, ...: any)
	assert(predicate ~= nil and type(predicate) == "function", "predicate must be a function")

	if RunService:IsClient() then
		error("FireFilteredClients(predicate, ...) called on the client")
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player) then
			self._RemoteEvent:FireClient(player, ...)
		end
	end
end

function NetworkEvent:FireAllClients(...: any)
	if RunService:IsClient() then
		error("FireAllClients(...) called on the client")
	end

	self._RemoteEvent:FireAllClients(...)
end

table.freeze(NetworkEvent)

return NetworkEvent