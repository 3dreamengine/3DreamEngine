--[[
#part of the 3DreamEngine by Luke100000
shader.lua - loads the shaders
--]]

local lib = _3DreamEngine

local testForOpenES = true

--enables auto shader validator
if _DEBUGMODE then
	love.graphics.newShader_old = love.graphics.newShader
	function love.graphics.newShader(pixel, vertex)
		local status, err = love.graphics.validateShader(testForOpenES, pixel, vertex)
		if not status then
			print()
			print("-----------------")
			print("SHADER ERROR")
			if not vertex and #pixel < 1024 and not pixel:find("\n") then
				print(pixel)
			end
			print(err)
			print(debug.traceback())
			print("-----------------")
			
			--dump shader in case of error
			love.filesystem.write("shader_errored.glsl", pixel)
			error("shader compile failed")
		end
		local sh = love.graphics.newShader_old(pixel, vertex)
		local warnings = sh:getWarnings()
		if #warnings ~= 29 then
			if not vertex and #pixel < 1024 and not pixel:find("\n") then
				print(pixel)
			end
			print(warnings)
			print()
		end
		return sh
	end
end

--shader library
lib.shaderLibrary = {
	base = { },
	light = { },
	module = { },
}

--shader register
function lib:registerShader(path)
	local name = (path:match("^.+/(.+)$") or path):sub(1, -5)
	local sh = require(path:sub(1, -5))
	self.shaderLibrary[sh.type][name] = sh
end

--register inbuild shaders
for i,v in ipairs({"base", "light", "modules"}) do
	for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/" .. v)) do
		if s:sub(-4) == ".lua" then
			lib:registerShader(lib.root .. "/shaders/" .. v .. "/" .. s)
		end
	end
end

