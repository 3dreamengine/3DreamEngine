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

--the sky sphere shader
lib.shaders.sky_cube = love.graphics.newShader(lib.root .. "/shaders/sky_cube.glsl")
lib.shaders.sky_hdri = love.graphics.newShader(lib.root .. "/shaders/sky_hdri.glsl")
lib.shaders.sky = love.graphics.newShader(lib.root .. "/shaders/sky.glsl")

--the shadow shader
lib.shaders.shadow = love.graphics.newShader(lib.root .. "/shaders/shadow.glsl")

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
	if self.default_settings.deferred or self.reflections_settings.deferred then
		local sh_light = love.filesystem.read(lib.root .. "/shaders/light.glsl")
		for d,s in pairs(self.shaderLibrary.light) do
			local lighting, lightRequirements
			if s.batchable then
				lighting = { }
				for i = 1, self.max_lights do
					lighting[#lighting+1] = {light_typ = d}
				end
				lightRequirements = {[d] = self.max_lights}
			else
				lighting = {{light_typ = d}}
				lightRequirements = {[d] = 1}
			end
			
			local lcInit, lc = self:getLightComponents(lighting, lightRequirements)
			local code = sh_light
			code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
			code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
			code = code:gsub("#import lightFunction", self.shaderLibrary.base[self.deferredShaderType]:constructLightFunction(self, info))
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
local moduleIDs = { }
local lastModuleID = 1
function lib:getShaderModule(name)
	if not moduleIDs[name] then
		lastModuleID = lastModuleID + 1
		moduleIDs[name] = 1.0 / lastModuleID
	end
	
	local sh = self.shaderLibrary.module[name]
	self.allActiveShaderModules[name] = sh
	if not sh.initilized then
		sh.initilized = true
		if sh.init then
			sh:init(self)
		end
	end
	return sh
end

--returns a fitting shader construction instruction for the current material and meshtype
function lib:getShaderInfo(s, obj)
	local mat = s.material
	local shaderType = s.shaderType
	local reflection = s.reflection or obj.reflection or self.sky_reflection
	local refraction = mat.ior ~= 1.0 and self.refraction
	local modules = s.modules or obj.modules or mat.modules
	
	--group shader and vertex shader
	if not self.mainShaders[shaderType] then
		self.mainShaders[shaderType] = { }
	end
	
	--add new type of shader to list
	local shs = self.mainShaders[shaderType]
	
	--get a unique ID
	assert(self.shaderLibrary.base[shaderType], "Shader '" .. shaderType .. "' does not exist!")
	local ID = self.shaderLibrary.base[shaderType]:getShaderInfoID(self, mat, shaderType, reflection)
	
	--reflection module
	ID = ID + (reflection and 1024 or 0)
	ID = ID + (refraction and 2048 or 0)
	
	--global modules
	local m = { }
	for d,s in pairs(self.activeShaderModules) do
		m[d] = self:getShaderModule(d)
		ID = ID + moduleIDs[d]
	end
	
	--local modules
	if modules then
		for d,s in pairs(modules) do
			if not self.activeShaderModules[d] then
				m[d] = self:getShaderModule(d)
				ID = ID + moduleIDs[d]
			end
		end
	end
	
	--create new shader info object if necessary
	if not shs[ID] then
		shs[ID] = self.shaderLibrary.base[shaderType]:getShaderInfo(self, mat, shaderType, reflection)
		shs[ID].shaderType = shaderType
		shs[ID].reflection = reflection
		shs[ID].refraction = refraction
		shs[ID].shaders = { }
		shs[ID].modules = m
	end
	
	return shs[ID]
end

--get a unique ID for this specific light setup
local lastID = 0
local lightRequirementIDs = { }
local function getLightSetupID(lighting, lightRequirements)
	local ID = 0
	if lighting then
		for d,s in pairs(lightRequirements) do
			if not lightRequirementIDs[d] then
				lightRequirementIDs[d] = 16 ^ lastID
				lastID = lastID + 1
			end
			ID = ID + lightRequirementIDs[d] * (lib.shaderLibrary.light[d].batchable and 1 or s)
		end
	end
	return ID
end

--construct a shader
local baseShader = love.filesystem.read(lib.root .. "/shaders/base.glsl")
function lib:getShader(info, canvases, pass, lighting, lightRequirements)
	local ID = getLightSetupID(lighting, lightRequirements)
	
	--additional settings
	local globalDefines = { }
	if canvases.deferred and pass == 1 then
		ID = ID + 0.5
		table.insert(globalDefines, "#define DEFERRED")
	end
	if info.refraction and pass == 2 then
		ID = ID + 0.25
		table.insert(globalDefines, "#define REFRACTIONS_ENABLED")
	end
	if canvases.postEffects and self.exposure and (canvases.direct or canvases.format == "rgba8") then
		ID = ID + 0.125
		table.insert(globalDefines, "#define EXPOSURE_ENABLED")
	end
	if canvases.postEffects and self.gamma and (canvases.direct or canvases.format == "rgba8") then
		ID = ID + 0.0625
		table.insert(globalDefines, "#define GAMMA_ENABLED")
	end
	if self.fog_enabled and canvases.direct then
		ID = ID + 1 / 32
		table.insert(globalDefines, "#define FOG_ENABLED")
	end
	
	if not info.shaders[ID] then
		--construct shader
		local code = baseShader
		
		--setting specific defines
		code = code:gsub("#import globalDefines", table.concat(globalDefines, "\n"))
		
		--the shader might need additional code
		code = code:gsub("#import mainDefines", self.shaderLibrary.base[info.shaderType]:constructDefines(self, info) or "")
		code = code:gsub("#import mainPixelPre", self.shaderLibrary.base[info.shaderType]:constructPixelPre(self, info) or "")
		code = code:gsub("#import mainPixelPost", self.shaderLibrary.base[info.shaderType]:constructPixelPost(self, info) or "")
		code = code:gsub("#import mainPixel", self.shaderLibrary.base[info.shaderType]:constructPixel(self, info) or "")
		code = code:gsub("#import mainVertex", self.shaderLibrary.base[info.shaderType]:constructVertex(self, info) or "")
		
		--import reflection function
		code = code:gsub("#import reflections", info.reflection and codes.reflections or codes.ambientOnly)
		
		--import additional modules
		local define = { }
		local vertex = { }
		local pixel = { }
		local pixelPost = { }
		for d,s in pairs(info.modules) do
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
		
		--fog engine
		if self.fog_enabled and canvases.direct then
			code = code:gsub("#import fog", codes.fog)
		end
		
		--construct forward lighting system
		if lighting and #lighting > 0 then
			local lcInit, lc = self:getLightComponents(lighting, lightRequirements)
			
			code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
			code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
			code = code:gsub("#import lightFunction", self.shaderLibrary.base[info.shaderType]:constructLightFunction(self, info))
		end
		
		--remove unused imports and remove tabs
		code = code:gsub("#import", "//#import")
		code = code:gsub("	", "")
		
		--compile
		info.shaders[ID] = love.graphics.newShader(code)
		
		--count
		self.mainShaderCount = self.mainShaderCount + 1
	end
	
	return info.shaders[ID]
end

local baseParticlesShader = love.filesystem.read(lib.root .. "/shaders/particles.glsl")
local baseParticleShader = love.filesystem.read(lib.root .. "/shaders/particle.glsl")
function lib:getParticlesShader(canvases, lighting, lightRequirements, emissive, single)
	local ID = getLightSetupID(lighting, lightRequirements)
	
	--additional settings
	local globalDefines = { }
	if emissive then
		ID = ID + 0.5
		table.insert(globalDefines, "#define TEX_EMISSION")
	end
	if canvases.postEffects and self.exposure and (canvases.direct or canvases.format == "rgba8") then
		ID = ID + 0.125
		table.insert(globalDefines, "#define EXPOSURE_ENABLED")
	end
	if canvases.postEffects and self.gamma and (canvases.direct or canvases.format == "rgba8") then
		ID = ID + 0.0625
		table.insert(globalDefines, "#define GAMMA_ENABLED")
	end
	if self.fog_enabled and canvases.direct then
		ID = ID + 1 / 32
		table.insert(globalDefines, "#define FOG_ENABLED")
	end
	
	--single particle
	if single then
		ID = -ID
	end
	
	if not self.particlesShader[ID] then
		--construct shader
		local code = single and baseParticleShader or baseParticlesShader
		
		--setting specific defines
		code = code:gsub("#import globalDefines", table.concat(globalDefines, "\n"))
		
		--fog engine
		if self.fog_enabled and canvases.direct then
			code = code:gsub("#import fog", codes.fog)
		end
		
		--construct forward lighting system
		if lighting and #lighting > 0 then
			local lcInit, lc = self:getLightComponents(lighting, lightRequirements, true)
			
			code = code:gsub("#import lightingSystemInit", table.concat(lcInit, "\n"))
			code = code:gsub("#import lightingSystem", table.concat(lc, "\n"))
		end
		
		--remove unused imports and remove tabs
		code = code:gsub("#import", "//#import")
		code = code:gsub("	", "")
		
		--compile
		self.particlesShader[ID] = love.graphics.newShader(code)
	end
	
	return self.particlesShader[ID]
end

function lib:getLightComponents(lighting, lightRequirements, basic)
	local lcInit = { }
	local lc = { }
	
	--global defines and code
	for d,s in pairs(lightRequirements) do
		assert(self.shaderLibrary.light[d], "Light of type '" .. d .. "' does not exist!")
		lcInit[#lcInit+1] = self.shaderLibrary.light[d]:constructDefinesGlobal(self, info)
		
		if basic then
			lc[#lc+1] = self.shaderLibrary.light[d]:constructPixelBasicGlobal(self, info)
		else
			lc[#lc+1] = self.shaderLibrary.light[d]:constructPixelGlobal(self, info)
		end
	end
	
	--defines and code
	local IDs = { }
	for	d,s in ipairs(lighting) do
		IDs[s.light_typ] = (IDs[s.light_typ] or -1) + 1
		lcInit[#lcInit+1] = self.shaderLibrary.light[s.light_typ]:constructDefines(self, info, IDs[s.light_typ])
		
		local px
		if basic then
			px = self.shaderLibrary.light[s.light_typ]:constructPixelBasic(self, info, IDs[s.light_typ])
		else
			px = self.shaderLibrary.light[s.light_typ]:constructPixel(self, info, IDs[s.light_typ])
		end
		if px then
			lc[#lc+1] = "{\n" .. px .. "\n}"
		end
	end
	
	return lcInit, lc
end