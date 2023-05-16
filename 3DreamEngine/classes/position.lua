---@type Dream
local lib = _3DreamEngine

---@param position DreamVec3
---@param size number
---@param value string
---@return DreamPosition
function lib:newPosition(position, size, value)
	local l = {
		name = "unnamed",
		position = position,
		size = size,
		value = value,
	}
	
	return setmetatable(l, self.meta.position)
end

---New position, mostly used internally for objects marked with the `POS` tag.
---@class DreamPosition : DreamClonable, DreamIsNamed
local class = {
	links = { "position", "clonable", "named" },
}

---@private
function class:tostring()
	return string.format("%s with value %s (%.3f size) at %s", self.name, self.value, self.size, self.position)
end

---@param position DreamVec3
function class:setPosition(position)
	self.position = position
end

---@return DreamVec3
function class:getPosition()
	return self.position
end

---@param value string
function class:setValue(value)
	self.value = value
end

---@return string @ the value passed with the tag while loading
function class:getValue()
	return self.value
end

---@param size number
function class:setSize(size)
	self.size = size
end

---@return number
function class:getSize()
	return self.size
end

---@private
function class:decode()
	self.position = lib.vec3(self.position)
end

return class