--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

local lib = _3DreamEngine

--creates a subset of light sources, optimized for the current scene, cam and alpha pass
function lib:getLightOverview(cam)
	--select the most important lights
	for d,s in ipairs(self.lighting) do
		s.active = false
		s.priority = s.brightness * (s.shadow and 2.0 or 1.0)
		if s.typ ~= "sun" then
			s.priority = s.priority / (1.0 + (cam.pos - vec3(s.x, s.y, s.z)):length())
		end
	end
	table.sort(self.lighting, function(a, b) return a.priority > b.priority end)
	
	--keep track of light count per type to construct shader
	local lights = { }
	local types = { }
	for d,s in ipairs(self.lighting) do
		local typ = s.typ .. "_" .. (s.shadow and "shadow" or "simple")
		s.light_typ = typ
		
		if (types[typ] or 0) < self.max_lights then
			types[typ] = (types[typ] or 0) + 1
			table.insert(lights, s)
			s.active = true
		end
	end
	
	return {
		lights = lights,
		types = types,
		ID = self:getLightSetupID(lights, types)
	}
end

function lib:sendLightUniforms(light, shader, overwriteTyp)
	--general settings
	local lightColor = { }
	local lightPos = { }
	
	--global uniforms
	for d,s in pairs(light.types) do
		self.lightShaders[d]:sendGlobalUniforms(self, shader, s, light.lights)
	end
	
	--uniforms
	local IDs = { }
	for d,s in ipairs(light.lights) do
		IDs[s.light_typ] = (IDs[s.light_typ] or -1) + 1
		self.lightShaders[overwriteTyp or s.light_typ]:sendUniforms(self, shader, s, IDs[s.light_typ])
	end
end