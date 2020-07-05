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

--load code snippsets
local codes = {
	functions = { },
	shading = { },
	shader = { },
	shadow = { },
	vertex = { },
}
for i,v in pairs(codes) do
	for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root  .. "/shaders/" .. i)) do
		v[s:sub(1, #s-5)] = love.filesystem.read(lib.root .. "/shaders/" .. i .. "/" .. s)
	end
end

lib.shaders = { }

--blur
lib.shaders.blur = love.graphics.newShader(lib.root .. "/shaders/blur.glsl")
lib.shaders.blur_cube = love.graphics.newShader(lib.root .. "/shaders/blur_cube.glsl")
lib.shaders.blur_SSR = love.graphics.newShader(lib.root .. "/shaders/blur_SSR.glsl")
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

local sh_final = love.filesystem.read(lib.root .. "/shaders/final.glsl")
function lib.getFinalShader(self, canvases, noSky)
	local parts = { }
	parts[#parts+1] = canvases.postEffects_enabled and self.autoExposure_enabled and "#define AUTOEXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.exposure > 0 and not self.autoExposure_enabled and "#define EXPOSURE_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and self.bloom_enabled and "#define BLOOM_ENABLED" or nil
	parts[#parts+1] = self.AO_enabled and "#define AO_ENABLED" or nil
	parts[#parts+1] = canvases.average_alpha and "#define AVERAGE_ALPHA" or nil
	parts[#parts+1] = canvases.deferred_lighting and "#define DEFERRED_LIGHTING" or nil
	parts[#parts+1] = (self.fxaa and canvases.msaa == 0) and "#define FXAA_ENABLED" or nil
	parts[#parts+1] = self.SSR_enabled and "#define SSR_ENABLED" or nil
	parts[#parts+1] = self.sky_enabled and not noSky and "#define SKY_ENABLED" or nil
	parts[#parts+1] = canvases.postEffects_enabled and "#define POSTEFFECTS_ENABLED" or nil
	parts[#parts+1] = self.lighting_engine == "PBR" and "#define SHADERTYPE_PBR" or nil
	parts[#parts+1] = self.refraction_enabled and "#define REFRACTION_ENABLED" or nil
	parts[#parts+1] = self.fog_enabled and "#define FOG_ENABLED" or nil
	parts[#parts+1] = self.rain_enabled and "#define RAIN_ENABLED" or nil
	local ID = table.concat(parts, "\n")
	if not self.shaders.final[ID] then
		self.shaders.final[ID] = love.graphics.newShader("#pragma language glsl3\n" .. ID .. "\n" .. sh_final)
	end
	return self.shaders.final[ID]
end

local sh_SSR = love.filesystem.read(lib.root .. "/shaders/SSR.glsl")
function lib.getSSRShader(self, canvases)
	local parts = { }
	parts[#parts+1] = canvases.postEffects_enabled and self.bloom_enabled and "#define BLOOM_ENABLED" or nil
	parts[#parts+1] = self.AO_enabled and "#define AO_ENABLED" or nil
	parts[#parts+1] = self.sky_enabled and "#define SKY_ENABLED" or nil
	parts[#parts+1] = self.lighting_engine == "PBR" and "#define SHADERTYPE_PBR" or nil
	
	local ID = table.concat(parts, "\n")
	if not self.shaders.SSR[ID] then
		self.shaders.SSR[ID] = love.graphics.newShader("#pragma language glsl3\n" .. ID .. "\n" .. sh_SSR)
	end
	return self.shaders.SSR[ID]
end

function lib.loadShader(self)
	self.shaders.final = { }
	self.shaders.SSR = { }
	self.mainShaders = { }

	--the ambient occlusion shader, once for deferred rendering (depth stored in alpha channel of normal) and once for forward (in own single channel depth canvas)
	local code = (
		"#define SAMPLE_COUNT " .. self.AO_quality .. "\n" ..
		love.filesystem.read(self.root .. "/shaders/SSAO.glsl")
	):gsub("	", "")
	self.shaders.SSAO = love.graphics.newShader(code)
	
	if self.deferred_lighting then
		local code = (
			"#define SAMPLE_COUNT " .. self.AO_quality .. "\n" ..
			love.filesystem.read(self.root .. "/shaders/SSAO_def.glsl")
		):gsub("	", "")
		self.shaders.SSAO_def = love.graphics.newShader(code)
	end
	
	--pass samples to the shader
	local f = { }
	local range = 64.0
	for i = 1, self.AO_quality do
		local r = i / self.AO_quality * math.pi * 2
		local d = (0.5 + i % 4) / 4
		f[#f+1] = {math.cos(r)*d*range / love.graphics.getWidth(), math.sin(r)*d*range / love.graphics.getHeight(), (1-d)^2 / self.AO_quality}
	end
	self.shaders.SSAO:send("samples", unpack(f))
	if self.deferred_lighting then
		self.shaders.SSAO_def:send("samples", unpack(f))
	end
	
	--assemble and compile lighting shader
	if self.deferred_lighting then
		local code = "#define MAX_LIGHTS " .. self.max_lights .. "\n" ..
			love.filesystem.read(self.root .. "/shaders/light/light.glsl"):gsub("#import lightEngine", codes.shading[self.lighting_engine])
		self.shaders.light = love.graphics.newShader(code)
		
		local code = "#pragma language glsl3\n" ..
			love.filesystem.read(self.root .. "/shaders/light/shadow_sun.glsl"):gsub("#import lightEngine", codes.shading[self.lighting_engine]):gsub("#import shadowEngine", codes.shadow["sun"])
		self.shaders.shadow_sun = love.graphics.newShader(code)
		
		local code = "#pragma language glsl3\n" ..
			love.filesystem.read(self.root .. "/shaders/light/shadow_point_smooth.glsl"):gsub("#import lightEngine", codes.shading[self.lighting_engine])
		self.shaders.shadow_point_smooth = love.graphics.newShader(code)
		
		local code = "#pragma language glsl3\n" ..
			love.filesystem.read(self.root .. "/shaders/light/shadow_point.glsl"):gsub("#import lightEngine", codes.shading[self.lighting_engine]):gsub("#import shadowEngine", codes.shadow["point"])
		self.shaders.shadow_point = love.graphics.newShader(code)
		
		self.shaders.shadow_point_smooth_pre = love.graphics.newShader(self.root .. "/shaders/light/shadow_point_smooth_pre.glsl")
	end
end

--returns a fitting shader for the current material and meshtype
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
	if shaderType == "PBR" or shaderType == "Phong" then
		local ID = ((reflection or self.sky_enabled) and 0 or 1) + (mat.tex_normal and 0 or 2) + (mat.tex_emission and 0 or 4)
		shs[ID] = shs[ID] or {
			tex_normal = mat.tex_normal ~= nil,
			tex_emission = mat.tex_emission ~= nil,
			
			shaderType = shaderType,
			vertexShader = vertexShader,
			reflection = reflection or self.sky_enabled,
			SSR = not reflection and self.SSR_enabled,
			
			shaders = { },
		}
		return shs[ID]
	else
		local ID = (reflection or self.sky_enabled) and 0 or 1
		shs[ID] = shs[ID] or {
			shaderType = shaderType,
			vertexShader = vertexShader,
			reflection = reflection or self.sky_enabled,
			SSR = not reflection and self.SSR_enabled,
			
			shaders = { },
		}
		return shs[ID]
	end
end

--returns a shader based on the shaderInfo and given light circumstances (assembles from code fragments)
function lib:getShader(info, lightRequirements)
	local ID = lightRequirements and ((lightRequirements.simple > 0 and 2 or 1) + lightRequirements.sun_shadow * 256^2 + lightRequirements.point_shadow * 256) or 0
	
	if not info.shaders[ID] then
		--construct shader
		local code = { }
		
		code[#code+1] = "#pragma language glsl3"
		
		--additional features
		if info.tex_normal then
			code[#code+1] = "#define TEX_NORMAL"
		end
		if info.tex_emission then
			code[#code+1] = "#define TEX_EMISSION"
		end
		if self.rain_enabled then
			code[#code+1] = "#define RAIN_ENABLED"
		end
		if info.SSR then
			code[#code+1] = "#define SSR_ENABLED"
		end
		
		--actual shader
		code[#code+1] = love.filesystem.read(self.root .. "/shaders/shader/" .. info.shaderType .. ".glsl")
		
		--concat
		code = table.concat(code, "\n")
		
		--import code snipsets
		if info.vertexShader then
			code = code:gsub("#import animations", codes.vertex[info.vertexShader])
		end
		code = code:gsub("#import reflections", info.reflection and codes.functions.reflections or codes.functions.ambientOnly)
		
		--construct forward lighting system
		if lightRequirements then
			local lcInit = (lightRequirements.point_shadow > 0 and codes.shadow.point or "") .. "\n" .. (lightRequirements.sun_shadow > 0 and codes.shadow.sun or "") .. "\n"
			local lc = ""
			local count = 0
			
			local getLightData = info.shaderType == "PBR" and "albedo.rgb, roughness, metallic" or "albedo.rgb, specular, glossiness"
			
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
			code = code:gsub("#import lightEngine", codes.shading[self.lighting_engine])
		else
			code = code:gsub("#import lightingSystemInit", "")
			code = code:gsub("#import lightingSystem", "")
			code = code:gsub("#import lightEngine", "")
		end
		
		--compile
		local ok, shader = pcall(love.graphics.newShader, code:gsub("	", ""))
		if ok then
			info.shaders[ID] = shader
			
			--debug
			if _DEBUGMODE then
				--love.filesystem.write("shader_" .. (lightRequirements and "forward" or "def") .. ".glsl", code)
			end
		end
	end
	
	return info.shaders[ID]
end