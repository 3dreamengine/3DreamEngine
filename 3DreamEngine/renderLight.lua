--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

local lib = _3DreamEngine

--creates a subset of light sources, optimized for the current scene, cam and alpha pass
function lib:getLightOverview(cam, alphaPass)
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
	local lighting = { }
	local lightRequirements = { }
	for d,s in ipairs(self.lighting) do
		local typ = s.typ .. "_" .. (s.shadow and (not alphaPass or not s.shadow.noAlphaPass) and "shadow" or "simple")
		s.light_typ = typ
		
		if (not alphaPass or not s.noAlphaPass) and (lightRequirements[typ] or 0) < self.max_lights then
			lightRequirements[typ] = (lightRequirements[typ] or 0) + 1
			lighting[#lighting+1] = s
			s.active = true
		end
	end
	
	return lighting, lightRequirements
end

function lib:sendLightUniforms(lighting, lightRequirements, shader, overwriteTyp)
	--general settings
	local lightColor = { }
	local lightPos = { }
	
	--global uniforms
	for d,s in pairs(lightRequirements) do
		self.shaderLibrary.light[d]:sendGlobalUniforms(self, shader, info, s, lighting)
	end
	
	--uniforms
	local IDs = { }
	for d,s in ipairs(lighting) do
		IDs[s.light_typ] = (IDs[s.light_typ] or -1) + 1
		self.shaderLibrary.light[overwriteTyp or s.light_typ]:sendUniforms(self, shader, info, s, IDs[s.light_typ])
	end
end