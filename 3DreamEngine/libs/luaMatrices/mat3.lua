--[[
MIT License

Copyright (c) 2022 Luke100000

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local methods = {
	type = "mat3"
}
local metatable = {
	__index = methods
}
local matrix = { }

local matrixMeta = {
	__call = function(self, x, y, z, x1, y1, z1, x2, y2, z2)
		if not x then
			return setmetatable({ 0, 0, 0, 0, 0, 0, 0, 0, 0 }, metatable)
		elseif type(x) == "table" then
			if type(x[1]) == "table" then
				return setmetatable({ x[1][1], x[1][2], x[1][3], x[2][1], x[2][2], x[2][3], x[3][1], x[3][2], x[3][3] }, metatable)
			else
				return setmetatable(x, metatable)
			end
		elseif type(x) == "number" then
			return setmetatable({ x, y, z, x1, y1, z1, x2, y2, z2 }, metatable)
		else
			error("can not construct matrix")
		end
	end
}

function matrix.getIdentity()
	return matrix({
		1, 0, 0,
		0, 1, 0,
		0, 0, 1
	})
end

function matrix.getTranslate(x, y)
	if type(x) == "table" then
		x, y = x[1], x[2]
	end
	return matrix({
		1, 0, x or 0,
		0, 1, y or 0,
		0, 0, 1
	})
end

function matrix.getScale(x, y, z)
	if type(x) == "table" then
		x, y = x[1], x[2]
	end
	return matrix({
		x, 0, 0,
		0, y or x, 0,
		0, 0, z or 1
	})
end

function matrix.getRotate(u, a)
	local l = u.x
	local m = u.y
	local n = u.z
	
	local sin = math.sin(a)
	local cos = math.cos(a)
	
	return mat3 {
		l * l * (1 - cos) + cos, m * l * (1 - cos) - n * sin, n * l * (1 - cos) + m * sin,
		l * m * (1 - cos) + n * sin, m * m * (1 - cos) + cos, n * m * (1 - cos) - l * sin,
		l * n * (1 - cos) - m * sin, m * n * (1 - cos) + l * sin, n * n * (1 - cos) + cos
	}
end

function matrix.getRotateX(rx)
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	return matrix({
		1, 0, 0,
		0, c, -s,
		0, s, c
	})
end

function matrix.getRotateY(ry)
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	return matrix({
		c, 0, -s,
		0, 1, 0,
		s, 0, c
	})
end

function matrix.getRotateZ(rz)
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	return matrix({
		c, s, 0,
		-s, c, 0,
		0, 0, 1
	})
end

function methods:get(x, y)
	return self[(y - 1) * 3 + x]
end

function methods:set(x, y, v)
	self[(y - 1) * 3 + x] = v
end

function methods:clone()
	return matrix({
		self[1], self[2], self[3],
		self[4], self[5], self[6],
		self[7], self[8], self[9]
	})
end

function methods:unpack()
	return {
		{ self[1], self[2], self[3] },
		{ self[4], self[5], self[6] },
		{ self[7], self[8], self[9] },
	}
end

function methods:det()
	return self[1] * (self[5] * self[9] - self[6] * self[8])
			- self[2] * (self[4] * self[9] - self[6] * self[7])
			+ self[3] * (self[4] * self[8] - self[5] * self[7])
end

function methods:subm(offsetX, offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0
	return mat2({
		self[1 + offsetX + offsetY * 3], self[2 + offsetX + offsetY * 3],
		self[4 + offsetX + offsetY * 3], self[5 + offsetX + offsetY * 3],
	})
end

function methods:transpose()
	return matrix({
		self[1], self[4], self[7],
		self[2], self[5], self[8],
		self[3], self[6], self[9]
	})
end

function methods:trace()
	return self[1] + self[5] + self[9]
end

function methods:invert()
	local A = self[5] * self[9] - self[6] * self[8]
	local B = -(self[4] * self[9] - self[6] * self[7])
	local C = (self[4] * self[8] - self[5] * self[7])
	local D = -(self[2] * self[9] - self[3] * self[8])
	local E = (self[1] * self[9] - self[3] * self[7])
	local F = -(self[1] * self[8] - self[2] * self[7])
	local G = (self[2] * self[6] - self[3] * self[5])
	local H = -(self[1] * self[6] - self[3] * self[4])
	local I = (self[1] * self[5] - self[2] * self[4])
	return mat3({ A, D, G, B, E, H, C, F, I }) / self:det()
end

function metatable.__add(a, b)
	if type(a) == "number" then
		return matrix({
			a + b[1],
			a + b[2],
			a + b[3],
			a + b[4],
			a + b[5],
			a + b[6],
			a + b[7],
			a + b[8],
			a + b[9],
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] + b,
			a[2] + b,
			a[3] + b,
			a[4] + b,
			a[5] + b,
			a[6] + b,
			a[7] + b,
			a[8] + b,
			a[9] + b,
		})
	else
		return matrix({
			a[1] + b[1],
			a[2] + b[2],
			a[3] + b[3],
			a[4] + b[4],
			a[5] + b[5],
			a[6] + b[6],
			a[7] + b[7],
			a[8] + b[8],
			a[9] + b[9],
		})
	end
end

function metatable.__sub(a, b)
	if type(a) == "number" then
		return matrix({
			a - b[1],
			a - b[2],
			a - b[3],
			a - b[4],
			a - b[5],
			a - b[6],
			a - b[7],
			a - b[8],
			a - b[9],
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] - b,
			a[2] - b,
			a[3] - b,
			a[4] - b,
			a[5] - b,
			a[6] - b,
			a[7] - b,
			a[8] - b,
			a[9] - b,
		})
	else
		return matrix({
			a[1] - b[1],
			a[2] - b[2],
			a[3] - b[3],
			a[4] - b[4],
			a[5] - b[5],
			a[6] - b[6],
			a[7] - b[7],
			a[8] - b[8],
			a[9] - b[9],
		})
	end
end

function metatable.__mul(a, b)
	if type(a) == "number" then
		return matrix({
			a * b[1],
			a * b[2],
			a * b[3],
			a * b[4],
			a * b[5],
			a * b[6],
			a * b[7],
			a * b[8],
			a * b[9],
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] * b,
			a[2] * b,
			a[3] * b,
			a[4] * b,
			a[5] * b,
			a[6] * b,
			a[7] * b,
			a[8] * b,
			a[9] * b,
		})
	elseif b.type == "vec3" then
		return vec3({
			a[1] * b[1] + a[2] * b[2] + a[3] * b[3],
			a[4] * b[1] + a[5] * b[2] + a[6] * b[3],
			a[7] * b[1] + a[8] * b[2] + a[9] * b[3],
		})
	elseif b.type == "vec2" then
		return vec2({
			a[1] * b[1] + a[2] * b[2] + a[3],
			a[4] * b[1] + a[5] * b[2] + a[6],
		})
	else
		return matrix({
			a[1] * b[1] + a[2] * b[4] + a[3] * b[7],
			a[1] * b[2] + a[2] * b[5] + a[3] * b[8],
			a[1] * b[3] + a[2] * b[6] + a[3] * b[9],
			a[4] * b[1] + a[5] * b[4] + a[6] * b[7],
			a[4] * b[2] + a[5] * b[5] + a[6] * b[8],
			a[4] * b[3] + a[5] * b[6] + a[6] * b[9],
			a[7] * b[1] + a[8] * b[4] + a[9] * b[7],
			a[7] * b[2] + a[8] * b[5] + a[9] * b[8],
			a[7] * b[3] + a[8] * b[6] + a[9] * b[9],
		})
	end
