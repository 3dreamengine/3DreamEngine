local job = { }
local lib = _3DreamEngine

function job:init()
	self.stencils = { }
end

function job:queue()
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "sun" then
			lib:addOperation("sunShadow", s)
		end
	end
end

function job:execute(light)
	local usesSmothing = light.shadow.smoothStatic or light.shadow.smoothDynamic
	
	--create new canvases if necessary
	if not light.shadow.canvases then
		light.shadow.canvases = { }
		light.shadow.cams = { }
	end
	
	local normal = light.direction
	local pos = light.pos
	local pos = lib.cam.pos
	
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
			
			local r = light.shadow.cascadeDistance / 2 * (light.shadow.cascadeFactor ^ (cascade-1))
			local n = 1.0
			local f = 100
			
			--camera orientation
			shadowCam.pos = pos
			shadowCam.normal = normal
			shadowCam.transform = lib:lookAt(shadowCam.pos + shadowCam.normal * (f * 0.5), shadowCam.pos, vec3(0.0, 1.0, 0.0))
			shadowCam.rendered = false
			
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
				light.shadow.canvases[cascade] = love.graphics.newCanvas(light.shadow.resolution, light.shadow.res,
					{format = static and "r16f" or "rg16f",
					readable = true,
					msaa = 0,
					type = "2d"})
			end
		end
		
		local canvases = {light.shadow.canvases[cascade]}
		local blurStrength = 20.0 * light.size / light.shadow.cascadeFactor ^ (cascade-1)
		
		--render
		local smoothStatic = false
		local smoothDynamic = false
		if light.shadow.static then
			--static shadow
			if not shadowCam.rendered then
				lib:renderShadows(shadowCam, canvases, light.blacklist, false, cascade > 1, usesSmothing)
				smoothStatic = light.shadow.smoothStatic
			end
		else
			if shadowCam.rendered then
				--dynamic part
				lib:renderShadows(shadowCam, canvases, light.blacklist, true, cascade > 1, usesSmothing)
				smoothDynamic = light.shadow.smoothDynamic
			else
				--both parts
				lib:renderShadows(shadowCam, canvases, light.blacklist, true, cascade > 1, usesSmothing)
				lib:renderShadows(shadowCam, canvases, light.blacklist, false, cascade > 1, usesSmothing)
				smoothDynamic = light.shadow.smoothDynamic
				smoothStatic = light.shadow.smoothStatic
			end
		end
		
		--smooth lighting
		local smooth
		if smoothStatic or smoothDynamic then
			local iterations = math.ceil(blurStrength)
			lib:blurCanvas(light.shadow.canvases[cascade], blurStrength / iterations, iterations, {smoothStatic, smoothDynamic, false, false})
		end
		
		shadowCam.rendered = true
	end
end

return job