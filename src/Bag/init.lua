local Event = require(script.Parent.Packages.Event)

type Bag = {
	className: string,
	new: () -> Bag,
	destroy: (self: Bag) -> (),
	add: (self: Bag, reference: any) -> (),
}

--[=[
	@within NetworkEvent
	@type Self NetworkEvent
]=]
export type Self = Bag

--[=[
	@class Bag

	A reference bag that can be used to retain references in a single instance. Destroying the bag will clear its references and
	perform a unique action depending on its type.

	- Function - Calls the function
	- RBXScriptConnection - Disconnects the connection
	- Thread - Resumes the thread
	- Object/Table with Disconnect method - Disconnect the connection (works for :disconnect() and :Disconnect())
	- Object/Table with Destroy method - Destroys the object (works for :destroy() and :Destroy())
]=]
local Bag = {}
Bag.__index = Bag
Bag.className = "Bag"

--[=[
	@tag Static

	Constructs a new `Bag` object
]=]
function Bag.new()
end

--[=[
	Deconstructs the `Bag` object
]=]
function Bag:destroy()
end

--[=[
	Adds a reference to the bag

	@param reference any
]=]
function Bag:add(reference: any)
end

return table.freeze(Bag)