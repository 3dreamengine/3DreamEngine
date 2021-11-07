local lib = _3DreamEngine

local notInitError = "Transform not initialized, call reset() at least once."

local I = mat4:getIdentity()

local class = { }
function class:reset(obj)
	obj.transform = I
	return obj
end

function class:setTransform(obj, t)
	obj.transform = t
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end
function class:getTransform(obj)
	return obj.transform
end

function class:translate(obj, x, y, z)
	obj.transform = (obj.transform or I):translate(x, y, z)
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end

function class:scale(obj, x, y, z)
	obj.transform = (obj.transform or I):scale(x, y, z)
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end

function class:rotateX(obj, rx)
	obj.transform = (obj.transform or I):rotateX(rx)
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end

function class:rotateY(obj, ry)
	obj.transform = (obj.transform or I):rotateY(ry)
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end

function class:rotateZ(obj, rz)
	obj.transform = (obj.transform or I):rotateZ(rz)
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end

function class:setDirection(obj, normal, up)
	obj.transform = lib:lookInDirection(normal, up):invert()
	obj.inverseTransform = false
	obj.dynamic = true
	return obj
end

function class:getInvertedTransform(obj)
	if not obj.inverseTransform then
		obj.inverseTransform = obj.transform:invert()
	end
	return obj.inverseTransform
end

function class:setDynamic(dynamic)
	self.dynamic = dynamic or false
end
function class:isDynamic()
	return self.dynamic
end

return class