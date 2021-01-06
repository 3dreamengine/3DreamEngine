local job = { }
local lib = _3DreamEngine

job.cost = 2

function job:init()
	
end

function job:queue(times)
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "sun" then
			local pos = vec3(s.x, s.y, s.z):normalize()
			for cascade = 1, 3 do
				local id = "shadow_sun_" .. tostring(s.shadow) .. tostring(cascade)
				lib:addOperation("shadow_sun", 1.0 / 2^cascade, id, s.frameSkip, s, pos, cascade)
			end
		end
	end
end

function job:execute(times, delta, light, pos, cascade)
	--create new canvases if necessary
	if not light.shadow.canvases then
		light.shadow.canvases = { }
		light.shadow.cams = { }
	end
	
	local shadowCam = light.shadow.cams[cascade]
	if not shadowCam or (lib.lastUsedCam.pos - shadowCam.pos):lengthSquared() > 1 then
		--render
		local r = lib.shadow_distance / 2 * (lib.shadow_factor ^ (cascade-1))
		local l = -r
		
		local n = 1.0
		local f = 100
		
		if not shadowCam then
			light.shadow.cams[cascade] = lib:newCam()
			shadowCam = light.shadow.cams[cascade]
			shadowCam.noFrustumCheck = true
			shadowCam.sun = true
		end
		if light.shadow.static == "dynamic" then
			shadowCam.dynamic = false
		else
			shadowCam.dynamic = nil
		end
		shadowCam.pos = lib.lastUsedCam.pos
		shadowCam.normal = pos
		shadowCam.transform = lib:lookAt(shadowCam.pos + shadowCam.normal * f * 0.5, shadowCam.pos, vec3(0.0, 1.0, 0.0))
		
		--optimized orthopgraphic projected multiplied by the cameras view matrix
		local a1 = 1 / r
		local a4 = -(r + l) / r / 2
		local a6 = -a1
		local a11 = -2 / (f - n)
		local a12 = -(f + n) / (f - n)
		local b = shadowCam.transform
		shadowCam.transformProj = mat4({
			a1 * b[1],   a1 * b[2],    a1 * b[3],    a1 * b[4] + a4,
			a6 * b[5],   a6 * b[6],    a6 * b[7],    a6 * b[8],
			a11 * b[9],  a11 * b[10],  a11 * b[11],  a11 * b[12] + a12,
			0.0,         0.0,          0.0,          1.0,
		})
		
		--generate canvas
		light.shadow.canvases[cascade] = light.shadow.canvases[cascade] or lib:newShadowCanvas("sun", light.shadow.res, light.shadow.static == "dynamic")
	end
	
	--only load scene for first canvas assuming nothing has changed in the meanwhile (TODO: possible instable, requires further inspection)
	if not light.scene then
		light.scene = lib:buildScene(shadowCam, lib.shadowSet, "shadows", light.blacklist, shadowCam.dynamic)
		if shadowCam.dynamic ~= nil then
			light.sceneDyn = lib:buildScene(shadowCam, lib.shadowSet, "shadows", light.blacklist, true)
		end
	end
	
	--render
	lib:renderShadows(shadowCam.dynamic and light.sceneDyn or light.scene, shadowCam, {light.shadow.canvases[cascade]}, false, shadowCam.dynamic)
	
	--also render dyn if static only is rendered to keep up with transformation
	if shadowCam.dynamic == false then
		lib:renderShadows(light.sceneDyn, shadowCam, {light.shadow.canvases[cascade]}, false, true)
	end
	
	if light.shadow.static == "dynamic" then
		shadowCam.dynamic = true
	end
	if cascade == 3 then
		light.scene = nil
		light.sceneDyn = nil
	end
end

return job