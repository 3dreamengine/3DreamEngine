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
				if not s.shadow.static or not s.shadow.done[cascade] then
					local id = "shadow_sun_" .. tostring(s.shadow) .. tostring(cascade)
					lib:addOperation("shadow_sun", 1.0 / 2^cascade, id, s.frameSkip, s, pos, cascade)
				end
			end
		end
	end
end

local shadowCam = lib:newCam()
shadowCam.noFrustumCheck = true

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
	
	shadowCam.pos = cam.pos
	shadowCam.normal = pos
	shadowCam.transform = lib:lookAt(cam.pos + shadowCam.normal * f * 0.5, cam.pos, vec3(0.0, 1.0, 0.0))
	
	--optimized arthopgraphic projected multiplied by the cameras view matrix
	local a1 = 2 / (r - l)
	local a4 = -(r + l) / (r - l)
	local a6 = -2 / (t - b)
	local a8 = -(t + b) / (t - b)
	local a11 = -2 / (f - n)
	local a12 = -(f + n) / (f - n)
	local b = shadowCam.transform
	shadowCam.transformProj =  mat4({
		a1 * b[1],   a1 * b[2],    a1 * b[3],    a1 * b[4] + a4,
		a6 * b[5],   a6 * b[6],    a6 * b[7],    a6 * b[8] + a8,
		a11 * b[9],  a11 * b[10],  a11 * b[11],  a11 * b[12] + a12,
		0.0,         0.0,          0.0,          1.0,
	})
	
	light.shadow["transformation_" .. cascade] = shadowCam.transformProj
	light.shadow.canvases[cascade] = light.shadow.canvases[cascade] or lib:newShadowCanvas("sun", light.shadow.res)
	
	--only load scene for first canvas assuming nothing has changed in the meanwhile (TODO: possible instable, requires further inspection)
	if not light.scene then
		light.scene = lib:buildScene(shadowCam, lib.shadowSet, "shadows", light.blacklist)
	end
	lib:renderShadows(light.scene, shadowCam, {depthstencil = light.shadow.canvases[cascade]})
	if cascade == 3 then
		light.scene = nil
	end
	
	light.shadow.done[cascade] = true
end

return job