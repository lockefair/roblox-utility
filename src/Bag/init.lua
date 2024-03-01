type Bag = {
	className: string,
	new: () -> Bag,
	destroy: (self: Bag) -> (),
	add: (self: Bag, object: any, disposeMethod: string?) -> any,
	remove: (self: Bag, object: any) -> boolean,
	dispose: (self: Bag) -> (),
	attach: (self: Bag, instance: Instance) -> ()
}

type _Bag = Bag & {
	_objects: {{object: any, disposeMethod: string}},
	_destroyingConnection: RBXScriptConnection?
}

--[=[
	@within Bag
	@type Self Bag
]=]
export type Self = Bag

--[=[
	@within Bag
	@tag Static
	@prop className string

	Static property that defines the class name `Bag`
]=]

local FUNCTION_CLEANUP_METHOD = "Function"
local THREAD_CLEANUP_METHOD = "Thread"
local TABLE_CLEANUP_METHODS = {"destroy", "Destroy", "disconnect", "Disconnect"}

local function getObjectCleanupFunction(object, disposeMethod)
	local objectType = typeof(object)
	if objectType == "function" then
		return FUNCTION_CLEANUP_METHOD
	elseif objectType == "thread" then
		return THREAD_CLEANUP_METHOD
	end

	if disposeMethod then
		return disposeMethod
	end

	if objectType == "Instance" then
		return "Destroy"
	elseif objectType == "RBXScriptConnection" then
		return "Disconnect"
	elseif objectType == "table" then
		for _, genericCleanupMethod in TABLE_CLEANUP_METHODS do
			if typeof(object[genericCleanupMethod]) == "function" then
				return genericCleanupMethod
			end
		end
	end
	error("Failed to get cleanup function for object " .. objectType .. ": " .. tostring(object), 3)
end

--[=[
	@class Bag

	A Bag is used to store and track objects that need to be disposed of at some point. When the Bag is destroyed, all
	objects within the Bag are also disposed of. This class is inspired by Trove, Maid and Janitor but implements a camelCased
	interface and has a few differences in how it handles cleanup

	```lua
	local Bag = Bag.new()
	local part = Instance.new("Part")
	Bag:add(part)
	Bag:add(part.Touched:Connect(function()
		print("Touched!")
	end))
	Bag:destroy() -- 'part' is destroyed and the 'Touched' connection is disconnected
	```
]=]
local Bag: _Bag = {}
Bag.__index = Bag
Bag.className = "Bag"

function Bag:_callDisposeMethodOnObject(object: any, disposeMethod: string)
	if disposeMethod == FUNCTION_CLEANUP_METHOD then
		object()
	elseif disposeMethod == THREAD_CLEANUP_METHOD then
		pcall(task.cancel, object)
	else
		object[disposeMethod](object)
	end
end

--[=[
	@return Bag

	Constructs a new `Bag` object
]=]
function Bag.new(): Bag
	local self = setmetatable({
		_objects = {},
		_destroyingConnection = nil
	}, Bag)
	return self
end

--[=[
	Deconstructs the `Bag` object
]=]
function Bag:destroy()
	self:dispose()
	self._objects = nil
	if self._destroyingConnection then
		self._destroyingConnection:Disconnect()
		self._destroyingConnection = nil
	end
end

--[=[
	@param object any -- Object to track
	@param disposeMethod string? -- An optional cleanup method name to call on the object
	@return object any -- The object that was passed in

	Adds an object to the Bag. When the Bag is disposed of or destroyed the objects dispose method will be invoked and the reference
	to the object will be removed from the Bag. The following types are accepted (e.g. `typeof(object)`):

	| Type | Cleanup |
	| ---- | ------- |
	| `Instance` | `object:Destroy()` |
	| `RBXScriptConnection` | `object:Disconnect()` |
	| `function` | `object()` |
	| `thread` | `task.cancel(object)` |
	| `table` | `object:Destroy()` _or_ `object:Disconnect()` _or_ `object:destroy()` _or_ `object:disconnect()` |
	| `table` with `disposeMethod` | `object:<disposeMethod>()` |

	:::caution
	An error will be thrown if a cleanup method cannot be found for the object type that was added to the Bag
	:::

	```lua
	-- Adding a part to the Bag and then destroying the Bag will also destroy the part
	local part = Instance.new("Part")
	Bag:add(part)
	Bag:destroy()

	-- Adding a function to the Bag and then destroying the Bag will also call the function
	Bag:add(function()
		print("Disposed!")
	end)
	Bag:destroy()

	-- Adding a table to the Bag and then destroying the Bag will call the `destroy`, 'disconnect' or their PascalCased counterpart methods on the table if they exist
	local class = {}
	function class:destroy()
		print("Disposed!")
	end
	Bag:add(class)

	-- Custom cleanup from table:
	local tbl = {}
	function tbl:DoSomething()
		print("Do something on cleanup")
	end
	Bag:Add(tbl, "DoSomething")
	```
]=]
function Bag:add(object: any, disposeMethod: string?): any
	local cleanupFunction = getObjectCleanupFunction(object, disposeMethod)
	table.insert(self._objects, {object, cleanupFunction})
	return object
end

--[=[
	@param object any -- Object to remove from the bag
	@return boolean -- Whether or not the object was removed

	Removes the object from the Bag and disposes of it

	```lua
	local func = Bag:add(function()
		print("Disposed!")
	end)
	Bag:remove(func) -- "Disposed!" will be printed
	```
]=]
function Bag:remove(object: any): boolean
	local objects = self._objects
	for i, objectData in ipairs(objects) do
		if objectData[1] ~= object then continue end
		local count = #objects
		objects[i] = objects[count]
		objects[count] = nil
		self:_callDisposeMethodOnObject(objectData[1], objectData[2])
		return true
	end
	return false
end

--[=[
	Disposes of all objects in the Bag. This is the same as calling `remove` on each object added to the Bag. The ordering in which
	the objects are disposed of isn't guaranteed to match the order in which they were added

	```lua
	local part = Instance.new("Part")
	local connection = part.Touched:Connect(function()
		print("Touched!")
	end)
	Bag:add(part)
	Bag:add(connection)
	Bag:dispose() -- 'part' is destroyed and 'connection' is disconnected
	```
]=]
function Bag:dispose()
	for _, object in self._objects do
		self:_callDisposeMethodOnObject(object[1], object[2])
	end
	table.clear(self._objects)
end

--[=[
	@param instance Instance

	Attaches the `Bag` object to a Roblox `Instance`. Calling this method will detach the `Bag` from any previously attached instance. When
	the attached instance is removed from the game (its parent or ancestor's parent is set to `nil`), the Bag will automatically
	destroy itself. It's important that any references to the bag are still released when it's no longer being used

	:::caution
	An error will be thrown if `instance` is not a descendant of the game's DataModel
	:::
]=]
function Bag:attach(instance: Instance)
	if not instance:IsDescendantOf(game) then
		error("Instance is not a descendant of the game DataModel", 2)
	end

	if self._destroyingConnection then
		self._destroyingConnection:Disconnect()
	end

	assert(typeof(instance) ~= "Instance", "Argument #1 must be an Instance")

	self._destroyingConnection = instance.Destroying:Connect(function()
		self:destroy()
	end)
end

return Bag