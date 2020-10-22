--[[
#part of the 3DreamEngine by Luke100000
settings.lua - a bunch of setter and getter to set global settings
--]]

local lib = _3DreamEngine

local function check(value, typ, argNr)
	assert(type(value) == typ, "bad argument #" .. (argNr or 1) .. " (number expected, got nil)")
end


--sets the shader to take the light function from when using the deferred pipeline
function lib:setDefaultShaderType(typ)
	if typ then
		check(typ, "string")
		assert(self.shaderLibrary.base[typ], "shader " .. typ .. " does not exist!")
		self.defaultShaderType = typ
	else
		self.defaultShaderType = false
	end
end
function lib:getDefaultShaderType()
	return self.defaultShaderType
end


--sets the shader to take the light function from when using the deferred pipeline
function lib:setDeferredShaderType(typ)
	check(typ, "string")
	assert(self.shaderLibrary.base[typ].constructLightFunction, "shader " .. typ .. " has no constructLightFunction!")
	self.deferredShaderType = typ
end
function lib:getDeferredShaderType()
	return self.deferredShaderType
end


--sets the max count of lights per type
function lib:setMaxLights(nr)
	check(nr, "number")
	self.max_lights = nr
end
function lib:getMaxLights()
	return self.max_lights
end


--sets the regex decoder strings for object names
function lib:setNameDecoder(regex)
	if regex then
		check(regex, "string")
		self.nameDecoder = regex
	else
		self.nameDecoder = false
	end
end
function lib:getNameDecoder()
	return self.nameDecoder
end


--enable/disable in frustum check
function lib:setFrustumCheck(c)
	check(c, "boolean")
	self.frustumCheck = c
end
function lib:getFrustumCheck()
	return self.frustumCheck
end


--sets the distance of the lowest LOD level
function lib:setLODDistance(d)
	check(d, "number")
	self.LODDistance = d
end
function lib:getLODDistance()
	return self.LODDistance
end


--sets the default dither
function lib:setDither(d)
	check(d, "boolean")
	self.dither = d
end
function lib:getDither()
	return self.dither
end

--exposure
function lib:setExposure(e)
	if e then
		check(e, "number")
		self.exposure = e
	else
		self.exposure = false
	end
end
function lib:getExposure()
	return self.exposure
end


--auto exposure
function lib:setAutoExposure(target, speed, skip)
	if target == true then
		self:setAutoExposure(0.25, 1.0, 4)
	elseif target then
		check(target, "number", 1)
		check(speed, "number", 2)
		self.autoExposure_enabled = true
		self.autoExposure_targetBrightness = target
		self.autoExposure_adaptionSpeed = speed
		self.autoExposure_frameSkip = skip
	else
		self.autoExposure_enabled = false
	end
end
function lib:getAutoExposure(target, speed, skip)
	return self.autoExposure_enabled, self.autoExposure_targetBrightness, self.autoExposure_adaptionSpeed, self.autoExposure_frameSkip
end


--gamma
function lib:setGamma(g)
	if g then
		check(g, "number")
		self.gamma = g
	else
		self.gamma = false
	end
end
function lib:getGamma()
	return self.gamma
end


--AO settings
function lib:setAO(samples, resolution, blur)
	if samples then
		check(samples, "number", 1)
		check(resolution, "number", 2)
		check(blur, "boolean", 3)
		
		self.AO_enabled = true
		self.AO_quality = samples
		self.AO_resolution = resolution
		self.AO_blur = blur
	else
		self.AO_enabled = false
	end
end
function lib:getAO()
	return self.AO_enabled, self.AO_quality, self.AO_resolution
end


--bloom settings
function lib:setBloom(quality, resolution, size, strength)
	if quality then
		check(quality, "number", 1)
		
		self.bloom_enabled = true
		self.bloom_quality = quality
		self.bloom_resolution = resolution or 0.5
		self.bloom_size = size or 0.075
		self.bloom_strength = strength or 1.0
	else
		self.bloom_enabled = false
	end
end
function lib:getBloom()
	return self.bloom_enabled, self.bloom_quality, self.bloom_resolution, self.bloom_size, self.bloom_strength
end


--fog
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
	if min then
		check(min, "number", 1)
		check(max, "number", 2)
		self.fog_min = min
		self.fog_max = max
	else
		self.fog_min = 1
		self.fog_max = -1
	end
end
function lib:getFogHeight()
	return self.fog_min, self.fog_max
