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
---@param fov number @ horizontal field of view in degrees
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

---Applies a perspective transform, called internally
function class:applyPerspectiveTransform(canvases)
	local n = self.near
	local f = self.far
	local fov = self.fov
	local scale = math.tan(fov * math.pi / 360)
	local aspect = canvases.width / canvases.height
	local r = scale * n * aspect
	local t = scale * n
	local m = canvases.mode == "direct" and 1 or -1
	
	--optimized matrix multiplication by removing constants
	--looks like a mess, but its only the opengl projection multiplied by the camera
	local b = self.transform:invert()
	local a1 = n / r
	local a6 = n / t * m
	local fn1 = 1 / (f - n)
	local a11 = -(f + n) * fn1
	local a12 = -2 * f * n * fn1
	
	self.transformProj = mat4(
			a1 * b[1], a1 * b[2], a1 * b[3], a1 * b[4],
			a6 * b[5], a6 * b[6], a6 * b[7], a6 * b[8],
			a11 * b[9], a11 * b[10], a11 * b[11], a11 * b[12] + a12,
			-b[9], -b[10], -b[11], -b[12]
	)
	
	local ma = self.transformProj
	self.transformProjOrigin = mat4(
			ma[1], ma[2], ma[3], 0.0,
			ma[5], ma[6], ma[7], 0.0,
			ma[9], ma[10], ma[11], a12,
			ma[13], ma[14], ma[15], 0.0
	)
	
	self.aspect = aspect
end

return class