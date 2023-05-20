---@type Dream
local lib = _3DreamEngine
local vec3, mat4 = lib.vec3, lib.mat4

---Creates a new camera
---@param transform DreamMat4
---@param transformProj DreamMat4
---@param position DreamVec3
---@param normal DreamVec3
---@return DreamCamera
function lib:newCamera(transform, transformProj, position, normal)
	local m = transform or position and mat4.getTranslate(position) or mat4.getIdentity()
	return setmetatable({
		transform = m,
		transformProj = transformProj and (transformProj * m),
		
		--todo remove
		transformProjOrigin = transformProj and (transformProj * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)),
		
		--extracted from transform matrix
		normal = normal or vec3(0, 0, 0),
		position = position or vec3(0, 0, 0),
		viewPosition = position or vec3(0, 0, 0),
		
		orthographic = false,
		
		fov = 90,
		near = 0.01,
		far = 1000,
		size = 10,
		aspect = 1.0,
	}, self.meta.camera)
end

---Contains transformation and lens information used to render the scene
---@class DreamCamera : DreamTransformable
local class = {
	links = { "transformable", "camera" },
}

---Updates the frustum planes, required for plane frustum check, called internally
---@private
function class:updateFrustumPlanes()
	self.planes = lib:getFrustumPlanes(self.transformProj)
end

---Set FOV
---@param fov number @ vertical field of view in degrees
function class:setFov(fov)
	self.fov = fov
end

---@return number
function class:getFov()
	return self.fov
end

---Set near plane
---@param near number
function class:setNear(near)
	self.near = near
end

---@return number
function class:getNear()
	return self.near
end

---Set far plane
---@param far number
function class:setFar(far)
	self.far = far
end

---@return number
function class:getFar()
	return self.far
end

---Sets the horizontal orthographic viewport size
---@param size number
function class:setSize(size)
	self.size = size
end

---@return number
function class:getSize()
	return self.size
end

---Sets projection transform to orthographic, does not work with sky-boxes
---@param orthographic boolean
function class:setOrthographic(orthographic)
	self.orthographic = orthographic
end

---@return boolean
function class:isOrthographic()
	return self.orthographic
end

---@return DreamVec3
function class:getNormal()
	return self.normal
end

---@return DreamVec3
function class:getPosition()
	return self.position
end

---Returns the final camera-perspective transform
---@private
function class:getPerspectiveTransform(canvases)
	local n = self.near
	local f = self.far
	local fov = self.fov
	local scale = math.tan(fov * math.pi / 360)
	local r = scale * n * self.aspect
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
	
	return mat4({
		a1 * b[1], a1 * b[2], a1 * b[3], a1 * b[4],
		a6 * b[5], a6 * b[6], a6 * b[7], a6 * b[8],
		a11 * b[9], a11 * b[10], a11 * b[11], a11 * b[12] + a12,
		-b[9], -b[10], -b[11], -b[12]
	})
end

--todo the frustum culling code fails for close objects, a constant factor "fix" it but it's not fixing the actual problem
local perspectiveWarpFactor = 1.5

local cache = { }

--todo octant test
---Checks if the giving sphere is in the cameras frustum
---@param pos DreamVec3
---@param radius number
---@param id any
function class:inFrustum(pos, radius, id)
	radius = radius * perspectiveWarpFactor
	
	local c = cache[id]
	if c then
		local plane = self.planes[c]
		local dist = plane[1] * pos[1] + plane[2] * pos[2] + plane[3] * pos[3] + plane[4]
		if dist + radius < 0.0 then
			return false
		end
		cache[id] = nil
	end
	
	--todo missing z plane?
	for i = 1, 4 do
		if i ~= c then
			local plane = self.planes[i]
			local dist = plane[1] * pos[1] + plane[2] * pos[2] + plane[3] * pos[3] + plane[4]
			if dist + radius < 0.0 then
				cache[id] = i
				return false
			end
		end
	end
	return true
end

---Returns the final camera-orthographic transform
---@private
function class:getOrthographicTransform(canvases)
	self.viewPosition = self.position - self.normal * 10000
	
	local zoom = 10
	local left = -self.aspect * zoom
	local right = self.aspect * zoom
	local bottom = -zoom
	local top = zoom
	local n = 0
	local f = self.far
	
	local m = canvases.mode == "direct" and 1 or -1
	local mat = mat4({
		2 / (right - left), 0, 0, -(right + left) / (right - left),
		0, 2 / (top - bottom) * m, 0, -(top + bottom) / (top - bottom) * m,
		0, 0, -2 / (f - n), -(f + n) / (f - n),
		0, 0, 0, 1
	})
	
	local b = self.transform:invert()
	return mat * b
end

---@private
function class:applyProjectionTransform(canvases)
	self.aspect = canvases.width / canvases.height
	
	if self.orthographic then
		self.transformProj = self:getOrthographicTransform(canvases)
	else
		self.transformProj = self:getPerspectiveTransform(canvases)
	end
	
	local ma = self.transformProj
	self.transformProjOrigin = mat4({
		ma[1], ma[2], ma[3], 0.0,
		ma[5], ma[6], ma[7], 0.0,
		ma[9], ma[10], ma[11], -1,
		ma[13], ma[14], ma[15], 0.0
	})
end

return class