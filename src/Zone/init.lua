local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Event = require(script.Parent.Event)

type Zone = {
	className: string,
	playerAdded: Event.Self,
	playerRemoved: Event.Self,
	detected: Event.Self,
	updateDelay: number,
	_detectedCount: number,
	_detectedHumanoidRootParts: {[Player]: BasePart},
	_detectedPlayers: {[Player]: boolean},
	_part: Part,
	_characters: {BasePart},
	_playerAddedConnection: RBXScriptConnection?,
	_playerRemovingConnection: RBXScriptConnection?,
	_characterAddedConnections: {[Player]: RBXScriptConnection},
	_characterRemovingConnections: {[Player]: RBXScriptConnection},
	_touchConnection: RBXScriptConnection?,
	_heartbeatConnection: RBXScriptConnection?,
	_enableTracking: boolean,
	_overlapParams: OverlapParams,
	new: (part: Part, updateDelay: number?, overlapParams: OverlapParams?) -> Zone,
	destroy: (self: Zone) -> (),
	enable: (self: Zone) -> (),
	disable: (self: Zone) -> (),
	getDetectedPlayers: (self: Zone) -> {Player},
	getDetectedHumanoidRootParts: (self: Zone) -> {[Player]: BasePart}
}

local DEFAULT_UPDATE_INTERVAL = 1

local function getPlayerForHumanoidRootPart(humanoidRootPart: BasePart): Player?
	if not humanoidRootPart:IsA("Part") or humanoidRootPart.Name ~= "HumanoidRootPart" then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(humanoidRootPart.Parent)
	if not player then return nil end

	return player
end

local Zone = {}
Zone.__index = Zone
Zone.className = "Zone"

function Zone:_monitorCharacters(player: Player)
	if player.Character then
		table.insert(self._characters, player.Character)
	end
	self._characterAddedConnections[player] = player.CharacterAdded:Connect(function(character: Model)
		table.insert(self._characters, character)
	end)
	self._characterRemovingConnections[player] = player.CharacterRemoving:Connect(function(character: Model)
		local position = table.find(self._characters, character)
		if position then
			table.remove(self._characters, position)
		end
	end)
end

function Zone:_monitorPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		self:_monitorCharacters(player)
	end
	self._playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		self:_monitorCharacters(player)
	end)
	self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self._characterAddedConnections[player]:Disconnect()
		self._characterAddedConnections[player] = nil
		self._characterRemovingConnections[player]:Disconnect()
		self._characterRemovingConnections[player] = nil
	end)
end

function Zone:_addPlayersWhoJoinedZone(parts: {BasePart})
	for _, part in ipairs(parts) do
		local player = getPlayerForHumanoidRootPart(part)
		if not player then continue end

		local existingPlayer = self._detectedPlayers[player]
		if existingPlayer then continue end

		self._detectedHumanoidRootParts[player] = part
		self._detectedPlayers[player] = true
		self.playerAdded:fire(player)

		self._detectedCount += 1
	end
end

function Zone:_removePlayersWhoLeftZone(parts: {BasePart})
	for _, humanoidRootPart in pairs(self._detectedHumanoidRootParts) do
		local player = getPlayerForHumanoidRootPart(humanoidRootPart)
		if not player then continue end

		local exists = false
		for _, part in ipairs(parts) do
			if humanoidRootPart ~= part then continue end
			exists = true
		end

		if not exists then
			self._detectedHumanoidRootParts[player] = nil
			self._detectedPlayers[player] = nil
			self.playerRemoved:fire(player)

			self._detectedCount -= 1
			if self._detectedCount == 0 then
				self:_stopTracking()
			end
		end
	end
end

function Zone:_updateDetectedArray()
	self._overlapParams.FilterDescendantsInstances = self._characters
	local parts = workspace:GetPartsInPart(self._part, self._overlapParams)

	self:_removePlayersWhoLeftZone(parts)

	if #parts == 0 then
		self:_stopTracking()
		return
	end

	self:_addPlayersWhoJoinedZone(parts)

	self.detected:fire()
end

function Zone:_startTracking()
	local updateBuffer = 0
	self._heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime: number)
		if not self._enableTracking then return end
		updateBuffer += deltaTime
		if updateBuffer < self.updateDelay then return end
		updateBuffer = 0
		self:_updateDetectedArray()
	end)
end

function Zone:_stopTracking()
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
end

function Zone.new(part: Part, updateDelay: number?, overlapParams: OverlapParams?): Zone
	assert(typeof(part) == "Instance" and part:IsA("Part"), "Argument #1 must be a Part")
	assert(updateDelay == nil or (typeof(updateDelay) == "number" and updateDelay > 0), "Argument #2 must be a positive number or nil")
	assert(overlapParams == nil or (typeof(overlapParams) == "Instance" and overlapParams:IsA("OverlapParams")), "Argument #3 must be an OverlapParams or nil")

	local self = setmetatable({
		playerAdded = Event.new(),
		playerRemoved = Event.new(),
		detected = Event.new(),
		updateDelay = updateDelay or DEFAULT_UPDATE_INTERVAL,
		_detectedCount = 0,
		_detectedHumanoidRootParts = {},
		_detectedPlayers = {},
		_part = part,
		_characters = {},
		_playerAddedConnection = nil,
		_playerRemovingConnection = nil,
		_characterAddedConnections = {},
		_characterRemovingConnections = {},
		_touchConnection = nil,
		_heartbeatConnection = nil,
		_enableTracking = false,
		_overlapParams = overlapParams or OverlapParams.new()
	}, Zone)

	self._overlapParams.FilterType = Enum.RaycastFilterType.Include
	self._overlapParams.FilterDescendantsInstances = self._characters

	local debounce = {}
	self._touchConnection = part.Touched:Connect(function(otherPart: Part)
		local player = getPlayerForHumanoidRootPart(otherPart)
		if player ~= nil and not debounce[player] then
			debounce[player] = true
			task.delay(0.1, function()
				debounce[player] = nil
			end)

			if self._heartbeatConnection then return end

			self:_startTracking()
			if self.updateDelay > 0.1 then
				task.delay(0.1, self._updateDetectedArray, self)
			end
		end
	end)

	self:_monitorPlayers()

	return self
end

function Zone:destroy()
	self.playerAdded:destroy()
	self.playerAdded = nil
	self.playerRemoved:destroy()
	self.playerRemoved = nil
	self.detected:destroy()
	self.detected = nil
	self.updateDelay = nil
	self._detectedCount = nil
	self._detectedHumanoidRootParts = nil
	self._detectedPlayers = nil
	self._part = nil
	self._characters = nil
	self._playerAddedConnection:Disconnect()
	self._playerAddedConnection = nil
	self._playerRemovingConnection:Disconnect()
	self._playerRemovingConnection = nil
	for _, connection in pairs(self._characterAddedConnections) do
		connection:Disconnect()
	end
	self._characterAddedConnections = nil
	for _, connection in pairs(self._characterRemovingConnections) do
		connection:Disconnect()
	end
	self._characterRemovingConnections = nil
	self._touchConnection:Disconnect()
	self._touchConnection = nil
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	self._enableTracking = nil
	self._overlapParams = nil
end

function Zone:enable()
	self._enableTracking = true
end

function Zone:disable()
	self._enableTracking = false
end

function Zone:getDetectedPlayers(): {Player}
	local players = {}
	for player, _ in pairs(self._detectedPlayers) do
		table.insert(players, player)
	end
	return players
end

function Zone:getDetectedHumanoidRootParts(): {[Player]: BasePart}
	return table.clone(self._detectedHumanoidRootParts)
end

return Zone