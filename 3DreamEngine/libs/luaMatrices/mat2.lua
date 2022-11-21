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
	type = "mat2"
}
local metatable = {
	__index = methods
}
local matrix = { }

local matrixMeta = {
	__call = function(self, x, y, x1, y1)
		if not x then
			return setmetatable({ 0, 0, 0, 0 }, metatable)
		elseif type(x) == "table" then
			if type(x[1]) == "table" then
				return setmetatable({ x[1][1], x[1][2], x[2][1], x[2][2] }, metatable)
			else
				return setmetatable(x, metatable)
			end
		elseif type(x) == "number" then
			return setmetatable({ x, y, x1, y1 }, metatable)
		else
			error("can not construct matrix")
		end
	end
}

function matrix.getIdentity()
	return matrix({
		1, 0,
		0, 1,
	})
end

function methods:get(x, y)
	return self[(y - 1) * 2 + x]
end

function methods:set(x, y, v)
	self[(y - 1) * 2 + x] = v
end

function methods:clone()
	return matrix({
		self[1], self[2],
		self[3], self[4]
	})
end

function methods:unpack()
	return {
		{ self[1], self[2] },
		{ self[3], self[4] }
	}
end

function methods:det()
	return self[1] * self[4] - self[2] * self[3]
end

function methods:transpose()
	return matrix({
		self[1], self[3],
		self[2], self[4]
	})
end

function methods:trace()
	return self[1] + self[3]
end

function methods:invert()
	return mat2({
		self[4], -self[2],
		-self[3], self[1]
	}) / self:det()
end

function metatable.__add(a, b)
	if type(a) == "number" then
		return matrix({
			a + b[1],
			a + b[2],
			a + b[3],
			a + b[4]
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] + b,
			a[2] + b,
			a[3] + b,
			a[4] + b
		})
	else
		return matrix({
			a[1] + b[1],
			a[2] + b[2],
			a[3] + b[3],
			a[4] + b[4]
		})
	end
end

function metatable.__sub(a, b)
	if type(a) == "number" then
		return matrix({
			a - b[1],
			a - b[2],
			a - b[3],
			a - b[4]
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] - b,
			a[2] - b,
			a[3] - b,
			a[4] - b
		})
	else
		return matrix({
			a[1] - b[1],
			a[2] - b[2],
			a[3] - b[3],
			a[4] - b[4]
		})
	end
end

function metatable.__mul(a, b)
	if type(a) == "number" then
		return matrix({
			a * b[1],
			a * b[2],
			a * b[3],
			a * b[4]
		})
	elseif type(b) == "number" then
		return matrix({
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
		return matrix({
			a[1] * b[1] + a[2] * b[3],
			a[1] * b[2] + a[2] * b[4],
			a[3] * b[1] + a[4] * b[3],
			a[3] * b[2] + a[4] * b[4]
		})
	end
end

function metatable.__div(a, b)
	if type(a) == "number" then
		return matrix({
			a / b[1],
			a / b[2],
			a / b[3],
			a / b[4]
		})
	elseif type(b) == "number" then
		return matrix({
			a[1] / b,
			a[2] / b,
			a[3] / b,
			a[4] / b
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
		-a[1], -a[2],
		-a[3], -a[4]
	})
end

function metatable.__pow(a, b)
	if type(a) == "number" then
		error("not supported")
	elseif type(b) == "number" then
		assert(math.floor(b) == b and b > 0, "only positive integer power supported")
		local t = a * a
		for _ = 3, b do
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
	return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
end

function metatable.__len()
	return 2
end

function metatable.__tostring(a)
	return string.format("%s\t%s\n%s\t%s",
			a[1], a[2],
			a[3], a[4]
	)
end

return setmetatable(matrix, matrixMeta)