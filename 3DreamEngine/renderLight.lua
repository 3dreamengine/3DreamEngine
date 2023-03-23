--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

---@type Dream
local lib = _3DreamEngine

local function sortPriority(a, b)
	return a.priority > b.priority
end

local lastID = 0
local IDs = { }

---@private
function lib:getLightSetupID(lights, types)
	local ID = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	if lights then
		for d, s in pairs(types) do
			if not IDs[d] then
				lastID = lastID + 1
				IDs[d] = lastID
			end
			
			ID[IDs[d]] = lib.lightShaders[d].batchable and 1 or s
		end
	end
	return string.char(unpack(ID))
end

---Creates a subset of light sources, optimized for the current scene
---@private
function lib:getLightOverview(cam)
	--select the most important lights
	for _, light in ipairs(self.lighting) do
		light.active = false
		light.priority = light.brightness * (light.shadow and 2.0 or 1.0)
		if light.typ ~= "sun" then
			light.priority = light.priority / (1.0 + (cam.position - lib.vec3(light.x, light.y, light.z)):length())
		end
	end
	table.sort(self.lighting, sortPriority)
	
	--keep track of light count per type to construct shader
	--todo cleanup
	local lights = { }
	local types = { }
	for _, light in ipairs(self.lighting) do
		local typ = light.typ .. "_" .. (light.shadow and (
				"shadow" .. (light.shadow.smooth and "_smooth" or "")
		) or "simple")
		light.light_typ = typ
		
		if (types[typ] or 0) < self.max_lights then
			types[typ] = (types[typ] or 0) + 1
			table.insert(lights, light)
			light.active = true
		end
	end
	
	return {
		lights = lights,
		types = types,
		ID = self:getLightSetupID(lights, types)
	}
end

---@private
function lib:sendLightUniforms(lightOverview, shader, overwriteTyp)
	--global uniforms
	for typ, count in pairs(lightOverview.types) do
		self.lightShaders[typ]:sendGlobalUniforms(shader, count, lightOverview.lights)
	end
	
	--uniforms
	local uniformIds = { }
	for _, light in ipairs(lightOverview.lights) do
		uniformIds[light.light_typ] = (uniformIds[light.light_typ] or -1) + 1
		self.lightShaders[overwriteTyp or light.light_typ]:sendUniforms(shader, light, light.light_typ .. "_" .. uniformIds[light.light_typ])
	end
end