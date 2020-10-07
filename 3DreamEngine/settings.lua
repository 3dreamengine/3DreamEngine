--[[
#part of the 3DreamEngine by Luke100000
settings.lua - a bunch of setter and getter to set global settings
--]]

local lib = _3DreamEngine

--default resolution
function lib:setShadowResolution(sun, point)
	assert(type(sun) == "number", "bad argument #1 (number expected, got nil)")
	assert(type(point) == "number", "bad argument #2 (number expected, got nil)")
	self.shadow_resolution = sun
	self.shadow_cube_resolution = sun
end
function lib:getShadowResolution()
	return self.shadow_resolution, self.shadow_cube_resolution
end

--default smoothing mode
function lib:setShadowSmoothing(enabled)
	assert(type(sun) == "boolean", "bad argument #1 (boolean expected, got nil)")
	self.shadow_smooth = enabled
end
function lib:getShadowSmoothing()
	return self.shadow_smooth
end

--sun shadow cascade
function lib:setShadowCascade(distance, factor)
	assert(type(sun) == "number", "bad argument #1 (number expected, got nil)")
	assert(type(point) == "number", "bad argument #2 (number expected, got nil)")
	self.shadow_distance = distance
	self.shadow_factor = factor
end
function lib:getShadowCascade()
	return self.shadow_distance, self.shadow_factor
end

--fog
function lib:setFog(density, color)
end