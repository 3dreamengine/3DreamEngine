--[[
#shared memory across love threads
since the channel is secure but slow, shared memory often makes more sense
the library is designed to keep vector, matrices or arrays of such in sync, without additional checks for race conditions etc

#usage
local sharedMem = require("sharedMem)

--create 8 matrices of dimension 4 with data type double
local mem = sharedMem:new(8 * 16, "double")

--sets the first matrix
mem:set(...)
mem:set({...})

--sets the third matrix
mem:setAt(2 * 16, ...)
mem:setAt(2 * 16, {...})

--gets the second matrix
local mat = mem:getMat4(1)

--gets the 18th value, regardless of theoretical type
local v = mem.array[17]

--sends the data to another thread via a love channel
channel:send(mem.data)

--and recreate another link to the shared memory on the other end
local data = channel:pop()
local mem = sharedMem:new(8 * 16, "double", data)
--]]

local ffi = require("ffi")

local meta = {
	__index = {
		set = function(self, ...)
			self:setAt(0, ...)
		end,
		
		setAt = function(self, offset, a, b, ...)
			offset = offset - 1
			if b then
				for d,s in ipairs({a, b, ...}) do
					self.array[offset + d] = s
				end
			else
				for d,s in ipairs(a) do
					self.array[offset + d] = s
				end
			end
		end,
		
		getVec2 = function(self, offset)
			local a = self.array
			local o = (offset or 0) * 2
			return {a[o + 0], a[o + 1]}
		end,
		
		getVec3 = function(self, offset)
			local a = self.array
			local o = (offset or 0) * 3
			return {a[o + 0], a[o + 1], a[o + 2]}
		end,
		
		getVec4 = function(self, offset)
			local a = self.array
			local o = (offset or 0) * 4
			return {a[o + 0], a[o + 1], a[o + 2], a[o + 3]}
		end,
		
		getMat3 = function(self, offset)
			local a = self.array
			local o = (offset or 0) * 9
			return {a[o + 0], a[o + 1], a[o + 2], a[o + 3], a[o + 4], a[o + 5], a[o + 6], a[o + 7], a[o + 8]}
		end,
		
		getMat4 = function(self, offset)
			local a = self.array
			local o = (offset or 0) * 16
			return {a[o + 0], a[o + 1], a[o + 2], a[o + 3], a[o + 4], a[o + 5], a[o + 6], a[o + 7], a[o + 8], a[o + 9], a[o + 10], a[o + 11], a[o + 12], a[o + 13], a[o + 14], a[o + 15]}
		end,
	},
}

local sharedMem = { }

function sharedMem:new(length, typ, data)
	length = length or 1
	typ = typ or "double"
	local data = data or love.data.newByteData(ffi.sizeof(typ) * length)
	
	return setmetatable({
		length = length,
		typ = typ,
		data = data,
		array = ffi.cast("double*", data:getPointer()),
	}, meta)
end

return sharedMem