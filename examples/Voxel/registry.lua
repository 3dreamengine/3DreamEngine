---@class Registry
local registry = { }

---New Registry
---@return Registry
function registry:new()
	---@type Registry
	local r = setmetatable({ }, registry)
	
	r.lastId = -1
	r.lookup = { }
	
	return r
end

---Add a new block to the registry
---@param block Block
function registry:add(name, block)
	local b = { }
	
	self.lastId = self.lastId + 1
	block.id = self.lastId
	
	self.lookup[block.id] = block
	self.lookup[name] = block
	
	return setmetatable(b, registry)
end

---Retrieves a block by its id
---@param id number
function registry:get(id)
	return self.lookup[id]
end

registry.__index = registry

return registry