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
	__call = function(self, x, y, x1, y1)
		if not x then
			return setmetatable({0, 0, 0, 0}, metatable)
		elseif type(x) == "table" then
			if type(x[1]) == "table" then
				return setmetatable({x[1][1], x[1][2], x[2][1], x[2][2]}, metatable)
			else
				return setmetatable(x, metatable)
			end
		elseif type(x) == "number" then
			return setmetatable({x, y, x1, y1}, metatable)
		else
			error("can not construct matrix")
		end
	end,
	
	getIdentity = function()
		return mat({
			1, 0,
			0, 1,
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
				a + b[4]
			})
		elseif type(b) == "number" then
			return mat({
				a[1] + b,
				a[2] + b,
				a[3] + b,
				a[4] + b
			})
		else
			return mat({
				a[1] + b[1],
				a[2] + b[2],
				a[3] + b[3],
				a[4] + b[4]
			})
		end
	end,
	
	__sub = function(a, b)
		if type(a) == "number" then
			return mat({
				a - b[1],
				a - b[2],
				a - b[3],
				a - b[4]
			})
		elseif type(b) == "number" then
			return mat({
				a[1] - b,
				a[2] - b,
				a[3] - b,
				a[4] - b
			})
		else
			return mat({
				a[1] - b[1],
				a[2] - b[2],
				a[3] - b[3],
				a[4] - b[4]
			})
		end
	end,
	
	__mul = function(a, b)
		if type(a) == "number" then
			return mat({
				a * b[1],
				a * b[2],
				a * b[3],
				a * b[4]
			})
		elseif type(b) == "number" then
			return mat({
				a[1] * b,
				a[2] * b,
				a[3] * b,
				a[4] * b
			})
		elseif b.type == "vec2" then
			return vec2({
			a[1] * b[1] + a[2] * b[2],
			a[3] * b[1] + a[4] * b[2],
			})
		else
			return mat({
				a[1] * b[1] + a[2] * b[3],
				a[1] * b[2] + a[2] * b[4],
				a[3] * b[1] + a[4] * b[3],
				a[3] * b[2] + a[4] * b[4]
			})
		end
	end,
	
	__div = function(a, b)
		if type(a) == "number" then
			return mat({
				a / b[1],
				a / b[2],
				a / b[3],
				a / b[4]
			})
		elseif type(b) == "number" then
			return mat({
				a[1] / b,
				a[2] / b,
				a[3] / b,
				a[4] / b
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
			-a[1],	-a[2],
			-a[3],	-a[4]
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
	end,
	
	__len = function()
		return 2
	end,
	
	__tostring = function(a)
		return string.format("%s\t%s\n%s\t%s",
			a[1],	a[2],
			a[3],	a[4]
		)
	end,
	
	__index = function(self, key)
		return rawget(metatable, key)
	end,
	
	get = function(a, x, y)
		return a[(y-1)*2 + x]
	end,
	
	set = function(a, x, y, v)
		a[(y-1)*2 + x] = v
	end,
	
	clone = function(a)
		return mat({
			a[1],	a[2],
			a[3],	a[4]
		})
	end,
	
	unpack = function(a)
		return {
			{a[1],	a[2]},
			{a[3],	a[4]}
		}
	end,
	
	det = function(a)
		return a[1] * a[4] - a[2] * a[3]
	end,
	
	transpose = function(a)
		return mat({
			a[1],	a[3],
			a[2],	a[4]
		})
	end,
	
	trace = function(a)
		return a[1] + a[3]
	end,
	
	invert = function(a)
		return mat2({
			a[4], -a[2],
			-a[3], a[1]
		}) / a:det()
	end,
	
	type = "mat2",
}

return setmetatable(mat, mat)