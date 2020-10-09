--[[
#part of the 3DreamEngine by Luke100000
settings.lua - a bunch of setter and getter to set global settings
--]]

local lib = _3DreamEngine

local function check(value, typ, argNr)
	assert(type(value) == typ, "bad argument #" .. argNr .. " (number expected, got nil)")
end

--exposure
function lib:setExposure(e)
	if e then
		check(e, "number", 1)
		self.exposure = e
	else
		self.exposure = false
	end
end
function lib:getExposure()
	return self.exposure
end


--gamma
function lib:setGamma(g)
	if g then
		check(g, "number", 1)
		self.gamma = g
	else
		self.gamma = false
	end
end
function lib:getGamma()
	return self.gamma
end


--AO settings
function lib:setAO(samples, resolution)
	if samples then
		check(samples, "number", 1)
		check(resolution, "number", 2)
		
		self.AO_enabled = true
		self.AO_quality = samples
		self.AO_resolution = resolution
	else
		self.AO_enabled = false
	end
end
function lib:getAO()
	return self.AO_enabled, self.AO_quality, self.AO_resolution
end


--bloom settings
function lib:setBloom(strength, size, resolution)
	if strength then
		check(strength, "number", 1)
		check(size, "number", 2)
		check(resolution, "number", 2)
		
		self.bloom_enabled = true
		self.bloom_size = size
		self.bloom_resolution = resolution
		self.bloom_strength = strength
	else
		self.bloom_enabled = false
	end
end
function lib:getBloom()
	return self.bloom_enabled, self.bloom_size, self.bloom_resolution, self.bloom_strength
end


--Fog
function lib:setFog(density, color, scatter)
	if density then
		check(density, "number", 1)
		check(color, "table", 2)
		check(scatter, "number", 3)
		assert(#color == 3, "vec3 color expected")
		
		self.fog_enabled = true
		self.fog_density = density
		self.fog_color = color
		self.fog_scatter = scatter
	else
		self.fog_enabled = false
	end
end
function lib:getFog()
	return self.fog_enabled, self.fog_density, self.fog_color, self.fog_scatter
end

function lib:setFogHeight(min, max)
	check(min, "number", 1)
	check(max, "number", 1)
	self.fog_min = min
	self.fog_max = max
end
function lib:getFogHeight(min, max)
	return self.fog_min, self.fog_max
end


--default shadow resolution
function lib:setShadowResolution(sun, point)
	check(sun, "number", 1)
	check(point, "number", 2)
	
	self.shadow_resolution = sun
	self.shadow_cube_resolution = sun
end
function lib:getShadowResolution()
	return self.shadow_resolution, self.shadow_cube_resolution
end


--default shadow smoothing mode
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


--day time
function lib:setDaytime(time)
	check(time, "number", 1)
	
	local c = #self.sunlight
	
	--time, 0.0 is sunrise, 0.5 is sunset
	self.sky_time = time % 1.0
	self.sky_day = math.floor(time % c)
	
	--position
	self.sun = mat4:getRotateZ(self.sun_offset) * vec3(
		0,
		math.sin(self.sky_time * math.pi * 2),
		-math.cos(self.sky_time * math.pi * 2)
	):normalize()
	
	--current sample
	local p = self.sky_time * c
	
	--direct sun color
	self.sun_color = (
		self.sunlight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.sunlight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
	
	--sky color
	self.sun_ambient = (
		self.skylight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.skylight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
end
function lib:getDaytime()
	return self.sky_time, self.sky_day
end


--sets the rain value and temparature
function lib:setWeather(rain, temp, raining)
	check(rain, "number", 1)
	temp = temp or (1.0 - rain)
	
	self.weather_rain = rain
	self.weather_temperature = temp
	
	--blue-darken ambient and sun color
	local color = rain * 0.75
	local darkBlue = vec3(30, 40, 60):normalize() * self.sun_color:length()
	self.sun_color = darkBlue * 0.2 * color + self.sun_color * (1.0 - color)
	self.sun_ambient = darkBlue * 0.1 * color + self.sun_ambient * (1.0 - color)
	self.sky_color = darkBlue * 0.25 * color + vec3(1.0, 1.0, 1.0) * (1.0 - color)
	
	--set module settings
	if raining == nil then
		raining = rain > 0.5
	end
	self:getShaderModule("rain").isRaining = raining
	self:getShaderModule("rain").strength = math.ceil(math.clamp((rain-0.5) / 0.5 * 5.0, 0.001, 5.0))
end
function lib:getWeather()
	return self.weather_rain, self.weather_temperature
end

--set resource loader settings
function lib:setResourceLoader(threaded, thumbnails)
	if threaded then
		check(thumbnails, "boolean", 2)
		self.textures_threaded = true
		self.textures_generateThumbnails = thumbnails
	else
		self.textures_threaded = false
	end
end
function lib:getResourceLoader()
	return self.textures_threaded, self.textures_generateThumbnails
end

function lib:setSmoothLoading(time)
	if time then
		check(time, "number", 1)
		self.textures_smoothLoading = true
		self.textures_smoothLoadingTime = time
	else
		self.textures_smoothLoading = false
	end
end
function lib:getSmoothLoading(time)
	return self.textures_smoothLoading, self.textures_smoothLoadingTime
end

function lib:setSmoothLoadingBufferSize(size)
	check(size, "number", 1)
	self.textures_bufferSize = size
end
function lib:getSmoothLoadingBufferSize(time)
	return self.textures_bufferSize
end

function lib:setMipmaps(mm)
	check(mm, "boolean", 1)
	self.textures_mipmaps = mm
end
function lib:getMipmaps()
	return self.textures_mipmaps
end