--load code snippsets
local codes = { }
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/functions")) do
	codes[s:sub(1, #s-5)] = love.filesystem.read(lib.root .. "/shaders/functions/" .. s)
end

lib.shaders = { }

--blur
lib.shaders.blur = love.graphics.newShader(lib.root .. "/shaders/blur.glsl")
lib.shaders.blur_cube = love.graphics.newShader(lib.root .. "/shaders/blur_cube.glsl")

--applies bloom at a given strength
lib.shaders.bloom = love.graphics.newShader(lib.root .. "/shaders/bloom.glsl")
lib.shaders.bloom_average = love.graphics.newShader(lib.root .. "/shaders/bloom_average.glsl")

--the sky sphere shader
lib.shaders.sky_cube = love.graphics.newShader(lib.root .. "/shaders/sky_cube.glsl")
lib.shaders.sky_hdri = love.graphics.newShader(lib.root .. "/shaders/sky_hdri.glsl")
lib.shaders.sky = love.graphics.newShader(lib.root .. "/shaders/sky.glsl")

--particle shader, draw textures at a given depth
lib.shaders.billboard = love.graphics.newShader(lib.root .. "/shaders/billboard.glsl")
lib.shaders.billboard_moon = love.graphics.newShader(lib.root .. "/shaders/billboard_moon.glsl")
lib.shaders.billboard_sun = love.graphics.newShader(lib.root .. "/shaders/billboard_sun.glsl")

--autoExposure vignette
lib.shaders.autoExposure = love.graphics.newShader(lib.root .. "/shaders/autoExposure.glsl")

--clouds
lib.shaders.clouds = love.graphics.newShader(lib.root .. "/shaders/clouds.glsl")

--debug shaders
if _DEBUGMODE then
	for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/debug")) do
		lib.shaders[s:sub(1, #s-5)] = love.graphics.newShader(lib.root .. "/shaders/debug/" .. s)
	end
end

--load all setting depending shaders
function lib.loadShader(self)
	self.shaders.final = { }
	self.mainShaders = { }
	self.particlesShader = { }
	self.mainShaderCount = 0

	--the ambient occlusion shader
	local code = (
		"#define SAMPLE_COUNT " .. self.AO_quality .. "\n" ..
		love.filesystem.read(self.root .. "/shaders/SSAO.glsl")
	):gsub("	", "")
	self.shaders.SSAO = love.graphics.newShader(code)
	
	--pass samples to the shader
	local f = { }
	local range = 64.0
	for i = 1, self.AO_quality do
		local r = i / self.AO_quality * math.pi * 2
		local d = (0.5 + i % 4) / 4
		f[#f+1] = {math.cos(r)*d*range / love.graphics.getWidth(), math.sin(r)*d*range / love.graphics.getHeight(), (1-d)^2 / self.AO_quality}
	end
	self.shaders.SSAO:send("samples", unpack(f))
	
	--create light shaders
	self.lightShaders = { }
	if self.renderSet.deferred or self.reflectionsSet.deferred then
		local sh_light = love.filesystem.read(lib.root .. "/shaders/light.glsl")
		for d,s in pairs(self.shaderLibrary.light) do
			local lights = { }
			if s.batchable then
				lights.lights = { }
				for i = 1, self.max_lights do
					lights.lights[#lights.lights+1] = {light_typ = d}
				end
				lights.types = {[d] = self.max_lights}
			else
				lights.lights = {{light_typ = d}}
				lights.types = {[d] = 1}
			end
			
			local lcInit, lc = self:getLightComponents(lights)
			local code = sh_light
			code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
			code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
			code = code:gsub("#import lightFunction", self.shaderLibrary.base[self.deferredShaderType]:constructLightFunction(self))
			self.lightShaders[d] = love.graphics.newShader(code)
		end
	end
end

--the final canvas combines all resources into one result
local sh_final = love.filesystem.read(lib.root .. "/shaders/final.glsl")
function lib.getFinalShader(self, canvases)
	local parts = { }
	parts[#parts+1] = canvases.postEffects and "#define POSTEFFECTS_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and self.autoExposure_enabled and "#define AUTOEXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and self.exposure and "#define EXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and self.gamma and "#define GAMMA_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and self.bloom_enabled and "#define BLOOM_ENABLED" or nil
	
	parts[#parts+1] = self.fog_enabled and "#define FOG_ENABLED" or nil
	parts[#parts+1] = self.AO_enabled and "#define AO_ENABLED" or nil
	
	parts[#parts+1] = (canvases.refractions or canvases.averageAlpha) and "#define ALPHAPASS_ENABLED" or nil
	parts[#parts+1] = canvases.averageAlpha and "#define AVERAGE_ALPHA" or nil
	
	parts[#parts+1] = (canvases.fxaa and canvases.msaa == 0) and "#define FXAA_ENABLED" or nil
	
	if self.fog_enabled then
		parts[#parts+1] = codes.fog
	end
	
	local ID = table.concat(parts, "\n")
	if not self.shaders.final[ID] then
		self.shaders.final[ID] = love.graphics.newShader("#pragma language glsl3\n" .. ID .. "\n" .. sh_final)
	end
	return self.shaders.final[ID]
end

--returns and initializes if not already done
do
	local lastID = 0
	function lib:getShaderModule(name)
		local sh = self.shaderLibrary.module[name]
		
		--give unique bit ID
		if not sh.ID then
			sh.ID = 2 ^ lastID
			lastID = lastID + 1
		end
		
		--initilized module
		self.allActiveShaderModules[name] = sh
		if not sh.initilized then
			sh.initilized = true
			if sh.init then
				sh:init(self)
			end
		end
		return sh
	end
end

--get a unique ID for this specific light setup
do
	local lastID = 0
	local IDs = { }
	function lib:getLightSetupID(lights, types)
		local ID = {0, 0, 0, 0, 0, 0, 0, 0}
		if lights then
			for d,s in pairs(types) do
				if not IDs[d] then
					lastID = lastID + 1
					IDs[d] = lastID
				end
				
				ID[IDs[d]] = lib.shaderLibrary.light[d].batchable and 1 or s
			end
		end
		return string.char(unpack(ID))
	end
end

--construct a shader
local baseShader = love.filesystem.read(lib.root .. "/shaders/base.glsl")
local baseShadowShader = love.filesystem.read(lib.root .. "/shaders/shadow.glsl")
function lib:getShader(o, pass, canvases, light, shadows)
	local mat = o.material
	local shaderType = o.shaderType
	local reflection = o.reflection or o.obj and o.obj.reflection or self.sky_reflection
	local refractions = mat.ior ~= 1.0
	local modules = o.modules or o.obj and o.obj.modules or mat.modules
	
	--check if required shader exists
	assert(self.shaderLibrary.base[shaderType], "Shader '" .. shaderType .. "' does not exist!")
	
	--get unique IDs for the components
	local ID_base = self.shaderLibrary.base[shaderType]:getTypeID(self, mat)
	local ID_light = shadows and 0 or light.ID
	local ID_settings = 0
	local ID_modules = 0
	
	--global modules
	local m = { }
	for d,s in pairs(self.activeShaderModules) do
		m[d] = self:getShaderModule(d)
		if not shadows or m[d].shadow then
			ID_modules = ID_modules + m[d].ID
		end
	end
	
	--local modules
	if modules then
		for d,s in pairs(modules) do
			if not self.activeShaderModules[d] then
				m[d] = self:getShaderModule(d)
				if not shadows or m[d].shadow then
					ID_modules = ID_modules + m[d].ID
				end
			end
		end
	end
	
	--settings
	local globalDefines
	if not shadows then
		globalDefines = { }
		if reflection then
			ID_settings = ID_settings + 2 ^ 0
		end
		if canvases.deferred and pass == 1 then
			ID_settings = ID_settings + 2 ^ 1
			table.insert(globalDefines, "#define DEFERRED")
		end
		if canvases.refractions and refractions and pass == 2 then
			ID_settings = ID_settings + 2 ^ 2
			table.insert(globalDefines, "#define REFRACTIONS_ENABLED")
		end
		if canvases.postEffects and self.exposure and (canvases.direct or canvases.format == "rgba8") then
			ID_settings = ID_settings + 2 ^ 3
			table.insert(globalDefines, "#define EXPOSURE_ENABLED")
		end
		if canvases.postEffects and self.gamma and (canvases.direct or canvases.format == "rgba8") then
			ID_settings = ID_settings + 2 ^ 4
			table.insert(globalDefines, "#define GAMMA_ENABLED")
		end
		if self.fog_enabled and canvases.direct then
			ID_settings = ID_settings + 2 ^ 5
			table.insert(globalDefines, "#define FOG_ENABLED")
		end
	end
	
	--construct full ID (8 bytes light, 1 byte base, 4 bytes modules and 1 byte settings
	local ID = ID_light .. string.char(ID_base, (ID_modules / 256^3) % 256, (ID_modules / 256^2) % 256, (ID_modules / 256^1) % 256, (ID_modules / 256^0) % 256, ID_settings)
	
	if not self.mainShaders[ID] then
		--construct shader
		local code = shadows and baseShadowShader or baseShader
		
		--additional data
		self.mainShaders[ID] = {
			shaderType = shaderType,
			modules = m,
			reflection = not shadows and reflection,
			shadows = shadows,
		}
		local info = self.mainShaders[ID]
		
		if not shadows then
			--setting specific defines
			code = code:gsub("#import globalDefines", table.concat(globalDefines, "\n"))
			
			--the shader might need additional code
			code = code:gsub("#import mainDefines", self.shaderLibrary.base[shaderType]:constructDefines(self, mat) or "")
			code = code:gsub("#import mainPixelPre", self.shaderLibrary.base[shaderType]:constructPixelPre(self, mat) or "")
			code = code:gsub("#import mainPixelPost", self.shaderLibrary.base[shaderType]:constructPixelPost(self, mat) or "")
			code = code:gsub("#import mainPixel", self.shaderLibrary.base[shaderType]:constructPixel(self, mat) or "")
			code = code:gsub("#import mainVertex", self.shaderLibrary.base[shaderType]:constructVertex(self, mat) or "")
			
			--import reflection function
			code = code:gsub("#import reflections", info.reflection and codes.reflections or codes.ambientOnly)
		end
		
		--import additional modules
		local define = { }
		local vertex = { }
		local pixel = { }
		local pixelPost = { }
		for d,s in pairs(m) do
			assert(s, "Shader module '" .. d .. "' does not exist!")
			table.insert(define, s.constructDefines and s:constructDefines(self, info) or "")
			table.insert(vertex, s.constructVertex and s:constructVertex(self, info) or "")
			table.insert(pixel, s.constructPixel and s:constructPixel(self, info) or "")
			table.insert(pixelPost, s.constructPixelPost and s:constructPixelPost(self, info) or "")
		end
		code = code:gsub("#import modulesDefines", table.concat(define, "\n"))
		code = code:gsub("#import modulesVertex", table.concat(vertex, "\n"))
		code = code:gsub("#import modulesPixelPost", table.concat(pixelPost, "\n"))
		code = code:gsub("#import modulesPixel", table.concat(pixel, "\n"))
		
		if not shadows then
			--fog engine
			if self.fog_enabled and canvases.direct then
				code = code:gsub("#import fog", codes.fog)
			end
			
			--construct forward lighting system
			if #light.lights > 0 then
				local lcInit, lc = self:getLightComponents(light)
				
				code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
				code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
				code = code:gsub("#import lightFunction", self.shaderLibrary.base[shaderType]:constructLightFunction(self, info))
			end
		end
		
		--remove unused imports and remove tabs
		code = code:gsub("#import", "//#import")
		code = code:gsub("	", "")
		
		--compile
		info.shader = love.graphics.newShader(code)
		
		--count
		self.mainShaderCount = self.mainShaderCount + 1
	end
	
	return self.mainShaders[ID]
end

local baseParticlesShader = love.filesystem.read(lib.root .. "/shaders/particles.glsl")
local baseParticleShader = love.filesystem.read(lib.root .. "/shaders/particle.glsl")
function lib:getParticlesShader(canvases, light, emissive, single)
	--additional settings
	local globalDefines = { }
	local ID_settings = 0
	if emissive then
		ID_settings = ID_settings + 2^0
		table.insert(globalDefines, "#define TEX_EMISSION")
	end
	if canvases.postEffects and self.exposure and (canvases.direct or canvases.format == "rgba8") then
		ID_settings = ID_settings + 2^1
		table.insert(globalDefines, "#define EXPOSURE_ENABLED")
	end
	if canvases.postEffects and self.gamma and (canvases.direct or canvases.format == "rgba8") then
		ID_settings = ID_settings + 2^2
		table.insert(globalDefines, "#define GAMMA_ENABLED")
	end
	if self.fog_enabled and canvases.direct then
		ID_settings = ID_settings + 2^4
		table.insert(globalDefines, "#define FOG_ENABLED")
	end
	if single then
		ID_settings = ID_settings + 2^5
	end
	
	local ID = light.ID .. string.char(ID_settings)
	
	if not self.particlesShader[ID] then
		local info = { }
		
		--construct shader
		local code = single and baseParticleShader or baseParticlesShader
		
		--setting specific defines
		code = code:gsub("#import globalDefines", table.concat(globalDefines, "\n"))
		
		--fog engine
		if self.fog_enabled and canvases.direct then
			code = code:gsub("#import fog", codes.fog)
		end
		
		--construct forward lighting system
		if light.lights and #light.lights > 0 then
			local lcInit, lc = self:getLightComponents(light, true)
			
			code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
			code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
		end
		
		--remove unused imports and remove tabs
		code = code:gsub("#import", "//#import")
		code = code:gsub("	", "")
		
		--compile
		info.shader = love.graphics.newShader(code)
		self.particlesShader[ID] = info
	end
	
	return self.particlesShader[ID]
end

function lib:getLightComponents(light, basic)
	local lcInit = { }
	local lc = { }
	
	--global defines and code
	for d,s in pairs(light.types) do
		assert(self.shaderLibrary.light[d], "Light of type '" .. d .. "' does not exist!")
		lcInit[#lcInit+1] = self.shaderLibrary.light[d]:constructDefinesGlobal(self)
		
		if basic then
			lc[#lc+1] = self.shaderLibrary.light[d]:constructPixelBasicGlobal(self)
		else
			lc[#lc+1] = self.shaderLibrary.light[d]:constructPixelGlobal(self)
		end
	end
	
	--defines and code
	local IDs = { }
	for	d,s in ipairs(light.lights) do
		IDs[s.light_typ] = (IDs[s.light_typ] or -1) + 1
		lcInit[#lcInit+1] = self.shaderLibrary.light[s.light_typ]:constructDefines(self, IDs[s.light_typ])
		
		local px
		if basic then
			px = self.shaderLibrary.light[s.light_typ]:constructPixelBasic(self, IDs[s.light_typ])
		else
			px = self.shaderLibrary.light[s.light_typ]:constructPixel(self, IDs[s.light_typ])
		end
		if px then
			lc[#lc+1] = "{\n" .. px .. "\n}"
		end
	end
	
	return lcInit, lc
end