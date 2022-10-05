local lib = _3DreamEngine

local ffi = require("ffi")

local structs = { }

local types = {
	vec2 = { "x", "y" },
	vec3 = { "x", "y", "z" },
	vec4 = { "x", "y", "z", "w" },
}

local sizeLookup = {
	[2] = "vec2",
	[3] = "vec3",
	[4] = "vec4",
	[9] = "mat3",
	[16] = "mat4",
}

function lib:newBufferFromArray(array)
	local buffer = self:newBuffer(sizeLookup[#array[1]], "float", #array)
	if buffer.type == "scalar" then
		for i, v in ipairs(array) do
			buffer[i - 1] = v
		end
	else
		for i, v in ipairs(array) do
			for ki, key in ipairs(types[buffer.type]) do
				buffer.buffer[i - 1][key] = v[ki]
			end
		end
	end
	return buffer
end

function lib:newBuffer(type, dataType, length)
	local id = "dream_" .. type .. "_" .. dataType
	if not structs[id] and type ~= "scalar" then
		ffi.cdef("typedef struct { " .. dataType .. " " .. table.concat(types[type], ", ") .. "; } " .. id .. ";")
	end
	
	return setmetatable({
		dataType = dataType,
		type = type,
		length = length,
		buffer = type == "scalar" and ffi.new(dataType .. "[?]", length) or ffi.new(id .. "[?]", length)
	}, self.meta.buffer)
end

local class = {
	link = { "buffer" },
}

function class:append(data)
	error("Can not insert into static buffer!")
end

function class:set(index, data)
	assert(index > 0 and index <= self.length)
	self.buffer[index - 1] = data
end

function class:get(index)
	assert(index > 0 and index <= self.length)
	return self.buffer[index - 1]
end

function class:getVector(index)
	assert(index > 0 and index <= self.length)
	local v = self.buffer[index - 1]
	if self.type == "vec4" then
		return vec4(v.x, v.y, v.z, v.w)
	elseif self.type == "vec3" then
		return vec3(v.x, v.y, v.z)
	elseif self.type == "vec2" then
		return vec2(v.x, v.y)
	else
		return v
	end
end

function class:getOrDefault(index, default)
	return index > 0 and index <= self.length and self.buffer[index - 1] or default
end

function class:getSize()
	return self.length
end

function class:ipairs()
	local offset = self.class == "buffer" and -1 or 0
	local i = 0
	local n = self:getSize()
	return function()
		i = i + 1
		if i <= n then
			return i, self.buffer[i + offset]
		end
	end
end

function class:tostring()
	return string.format("Static %s %s Buffer of size %d", self.dataType, self.type, self.length)
end

return class