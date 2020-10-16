local lib = _3DreamEngine

local notInitError = "Transform not initialized, call reset() at least once."

return {
	reset = function(obj)
		obj.transform = mat4:getIdentity()
		return obj
	end,

	setTransform = function(obj, t)
		obj.transform = t
		return obj
	end,

	translate = function(obj, x, y, z)
		assert(obj.transform, notInitError)
		obj.transform = obj.transform:translate(x, y, z)
		return obj
	end,

	translateTo = function(obj, x, y, z)
		obj.transform = mat4:getTranslate(x, y, z)
		return obj
	end,

	scale = function(obj, x, y, z)
		assert(obj.transform, notInitError)
		obj.transform = obj.transform:scale(x, y, z)
		return obj
	end,

	rotateX = function(obj, rx)
		assert(obj.transform, notInitError)
		obj.transform = obj.transform:rotateX(rx)
		return obj
	end,

	rotateY = function(obj, ry)
		assert(obj.transform, notInitError)
		obj.transform = obj.transform:rotateY(ry)
		return obj
	end,

	rotateZ = function(obj, rz)
		assert(obj.transform, notInitError)
		obj.transform = obj.transform:rotateZ(rz)
		return obj
	end,

	setDirection = function(obj, normal, up)
		obj.transform = lib:lookAt(vec3(0, 0, 0), normal, up):invert() * obj.transform
		return obj
	end,
}