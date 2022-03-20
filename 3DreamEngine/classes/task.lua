local identityMatrix = mat4:getIdentity()

local class = {
	link = {"task"}
}

function class:getMesh()
	return self[1]
end

function class:getTransform()
	return self[2] or identityMatrix
end

function class:getPos()
	return self[3]
end

function class:getSize()
	return self[4]
end

function class:setShaderID(sh)
	self[5] = sh
end

function class:getShaderID()
	return self[5]
end

function class:getBoneTransforms()
	return self[6]
end

function class:getReflection()
	return self[7]
end

function class:getDistance()
	return self[8]
end

function class:setDistance(d)
	self[8] = d
end

return class