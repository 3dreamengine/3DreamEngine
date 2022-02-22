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

local lastShaderID = 0
function lib:newShader(path)
	local shader = require(path)
	
	shader.path = path
	
	shader.id = lastShaderID
	lastShaderID = lastShaderID + 1
	
	if shader.init then
		shader:init(self)
	end
	
	return shader
end

lib.shaderRegister = { }
function lib:registerShader(shader, name)
	if type(shader) == "string" then
		name = name or shader:match("[^%/]*$")
		self.shaderRegister[name] = lib:newShader(shader)
	else
		self.shaderRegister[name] = shader
	end
	return self.shaderRegister[name]
end

function lib:resolveShaderName(name)
	if type(name) == "table" then
		return name
	elseif name then
		local sh = lib.shaderRegister[name]
		assert(sh, "required shader " .. tostring(name) .. " is not registered")
		return sh
	end
end

--inbuilt shader
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/inbuilt")) do
	if s:sub(-4) == ".lua" then
		lib:registerShader(lib.root .. "/shaders/inbuilt/" .. s:sub(1, #s-4))
	end
end

--default shader
lib.defaultPixelShader = lib:resolveShaderName("textured")
lib.defaultVertexShader = lib:resolveShaderName("vertex")
lib.defaultWorldShader = lib:resolveShaderName("PBR")

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

--load all setting depending shaders
function lib.loadShader(self)
	self.finalShaders = { }
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
function lib.getFinalShader(self, canvases)
	local parts = { }
	
	table.insert(parts, self.autoExposure_enabled and "#define AUTOEXPOSURE_ENABLED" or nil)
	table.insert(parts, self.exposure and "#define EXPOSURE_ENABLED" or nil)
	table.insert(parts, self.bloom_enabled and "#define BLOOM_ENABLED" or nil)
	
	table.insert(parts, self.fog_enabled and "#define FOG_ENABLED" or nil)
	table.insert(parts, self.AO_enabled and "#define AO_ENABLED" or nil)
	
	table.insert(parts, self.gamma and "#define GAMMA_CORRECTION" or nil)
	
	table.insert(parts, canvases.refractions and "#define REFRACTIONS_ENABLED" or nil)
	
	table.insert(parts, (canvases.fxaa and canvases.msaa == 0) and "#define FXAA_ENABLED" or nil)
	
	table.insert(parts, self.distortionMargin and string.format("#define DISTORTION_MARGIN %f", self.distortionMargin) or nil)
	
	table.insert(parts, self.fog_enabled and codes.fog or nil)
	
	local ID = table.concat(parts, "\n")
	if not self.finalShaders[ID] then
		self.finalShaders[ID] = love.graphics.newShader("#pragma language glsl3\n" .. ID .. "\n" .. codes.final)
	end
	return self.finalShaders[ID]
end

function lib:getRenderShaderID(task, pass, shadows)
	local mesh = task:getMesh()
	local mat = mesh.material
	
	--todo reflections can now support different models, for example for BB reflections
	local reflections = not shadows and (task:getReflection() or self.defaultReflection)
	
	local pixelShader = mat.pixelShader or mesh.pixelShader or self.defaultPixelShader
	local vertexShader = mat.vertexShader or mesh.vertexShader or self.defaultVertexShader
	local worldShader = mat.worldShader or mesh.worldShader or self.defaultWorldShader
	
	--construct full ID
	return string.char(
		mesh.instanceMesh and 1 or 0,
		reflections and 1 or 0,
		mesh.instanceMesh and 1 or 0,
		pixelShader.id % 256, math.floor(pixelShader.id / 256),
		vertexShader.id % 256, math.floor(vertexShader.id / 256),
		worldShader.id % 256, math.floor(worldShader.id / 256),
		pixelShader:getId(self, mat, shadows),
		vertexShader:getId(self, mat, shadows),
		worldShader:getId(self, mat, shadows)
	)
end

function lib:getRenderShader(ID, mesh, pass, canvases, light, shadows, sun)
	--collect additional defines
	local settings = 0
	if shadows then
		settings = settings + 2 ^ 0
		if sun then
			settings = settings + 2 ^ 1
		end
	else
		--settings
		if pass == 1 then
			settings = settings + 2 ^ 2
		elseif pass == 2 then
			if canvases.refractions then
				settings = settings + 2 ^ 3
			end
			settings = settings + 2 ^ 4
		end
		
		--canvas settings
		if canvases.mode ~= "direct" then
			settings = settings + 2 ^ 5
		end
		if self.gamma then
			settings = settings + 2 ^ 6
		end
		if self.fog_enabled and canvases.mode ~= "normal" then
			settings = settings + 2 ^ 7
		end
	end
	
	local shaderID = ID .. (light and light.ID or "") .. string.char(settings)
	
	if not self.mainShaders[shaderID] then
		local mat = mesh.material
		local reflection = not shadows and (mesh.reflection or self.defaultReflection)
		
		--additional data
		local info = {
			reflection = reflection,
			material = mat,
			modules = m,
			shadows = shadows,
			uniforms = { },
			
			pixelShader = mat.pixelShader or mesh.pixelShader or self.defaultPixelShader,
			vertexShader = mat.vertexShader or mesh.vertexShader or self.defaultVertexShader,
			worldShader = mat.worldShader or mesh.worldShader or self.defaultWorldShader,
		}
		self.mainShaders[shaderID] = info
		
		--additional code
		local defines = { }
		local pixel = { }
		local pixelMaterial = { }
		local vertex = { }
		
		--if instancing is used
		if mesh.instanceMesh then
			table.insert(defines, "#define INSTANCING")
		end
		
		--collect additional defines
		if shadows then
			table.insert(defines, "#define IS_SHADOW")
			if sun then
				table.insert(defines, "#define IS_SUN")
			end
		else
			--settings
			if pass == 1 then
				table.insert(defines, "#define DEPTH_ENABLED")
			elseif pass == 2 then
				if canvases.refractions then
					table.insert(defines, "#define REFRACTIONS_ENABLED")
				end
				table.insert(defines, "#define ALPHA_PASS")
			end
			
			--canvas settings
			if canvases.mode ~= "direct" then
				table.insert(defines, "#define DEPTH_AVAILABLE")
			end
			if self.gamma then
				table.insert(defines, "#define GAMMA_CORRECTION")
			end
			if self.fog_enabled and canvases.mode ~= "normal" then
				table.insert(defines, "#define FOG_ENABLED")
			end
		end
		
		--helpful functions
		table.insert(defines, codes.functions)
		
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
		
		--material shader
		table.insert(defines, info.pixelShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.pixelShader.defines)
		table.insert(defines, info.vertexShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.vertexShader.defines)
		
		table.insert(pixelMaterial, info.pixelShader:buildPixel(self, mat, shadows))
		table.insert(pixelMaterial, info.pixelShader.pixel)
		table.insert(pixelMaterial, info.vertexShader:buildPixel(self, mat, shadows))
		table.insert(pixelMaterial, info.vertexShader.pixel)
		
		table.insert(vertex, info.pixelShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.pixelShader.vertex)
		table.insert(vertex, info.vertexShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.vertexShader.vertex)
		
		--world
		table.insert(defines, info.worldShader:buildDefines(self, mat, shadows))
		table.insert(defines, info.worldShader.defines)
		
		table.insert(pixel, info.worldShader:buildPixel(self, mat, shadows))
		table.insert(pixel, info.worldShader.pixel)
		
		table.insert(vertex, info.worldShader:buildVertex(self, mat, shadows))
		table.insert(vertex, info.worldShader.vertex)
		
		--build code
		local code = codes.base
		code = code:gsub("#import defines", table.concat(defines, "\n"))
		code = code:gsub("#import pixelMaterial", table.concat(pixelMaterial, "\n"))
		code = code:gsub("#import pixel", table.concat(pixel, "\n"))
		code = code:gsub("#import vertex", table.concat(vertex, "\n"))
		code = code:gsub("\t", "")
		
		--compile
		info.code = code
		info.shader = love.graphics.newShader(code)
		
		--count
		self.mainShaderCount = self.mainShaderCount + 1
	end
	
	return self.mainShaders[shaderID]
end

function lib:getParticlesShaderID(pass, canvases, emissive, distortion, single)
	local id = 0
	if emissive then
		id = id + 2^0
	end
	if distortion and pass == 2 then
		id = id + 2^1
	end
	if self.fog_enabled and canvases.mode ~= "normal" then
		id = id + 2^2
	end
	if self.gamma then
		id = id + 2^3
	end
	if canvases.refractions and pass == 2 then
		id = id + 2^5
	end
	if pass == 1 and canvases.mode ~= "direct" then
		id = id + 2^6
	end
	if single then
		id = id + 2^7
	end
	return string.char(id)
end

function lib:getParticlesShader(pass, canvases, light, emissive, distortion, single)
	local ID = light.ID .. self:getParticlesShaderID(pass, canvases, emissive, distortion, single)
	
	if not self.particlesShader[ID] then
		local defines = { }
		if emissive then
			table.insert(defines, "#define TEX_EMISSION")
		end
		if distortion and pass == 2 then
			table.insert(defines, "#define TEX_DISORTION")
		end
		if self.fog_enabled and canvases.mode ~= "normal" then
			table.insert(defines, "#define FOG_ENABLED")
		end
		if self.gamma then
			table.insert(defines, "#define GAMMA_CORRECTION")
		end
		if canvases.refractions and pass == 2 then
			table.insert(defines, "#define REFRACTIONS_ENABLED")
		end
		if pass == 1 and canvases.mode ~= "direct" then
			table.insert(defines, "#define DEPTH_ENABLED")
		end
		if single then
			table.insert(defines, "#define SINGLE")
		end
		
		--helpful functions
		table.insert(defines, codes.functions)
		
		local info = {
			uniforms = { }
		}
		
		--construct shader
		local code = codes.particle
		
		--setting specific defines
		code = code:gsub("#import defines", table.concat(defines, "\n"))
		
		--fog engine
		if self.fog_enabled and canvases.mode ~= "normal" then
			code = code:gsub("#import fog", codes.fog)
		end
		
		--construct forward lighting system
		if light.lights and #light.lights > 0 then
			local def, p = self:getLightComponents(light, true)
			
			code = code:gsub("#import lightingSystemInit", def)
			code = code:gsub("#import lightingSystem", p)
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
	for typ,count in pairs(light.types) do
		assert(self.lightShaders[typ], "Light of type '" .. typ .. "' does not exist!")
		lcInit[#lcInit+1] = self.lightShaders[typ]:constructDefinesGlobal(self)
		
		if basic then
			lc[#lc+1] = self.lightShaders[typ]:constructPixelBasicGlobal(self)
		else
			lc[#lc+1] = self.lightShaders[typ]:constructPixelGlobal(self)
		end
	end
	
	--defines and code
	local IDs = { }
	for	_,light in ipairs(light.lights) do
		IDs[light.light_typ] = (IDs[light.light_typ] or -1) + 1
		lcInit[#lcInit+1] = self.lightShaders[light.light_typ]:constructDefines(self, light.light_typ .. "_" .. IDs[light.light_typ])
		
		local px
		if basic then
			px = self.lightShaders[light.light_typ]:constructPixelBasic(self, light.light_typ .. "_" .. IDs[light.light_typ])
		else
			px = self.lightShaders[light.light_typ]:constructPixel(self, light.light_typ .. "_" .. IDs[light.light_typ])
		end
		if px then
			table.insert(lc, "{\n" .. px .. "\n}")
		end
	end
	
	return table.concat(lcInit, "\n"), table.concat(lc, "\n")
end