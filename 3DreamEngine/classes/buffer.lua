local lib = _3DreamEngine

local ffi = require("ffi")

local structs = { }

local types = {
	vec2 = { "x", "y" },
	vec3 = { "x", "y", "z" },
	vec4 = { "x", "y", "z", "w" },
	mat4 = { "v00", "v10", "v20", "v30", "v01", "v11", "v21", "v31", "v02", "v12", "v22", "v32", "v03", "v13", "v23", "v33" },
}

local sizes = {
	scalar = 1,
	vec2 = 2,
	vec3 = 3,
	vec4 = 4,
	mat4 = 16,
}

local sizeLookup = {
	[2] = "vec2",
	[3] = "vec3",
	[4] = "vec4",
	[16] = "mat4",
}

---@return DreamBuffer
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

---@return DreamBuffer
function lib:newBufferLike(buffer)
	return self:newBuffer(buffer:getType(), buffer:getDataType(), buffer:getSize())
end

---@return DreamBuffer
function lib:bufferFromString(type, dataType, str)
	local buffer = self:newBuffer(type, dataType, #str / (ffi.sizeof(dataType) * sizes[type]))
	local source = ffi.cast("char*", love.data.newByteData(str):getFFIPointer())
	ffi.copy(buffer.buffer, source, #str)
	return buffer
end

---@return DreamBuffer
function lib:newBuffer(type, dataType, length)
	local id = ("dream_" .. type .. "_" .. dataType):gsub(" ", "_")
	if not structs[id] and type ~= "scalar" then
		ffi.cdef("typedef struct { " .. dataType .. " " .. table.concat(types[type], ", ") .. "; } " .. id .. ";")
		structs[id] = true
	end
	
	return setmetatable({
		type = type,
		dataType = dataType,
		length = length,
		buffer = type == "scalar" and ffi.new(dataType .. "[?]", length) or ffi.new(id .. "[?]", length)
	}, self.meta.buffer)
end

---@class DreamBuffer
local class = {
	links = { "buffer" },
}

function class:getType()
	return self.type
end

function class:getDataType()
	return self.dataType
end

---Append a value to the buffer
---@param data number|"vec2"|"vec2"|"vec2"
function class:append(data)
	error("Can not insert into static buffer!")
end

---Set a value in the buffer
---@param index number
---@param data number|"vec2"|"vec2"|"vec2"
function class:set(index, data)
	assert(index > 0 and index <= self.length)
	self.buffer[index - 1] = data
end

---Get a raw value from the buffer
---@param index number
---@return "ctype"|number
function class:get(index)
	assert(index > 0 and index <= self.length)
	return self.buffer[index - 1]
end

---Get a raw value from the buffer without risking a out of bounds
---@param index number
---@return "ctype"|number
function class:getOrDefault(index, default)
	return index > 0 and index <= self.length and self.buffer[index - 1] or default
end

---Get a casted value from the buffer
---@param index number
---@return number|"vec2"|"vec2"|"vec2"
function class:getVector(index)
	assert(index > 0 and index <= self.length)
	local v = self.buffer[index - 1]
	if self.type == "vec4" then
		return vec4(v.x, v.y, v.z, v.w)
	elseif self.type == "vec3" then
		return vec3(v.x, v.y, v.z)
	elseif self.type == "vec2" then
		return vec2(v.x, v.y)
	elseif self.type == "mat4" then
		return mat4({
			v.v00, v.v01, v.v02, v.v03,
			v.v10, v.v11, v.v12, v.v13,
			v.v20, v.v21, v.v22, v.v23,
			v.v30, v.v31, v.v32, v.v33,
		})
	else
		return v
	end
end

---Copy data from one buffer into another, offsets given in indices
---@param source DreamBuffer
---@param dstOffset number
---@param srcOffset number
---@param srcLength number
function class:copyFrom(source, dstOffset, srcOffset, srcLength)
	dstOffset = dstOffset or 0
	srcOffset = srcOffset or 0
	srcLength = srcLength or (source:getSize() - srcOffset)
	if source.class == "buffer" and self.class == "buffer" and self:getDataType() == source:getDataType() then
		ffi.copy(self.buffer + dstOffset, source.buffer + srcOffset, ffi.sizeof(self:getDataType()) * sizes[self:getType()] * srcLength)
	elseif self:getType() == "scalar" then
		for i = 1, source:getSize() do
			self:set(i + dstOffset, source:getVector(i + srcOffset))
		end
	else
		for i = 1, source:getSize() do
			self:set(i + dstOffset, source:getVector(i + srcOffset):clone())
		end
	end
end

---Get the size of this buffer
function class:getSize()
	return self.length
end

---Iterate over every raw value
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

---Convert buffer to a Lua array
function class:toArray()
	local array = { }
	for i = 1, self:getSize() do
		table.insert(array, self:getVector(i))
	end
	return array
end

function class:tostring()
	return string.format("Static %s %s Buffer of size %d", self.dataType, self.type, self.length)
end

return class