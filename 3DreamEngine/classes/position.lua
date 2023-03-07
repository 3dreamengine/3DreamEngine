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
---@class DreamPosition : DreamClonable
local class = {
	links = { "position", "clonable" },
}

---@private
function class:tostring()
	return string.format("%s with value %s (%.3f size) at %s", self.name, self.value, self.size, self.position)
end

function class:setName(name)
	self.name = lib:removePostfix(name)
end

function class:getName()
	return self.name
end

function class:setPosition(position)
	self.position = position
end

function class:getPosition()
	return self.position
end

function class:setValue(value)
	self.value = value
end

function class:getValue()
	return self.value
end

function class:setSize(size)
	self.size = size
end

function class:getSize()
	return self.size
end

---@private
function class:decode()
	self.position = lib.vec3(self.position)
end

return class