--[[
#part of the 3DreamEngine by Luke100000
shader.lua - loads the shaders
--]]

local lib = _3DreamEngine

local testForOpenES = true

--enables auto shader validator
if _DEBUGMODE then
	love.graphics.newShader_old = love.graphics.newShader
	function love.graphics.newShader(pixel, vertex, name)
		local status, err = love.graphics.validateShader(testForOpenES, pixel, vertex)
		if not status then
			print()
			print("-----------------")
			print("SHADER ERROR " .. tostring(name))
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

function lib:newShader(path)
	local shader = require(path)
	local project = love.filesystem.getInfo(path .. ".3ds") and love.filesystem.load(path .. ".3ds")()
	
	local defines, pixel, vertex
	if project then
		defines, pixel, vertex = self:compileShader(project)
	else
		defines, pixel, vertex = "", "", ""
	end
	
	shader.path = path
	shader.compiledDefines = defines
	shader.compiledPixel = pixel
	shader.compiledVertex = vertex
	
	return shader
end

lib.defaultMaterialPixelShader = lib:newShader(lib.root .. "/shaders/material/default")
lib.defaultMaterialVertexShader = lib:newShader(lib.root .. "/shaders/material/vertex")
lib.defaultWorldPixelShader = lib:newShader(lib.root .. "/shaders/world/PBR")
lib.defaultWorldVertexShader = lib:newShader(lib.root .. "/shaders/world/empty")

