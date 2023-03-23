---@type Dream
local lib = _3DreamEngine

---@class DreamIsNamed
local class = { }

---A name has no influence other than being able to print more nicely
---Unlike the id used to query objects, the name is not unique
---@param name string
function class:setName(name)
	self.name = lib:removePostfix(name)
end

---Gets the name, or "unnamed"
---@return string
function class:getName()
	return self.name or "unnamed"
end

return class