local identityMatrix = mat4.getIdentity()

---@class DreamTask
local class = {
	links = {"task"}
}

function class:getMesh()
	return self[1]
end

function class:getTransform()
	return self[2] or identityMatrix
end

function class:getPosition()
	return self[3]
end

function class:getSize()
	return self[4]
end

function class:setShader(sh)
	self[5] = sh
end

function class:getShader()
	return self[5]
end

function class:getReflection()
	return self[6]
end

function class:getDistance()
	return self[7]
end

function class:setDistance(d)
	self[7] = d
end

return class