end


--rainbow
function lib:setRainbow(strength, size, thickness)
	check(strength, "number")
	self.rainbow_strength = strength
	self.rainbow_size = size or self.rainbow_size or math.cos(42 / 180 * math.pi)
	self.rainbow_thickness = thickness or self.rainbow_thickness or 0.2
end
function lib:getRainbow()
	return self.rainbow_strength, self.rainbow_size, self.rainbow_thickness
end

function lib:setRainbowDir(v)
	self.rainbow_dir = v:normalize()
end
function lib:getRainbowDir()
	return self.rainbow_dir:unpack()
end


--default shadow resolution
function lib:setShadowResolution(sun, point)
	check(sun, "number", 1)
	check(point, "number", 2)
	
	self.shadow_resolution = sun
	self.shadow_cube_resolution = point
end
function lib:getShadowResolution()
	return self.shadow_resolution, self.shadow_cube_resolution
end


--default shadow smoothing mode
function lib:setShadowSmoothing(enabled)
	check(enabled, "boolean")
	self.shadow_smooth = enabled
end
function lib:getShadowSmoothing()
	return self.shadow_smooth
end


--sun shadow cascade
function lib:setShadowCascade(distance, factor)
	check(distance, "number", 1)
	check(factor, "number", 2)
	
	self.shadow_distance = distance
	self.shadow_factor = factor
end
function lib:getShadowCascade()
	return self.shadow_distance, self.shadow_factor
end


--set sun shadow
function lib:setSunShadow(e)
	check(e, "boolean")
	self.sun_shadow = e
end
function lib:getSunShadow(o)
	return self.sun_shadow
end


--set sun offset
function lib:setSunDir(v)
	self.sun = v:normalize()
end
function lib:getSunDir()
	return self.sun
end


--set sun offset
function lib:setSunOffset(o)
	check(o, "number")
	self.sun_offset = o
end
function lib:getSunOffset()
	return self.sun_offset
end


--day time
function lib:setDaytime(time)
	check(time, "number")
	
	local c = #self.sunlight
	
	--time, 0.0 is sunrise, 0.5 is sunset
	self.sky_time = time % 1.0
	self.sky_day = time % c
	
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
	if rain then
		temp = temp or (1.0 - rain)
		self.weather_rain = rain
		self.weather_temperature = temp
	end
	
	--blue-darken ambient and sun color
	local color = self.weather_rain * 0.75
	local darkBlue = vec3(30, 40, 60):normalize() * self.sun_color:length()
	self.sun_color = darkBlue * 0.2 * color + self.sun_color * (1.0 - color)
	self.sun_ambient = darkBlue * 0.1 * color + self.sun_ambient * (1.0 - color)
	self.sky_color = darkBlue * 0.2 * color + vec3(0.6, 0.8, 1.0) * (1.0 - color)
	
	--set module settings
	if raining == nil then
		raining = self.weather_rain > 0.5
	end
	self.weather_rainStrength = raining and (self.weather_rain-0.5) / 0.5 or 0.0
	self:getShaderModule("rain").isRaining = raining
	self:getShaderModule("rain").strength = math.ceil(math.clamp(self.weather_rainStrength * 5.0, 0.001, 5.0))
end
function lib:getWeather()
	return self.weather_rain, self.weather_temperature, self:getShaderModule("rain").isRaining
end


--updates weather slowly
function lib:updateWeather(rain, temp, dt)
	if rain > self.weather_rain then
		self.weather_rain = math.min(rain, self.weather_rain + dt * dt)
	else
		self.weather_rain = math.max(rain, self.weather_rain - dt * dt)
	end
	
	if temp > self.weather_temperature then
		self.weather_temperature = math.min(temp, self.weather_temperature + dt * dt)
	else
		self.weather_temperature = math.max(temp, self.weather_temperature - dt * dt)
	end
	
	self:setWeather()
	
	--mist level
	self.weather_mist = math.clamp((self.weather_mist or 0) + (self.weather_rainStrength > 0 and self.weather_rainStrength or -0.1) * dt * 0.1, 0.0, 1.0)
	
	--set fog
	self:setFog(self.weather_mist * 0.005, self.sky_color, 1.0)
	
	--set rainbow
	local strength = math.max(0.0, self.weather_mist * (1.0 - self.weather_rain * 2.0))
	self:setRainbow(strength)
end


