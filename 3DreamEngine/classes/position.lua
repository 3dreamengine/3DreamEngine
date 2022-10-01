local lib = _3DreamEngine

function lib:newPosition(position, size, value)
	local l = {
		position = position,
		size = size,
		value = value,
	}
	
	return setmetatable(l, self.meta.position)
end

local class = {
	link = { "position", "clone" },
}

function class:tostring()
	return string.format("%s (%.3f size) at %s", self.value, self.size, self.position)
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