--[[
Helpful optimized operations
--]]

local matrix = _G.mat4
local methods = getmetatable(matrix.getIdentity()).__index

function methods:translate(x, y, z)
	if type(x) == "table" then
		x, y, z = x[1], x[2], x[3]
	else
		x = x or 0
		y = y or 0
		z = z or 0
	end
	
	local m = matrix({
		self[1],
		self[2],
		self[3],
		self[1] * x + self[2] * y + self[3] * z + self[4],
		self[5],
		self[6],
		self[7],
		self[5] * x + self[6] * y + self[7] * z + self[8],
		self[9],
		self[10],
		self[11],
		self[9] * x + self[10] * y + self[11] * z + self[12],
		self[13],
		self[14],
		self[15],
		self[16],
	})
	return m
end

function methods:scale(x, y, z)
	if type(x) == "table" then
		x, y, z = x[1], x[2], x[3]
	else
		x = x or 1
		y = y or x
		z = z or x
	end
	
	local m = matrix({
		self[1] * x, self[2] * y, self[3] * z, self[4],
		self[5] * x, self[6] * y, self[7] * z, self[8],
		self[9] * x, self[10] * y, self[11] * z, self[12],
		self[13], self[14], self[15], self[16],
	})
	return m
end

function methods:rotateX(rx)
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	
	local m = matrix({
		self[1],
		self[2] * c + self[3] * s,
		self[2] * (-s) + self[3] * c,
		self[4],
		self[5],
		self[6] * c + self[7] * s,
		self[6] * (-s) + self[7] * c,
		self[8],
		self[9],
		self[10] * c + self[11] * s,
		self[10] * (-s) + self[11] * c,
		self[12],
		self[13],
		self[14] * c + self[15] * s,
		self[14] * (-s) + self[15] * c,
		self[16],
	})
	return m
end

function methods:rotateY(ry)
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	
	local m = matrix({
		self[1] * c + self[3] * s,
		self[2],
		self[1] * (-s) + self[3] * c,
		self[4],
		self[5] * c + self[7] * s,
		self[6],
		self[5] * (-s) + self[7] * c,
		self[8],
		self[9] * c + self[11] * s,
		self[10],
		self[9] * (-s) + self[11] * c,
		self[12],
		self[13] * c + self[15] * s,
		self[14],
		self[13] * (-s) + self[15] * c,
		self[16],
	})
	return m
end

function methods:rotateZ(rz)
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	
	local m = matrix({
		self[1] * c + self[2] * (-s),
		self[1] * s + self[2] * c,
		self[3],
		self[4],
		self[5] * c + self[6] * (-s),
		self[5] * s + self[6] * c,
		self[7],
		self[8],
		self[9] * c + self[10] * (-s),
		self[9] * s + self[10] * c,
		self[11],
		self[12],
		self[13] * c + self[14] * (-s),
		self[13] * s + self[14] * c,
		self[15],
		self[16],
	})
	return m
end

function methods:transform(x, y, angle, sx, sy, ox, oy, kx, ky)
	x = x or 0
	y = y or 0
	angle = angle or 0
	sx = sx or 1
	sy = sy or sx
	ox = ox or 0
	oy = oy or 0
	kx = kx or 0
	ky = ky or 0
	
	local c = math.cos(angle)
	local s = math.sin(angle)
	
	local e0 = c * sx - ky * s * sy
	local e1 = s * sx + ky * c * sy
	local e4 = kx * c * sx - s * sy
	local e5 = kx * s * sx + c * sy
	local e12 = x - ox * e0 - oy * e4
	local e13 = y - ox * e1 - oy * e5
	
	local m = matrix({
		self[1] * e0 + self[2] * e1,
		self[1] * e4 + self[2] * e5,
		self[3],
		self[1] * e12 + self[2] * e13 + self[4],
		self[5] * e0 + self[6] * e1,
		self[5] * e4 + self[6] * e5,
		self[4],
		self[5] * e12 + self[6] * e13 + self[8],
		self[9] * e0 + self[10] * e1,
		self[9] * e4 + self[10] * e5,
		self[11],
		self[9] * e12 + self[10] * e13 + self[12],
		self[13] * e0 + self[14] * e1,
		self[13] * e4 + self[14] * e5,
		self[13] * e12 + self[14] * e13 + self[16]
	})
	
	return m
end

function methods:getLossySize()
	return math.sqrt(math.max(
			(self[1] ^ 2 + self[5] ^ 2 + self[9] ^ 2),
			(self[2] ^ 2 + self[6] ^ 2 + self[10] ^ 2),
			(self[3] ^ 2 + self[7] ^ 2 + self[11] ^ 2)
	))
end