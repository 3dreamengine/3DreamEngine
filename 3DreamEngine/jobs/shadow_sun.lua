local job = { }
local lib = _3DreamEngine

job.cost = 2

function job:init()

end

function job:queue(times, operations)
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "sun" then
			local pos = vec3(s.x, s.y, s.z):normalize()
			for cascade = 1, 3 do
				if not s.shadow.static or not s.shadow.done[cascade] then
					local id = "shadow_sun_" .. tostring(s.shadow) .. tostring(cascade)
					operations[#operations+1] = {"shadow_sun", 1.0 / 2^cascade, id, s, pos, cascade}
				end
			end
		end
	end
end

function job:execute(times, delta, light, pos, cascade)
	local cam = lib.lastUsedCam
	light.shadow.lastPos = pos
	
	--create new canvases if necessary
	if not light.shadow.canvases then
		light.shadow.canvases = { }
	end
	
	--render
	local r = lib.shadow_distance / 2 * (lib.shadow_factor ^ (cascade-1))
	local t = lib.shadow_distance / 2 * (lib.shadow_factor ^ (cascade-1))
	local l = -r
	local b = -t
	
	local n = 1.0
	local f = 100
	
	local projection = mat4(
		2 / (r - l),	0,	0,	-(r + l) / (r - l),
		0, -2 / (t - b), 0, -(t + b) / (t - b),
		0, 0, -2 / (f - n), -(f + n) / (f - n),
		0, 0, 0, 1
	)
	
	local shadowCam = lib:newCam()
	shadowCam.noFrustumCheck = true
	shadowCam.pos = cam.pos
	shadowCam.normal = pos
	shadowCam.transform = lib:lookAt(cam.pos + shadowCam.normal * f * 0.5, cam.pos, vec3(0.0, 1.0, 0.0))
	shadowCam.transformProj = projection * shadowCam.transform
	local m = shadowCam.transform
	shadowCam.transformProjOrigin = projection * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)
	light.shadow["transformation_" .. cascade] = shadowCam.transformProj
	light.shadow.canvases[cascade] = light.shadow.canvases[cascade] or lib:newShadowCanvas("sun", light.shadow.res)
	
	local sceneSolid = lib:buildScene(shadowCam, "shadows", light.blacklist)
	lib:renderShadows(sceneSolid, shadowCam, {depthstencil = light.shadow.canvases[cascade]})
	
	light.shadow.done[cascade] = true
end

return job