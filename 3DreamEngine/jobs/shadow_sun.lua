local job = { }
local lib = _3DreamEngine

function job:init()
	self.stencils = { }
end

function job:queue()
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "sun" then
			lib:addOperation("shadow_sun", s)
		end
	end
end

function job:execute(light)
	--create new canvases if necessary
	if not light.shadow.canvases then
		light.shadow.canvases = { }
		light.shadow.cams = { }
	end
	
	local dynamic = light.shadow.static == "dynamic"
	local normal = light.direction
	local pos = light.pos
	
	for cascade = 1, 3 do
		local stepSize = light.shadow.refreshStepSize * 2.3 ^ (cascade-1)
		
		local shadowCam = light.shadow.cams[cascade]
		if not shadowCam or (pos - shadowCam.pos):lengthSquared() > stepSize or (normal - shadowCam.normal):lengthSquared() > 0 then
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
			shadowCam.pos = pos
			shadowCam.normal = normal
			shadowCam.transform = lib:lookAt(shadowCam.pos + shadowCam.normal * (f * 0.5), shadowCam.pos, vec3(0.0, 1.0, 0.0))
			shadowCam.dynamic = false
			
			--orthopgraphic projected multiplied by the cameras view matrix
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
			if not light.shadow.tempCanvas then
				light.shadow.tempCanvas = lib:newShadowCanvas("sun", light.shadow.res, dynamic)
			end
		end
		
		local canvases = {light.shadow.canvases[cascade]}
		local blurRes = light.shadow.res / light.size * 0.25 * lib.shadow_factor ^ (cascade-1)
		
		--render
		if dynamic then
			--dynamic
			lib:renderShadows(shadowCam, canvases, light.blacklist, shadowCam.dynamic, shadowCam.dynamic and cascade > 1)
			
			--also render dynamic if static only is rendered to keep up with transformation
			if not shadowCam.dynamic then
				lib:renderShadows(shadowCam, canvases, light.blacklist, true, cascade > 1)
			end
			
			lib:blurCanvas(light.shadow.canvases[cascade], light.shadow.tempCanvas, blurRes, 2, {not shadowCam.dynamic, true, false, false})
		elseif light.shadow.static then
			if not shadowCam.dynamic then
				--static and not done
				lib:renderShadows(shadowCam, canvases, light.blacklist, false, shadowCam.dynamic and cascade > 1)
				lib:blurCanvas(light.shadow.canvases[cascade], light.shadow.tempCanvas, blurRes, 1, {true, false, false, false})
			end
		else
			--full slow render
			lib:renderShadows(shadowCam, canvases, light.blacklist, nil)
		end
		
		--next render will be a dynamic
		shadowCam.dynamic = true
	end
end

return job