end

function metatable.__div(a, b)
	if type(a) == "number" then
		return matrix({
			a / b[1],
			a / b[2],
			a / b[3],
			a / b[4],
			a / b[5],
			a / b[6],
			a / b[7],
			a / b[8],
			a / b[9],
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] / b,
			a[2] / b,
			a[3] / b,
			a[4] / b,
			a[5] / b,
			a[6] / b,
			a[7] / b,
			a[8] / b,
			a[9] / b,
		})
	else
		error("you can not divide two matrices!")
	end
end

function metatable.__mod(a, b)
	error("not supported")
end

function metatable.__unm(a)
	return matrix({
		-a[1], -a[2], -a[3],
		-a[4], -a[5], -a[6],
		-a[7], -a[8], -a[9],
	})
end

function metatable.__pow(a, b)
	if type(a) == "number" then
		error("not supported")
	elseif type(b) == "number" then
		assert(math.floor(b) == b and b > 0, "only positive integer power supported")
		local t = a * a
		for i = 3, b do
			t = t * a
		end
		return t
	elseif b == "T" then
		return a:transpose()
	else
		error("not supported")
	end
end

function metatable.__eq(a, b)
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
			and a[4] == b[4] and a[5] == b[5] and a[6] == b[6]
			and a[7] == b[7] and a[8] == b[8] and a[9] == b[9]
end

function metatable.__len()
	return 3
end

function metatable.__tostring(a)
	return string.format("%s\t%s\t%s\n%s\t%s\t%s\n%s\t%s\t%s",
			a[1], a[2], a[3],
			a[4], a[5], a[6],
			a[7], a[8], a[9]
	)
end

return setmetatable(matrix, matrixMeta)