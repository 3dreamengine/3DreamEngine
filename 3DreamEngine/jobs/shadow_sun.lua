local job = { }
local lib = _3DreamEngine

job.cost = 2

function job:init()
	self.stencils = { }
end

function job:queue(times)
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "sun" then
			for cascade = 1, 3 do
				local id = "shadow_sun_" .. tostring(s.shadow) .. tostring(cascade)
				lib:addOperation("shadow_sun", 1.0 / 2^cascade, id, s.frameSkip, s, cascade)
			end
		end
	end
end

function job:execute(times, delta, light, cascade)
	--create new canvases if necessary
	if not light.shadow.canvases then
		light.shadow.canvases = { }
		light.shadow.cams = { }
	end
	
	local dynamic = light.shadow.static == "dynamic"
	local stepSize = 1 * 2.3 ^ (cascade-1)
	local pos = vec3(light.x, light.y, light.z):normalize()
	
	local shadowCam = light.shadow.cams[cascade]
	if not shadowCam or (lib.lastUsedCam.pos - shadowCam.pos):lengthSquared() > stepSize or (pos - shadowCam.normal):lengthSquared() > 0 then
		--create shadow camera
		if not shadowCam then
			light.shadow.cams[cascade] = lib:newCam()
			shadowCam = light.shadow.cams[cascade]
			shadowCam.noFrustumCheck = true
			shadowCam.sun = true
		end
		
		local r = lib.shadow_distance / 2 * (lib.shadow_factor ^ (cascade-1))
		local n = 1.0
		local f = 100
		
		--camera orientation
		shadowCam.pos = lib.lastUsedCam.pos
		shadowCam.normal = pos
		shadowCam.transform = lib:lookAt(shadowCam.pos + shadowCam.normal * (f * 0.5), shadowCam.pos, vec3(0.0, 1.0, 0.0))
		shadowCam.dynamic = false
		
		--optimized orthopgraphic projected multiplied by the cameras view matrix
		local a1 = 1 / r
		local a6 = -a1
		local a11 = -2 / (f - n)
		local a12 = -(f + n) / (f - n)
		
		local b = shadowCam.transform
		shadowCam.transformProj = mat4({
			a1 * b[1],   a1 * b[2],    a1 * b[3],    a1 * b[4],
			a6 * b[5],   a6 * b[6],    a6 * b[7],    a6 * b[8],
			a11 * b[9],  a11 * b[10],  a11 * b[11],  a11 * b[12] + a12,
			0.0,         0.0,          0.0,          1.0,
		})
		
		--generate canvas
		if not light.shadow.canvases[cascade] then
			light.shadow.canvases[cascade] = lib:newShadowCanvas("sun", light.shadow.res, dynamic)
		end
	end
	
	local canvases = {light.shadow.canvases[cascade]}
	
	--render
	if light.shadow.static then
		if dynamic or not shadowCam.dynamic then
			lib:renderShadows(shadowCam, canvases, light.blacklist, shadowCam.dynamic, true)
		end
	else
		lib:renderShadows(shadowCam, canvases, light.blacklist, nil, true)
	end
	
	--also render dynamic if static only is rendered to keep up with transformation
	if dynamic and not shadowCam.dynamic then
		lib:renderShadows(shadowCam, canvases, false, true)
	end
	
	--next render will be a dynamic
	shadowCam.dynamic = true
end

return job