local abs = math.abs
local vec
local metatable
local methods

vec = {
	__call = function(self, x, y, z, w)
		if not x then
			return setmetatable({ 0, 0, 0, 0 }, metatable)
		elseif type(x) == "number" then
			return setmetatable({ x, y, z, w }, metatable)
		else
			return setmetatable(x, metatable)
		end
	end,
}

methods = {
	clone = function(a)
		return vec(a[1], a[2], a[3], a[4])
	end,
	
	length = function(a)
		return math.sqrt(a[1] * a[1] + a[2] * a[2] + a[3] * a[3] + a[4] * a[4])
	end,
	
	lengthSquared = function(a)
		return a[1] * a[1] + a[2] * a[2] + a[3] * a[3] + a[4] * a[4]
	end,
	
	normalize = function(a)
		return a / a:length()
	end,
	
	abs = function(a)
		return vec(abs(a[1]), abs(a[2]), abs(a[3]), abs(a[4]))
	end,
	
	dot = function(a, b)
		return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4] * b[4]
	end,
	
	reflect = function(i, n)
		return i - 2 * n:dot(i) * n
	end,
	
	min = function(a, b)
		return vec(math.min(a[1], b[1]), math.min(a[2], b[2]), math.min(a[3], b[3]), math.min(a[4], b[4]))
	end,
	
	max = function(a, b)
		return vec(math.max(a[1], b[1]), math.max(a[2], b[2]), math.max(a[3], b[3]), math.min(a[4], b[4]))
	end,
	
	unpack = function(a)
		return a[1], a[2], a[3], a[4]
	end,
	
	type = "vec4",
}

metatable = {
	__add = function(a, b)
		if type(a) == "number" then
			return vec(a + b[1], a + b[2], a + b[3], a + b[4])
		elseif type(b) == "number" then
			return vec(a[1] + b, a[2] + b, a[3] + b, a[4] + b)
		else
			return vec(a[1] + b[1], a[2] + b[2], a[3] + b[3], a[4] + b[4])
		end
	end,
	
	__sub = function(a, b)
		if type(a) == "number" then
			return vec(a - b[1], a - b[2], a - b[3], a - b[4])
		elseif type(b) == "number" then
			return vec(a[1] - b, a[2] - b, a[3] - b, a[4] - b)
		else
			return vec(a[1] - b[1], a[2] - b[2], a[3] - b[3], a[4] - b[4])
		end
	end,
	
	__mul = function(a, b)
		if type(a) == "number" then
			return vec(a * b[1], a * b[2], a * b[3], a * b[4])
		elseif type(b) == "number" then
			return vec(a[1] * b, a[2] * b, a[3] * b, a[4] * b)
		else
			return vec(a[1] * b[1], a[2] * b[2], a[3] * b[3], a[4] * b[4])
		end
	end,
	
	__div = function(a, b)
		if type(a) == "number" then
			return vec(a / b[1], a / b[2], a / b[3], a / b[4])
		elseif type(b) == "number" then
			return vec(a[1] / b, a[2] / b, a[3] / b, a[4] / b)
		else
			return vec(a[1] / b[1], a[2] / b[2], a[3] / b[3], a[4] / b[4])
		end
	end,
	
	__mod = function(a, b)
		if type(a) == "number" then
			return vec(a % b[1], a % b[2], a % b[3], a % b[4])
		elseif type(b) == "number" then
			return vec(a[1] % b, a[2] % b, a[3] % b, a[4] % b)
		else
			return vec(a[1] % b[1], a[2] % b[2], a[3] % b[3], a[4] % b[4])
		end
	end,
	
	__unm = function(a)
		return vec(-a[1], -a[2], -a[3], -a[4])
	end,
	
	__pow = function(a, b)
		if type(a) == "number" then
			return vec(a ^ b[1], a ^ b[2], a ^ b[3], a ^ b[4])
		elseif type(b) == "number" then
			return vec(a[1] ^ b, a[2] ^ b, a[3] ^ b, a[4] ^ b)
		else
			return vec(a[1] ^ b[1], a[2] ^ b[2], a[3] ^ b[3], a[4] ^ b[4])
		end
	end,
	
	__eq = function(a, b)
		return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
	end,
	
	__len = function()
		return 4
	end,
	
	__tostring = function(self)
		return "{" .. self[1] .. ", " .. self[2] .. ", " .. self[3] .. ", " .. self[4] .. "}"
	end,
	
	__index = function(self, key)
		if key == "x" then
			return self[1]
		elseif key == "y" then
			return self[2]
		elseif key == "z" then
			return self[3]
		elseif key == "w" then
			return self[4]
		else
			return rawget(methods, key)
		end
	end,
	
	__newindex = function(self, key, value)
		if key == "x" then
			rawset(self, 1, value)
		elseif key == "y" then
			rawset(self, 2, value)
		elseif key == "z" then
			rawset(self, 3, value)
		elseif key == "w" then
			rawset(self, 4, value)
		else
			rawset(self, key, value)
		end
	end,
}

return setmetatable(vec, vec)