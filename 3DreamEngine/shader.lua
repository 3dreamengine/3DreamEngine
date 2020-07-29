--[[
#part of the 3DreamEngine by Luke100000
shader.lua - loads the shaders
--]]

local lib = _3DreamEngine

local testForOpenES = false

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
			print()
			
			--dump shader in case of error
			if not ok then
				love.filesystem.write("shader_errored.glsl", pixel)
			end
		end
		return love.graphics.newShader_old(pixel, vertex)
	end
end

--shader library
lib.shaderLibrary = {
	base = { },
}

--shader register
function lib:registerBaseShader(path)
	local name = (path:match("^.+/(.+)$") or path):sub(1, -5)
	self.shaderLibrary.base[name] = require(path:sub(1, -5))
end

--register inbuild shaders
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/baseShaders")) do
	lib:registerBaseShader(lib.root .. "/baseShaders/" .. s)
end

--load code snippsets
local codes = {
	functions = { },
	shading = { },
	shader = { },
	shadow = { },
	vertex = { },
}
for i,v in pairs(codes) do
	for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/shaders/" .. i)) do
		v[s:sub(1, #s-5)] = love.filesystem.read(lib.root .. "/shaders/" .. i .. "/" .. s)
	end
end

lib.shaders = { }

--blur
lib.shaders.blur = love.graphics.newShader(lib.root .. "/shaders/blur.glsl")
lib.shaders.blur_cube = love.graphics.newShader(lib.root .. "/shaders/blur_cube.glsl")
lib.shaders.blur_shadow = love.graphics.newShader(lib.root .. "/shaders/blur_shadow.glsl")

--applies bloom at a given strength
lib.shaders.bloom = love.graphics.newShader(lib.root .. "/shaders/bloom.glsl")

--the sky sphere shader
lib.shaders.sky = love.graphics.newShader(lib.root .. "/shaders/sky.glsl")
lib.shaders.sky_hdri = love.graphics.newShader(lib.root .. "/shaders/sky_hdri.glsl")
lib.shaders.sky_WilkieHosek = love.graphics.newShader(lib.root .. "/shaders/sky_WilkieHosek.glsl")

--the shadow shader
lib.shaders.shadow = love.graphics.newShader(lib.root .. "/shaders/shadow.glsl")

--particle shader, draw textures at a given depth
lib.shaders.particle = love.graphics.newShader(lib.root .. "/shaders/particle.glsl")
lib.shaders.billboard = love.graphics.newShader(lib.root .. "/shaders/billboard.glsl")
lib.shaders.billboard_moon = love.graphics.newShader(lib.root .. "/shaders/billboard_moon.glsl")
lib.shaders.billboard_sun = love.graphics.newShader(lib.root .. "/shaders/billboard_sun.glsl")

--autoExposure vignette
lib.shaders.autoExposure = love.graphics.newShader(lib.root .. "/shaders/autoExposure.glsl")

--clouds
lib.shaders.clouds = love.graphics.newShader(lib.root .. "/shaders/clouds.glsl")

--rain
lib.shaders.rain = love.graphics.newShader(lib.root .. "/shaders/rain.glsl")
lib.shaders.rain_splashes = love.graphics.newShader(lib.root .. "/shaders/rain_splashes.glsl")

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
end

--the final canvas combines all resources into one result
local sh_final = love.filesystem.read(lib.root .. "/shaders/final.glsl")
function lib.getFinalShader(self, canvases, noSky)
	local parts = { }
	parts[#parts+1] = canvases.postEffects_enabled and self.autoExposure_enabled and "#define AUTOEXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.exposure > 0 and not self.autoExposure_enabled and "#define EXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.bloom_enabled and "#define BLOOM_ENABLED" or nil
	parts[#parts+1] = self.AO_enabled and "#define AO_ENABLED" or nil
	parts[#parts+1] = canvases.alphaBlendMode == "average" and "#define AVERAGE_ALPHA" or nil
	parts[#parts+1] = (self.fxaa and canvases.msaa == 0) and "#define FXAA_ENABLED" or nil
	parts[#parts+1] = self.SSR_enabled and "#define SSR_ENABLED" or nil
	parts[#parts+1] = self.sky_enabled and not noSky and "#define SKY_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and "#define POSTEFFECTS_ENABLED" or nil
	parts[#parts+1] = self.lighting_engine == "PBR" and "#define SHADERTYPE_PBR" or nil
	parts[#parts+1] = self.refraction_enabled and "#define REFRACTION_ENABLED" or nil
	parts[#parts+1] = self.fog_enabled and "#define FOG_ENABLED" or nil
	local ID = table.concat(parts, "\n")
	if not self.shaders.final[ID] then
		self.shaders.final[ID] = love.graphics.newShader("#pragma language glsl3\n" .. ID .. "\n" .. sh_final)
	end
	return self.shaders.final[ID]
end

--returns a fitting shader construction instruction for the current material and meshtype
function lib:getShaderInfo(mat, shaderType, reflection)
	local vertexShader = mat.shader or "default"
	
	--group shader and vertex shader
	if not self.mainShaders[shaderType] then
		self.mainShaders[shaderType] = { }
	end
	if not self.mainShaders[shaderType][vertexShader] then
		self.mainShaders[shaderType][vertexShader] = { }
	end
	
	--add new type of shader to list
	local shs = self.mainShaders[shaderType][vertexShader]
	
	--get a unique ID
	local ID = self.shaderLibrary.base[shaderType]:getShaderInfoID(self, mat, shaderType, reflection)
	
	--create new shader info object if necessary
	if not shs[ID] then
		shs[ID] = self.shaderLibrary.base[shaderType]:getShaderInfo(self, mat, shaderType, reflection)
		shs[ID].shaderType = shaderType
		shs[ID].vertexShader = vertexShader
		shs[ID].shaders = { }
	end
	
	return shs[ID]
end

--construct a shader
local baseShader = love.filesystem.read(lib.root .. "/shaders/base.glsl")
function lib:getShader(info, lightRequirements)
	--based on scene light we need a specific shader
	local ID = lightRequirements and ((lightRequirements.simple > 0 and 2 or 1) + lightRequirements.sun_shadow * 256^2 + lightRequirements.point_shadow * 256) or 0
	
	if not info.shaders[ID] then
		--construct shader
		local code = baseShader
		
		--setting specific defines
		code = code:gsub("#import globalDefines", [[
			#define REFRACTION_ENABLED
		]])
		
		--the shader might need additional code
		code = code:gsub("#import shaderDefines", self.shaderLibrary.base[info.shaderType]:constructDefines(self, info))
		code = code:gsub("#import mainPixelPre", self.shaderLibrary.base[info.shaderType]:constructPixelPre(self, info))
		code = code:gsub("#import mainPixel", self.shaderLibrary.base[info.shaderType]:constructPixel(self, info))
		code = code:gsub("#import mainVertex", self.shaderLibrary.base[info.shaderType]:constructVertex(self, info))
		
		--import code snipsets
		code = code:gsub("#import animations", codes.vertex[info.vertexShader])
		code = code:gsub("#import reflections", info.reflection and codes.functions.reflections or codes.functions.ambientOnly)
		
		--construct forward lighting system
		if lightRequirements then
			local lcInit = (lightRequirements.point_shadow > 0 and codes.shadow.point or "") .. "\n" .. (lightRequirements.sun_shadow > 0 and codes.shadow.sun or "") .. "\n"
			local lc = ""
			local count = 0
			
			local getLightData = self.shaderLibrary.base[info.shaderType]:getLightSignature(self)
			
			--light positions, colors and meters (not always used)
			lcInit = lcInit .. [[
				extern vec3 lightPos[]] .. self.max_lights .. [[];
				extern vec3 lightColor[]] .. self.max_lights .. [[];
				extern float lightMeter[]] .. self.max_lights .. [[];
			]] .. "\n"
			
			--sun with tripple cascade shadow
			for i = 1, lightRequirements.sun_shadow do
				lcInit = lcInit .. [[
					extern highp mat4 transformProjShadow_]] .. count .. [[_1;
					extern highp mat4 transformProjShadow_]] .. count .. [[_2;
					extern highp mat4 transformProjShadow_]] .. count .. [[_3;
					extern sampler2DShadow tex_shadow_1_]] .. count .. [[;
					extern sampler2DShadow tex_shadow_2_]] .. count .. [[;
					extern sampler2DShadow tex_shadow_3_]] .. count .. [[;
				]] .. "\n"
				
				lc = lc .. [[{
					float shadow = sampleShadowSun(vertexPos, transformProjShadow_]] .. count .. [[_1, transformProjShadow_]] .. count .. [[_2, transformProjShadow_]] .. count .. [[_3, tex_shadow_1_]] .. count .. [[, tex_shadow_2_]] .. count .. [[, tex_shadow_3_]] .. count .. [[);
					if (shadow > 0.0) {
						vec3 lightVec = normalize(lightPos[]] .. count .. [[]);
						col += getLight(lightColor[]] .. count .. [[], viewVec, lightVec, normal, ]] .. getLightData .. [[) * albedo.a;
					}
				}]] .. "\n"
				
				count = count + 1
			end
			
			--point with cubemap shadow
			for i = 1, lightRequirements.point_shadow do
				lcInit = lcInit .. [[
					extern float size_]] .. count .. [[;
					extern samplerCube tex_shadow_]] .. count .. [[;
				]] .. "\n"
				
				lc = lc .. [[{
					highp vec3 lightVec = lightPos[]] .. count .. [[] - vertexPos;
					float shadow = sampleShadowPoint(lightVec, size_]] .. count .. [[, tex_shadow_]] .. count .. [[);
					if (shadow > 0.0) {
						float distance = length(lightVec) * lightMeter[]] .. count .. [[];
						float power = 1.0 / (0.1 + distance * distance);
						col += getLight(lightColor[]] .. count .. [[] * shadow * power, viewVec, normalize(lightVec), normal, ]] .. getLightData .. [[) * albedo.a;
					}
				}]] .. "\n"
				
				count = count + 1
			end
			
			--simple point or sun lights
			if lightRequirements.simple > 0 then
				lc = lc .. [[{
					for (int i = ]].. count .. [[; i < lightCount; i++) {
						if (lightMeter[i] > 0.0) {
							vec3 lightVecRaw = lightPos[i] - vertexPos;
							vec3 lightVec = normalize(lightVecRaw);
							float distance = length(lightVecRaw) * lightMeter[i];
							float power = 1.0 / (0.1 + distance * distance);
							col += getLight(lightColor[i] * power, viewVec, lightVec, normal, ]] .. getLightData .. [[) * albedo.a;
						} else {
							vec3 lightVec = normalize(lightPos[i]);
							col += getLight(lightColor[i], viewVec, lightVec, normal, ]] .. getLightData .. [[) * albedo.a;
						}
					}
				}]] .. "\n"
			end
			
			code = code:gsub("#import lightingSystemInit", lcInit)
			code = code:gsub("#import lightingSystem", lc)
			code = code:gsub("#import lightFunction", codes.shading[self.lighting_engine])
		end
		
		--remove unused imports and remove tabs
		code = code:gsub("#import", "//#import")
		code = code:gsub("	", "")
		
		--compile
		local ok, shader = pcall(love.graphics.newShader, code)
		if ok then
			info.shaders[ID] = shader
		end
	end
	
	return info.shaders[ID]
end