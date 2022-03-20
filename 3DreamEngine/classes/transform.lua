local lib = _3DreamEngine

local notInitError = "Transform not initialized, call reset() at least once."

local I = mat4:getIdentity()

local class = { }
function class:reset()
	self.transform = I
	return self
end

function class:setTransform(t)
	self.transform = t
	self.inverseTransform = false
	self.dynamic = true
	return self
end
function class:getTransform()
	return self.transform
end

function class:translate(x, y, z)
	self.transform = (self.transform or I):translate(x, y, z)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:scale(x, y, z)
	self.transform = (self.transform or I):scale(x, y, z)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateX(rx)
	self.transform = (self.transform or I):rotateX(rx)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateY(ry)
	self.transform = (self.transform or I):rotateY(ry)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:rotateZ(rz)
	self.transform = (self.transform or I):rotateZ(rz)
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:setDirection(normal, up)
	self.transform = lib:lookInDirection(normal, up):invert()
	self.inverseTransform = false
	self.dynamic = true
	return self
end

function class:getInvertedTransform()
	if not self.inverseTransform then
		self.inverseTransform = self.transform:invert()
	end
	return self.inverseTransform
end

function class:setDynamic(dynamic)
	self.dynamic = dynamic or false
end
function class:isDynamic()
	return self.dynamic
end

return class