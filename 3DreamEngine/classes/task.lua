local identityMatrix = _3DreamEngine.mat4.getIdentity()

---@class DreamTask
local class = {
	links = { "task" }
}

---@return DreamMesh
function class:getMesh()
	return self[1]
end

---@return DreamMat4
function class:getTransform()
	return self[2] or identityMatrix
end

---@return DreamVec3
function class:getPosition()
	return self[3]
end

---@param sh DreamShader
function class:setShader(sh)
	self[4] = sh
end

---@return DreamShader
function class:getShader()
	return self[4]
end

---@return DreamReflection
function class:getReflection()
	return self[5]
end

---@return number
function class:getDistance()
	return self[6]
end

return class