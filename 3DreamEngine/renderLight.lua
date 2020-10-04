--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

local lib = _3DreamEngine

local lightTypes = { }
local lastLightTyp = 0
function lib:getLightOverview(cam)
	--select the most important lights
	for d,s in ipairs(self.lighting) do
		s.active = false
		s.priority = s.brightness * (s.meter == 0 and 100.0 or 1.0) * (s.shadow and 2.0 or 1.0) / (cam.pos - vec3(s.x, s.y, s.z)):length()
	end
	table.sort(self.lighting, function(a, b) return a.priority > b.priority end)
	
	--keep track of light count per type to construct shader
	local lighting = { }
	local lightRequirements = { }
	for d,s in ipairs(self.lighting) do
		local typ = s.typ .. "_" .. (s.shadow and "shadow" or "simple")
		if not lightTypes[typ] then
			lightTypes[typ] = lastLightTyp
			lastLightTyp = lastLightTyp + 1
		end
		
		s.light_typ = typ
		s.light_typ_id = lightTypes[typ]
		
		lightRequirements[typ] = (lightRequirements[typ] or 0) + 1
		lighting[#lighting+1] = s
		
		s.active = true
		if #lighting == self.max_lights then
			break
		end
	end
	
	table.sort(lighting, function(a, b) return a.light_typ_id > b.light_typ_id end)
	
	return lighting, lightRequirements
end

function lib:sendLightUniforms(lighting, lightRequirements, shader)
	--general settings
	local lightColor = { }
	local lightPos = { }
	
	--global uniforms
	for d,s in pairs(lightRequirements) do
		self.shaderLibrary.light[d]:sendGlobalUniforms(self, shader, info, lighting, lightRequirements)
	end
	
	--uniforms
	for d,s in ipairs(lighting) do
		local hide = self.shaderLibrary.light[s.light_typ]:sendUniforms(self, shader, info, s, d-1)
		if hide then
			lightColor[d] = {0, 0, 0}
			lightPos[d] = {0, 0, 0}
		else
			lightColor[d] = {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness}
			if s.shadow then
				lightPos[d] = {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z}
			else
				lightPos[d] = {s.x, s.y, s.z}
			end
		end
	end
	
	shader:send("lightColor", unpack(lightColor))
	shader:send("lightPos", unpack(lightPos))
end