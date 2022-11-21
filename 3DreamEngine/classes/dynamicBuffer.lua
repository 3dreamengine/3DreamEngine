local lib = _3DreamEngine

---@return DreamBuffer
function lib:newDynamicBuffer()
	return setmetatable({
		buffer = { }
	}, self.meta.dynamicBuffer)
end

local class = {
	links = { "buffer", "dynamicBuffer" },
}

local function wrap(data)
	return type(data) == "table" and (#data == 4 and vec4(data) or #data == 3 and vec3(data) or #data == 2 and vec2(data)) or data
end

function class:getType()
	local data = self.buffer[1] or { }
	return #data == 4 and "vec4" or #data == 3 and "vec3" or #data == 2 and "vec2" or "scalar"
end

function class:getDataType()
	return "float"
end

function class:append(data)
	table.insert(self.buffer, wrap(data))
end

function class:set(index, data)
	assert(index > 0 and index <= #self.buffer)
	self.buffer[index] = wrap(data)
end

function class:get(index)
	assert(index > 0 and index <= #self.buffer)
	return self.buffer[index]
end

function class:getVector(index)
	assert(index > 0 and index <= #self.buffer)
	return self.buffer[index]
end

function class:getOrDefault(index, default)
	return self.buffer[index] or default
end

function class:getSize()
	return #self.buffer
end

function class:tostring()
	return "Dynamic Buffer"
end

return class