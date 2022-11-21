--[[
#part of the 3DreamEngine by Luke100000
shader.lua - loads the shaders
--]]

local lib = _3DreamEngine

local testForOpenES = true

--enables auto shader validator
if _DEBUGMODE and love.graphics then
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
			love.filesystem.write("shaderErrored.glsl", pixel)
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

function lib:getShader(name)
	if type(name) == "table" then
		return name
	elseif name then
		local sh = lib.shaderRegister[name]
		assert(sh, "required shader " .. tostring(name) .. " is not registered")
		return sh
	end
end

--inbuilt shader
for _,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/inbuilt")) do
	if s:sub(-4) == ".lua" then
		lib:registerShader(lib.root .. "/shaders/inbuilt/" .. s:sub(1, #s-4))
	end
end

--default shader
lib.defaultPixelShader = lib:getShader("textured")
lib.defaultVertexShader = lib:getShader("vertex")
lib.defaultWorldShader = lib:getShader("PBR")

--load code snippsets
local codes = { }
for _,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/code")) do
	codes[s:sub(1, #s-5)] = love.filesystem.read(lib.root .. "/shaders/code/" .. s)
end

--light shaders
lib.lightShaders = { }
for _,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/light")) do
	local name = s:sub(1, #s-4)
	lib.lightShaders[name] = require(lib.root .. "/shaders/light/" .. name)
end

--return and load shader if nececary
lib.shaders = { }
function lib:getBasicShader(s)
	if not lib.shaders[s] then
		local r = love.filesystem.read
		local shader = r(lib.root .. "/shaders/" .. s .. ".glsl") or r(lib.root .. "/shaders/sky/" .. s .. ".glsl") or r(lib.root .. "/shaders/debug/" .. s .. ".glsl")
		assert(shader, "shader " .. tostring(s) .. " does not exist")
		lib.shaders[s] = love.graphics.newShader(shader, nil, s)
	end
	return lib.shaders[s]
end

local function generateHeader(text)
	return "//########################################//\n//" .. string.rep(" ", math.floor((40 - #text)/2)) .. text .. "//\n//########################################//"
end

local function generateFooter()
	return "//////////////////////////////////////////"
end

local function insertHeader(t, name, code)
	if code and #code > 0 then
		table.insert(t, generateHeader(name))
		table.insert(t, code)
		table.insert(t, generateFooter())
	end
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
		self.shaders.SSAO:send("samples", table.unpack(f))
	end
end

--the final canvas combines all resources into one result
function lib:getFinalShader(canvases)
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

function lib:getRenderShaderID(task, shadows)
	local mesh = task:getMesh()
	local mat = mesh.material
	
	--todo reflections can now support different models, for example for BB reflections
	local reflections = not shadows and (task:getReflection() or self.defaultReflection)
	
	local pixelShader = mat.pixelShader or mesh.pixelShader or self.defaultPixelShader
	local vertexShader = mat.vertexShader or mesh.vertexShader or self.defaultVertexShader
	local worldShader = mat.worldShader or mesh.worldShader or self.defaultWorldShader
	
	--construct full ID
	return string.char(
		reflections and 1 or 0,
		(mesh.instanceMesh and 1 or 0) + (mat.discard and 2 or 0) + (mat.dither and 4 or 0) + (mat.translucency > 0 and 8 or 0),
		pixelShader.id % 256, math.floor(pixelShader.id / 256),
		vertexShader.id % 256, math.floor(vertexShader.id / 256),
		worldShader.id % 256, math.floor(worldShader.id / 256),
		pixelShader:getId(mat, shadows),
		vertexShader:getId(mat, shadows),
		worldShader:getId(mat, shadows)
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
		
		--discard
		if mat.discard then
			table.insert(defines, "#define DISCARD")
		end
		
		--dither
		if mat.dither then
			table.insert(defines, "#define DITHER")
		end
		
		--translucency
		if mat.translucency > 0 then
			table.insert(defines, "#define TRANSLUCENCY")
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
				table.insert(defines, generateHeader("fog"))
				table.insert(defines, codes.fog)
				table.insert(defines, generateFooter())
			end
			
			--reflection
			table.insert(defines, generateHeader("reflection"))
			if reflection then
				table.insert(defines, codes.reflections)
			else
				table.insert(defines, codes.ambientOnly)
			end
			table.insert(defines, generateFooter())
		end
		
		--material shader
		insertHeader(defines, "pixel shader", info.pixelShader:buildDefines(mat, shadows))
		insertHeader(defines, "vertex shader", info.vertexShader:buildDefines(mat, shadows))
		
		insertHeader(pixelMaterial, "pixel shader", info.pixelShader:buildPixel(mat, shadows))
		insertHeader(pixelMaterial, "vertex shader", info.vertexShader:buildPixel(mat, shadows))
		
		insertHeader(vertex, "vertex shader", info.vertexShader:buildVertex(mat, shadows))
		insertHeader(vertex, "pixel shader", info.pixelShader:buildVertex(mat, shadows))
		
		--world
		insertHeader(defines, "world shader", info.worldShader:buildDefines(mat, shadows))
		insertHeader(pixel, "world shader", info.worldShader:buildPixel(mat, shadows))
		insertHeader(vertex, "world shader", info.worldShader:buildVertex(mat, shadows))
		
		--build code
		local code = codes.base
		code = code:gsub("#import defines", table.concat(defines, "\n\n"))
		code = code:gsub("#import pixelMaterial", table.concat(pixelMaterial, "\n"))
		code = code:gsub("#import pixel", table.concat(pixel, "\n"))
		code = code:gsub("#import vertex", table.concat(vertex, "\n"))
		
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
			table.insert(defines, "#define EMISSION_TEXTURE")
		end
		if distortion and pass == 2 then
			table.insert(defines, "#define DISTORTION_TEXTURE")
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
		code = code:gsub("#import defines", table.concat(defines, "\n\n"))
		
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
	for typ, _ in pairs(light.types) do
		local id = "light " .. typ
		assert(self.lightShaders[typ], "Light of type '" .. typ .. "' does not exist!")
		insertHeader(lcInit, id, self.lightShaders[typ]:constructDefinesGlobal(self))
		
		if basic then
			insertHeader(lc, id, self.lightShaders[typ]:constructPixelBasicGlobal(self))
		else
			insertHeader(lc, id, self.lightShaders[typ]:constructPixelGlobal(self))
		end
	end
	
	--defines and code
	local IDs = { }
	for	_, light in ipairs(light.lights) do
		
		IDs[light.light_typ] = (IDs[light.light_typ] or -1) + 1
		local id = light.light_typ .. "_" .. IDs[light.light_typ]
		
		insertHeader(lcInit, id, self.lightShaders[light.light_typ]:constructDefines(id))
		
		local px
		if basic then
			px = self.lightShaders[light.light_typ]:constructPixelBasic(id)
		else
			px = self.lightShaders[light.light_typ]:constructPixel(id)
		end
		if px then
			insertHeader(lc, id, "{\n" .. px .. "\n}")
		end
	end
	
	return table.concat(lcInit, "\n"), table.concat(lc, "\n")
end