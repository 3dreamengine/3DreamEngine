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
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	translate = function(obj, x, y, z)
		obj.transform = (obj.transform or I):translate(x, y, z)
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	scale = function(obj, x, y, z)
		obj.transform = (obj.transform or I):scale(x, y, z)
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	rotateX = function(obj, rx)
		obj.transform = (obj.transform or I):rotateX(rx)
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	rotateY = function(obj, ry)
		obj.transform = (obj.transform or I):rotateY(ry)
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	rotateZ = function(obj, rz)
		obj.transform = (obj.transform or I):rotateZ(rz)
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	setDirection = function(obj, normal, up)
		obj.transform = lib:lookInDirection(normal, up):invert()
		obj.inverseTransform = false
		obj.dynamic = true
		return obj
	end,

	getInvertedTransform = function(obj)
		if not obj.inverseTransform then
			obj.inverseTransform = obj.transform:invert()
		end
		return obj.inverseTransform
	end,
	
	setDynamic = function(self, dynamic)
		self.dynamic = dynamic or false
	end,
	isDynamic = function(self)
		return self.dynamic
	end
}