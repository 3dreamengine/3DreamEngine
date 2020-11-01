local lib = _3DreamEngine

function lib:newCam(transform, transformProj, pos, normal)
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
	}, self.meta.cam)
end

return {
	link = {"transform", "cam"},
	
	setterGetter = {
		fov = "number",
		near = "number",
		far = "number",
	},
	
	--required for fast frustum check
	updateFrustumAngle = function(self, aspect)
		local scale = self.fov * math.pi / 360
		local hFov = math.atan(scale * (aspect or 1.0)) * 360 / math.pi
		self.frustumAngle = 1.0 - math.cos(math.max(self.fov, hFov) / 360 * math.pi)
	end,
	
	--required for plane frustum check
	updateFrustumPlanes = function(self)
		self.planes = lib:getFrustumPlanes(self.transformProj)
	end,
}