--https://rosettacode.org/wiki/Quaternion_type#Lua
--modified by Luke100000

local quat = { }
local meta = { }

function quat.new(a, b, c, d)
	local q = type(a) == "table" and a or {a or 1, b or 0, c or 0, d or 0}
	return setmetatable(q, meta)
end

function quat.between(a, b)
	local w = math.sqrt(a:lengthSquared() * b:lengthSquared()) + a:dot(b)
	local c = a:cross(b)
	local q = setmetatable({w, c[1], c[2], c[3]}, meta)
	return q:normalize()
end

function quat.add(p, q)
	if type(p) == "number" then
		return quat.new(p+q[1], q[2], q[3], q[4])
	elseif type(q) == "number" then
		return quat.new(p[1]+q, p[2], p[3], p[4])
	else
		return quat.new(p[1]+q[1], p[2]+q[2], p[3]+q[3], p[4]+q[4])
	end
end

function quat.sub(p, q)
	if type(p) == "number" then
		return quat.new(p-q[1], q[2], q[3], q[4])
	elseif type(q) == "number" then
		return quat.new(p[1]-q, p[2], p[3], p[4])
	else
		return quat.new(p[1]-q[1], p[2]-q[2], p[3]-q[3], p[4]-q[4])
	end
end

function quat.unm(p)
	return quat.new(-p[1], -p[2], -p[3], -p[4])
end

function quat.mul(p, q)
	if type(p) == "number" then
		return quat.new(p*q[1], p*q[2], p*q[3], p*q[4])
	elseif type(q) == "number" then
		return quat.new(p[1]*q, p[2]*q, p[3]*q, p[4]*q)
	else
		return quat.new(
			p[1]*q[1] - p[2]*q[2] - p[3]*q[3] - p[4]*q[4],
			p[1]*q[2] + p[2]*q[1] + p[3]*q[4] - p[4]*q[3],
			p[1]*q[3] - p[2]*q[4] + p[3]*q[1] + p[4]*q[2],
			p[1]*q[4] + p[2]*q[3] - p[3]*q[2] + p[4]*q[1]
		)
	end
end

function quat.div(p, q)
	return quat.new(p[1] / q, p[2] / q, p[3] / q, p[4] / q)
end

function quat.conj(p)
	return quat.new(p[1], -p[2], -p[3], -p[4])
end

function quat.norm(p)
	return math.sqrt(p[1]^2 + p[2]^2 + p[3]^2 + p[4]^2)
end

function quat.clone(p)
	return quat.new(p[1], p[2], p[3], p[4])
end

function quat.toString(p)
	return string.format("%f + %fi + %fj + %fk", p[1], p[2], p[3], p[4])
end

function quat.isZero(p)
	return p[1] == 0 and p[2] == 0 and p[3] == 0 and p[4] == 0
end

function quat.normalize(p)
	if p:isZero() then
		return quat.new(0, 0, 0, 0)
	end
	return p / p:norm()
end

function quat.lerp(p, q, f)
	return p + f * (q - p)
end

function quat.nLerp(p, q, f)
	local dot = p[1] * q[1] + p[2] * q[2] + p[3] * q[3] + p[4] * q[4]
	if dot < 0 then
		return p:lerp(-q, f)
	else
		return p:lerp(q, f)
	end
end

--requires compatible mat4 lib
function quat.toMatrix(p)
	local xy = p[1] * p[2]
	local xz = p[1] * p[3]
	local xw = p[1] * p[4]
	local yz = p[2] * p[3]
	local yw = p[2] * p[4]
	local zw = p[3] * p[4]
	local xSquared = p[1] * p[1]
	local ySquared = p[2] * p[2]
	local zSquared = p[3] * p[3]
	
	local c = mat4({
		1 - 2 * (ySquared + zSquared),
		2 * (xy - zw),
		2 * (xz + yw),
		0,
		2 * (xy + zw),
		1 - 2 * (xSquared + zSquared),
		2 * (yz - xw),
		0,
		2 * (xz - yw),
		2 * (yz + xw),
		1 - 2 * (xSquared + ySquared),
		0,
		0, 0, 0, 1
	})
	return c
end

--requires compatible mat4 lib
function quat.fromMatrix(m)
	local tr = m[1] + m[5] + m[9]
	local w, x, y, z
	if tr > 0 then
		local S = math.sqrt(tr+1.0) * 2
		w = 0.25 * S
		x = (m[8] - m[6]) / S
		y = (m[3] - m[7]) / S
		z = (m[4] - m[2]) / S
	elseif m[1] > m[5] and m[1] > m[9] then
		local S = math.sqrt(1.0 + m[1] - m[5] - m[9]) * 2
		w = (m[8] - m[6]) / S
		x = 0.25 * S
		y = (m[2] + m[4]) / S
		z = (m[3] + m[7]) / S
	elseif m[5] > m[9] then
		local S = math.sqrt(1.0 + m[5] - m[1] - m[9]) * 2
		w = (m[3] - m[7]) / S
		x = (m[2] + m[4]) / S
		y = 0.25 * S
		z = (m[6] + m[8]) / S
	else
		local S = math.sqrt(1.0 + m[9] - m[1] - m[5]) * 2
		w = (m[4] - m[2]) / S
		x = (m[3] + m[7]) / S
		y = (m[6] + m[8]) / S
		z = 0.25 * S
	end
	return quat.new(x, y, z, w)
end

meta = {
	__add = quat.add,
	__sub = quat.sub,
	__unm = quat.unm,
	__mul = quat.mul,
	__div = quat.div,
	__tostring = quat.toString,
	__index = quat,
}

return setmetatable(quat, {__call = function(self, ...) return quat.new(...) end})