--[[
#part of the 3DreamEngine by Luke100000
settings.lua - a bunch of setter and getter to set global settings
--]]

local lib = _3DreamEngine

local function check(value, typ, argNr)
	assert(type(value) == typ, "bad argument #" .. argNr .. " (number expected, got nil)")
end

--AO settings
function lib:setAO(samples, resolution)
	if samples then
		check(samples, "number", 1)
		check(resolution, "number", 2)
		
		lib.AO_enabled = true
		lib.AO_quality = samples
		lib.AO_resolution = resolution
	else
		lib.AO_enabled = false
	end
end

--bloom settings
function lib:setBloom(strength, size, resolution)
	if strength then
		check(strength, "number", 1)
		check(size, "number", 2)
		check(resolution, "number", 2)
		
		lib.bloom_enabled = true
		lib.bloom_size = size
		lib.bloom_resolution = resolution
		lib.bloom_strength = strength
	else
		lib.bloom_enabled = false
	end
end

--default resolution
function lib:setShadowResolution(sun, point)
	check(sun, "number", 1)
	check(point, "number", 2)
	
	self.shadow_resolution = sun
	self.shadow_cube_resolution = sun
end
function lib:getShadowResolution()
	return self.shadow_resolution, self.shadow_cube_resolution
end

--default smoothing mode
function lib:setShadowSmoothing(enabled)
	check(enabled, "boolean", 1)
	self.shadow_smooth = enabled
end
function lib:getShadowSmoothing()
	return self.shadow_smooth
end

--sun shadow cascade
function lib:setShadowCascade(distance, factor)
	check(distance, "number", 1)
	check(factor, "number", 1)
	
	self.shadow_distance = distance
	self.shadow_factor = factor
end
function lib:getShadowCascade()
	return self.shadow_distance, self.shadow_factor
end

--fog
function lib:setFog(density, color)
end