--[[
MIT License

Copyright (c) 2020 Luke100000

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

local mat
local metatable
local methods

mat = {
	__call = function(self, x, y, z, w, x1, y1, z1, w1, x2, y2, z2, w2, x3, y3, z3, w3)
		if not x then
			return setmetatable({0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, metatable)
		elseif type(x) == "table" then
			if type(x[1]) == "table" then
				return setmetatable({x[1][1], x[1][2], x[1][3], x[1][4], x[2][1], x[2][2], x[2][3], x[2][4], x[3][1], x[3][2], x[3][3], x[3][4], x[4][1], x[4][2], x[4][3], x[4][4]}, metatable)
			else
				return setmetatable(x, metatable)
			end
		elseif type(x) == "number" then
			return setmetatable({x, y, z, w, x1, y1, z1, w1, x2, y2, z2, w2, x3, y3, z3, w3}, metatable)
		else
			error("can not construct matrix")
		end
	end,
	
	getIdentity = function(self)
		local c = mat({
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		})
		return c
	end,
	
	getTranslate = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		local c = mat({
			1, 0, 0, x or 0,
			0, 1, 0, y or 0,
			0, 0, 1, z or 0,
			0, 0, 0, 1,
		})
		return c
	end,

	getScale = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		local c = mat({
			x, 0, 0, 0,
			0, y or x, 0, 0,
			0, 0, z or x, 0,
			0, 0, 0, 1,
		})
		return c
	end,
	
	getRotate = function(self, u, a)
		local l = u.x
		local m = u.y
		local n = u.z
		
		local sin = math.sin(a)
		local cos = math.cos(a)
		
		local c = mat3{
			l * l * (1-cos) + cos, m * l * (1-cos) - n * sin, n * l * (1-cos) + m * sin, 0.0,
			l * m * (1-cos) + n * sin, m * m * (1-cos) + cos, n * m * (1-cos) - l * sin, 0.0,
			l * n * (1-cos) - m * sin, m * n * (1-cos) + l * sin, n * n * (1-cos) + cos, 0.0,
			0.0, 0.0, 0.0, 1.0
		}
		return c
	end,

	getRotateX = function(self, rx)
		local c = math.cos(rx or 0)
		local s = math.sin(rx or 0)
		local c = mat({
			1, 0, 0, 0,
			0, c, -s, 0,
			0, s, c, 0,
			0, 0, 0, 1,
		})
		return c
	end,

	getRotateY = function(self, ry)
		local c = math.cos(ry or 0)
		local s = math.sin(ry or 0)
		local c = mat({
			c, 0, -s, 0,
			0, 1, 0, 0,
			s, 0, c, 0,
			0, 0, 0, 1,
		})
		return c
	end,

	getRotateZ = function(self, rz)
		local c = math.cos(rz or 0)
		local s = math.sin(rz or 0)
		local c = mat({
			c, s, 0, 0,
			-s, c, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1,
		})
		return c
	end,
}

methods = {
	get = function(a, x, y)
		return a[(y-1)*4 + x]
	end,
	
	set = function(a, x, y, v)
		a[(y-1)*4 + x] = v
	end,
	
	clone = function(a)
		local c = mat({
			a[1],	a[2],	a[3],	a[4],
			a[5],	a[6],	a[7],	a[8],
			a[9],	a[10],	a[11],	a[12],
			a[13],	a[14],	a[15],	a[16],
		})
		return c
	end,
	
	unpack = function(a)
		local c = {
			{a[1],	a[2],	a[3],	a[4]},
			{a[5],	a[6],	a[7],	a[8]},
			{a[9],	a[10],	a[11],	a[12]},
			{a[13],	a[14],	a[15],	a[16]},
		}
		return c
	end,
	
	det = function(a)
		return a[1] *
				(a[6] * (a[11] * a[16] - a[12] * a[15])
				-a[7] * (a[10] * a[16] - a[12] * a[14])
				+a[8] * (a[10] * a[15] - a[11] * a[14]))
			- a[2] *
				(a[5] * (a[11] * a[16] - a[12] * a[15])
				-a[7] * (a[9] * a[16] - a[12] * a[13])
				+a[8] * (a[9] * a[15] - a[11] * a[13]))
			+ a[3] *
				(a[5] * (a[10] * a[16] - a[12] * a[14])
				-a[6] * (a[9] * a[16] - a[12] * a[13])
				+a[8] * (a[9] * a[14] - a[10] * a[13]))
			- a[4] *
				(a[5] * (a[10] * a[15] - a[11] * a[14])
				-a[6] * (a[9] * a[15] - a[11] * a[13])
				+a[7] * (a[9] * a[14] - a[10] * a[13]))
	end,
	
	subm = function(a, size, offsetX, offsetY)
		size = size or 3
		offsetX = offsetX or 0
		offsetY = offsetY or 0
		local c
		if size == 3 then
			c = mat3({
				a[1+offsetX + offsetY*4], a[2+offsetX + offsetY*4], a[3+offsetX + offsetY*4],
				a[5+offsetX + offsetY*4], a[6+offsetX + offsetY*4], a[7+offsetX + offsetY*4],
				a[9+offsetX + offsetY*4], a[10+offsetX + offsetY*4], a[11+offsetX + offsetY*4],
			})
		elseif size == 2 then
			local c = mat2({
				a[1+offsetX + offsetY*4], a[2+offsetX + offsetY*4],
				a[5+offsetX + offsetY*4], a[6+offsetX + offsetY*4],
			})
		else
			error("invalid size")
		end
		return c
	end,
	
	transpose = function(a)
		local c = mat({
			a[1],	a[5],	a[9],	a[13],
			a[2],	a[6],	a[10],	a[14],
			a[3],	a[6],	a[11],	a[15],
			a[4],	a[8],	a[12],	a[16],
		})
		return c
	end,
	
	trace = function(a)
		return a[1] + a[6] + a[11] + a[16]
	end,
	
	invert = function(a)
		local a2 = a*a
		local a3 = a2*a
		local t = a:trace()
		local t2 = a2:trace()
		local t3 = a3:trace()
		local d = a:det()
		local dth = 1 / d
		local d6 = (t^3 - 3*t*t2 + 2*t3) / 6
		local m1 = 0.5 * (t*t - t2)
		
		return 	mat4({
			(a2[1] * t - m1 * a[1] - a3[1] + d6) * dth,
			(a2[2] * t - m1 * a[2] - a3[2]) * dth,
			(a2[3] * t - m1 * a[3] - a3[3]) * dth,
			(a2[4] * t - m1 * a[4] - a3[4]) * dth,
			(a2[5] * t - m1 * a[5] - a3[5]) * dth,
			(a2[6] * t - m1 * a[6] - a3[6] + d6) * dth,
			(a2[7] * t - m1 * a[7] - a3[7]) * dth,
			(a2[8] * t - m1 * a[8] - a3[8]) * dth,
			(a2[9] * t - m1 * a[9] - a3[9]) * dth,
			(a2[10] * t - m1 * a[10] - a3[10]) * dth,
			(a2[11] * t - m1 * a[11] - a3[11] + d6) * dth,
			(a2[12] * t - m1 * a[12] - a3[12]) * dth,
			(a2[13] * t - m1 * a[13] - a3[13]) * dth,
			(a2[14] * t - m1 * a[14] - a3[14]) * dth,
			(a2[15] * t - m1 * a[15] - a3[15]) * dth,
			(a2[16] * t - m1 * a[16] - a3[16] + d6) * dth,
		})
	end,
	
	--transformations
	translate = function(a, x, y, z)
		return mat:getTranslate(x, y, z) * a
	end,
	scale = function(a, x, y, z)
		return mat:getScale(x, y, z) * a
	end,
	rotateX = function(a, rx)
		return mat:getRotateX(rx) * a
	end,
	rotateY = function(a, ry)
		return mat:getRotateY(ry) * a
	end,
	rotateZ = function(a, rz)
		return mat:getRotateZ(rz) * a
	end,
	
	type = "mat4",
}

metatable = {
	__add = function(a, b)
		local c
		if type(a) == "number" then
			c = mat({
				a + b[1],
				a + b[2],
				a + b[3],
				a + b[4],
				a + b[5],
				a + b[6],
				a + b[7],
				a + b[8],
				a + b[9],
				a + b[10],
				a + b[11],
				a + b[12],
				a + b[13],
				a + b[14],
				a + b[15],
				a + b[16],
			})
		elseif type(b) == "number" then
			c = mat({
				a[1] + b,
				a[2] + b,
				a[3] + b,
				a[4] + b,
				a[5] + b,
				a[6] + b,
				a[7] + b,
				a[8] + b,
				a[9] + b,
				a[10] + b,
				a[11] + b,
				a[12] + b,
				a[13] + b,
				a[14] + b,
				a[15] + b,
				a[16] + b,
			})
		else
			c = mat({
				a[1] + b[1],
				a[2] + b[2],
				a[3] + b[3],
				a[4] + b[4],
				a[5] + b[5],
				a[6] + b[6],
				a[7] + b[7],
				a[8] + b[8],
				a[9] + b[9],
				a[10] + b[10],
				a[11] + b[11],
				a[12] + b[12],
				a[13] + b[13],
				a[14] + b[14],
				a[15] + b[15],
				a[16] + b[16],
			})
		end
		return c
	end,
	
	__sub = function(a, b)
		local c
		if type(a) == "number" then
			c = mat({
				a - b[1],
				a - b[2],
				a - b[3],
				a - b[4],
				a - b[5],
				a - b[6],
				a - b[7],
				a - b[8],
				a - b[9],
				a - b[10],
				a - b[11],
				a - b[12],
				a - b[13],
				a - b[14],
				a - b[15],
				a - b[16],
			})
		elseif type(b) == "number" then
			c = mat({
				a[1] - b,
				a[2] - b,
				a[3] - b,
				a[4] - b,
				a[5] - b,
				a[6] - b,
				a[7] - b,
				a[8] - b,
				a[9] - b,
				a[10] - b,
				a[11] - b,
				a[12] - b,
				a[13] - b,
				a[14] - b,
				a[15] - b,
				a[16] - b,
			})
		else
			c = mat({
				a[1] - b[1],
				a[2] - b[2],
				a[3] - b[3],
				a[4] - b[4],
				a[5] - b[5],
				a[6] - b[6],
				a[7] - b[7],
				a[8] - b[8],
				a[9] - b[9],
				a[10] - b[10],
				a[11] - b[11],
				a[12] - b[12],
				a[13] - b[13],
				a[14] - b[14],
				a[15] - b[15],
				a[16] - b[16],
			})
		end
		return c
	end,
	
	__mul = function(a, b)
		local c
		if type(a) == "number" then
			c = mat({
				a * b[1],
				a * b[2],
				a * b[3],
				a * b[4],
				a * b[5],
				a * b[6],
				a * b[7],
				a * b[8],
				a * b[9],
				a * b[10],
				a * b[11],
				a * b[12],
				a * b[13],
				a * b[14],
				a * b[15],
				a * b[16],
			})
		elseif type(b) == "number" then
			c = mat({
				a[1] * b,
				a[2] * b,
				a[3] * b,
				a[4] * b,
				a[5] * b,
				a[6] * b,
				a[7] * b,
				a[8] * b,
				a[9] * b,
				a[10] * b,
				a[11] * b,
				a[12] * b,
				a[13] * b,
				a[14] * b,
				a[15] * b,
				a[16] * b,
			})
		elseif b.type == "vec4" then
			c = vec4({
				a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4] * b[4],
				a[5] * b[1] + a[6] * b[2] + a[7] * b[3] + a[8] * b[4],
				a[9] * b[1] + a[10] * b[2] + a[11] * b[3] + a[12] * b[4],
				a[13] * b[1] + a[14] * b[2] + a[15] * b[3] + a[16] * b[4],
			})
		elseif b.type == "vec3" then
			c = vec3({
				a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4],
				a[5] * b[1] + a[6] * b[2] + a[7] * b[3] + a[8],
				a[9] * b[1] + a[10] * b[2] + a[11] * b[3] + a[12],
			})
		else
			c = mat({
				a[1] * b[1] + a[2] * b[5] + a[3] * b[9] + a[4] * b[13],
				a[1] * b[2] + a[2] * b[6] + a[3] * b[10] + a[4] * b[14],
				a[1] * b[3] + a[2] * b[7] + a[3] * b[11] + a[4] * b[15],
				a[1] * b[4] + a[2] * b[8] + a[3] * b[12] + a[4] * b[16],
				a[5] * b[1] + a[6] * b[5] + a[7] * b[9] + a[8] * b[13],
				a[5] * b[2] + a[6] * b[6] + a[7] * b[10] + a[8] * b[14],
				a[5] * b[3] + a[6] * b[7] + a[7] * b[11] + a[8] * b[15],
				a[5] * b[4] + a[6] * b[8] + a[7] * b[12] + a[8] * b[16],
				a[9] * b[1] + a[10] * b[5] + a[11] * b[9] + a[12] * b[13],
				a[9] * b[2] + a[10] * b[6] + a[11] * b[10] + a[12] * b[14],
				a[9] * b[3] + a[10] * b[7] + a[11] * b[11] + a[12] * b[15],
				a[9] * b[4] + a[10] * b[8] + a[11] * b[12] + a[12] * b[16],
				a[13] * b[1] + a[14] * b[5] + a[15] * b[9] + a[16] * b[13],
				a[13] * b[2] + a[14] * b[6] + a[15] * b[10] + a[16] * b[14],
				a[13] * b[3] + a[14] * b[7] + a[15] * b[11] + a[16] * b[15],
				a[13] * b[4] + a[14] * b[8] + a[15] * b[12] + a[16] * b[16],
			})
		end
		return c
	end,
	
	__div = function(a, b)
		local c
		if type(a) == "number" then
			c = mat({
				a / b[1],
				a / b[2],
				a / b[3],
				a / b[4],
				a / b[5],
				a / b[6],
				a / b[7],
				a / b[8],
				a / b[9],
				a / b[10],
				a / b[11],
				a / b[12],
				a / b[13],
				a / b[14],
				a / b[15],
				a / b[16],
			})
		elseif type(b) == "number" then
			c = mat({
				a[1] / b,
				a[2] / b,
				a[3] / b,
				a[4] / b,
				a[5] / b,
				a[6] / b,
				a[7] / b,
				a[8] / b,
				a[9] / b,
				a[10] / b,
				a[11] / b,
				a[12] / b,
				a[13] / b,
				a[14] / b,
				a[15] / b,
				a[16] / b,
			})
		else
			error("you can not divide two matrices!")
		end
		return c
	end,
	
	__mod = function(a, b)
		error("not supported")
	end,
	
	__unm = function(a)
		local c = mat({
			-a[1],	-a[2],	-a[3],	-a[4],
			-a[5],	-a[6],	-a[7],	-a[8],
			-a[9],	-a[10],	-a[11],	-a[12],
			-a[13],	-a[14],	-a[15],	-a[16],
		})
		return c
	end,
	
	__pow = function(a, b)
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
	end,
	
	__eq = function(a, b)
		return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
			and a[5] == b[5] and a[6] == b[6] and a[7] == b[7] and a[8] == b[8]
			and a[9] == b[9] and a[10] == b[10] and a[11] == b[11] and a[12] == b[12]
			and a[13] == b[13] and a[14] == b[14] and a[15] == b[15] and a[16] == b[16]
	end,
	
	__len = function()
		return 4
	end,
	
	__tostring = function(a)
		return string.format("%s\t%s\t%s\t%s\n%s\t%s\t%s\t%s\n%s\t%s\t%s\t%s\n%s\t%s\t%s\t%s",
			a[1],	a[2],	a[3],	a[4],
			a[5],	a[6],	a[7],	a[8],
			a[9],	a[10],	a[11],	a[12],
			a[13],	a[14],	a[15],	a[16]
		)
	end,
	
	__index = methods
}

return setmetatable(mat, mat)