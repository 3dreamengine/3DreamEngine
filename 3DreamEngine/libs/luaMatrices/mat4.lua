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
		return mat({
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		})
	end,
	
	getTranslate = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		return mat({
			1, 0, 0, x or 0,
			0, 1, 0, y or 0,
			0, 0, 1, z or 0,
			0, 0, 0, 1,
		})
	end,

	getScale = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		return mat({
			x, 0, 0, 0,
			0, y or x, 0, 0,
			0, 0, z or x, 0,
			0, 0, 0, 1,
		})
	end,

	getRotateX = function(self, rx)
		local c = math.cos(rx or 0)
		local s = math.sin(rx or 0)
		return mat({
			1, 0, 0, 0,
			0, c, -s, 0,
			0, s, c, 0,
			0, 0, 0, 1,
		})
	end,

	getRotateY = function(self, ry)
		local c = math.cos(ry or 0)
		local s = math.sin(ry or 0)
		return mat({
			c, 0, -s, 0,
			0, 1, 0, 0,
			s, 0, c, 0,
			0, 0, 0, 1,
		})
	end,

	getRotateZ = function(self, rz)
		local c = math.cos(rz or 0)
		local s = math.sin(rz or 0)
		return mat({
			c, s, 0, 0,
			-s, c, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1,
		})
	end,
}

metatable = {
	__add = function(a, b)
		if type(a) == "number" then
			return mat({
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
			return mat({
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
			return mat({
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
	end,
	
	__sub = function(a, b)
		if type(a) == "number" then
			return mat({
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
			return mat({
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
			return mat({
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
	end,
	
	__mul = function(a, b)
		if type(a) == "number" then
			return mat({
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
			return mat({
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
			return vec4({
				a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4] * b[4],
				a[5] * b[1] + a[6] * b[2] + a[7] * b[3] + a[8] * b[4],
				a[9] * b[1] + a[10] * b[2] + a[11] * b[3] + a[12] * b[4],
				a[13] * b[1] + a[14] * b[2] + a[15] * b[3] + a[16] * b[4],
			})
		elseif b.type == "vec3" then
			return vec3({
				a[1] * b[1] + a[2] * b[2] + a[3] * b[3] + a[4],
				a[5] * b[1] + a[6] * b[2] + a[7] * b[3] + a[8],
				a[9] * b[1] + a[10] * b[2] + a[11] * b[3] + a[12],
			})
		else
			return mat({
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
	end,
	
	__div = function(a, b)
		if type(a) == "number" then
			return mat({
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
			return mat({
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
	end,
	
	__mod = function(a, b)
		error("not supported")
	end,
	
	__unm = function(a)
		return mat({
			-a[1],	-a[2],	-a[3],	-a[4],
			-a[5],	-a[6],	-a[7],	-a[8],
			-a[9],	-a[10],	-a[11],	-a[12],
			-a[13],	-a[14],	-a[15],	-a[16],
		})
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
	
	__index = function(self, key)
		return rawget(metatable, key)
	end,
	
	get = function(a, x, y)
		return a[(y-1)*4 + x]
	end,
	
	set = function(a, x, y, v)
		a[(y-1)*4 + x] = v
	end,
	
	clone = function(a)
		return mat({
			a[1],	a[2],	a[3],	a[4],
			a[5],	a[6],	a[7],	a[8],
			a[9],	a[10],	a[11],	a[12],
			a[13],	a[14],	a[15],	a[16],
		})
	end,
	
	unpack = function(a)
		return {
			{a[1],	a[2],	a[3],	a[4]},
			{a[5],	a[6],	a[7],	a[8]},
			{a[9],	a[10],	a[11],	a[12]},
			{a[13],	a[14],	a[15],	a[16]},
		}
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
		if size == 3 then
			return mat3({
				a[1+offsetX + offsetY*4], a[2+offsetX + offsetY*4], a[3+offsetX + offsetY*4],
				a[5+offsetX + offsetY*4], a[6+offsetX + offsetY*4], a[7+offsetX + offsetY*4],
				a[9+offsetX + offsetY*4], a[10+offsetX + offsetY*4], a[11+offsetX + offsetY*4],
			})
		elseif size == 2 then
			return mat2({
				a[1+offsetX + offsetY*4], a[2+offsetX + offsetY*4],
				a[5+offsetX + offsetY*4], a[6+offsetX + offsetY*4],
			})
		else
			error("invalid size")
		end
	end,
	
	transpose = function(a)
		return mat({
			a[1],	a[5],	a[9],	a[13],
			a[2],	a[6],	a[10],	a[14],
			a[3],	a[6],	a[11],	a[15],
			a[4],	a[8],	a[12],	a[16],
		})
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
		local d6 = 1/6
		local I = setmetatable({d6, 0, 0, 0, 0, d6, 0, 0, 0, 0, d6, 0, 0, 0, 0, d6}, metatable)
		
		return (I * (t*t*t - 3*t*t2 + 2*t3) - a * 0.5 * (t*t - t2) + a2 * t - a3) / d
	end,
	
	affineAdd = function(a, b)
		if b.type == "vec3" then
			do return a * mat4:getTranslate(b) end
			return mat({
				a[1] * b[1], a[2] * b[2], a[3] * b[3], a[4],
				a[5] * b[1], a[6] * b[2], a[7] * b[3], a[8],
				a[9] * b[1], a[10] * b[2], a[11] * b[3], a[12],
				a[13] * b[1], a[14] * b[6], a[15] * b[11], a[16],
			})
		else
			return mat({
				a[1] * b[1] + a[2] * b[5] + a[3] * b[9],
				a[1] * b[2] + a[2] * b[6] + a[3] * b[10],
				a[1] * b[3] + a[2] * b[7] + a[3] * b[11],
				a[1] * b[4] + a[2] * b[8] + a[3] * b[12] + a[4],
				a[5] * b[1] + a[6] * b[5] + a[7] * b[9],
				a[5] * b[2] + a[6] * b[6] + a[7] * b[10],
				a[5] * b[3] + a[6] * b[7] + a[7] * b[11],
				a[5] * b[4] + a[6] * b[8] + a[7] * b[12] + a[8],
				a[9] * b[1] + a[10] * b[5] + a[11] * b[9],
				a[9] * b[2] + a[10] * b[6] + a[11] * b[10],
				a[9] * b[3] + a[10] * b[7] + a[11] * b[11],
				a[9] * b[4] + a[10] * b[8] + a[11] * b[12] + a[12],
				0, 0, 0, 1
			})
		end
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

return setmetatable(mat, mat)