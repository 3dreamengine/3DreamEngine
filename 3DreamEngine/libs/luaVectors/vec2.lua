local abs = math.abs
local vec
local metatable
local methods

vec = {
	__call = function(self, x, y)
		if not x then
			return setmetatable({ 0, 0 }, metatable)
		elseif type(x) == "number" then
			return setmetatable({ x, y }, metatable)
		else
			return setmetatable(x, metatable)
		end
	end,
}

methods = {
	clone = function(a)
		return vec(a[1], a[2])
	end,
	
	length = function(a)
		return math.sqrt(a[1] * a[1] + a[2] * a[2])
	end,
	
	lengthSquared = function(a)
		return a[1] * a[1] + a[2] * a[2]
	end,
	
	normalize = function(a)
		return a / a:length()
	end,
	
	abs = function(a)
		return vec(abs(a[1]), abs(a[2]))
	end,
	
	dot = function(a, b)
		return a[1] * b[1] + a[2] * b[2]
	end,
	
	reflect = function(i, n)
		return i - 2 * n:dot(i) * n
	end,
	
	min = function(a, b)
		return vec(math.min(a[1], b[1]), math.min(a[2], b[2]))
	end,
	
	max = function(a, b)
		return vec(math.max(a[1], b[1]), math.max(a[2], b[2]))
	end,
	
	unpack = function(a)
		return a[1], a[2]
	end,
	
	type = "vec2",
}

metatable = {
	__add = function(a, b)
		if type(a) == "number" then
			return vec(a + b[1], a + b[2])
		elseif type(b) == "number" then
			return vec(a[1] + b, a[2] + b)
		else
			return vec(a[1] + b[1], a[2] + b[2])
		end
	end,
	
	__sub = function(a, b)
		if type(a) == "number" then
			return vec(a - b[1], a - b[2])
		elseif type(b) == "number" then
			return vec(a[1] - b, a[2] - b)
		else
			return vec(a[1] - b[1], a[2] - b[2])
		end
	end,
	
	__mul = function(a, b)
		if type(a) == "number" then
			return vec(a * b[1], a * b[2])
		elseif type(b) == "number" then
			return vec(a[1] * b, a[2] * b)
		else
			return vec(a[1] * b[1], a[2] * b[2])
		end
	end,
	
	__div = function(a, b)
		if type(a) == "number" then
			return vec(a / b[1], a / b[2])
		elseif type(b) == "number" then
			return vec(a[1] / b, a[2] / b)
		else
			return vec(a[1] / b[1], a[2] / b[2])
		end
	end,
	
	__mod = function(a, b)
		if type(a) == "number" then
			return vec(a % b[1], a % b[2])
		elseif type(b) == "number" then
			return vec(a[1] % b, a[2] % b)
		else
			return vec(a[1] % b[1], a[2] % b[2])
		end
	end,
	
	__unm = function(a)
		return vec(-a[1], -a[2])
	end,
	
	__pow = function(a, b)
		if type(a) == "number" then
			return vec(a ^ b[1], a ^ b[2])
		elseif type(b) == "number" then
			return vec(a[1] ^ b, a[2] ^ b)
		else
			return vec(a[1] ^ b[1], a[2] ^ b[2])
		end
	end,
	
	__eq = function(a, b)
		return a[1] == b[1] and a[2] == b[2]
	end,
	
	__len = function()
		return 2
	end,
	
	__tostring = function(self)
		return "{" .. self[1] .. ", " .. self[2] .. "}"
	end,
	
	__index = function(self, key)
		if key == "x" then
			return self[1]
		elseif key == "y" then
			return self[2]
		else
			return rawget(methods, key)
		end
	end,
	
	__newindex = function(self, key, value)
		if key == "x" then
			rawset(self, 1, value)
		elseif key == "y" then
			rawset(self, 2, value)
		else
			rawset(self, key, value)
		end
	end,
}

return setmetatable(vec, vec)