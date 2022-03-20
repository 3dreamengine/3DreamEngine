--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

local lib = _3DreamEngine

local function sortPriority(a, b)
	return a.priority > b.priority
end

local lastID = 0
local IDs = { }
function lib:getLightSetupID(lights, types)
	local ID = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	if lights then
		for d,s in pairs(types) do
			if not IDs[d] then
				lastID = lastID + 1
				IDs[d] = lastID
			end
			
			ID[IDs[d]] = lib.lightShaders[d].batchable and 1 or s
		end
	end
	return string.char(unpack(ID))
end

--creates a subset of light sources, optimized for the current scene
function lib:getLightOverview(cam)
	--select the most important lights
	for d,s in ipairs(self.lighting) do
		s.active = false
		s.priority = s.brightness * (s.shadow and 2.0 or 1.0)
		if s.typ ~= "sun" then
			s.priority = s.priority / (1.0 + (cam.pos - vec3(s.x, s.y, s.z)):length())
		end
	end
	table.sort(self.lighting, sortPriority)
	
	--keep track of light count per type to construct shader
	--todo cleanup
	local lights = { }
	local types = { }
	for d,s in ipairs(self.lighting) do
		local typ = s.typ .. "_" .. (s.shadow and (
			"shadow" .. (s.shadow.smooth and "_smooth" or "") .. (s.shadow.dynamic and "_dynamic" or "")
		) or "simple")
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
	for typ,count in pairs(light.types) do
		self.lightShaders[typ]:sendGlobalUniforms(self, shader, count, light.lights)
	end
	
	--uniforms
	local IDs = { }
	for _,light in ipairs(light.lights) do
		IDs[light.light_typ] = (IDs[light.light_typ] or -1) + 1
		self.lightShaders[overwriteTyp or light.light_typ]:sendUniforms(self, shader, light, light.light_typ .. "_" .. IDs[light.light_typ])
	end
end