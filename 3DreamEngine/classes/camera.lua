local lib = _3DreamEngine

function lib:newCamera(transform, transformProj, pos, normal)
	local m = transform or pos and mat4:getIdentity():translate(pos) or mat4:getIdentity()
	return setmetatable({
		transform = m,
		transformProj = transformProj and (transformProj * m),
		transformProjOrigin = transformProj and (transformProj * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)),
		
		--extracted from transform matrix
		normal = normal or vec3(0, 0, 0),
		pos = pos or vec3(0, 0, 0),
		
		fov = 90,
		near = 0.01,
		far = 1000,
		aspect = 1.0,
	}, self.meta.camera)
end

local class = {
	link = {"transform", "camera"},
	
	setterGetter = {
		fov = "number",
		near = "number",
		far = "number",
	},
}
	
--required for plane frustum check
function class:updateFrustumPlanes()
	self.planes = lib:getFrustumPlanes(self.transformProj)
end

return class