--sets the reflection type used to reflections
function lib:setReflection(tex)
	if tex == true then
		--use sky
		self.sky_reflection = true
	elseif tex == false then
		--use ambient
		self.sky_reflection = false
	elseif type(tex) == "table" then
		self.sky_reflection = tex
	elseif type(tex) == "userdata" and tex:getTextureType() == "cube" then
		--cubemap, wrap in reflection object
		self.sky_reflection = lib:newReflection(tex)
	elseif type(tex) == "userdata" and tex:getTextureType() == "2d" then
		--HDRI
		error("HDRI not supported, please convert to cubemap first")
	end
end
function lib:getReflection(tex)
	return self.sky_reflection
end

function lib:setSkyReflectionFormat(resolution, format, skip)
	check(resolution, "number", 1)
	check(format, "string", 2)
	self.sky_resolution = resolution
	self.sky_format = format
	self.sky_frameSkip = skip
end
function lib:getSkyReflectionFormat()
	return self.sky_resolution, self.sky_format, self.sky_frameSkip
end


--sets the sky HDRI, cubemap or just sky dome
function lib:setSky(tex, exposure)
	if tex == true then
		--use sky
		self.sky_texture = true
	elseif tex == false then
		--disable sky
		self.sky_texture = false
	elseif type(tex) == "userdata" and tex:getTextureType() == "cube" then
		--cubemap
		self.sky_texture = tex
		
		--also sets reflections
		self:setReflection(tex)
	elseif type(tex) == "userdata" and tex:getTextureType() == "2d" then
		--HDRI
		self.sky_texture = tex
	end
	self.sky_hdri_exposure = exposure or 1.0
end
function lib:getSky(tex)
	return self.sky_texture, self.sky_hdri_exposure
end


--sets cloud texture
function lib:setCloudsTexture(tex)
	self.textures.clouds = tex or love.graphics.newImage(self.root .. "/res/clouds.png")
end
function lib:getCloudsTexture(tex)
	return self.textures.clouds
end


--sets clouds and settings
function lib:setClouds(enabled, resolution, scale, amount, rotations)
	if enabled then
		self.clouds_enabled = true
		self.clouds_resolution = resolution or 1024
		self.clouds_scale = scale or 2.0
		self.clouds_amount = amount or 32
		self.clouds_rotations = rotations == nil or rotations
	else
		self.clouds_enabled = false
	end
end
function lib:getClouds()
	return self.clouds_enabled, self.clouds_resolution, self.clouds_scale
end


--sets strength of wind, affecting the clouds
function lib:setWind(x, y)
	assert(x, "number", 1)
	assert(y, "number", 2)
	self.clouds_wind = vec2(x, y)
	self.clouds_pos = self.clouds_pos or vec2(0.0, 0.0)
end
function lib:getWind()
	return self.clouds_wind.x, self.clouds_wind.y
end


--sets a few cloud animation parameters
function lib:setCloudsAnim(size, position)
	assert(size, "number", 1)
	assert(position, "number", 2)
	
	self.clouds_anim_size = size
	self.clouds_anim_position = position
end
function lib:getCloudsAnim()
	return self.clouds_anim_size, self.clouds_anim_position
end


--sets the stretch of the clouds caused by wind
function lib:setCloudsStretch(stretch, stretch_wind, angle)
	check(stretch, "number", 1)
	check(stretch_wind, "number", 2)
	check(angle, "number", 3)
	
	self.clouds_stretch = stretch
	self.clouds_stretch_wind = stretch_wind
	self.clouds_angle = angle
end
function lib:getCloudsStretch()
	return self.clouds_stretch, self.clouds_angle
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


--lag-free texture loading
function lib:setSmoothLoading(time)
	if time then
		check(time, "number")
		self.textures_smoothLoading = true
		self.textures_smoothLoadingTime = time
	else
		self.textures_smoothLoading = false
	end
end
function lib:getSmoothLoading(time)
	return self.textures_smoothLoading, self.textures_smoothLoadingTime
end


--stepsize of lag free loader
function lib:setSmoothLoadingBufferSize(size)
	check(size, "number")
	self.textures_bufferSize = size
end
function lib:getSmoothLoadingBufferSize(time)
	return self.textures_bufferSize
end


--default mipmapping mode for textures
function lib:setMipmaps(mm)
	check(mm, "boolean")
	self.textures_mipmaps = mm
end
function lib:getMipmaps()
	return self.textures_mipmaps
end