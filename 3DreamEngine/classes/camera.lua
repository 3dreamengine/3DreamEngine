local lib = _3DreamEngine

---@return DreamCamera | DreamTransformable
function lib:newCamera(transform, transformProj, position, normal)
	local m = transform or position and mat4.getTranslate(position) or mat4.getIdentity()
	return setmetatable({
		transform = m,
		transformProj = transformProj and (transformProj * m),
		transformProjOrigin = transformProj and (transformProj * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)),
		
		--extracted from transform matrix
		normal = normal or vec3(0, 0, 0),
		position = position or vec3(0, 0, 0),
		
		fov = 90,
		near = 0.01,
		far = 1000,
		aspect = 1.0,
	}, self.meta.camera)
end

---@class DreamCamera
local class = {
	links = { "transform", "camera" },
}

---Updates the frustum planes, required for plane frustum check, called internally
function class:updateFrustumPlanes()
	self.planes = lib:getFrustumPlanes(self.transformProj)
end

---Set FOV
---@param fov number
function class:setFov(fov)
	self.fov = fov
end
function class:getFov()
	return self.fov
end

---Set near plane
---@param near number
function class:setNear(near)
	self.near = near
end
function class:getNear()
	return self.near
end

---Set far plane
---@param far number
function class:setFar(far)
	self.far = far
end
function class:getFar()
	return self.far
end

---@return "vec3"
function class:getNormal()
	return self.normal
end

---@return "vec3"
function class:getPosition()
	return self.position
end

return class