--[[
#part of the 3DreamEngine by Luke100000
settings.lua - a bunch of setter and getter to set global settings
--]]

local lib = _3DreamEngine

local function check(value, typ, argNr)
	assert(type(value) == typ, "bad argument #" .. (argNr or 1) .. " (number expected, got nil)")
end


--sets the max count of lights per type
function lib:setMaxLights(nr)
	check(nr, "number")
	self.max_lights = nr
end
function lib:getMaxLights()
	return self.max_lights
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
	self.LODFactor = 1 / d
end
function lib:getLODDistance()
	return self.LODDistance
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
function lib:setAutoExposure(target, speed)
	if target == true then
		self:setAutoExposure(0.3, 1.0)
	elseif target then
		check(target, "number", 1)
		check(speed, "number", 2)
		self.autoExposure_enabled = true
		self.autoExposure_targetBrightness = target
		self.autoExposure_adaptionSpeed = speed
	else
		self.autoExposure_enabled = false
	end
end
function lib:getAutoExposure()
	return self.autoExposure_enabled, self.autoExposure_targetBrightness, self.autoExposure_adaptionSpeed
end



--gamma
function lib:setGamma(g)
	check(g, "boolean")
	self.gamma = g
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
		self.bloom_size = size or 0.1
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

--sets the reflection type used for reflections
function lib:setDefaultReflection(tex)
	if tex == "sky" then
		--use sky
		self.defaultReflection = "sky"
	elseif tex == false then
		--use ambient
		self.defaultReflection = false
	elseif type(tex) == "table" and tex.class == "reflection" then
		--reflection object
		self.defaultReflection = tex
	elseif type(tex) == "userdata" and tex:getTextureType() == "cube" then
		--cubemap, wrap in reflection object
		self.defaultReflection = lib:newReflection(tex)
	elseif type(tex) == "userdata" and tex:getTextureType() == "2d" then
		--HDRI
		error("HDRI not supported, please convert to cubemap first")
	else
		error("Unknown reflection")
	end
end
function lib:getDefaultReflection(tex)
	return self.defaultReflection
end

function lib:setSkyReflectionFormat(resolution, format, lazy)
	check(resolution, "number", 1)
	check(format, "string", 2)
	self.sky_resolution = resolution
	self.sky_format = format
	self.sky_lazy = lazy
end
function lib:getSkyReflectionFormat()
	return self.sky_resolution, self.sky_format, self.sky_lazy
end


--sets the sky HDRI, cubemap or just sky dome
function lib:setSky(sky, exposure)
	if type(sky) == "table" then
		--use constant color
		self.sky_texture = sky
	elseif not sky then
		--disable sky
		self.sky_texture = false
	elseif type(sky) == "userdata" and sky:getTextureType() == "cube" then
		--cubemap
		self.sky_texture = sky
		
		--also sets reflections
		self:setDefaultReflection(sky)
	elseif type(sky) == "userdata" and sky:getTextureType() == "2d" then
		--HDRI
		self.sky_texture = sky
		self.sky_hdri_exposure = exposure or 1.0
	elseif type(sky) == "function" then
		self.sky_texture = sky
	else
		error("Unknown sky")
	end
end
function lib:getSky(tex)
	return self.sky_texture, self.sky_hdri_exposure
end


--set resource loader settings
function lib:setResourceLoader(threaded)
	check(threaded, "boolean")
	self.textures_threaded = threaded
end
function lib:getResourceLoader()
	return self.textures_threaded
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


--godrays
function lib:setGodrays(quality)
	if quality then
		self.godrays_enabled = true
		self.godrays_quality = quality
	else
		self.godrays_enabled = false
	end
end
function lib:getGodrays()
	return self.godrays_enabled, self.godrays_quality
end


--refraction margin
function lib:setDistortionMargin(value)
	if value == true then
		self.distortionMargin = 2.0
	elseif value then
		self.distortionMargin = value
	else
		self.distortionMargin = false
	end
end
function lib:getDistortionMargin()
	return self.distortionMargin
end


--shaders
function lib:setDefaultPixelShader(shader)
	shader = lib:getShader(shader)
	assert(shader.type == "pixel", "invalid shader type")
	self.defaultPixelShader = shader
end
function lib:setDefaultVertexShader(shader)
	shader = lib:getShader(shader)
	assert(shader.type == "vertex", "invalid shader type")
	self.defaultVertexShader = shader
end
function lib:setDefaultWorldShader(shader)
	shader = lib:getShader(shader)
	assert(shader.type == "world", "invalid shader type")
	self.defaultWorldShader = shader
end

function lib:getDefaultPixelShader()
	return self.defaultPixelShader
end
function lib:getDefaultVertexShader()
	return self.defaultVertexShader
end
function lib:getDefaultWorldShader()
	return self.defaultWorldShader
end

function lib:registerMeshFormat(name, f)
	self.meshFormats[name] = f
end