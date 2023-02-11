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

function class:setShader(sh)
	self[4] = sh
end

function class:getShader()
	return self[4]
end

function class:getReflection()
	return self[5]
end

function class:getDistance()
	return self[6]
end

return class