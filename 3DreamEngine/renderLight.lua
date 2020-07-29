--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

local lib = _3DreamEngine

function lib:getLightOverview(cam)
	--select the most important lights
	for d,s in ipairs(self.lighting) do
		s.active = false
		s.priority = s.brightness * (s.meter == 0 and 100.0 or 1.0) * (s.shadow and 2.0 or 1.0) / (cam.pos - vec3(s.x, s.y, s.z)):length()
	end
	table.sort(self.lighting, function(a, b) return a.priority > b.priority end)
	
	--keep track of light count per type to construct shader
	local lighting = { }
	local lightRequirements = {
		simple = 0,
		point_shadow = 0,
		sun_shadow = 0,
	}
	for d,s in ipairs(self.lighting) do
		s.active = true
		if not s.shadow then
			lighting[#lighting+1] = s
			lightRequirements.simple = lightRequirements.simple + 1
		elseif s.shadow and s.shadow.typ == "point" then
			lighting[#lighting+1] = s
			lightRequirements.point_shadow = lightRequirements.point_shadow + 1
		elseif s.shadow and s.shadow.typ == "sun" then
			lighting[#lighting+1] = s
			lightRequirements.sun_shadow = lightRequirements.sun_shadow + 1
		end
		
		if #lighting == self.max_lights then
			break
		end
	end
	return lighting, lightRequirements
end

function lib:sendLightUniforms(lighting, lightRequirements, shader, lighting)
	if lightRequirements.simple > 0 then
		shader:send("lightCount", #lighting)
	end
	
	--current light id
	local count = 0
	
	--fill light buffers
	local lightColor = { }
	local lightPos = { }
	local lightMeter = { }
	for i = 1, self.max_lights do
		lightColor[i] = {0, 0, 0}
		lightPos[i] = {0, 0, 0}
		lightMeter[i] = 0
	end
	
	--sun lighting
	for d,s in ipairs(lighting) do
		if s.shadow and s.shadow.typ == "sun" then
			local enable = 0.0
			if s.shadow.canvases and s.shadow.canvases[3] then
				shader:send("transformProjShadow_" .. count .. "_1", s.shadow.transformation_1)
				shader:send("transformProjShadow_" .. count .. "_2", s.shadow.transformation_2)
				shader:send("transformProjShadow_" .. count .. "_3", s.shadow.transformation_3)
				shader:send("tex_shadow_1_" .. count, s.shadow.canvases[1])
				shader:send("tex_shadow_2_" .. count, s.shadow.canvases[2])
				shader:send("tex_shadow_3_" .. count, s.shadow.canvases[3])
				enable = 1.0
			end
			
			count = count + 1
			
			lightColor[count] = {s.r * s.brightness * enable, s.g * s.brightness * enable, s.b * s.brightness * enable}
			lightPos[count] = {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z}
			lightMeter[count] = s.meter
		end
	end
	
	--sun lighting settings
	if lightRequirements.sun_shadow > 0 then
		shader:send("factor", self.shadow_factor)
		shader:send("shadowDistance", 2 / self.shadow_distance)
		shader:send("texelSize", 1.0 / self.shadow_resolution)
	end
	
	--point lighting
	for d,s in ipairs(lighting) do
		if s.shadow and s.shadow.typ == "point" then
			local enable = 0.0
			if s.shadow.canvas then
				shader:send("tex_shadow_" .. count, s.shadow.canvas)
				enable = 1.0
			end
			
			count = count + 1
			
			lightColor[count] = {s.r * s.brightness * enable, s.g * s.brightness * enable, s.b * s.brightness * enable}
			lightPos[count] = {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z}
			lightMeter[count] = s.meter
		end
	end
	
	--point lighting without shadow
	for d,s in ipairs(lighting) do
		if not s.shadow then
			count = count + 1
			
			lightColor[count] = {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness}
			lightPos[count] = {s.x, s.y, s.z}
			lightMeter[count] = s.meter
		end
	end
	
	--general settings
	shader:send("lightColor", unpack(lightColor))
	shader:send("lightPos", unpack(lightPos))
	if lightRequirements.simple > 0 or lightRequirements.point_shadow > 0 then
		shader:send("lightMeter", unpack(lightMeter))
	end
end