--load code snippsets
local codes = { }
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/code")) do
	codes[s:sub(1, #s-5)] = love.filesystem.read(lib.root .. "/shaders/code/" .. s)
end

--light shaders
lib.lightShaders = { }
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/light")) do
	local name = s:sub(1, #s-4)
	lib.lightShaders[name] = require(lib.root .. "/shaders/light/" .. name)
end

--return and load shader if nececary
lib.shaders = { }
function lib:getShader(s)
	if not lib.shaders[s] then
		local r = love.filesystem.read
		local shader = r(lib.root .. "/shaders/" .. s .. ".glsl") or r(lib.root .. "/shaders/sky/" .. s .. ".glsl") or r(lib.root .. "/shaders/debug/" .. s .. ".glsl")
		assert(shader, "shader " .. tostring(s) .. " does not exist")
		lib.shaders[s] = love.graphics.newShader(shader, nil, s)
	end
	return lib.shaders[s]
end

local function earlyExposure(canvases)
	return canvases.mode ~= "normal" or canvases.format == "rgba8"
end

--load all setting depending shaders
function lib.loadShader(self)
	self.shaders.final = { }
	self.mainShaders = { }
	self.particlesShader = { }
	self.mainShaderCount = 0

	--the ambient occlusion shader
	if self.AO_enabled then
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
	end
end

--the final canvas combines all resources into one result
local sh_final = love.filesystem.read(lib.root .. "/shaders/final.glsl")
function lib.getFinalShader(self, canvases)
	local parts = { }
	parts[#parts+1] = canvases.postEffects and "#define POSTEFFECTS_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and self.autoExposure_enabled and "#define AUTOEXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and earlyExposure(canvases) and self.exposure and "#define EXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and earlyExposure(canvases) and self.gamma and "#define GAMMA_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects and self.bloom_enabled and "#define BLOOM_ENABLED" or nil
	
	parts[#parts+1] = self.fog_enabled and "#define FOG_ENABLED" or nil
	parts[#parts+1] = self.AO_enabled and "#define AO_ENABLED" or nil
	
	parts[#parts+1] = canvases.refractions and "#define REFRACTIONS_ENABLED" or nil
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
				
				ID[IDs[d]] = lib.lightShaders[d].batchable and 1 or s
			end
		end
		return string.char(unpack(ID))
	end
end

function lib:getRenderShaderID(obj, pass, shadows)
	local mat = obj.material
	local reflections = not shadows and (obj.reflection or obj.obj and obj.obj.reflection or self.sky_reflection)
	
	--construct full ID
	return string.char(
		reflections and 1 or 0, --todo reflections can now support different models
		(mat.materialPixelShader or self.defaultMaterialPixelShader):getPixelId(self, mat, shadows),
		(mat.materialVertexShader or self.defaultMaterialVertexShader):getVertexId(self, mat, shadows),
		(mat.worldPixelShader or self.defaultWorldPixelShader):getPixelId(self, mat, shadows),
		(mat.worldVertexShader or self.defaultWorldVertexShader):getVertexId(self, mat, shadows)
	)
end

function lib:getRenderShader(ID, obj, pass, canvases, light, shadows, sun)
	--combine the settings ID and the light id
	local shaderID = (pass or 0) + (canvases and canvases.shaderID or 0)
	if light then
		shaderID = light.ID .. shaderID
	end
	if not self.mainShaders[shaderID] then
		self.mainShaders[shaderID] = { }
	end
	
	if not self.mainShaders[shaderID][ID] then
		local mat = obj.material
		local reflection = not shadows and (obj.reflection or obj.obj and obj.obj.reflection or self.sky_reflection)
		
		--additional data
		local info = {
			shaderType = shaderType,
			reflection = reflection,
			material = mat,
			modules = m,
			shadows = shadows,
			uniforms = { },
			
			materialPixelShader = mat.materialPixelShader or self.defaultMaterialPixelShader,
			materialVertexShader = mat.materialVertexShader or self.defaultMaterialVertexShader,
			worldVertexShader = mat.worldVertexShader or self.defaultWorldVertexShader,
			worldPixelShader = mat.worldPixelShader or self.defaultWorldPixelShader,
		}
		self.mainShaders[shaderID][ID] = info
		
		--additional code
		local defines = { }
		local pixel = { }
		local vertex = { }
		
		--collect additional defines
		if shadows then
			table.insert(defines, "#define IS_SHADOW")
			if sun then
				table.insert(defines, "#define IS_SUN")
			end
			
			if mat.discard then
				table.insert(defines, "#define DISCARD_ENABLED")
			end
		else
			--settings
			if pass == 1 then
				if mat.discard or mat.dither or self.dither then
					table.insert(defines, "#define DISCARD_ENABLED")
				end
				table.insert(defines, "#define DEPTH_ENABLED")
			elseif pass == 2 then
				if canvases.refractions then
					table.insert(defines, "#define REFRACTIONS_ENABLED")
				end
				if canvases.averageAlpha then
					table.insert(defines, "#define AVERAGE_ENABLED")
				end
				table.insert(defines, "#define ALPHA_PASS")
			end
			
			if canvases.postEffects and self.exposure and earlyExposure(canvases) then
				table.insert(defines, "#define EXPOSURE_ENABLED")
			end
			if canvases.postEffects and self.gamma and earlyExposure(canvases) then
				table.insert(defines, "#define GAMMA_ENABLED")
			end
			if self.fog_enabled and canvases.mode ~= "normal" then
				table.insert(defines, "#define FOG_ENABLED")
			end
			if mat.translucent > 0 then
				table.insert(defines, "#define TRANSLUCENT_ENABLED")
			end
		end
		
		--material shader
		table.insert(defines, info.materialPixelShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.materialPixelShader.compiledDefines)
		table.insert(defines, info.materialVertexShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.materialVertexShader.compiledDefines)
		
		table.insert(pixel, info.materialPixelShader:buildPixel(self, mat, shadows))
		table.insert(pixel, info.materialPixelShader.compiledPixel)
		
		table.insert(vertex, info.materialPixelShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.materialPixelShader.compiledVertex)
		table.insert(vertex, info.materialVertexShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.materialVertexShader.compiledVertex)
		
		--additional code
		if not shadows then
			--construct forward lighting system
			if #light.lights > 0 then
				local def, p = self:getLightComponents(light)
				table.insert(defines, "#ifdef PIXEL")
				table.insert(defines, def)
				table.insert(defines, "#endif")
				
				table.insert(pixel, p)
			end
			
			--fog engine
			if self.fog_enabled then
				table.insert(defines, codes.fog)
			end
			
			--reflection
			if reflection then
				table.insert(defines, codes.reflections)
			else
				table.insert(defines, codes.ambientOnly)
			end
		end
		
		--world
		table.insert(defines, info.worldPixelShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.worldPixelShader.compiledDefines)
		table.insert(defines, info.worldVertexShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.worldVertexShader.compiledDefines)
		
		table.insert(pixel, info.worldPixelShader:buildPixel(self, mat, shadows))
		table.insert(pixel, info.worldPixelShader.compiledPixel)
		
		table.insert(vertex, info.worldPixelShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.worldPixelShader.compiledVertex)
		table.insert(vertex, info.worldVertexShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.worldVertexShader.compiledVertex)
		
		--build code
		local code = codes.base
		code = code:gsub("#import defines", table.concat(defines, "\n"))
		code = code:gsub("#import pixel", table.concat(pixel, "\n"))
		code = code:gsub("#import vertex", table.concat(vertex, "\n"))
		code = code:gsub("\t", "")
		
		--compile
		info.code = code
		info.shader = love.graphics.newShader(code)
		
		--count
		self.mainShaderCount = self.mainShaderCount + 1
	end
	
	return self.mainShaders[shaderID][ID]
end

function lib:getLightComponents(light, basic)
	local lcInit = { }
	local lc = { }
	
	--global defines and code
	for d,s in pairs(light.types) do
		assert(self.lightShaders[d], "Light of type '" .. d .. "' does not exist!")
		lcInit[#lcInit+1] = self.lightShaders[d]:constructDefinesGlobal(self)
		
		if basic then
			lc[#lc+1] = self.lightShaders[d]:constructPixelBasicGlobal(self)
		else
			lc[#lc+1] = self.lightShaders[d]:constructPixelGlobal(self)
		end
	end
	
	--defines and code
	local IDs = { }
	for	d,s in ipairs(light.lights) do
		IDs[s.light_typ] = (IDs[s.light_typ] or -1) + 1
		lcInit[#lcInit+1] = self.lightShaders[s.light_typ]:constructDefines(self, IDs[s.light_typ])
		
		local px
		if basic then
			px = self.lightShaders[s.light_typ]:constructPixelBasic(self, IDs[s.light_typ])
		else
			px = self.lightShaders[s.light_typ]:constructPixel(self, IDs[s.light_typ])
		end
		if px then
			lc[#lc+1] = "{\n" .. px .. "\n}"
		end
	end
	
	return table.concat(lcInit, "\n"), table.concat(lc, "\n")
end