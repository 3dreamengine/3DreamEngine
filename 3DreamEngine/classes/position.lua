local lib = _3DreamEngine

---@return DreamPosition | DreamClonable
function lib:newPosition(position, size, value)
	local l = {
		name = "unnamed",
		position = position,
		size = size,
		value = value,
	}
	
	return setmetatable(l, self.meta.position)
end

---@class DreamPosition
local class = {
	links = { "position", "clone" },
}

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

function class:decode()
	self.position = vec3(self.position)
end

return class