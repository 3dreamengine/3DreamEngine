local lib = _3DreamEngine

local notInitError = "Transform not initialized, call reset() at least once."

local I = mat4:getIdentity()

return {
	reset = function(obj)
		obj.transform = I
		return obj
	end,

	setTransform = function(obj, t)
		obj.transform = t
		return obj
	end,

	translate = function(obj, x, y, z)
		obj.transform = (obj.transform or I):translate(x, y, z)
		return obj
	end,

	scale = function(obj, x, y, z)
		obj.transform = (obj.transform or I):scale(x, y, z)
		return obj
	end,

	rotateX = function(obj, rx)
		obj.transform = (obj.transform or I):rotateX(rx)
		return obj
	end,

	rotateY = function(obj, ry)
		obj.transform = (obj.transform or I):rotateY(ry)
		return obj
	end,

	rotateZ = function(obj, rz)
		obj.transform = (obj.transform or I):rotateZ(rz)
		return obj
	end,

	setDirection = function(obj, normal, up)
		obj.transform = lib:lookAt(vec3(0, 0, 0), normal, up):invert() * obj.transform
		return obj
	end,
}