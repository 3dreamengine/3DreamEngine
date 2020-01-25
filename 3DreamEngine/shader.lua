--[[
#part of the 3DreamEngine by Luke100000
shader.lua - loads the shaders
--]]

local lib = _3DreamEngine

--in case the engine is loaded in a thread as a loader only
if not love.graphics then
	return
end

--enables auto shader validator
if _DEBUGMODE then
	love.graphics.newShader_old = love.graphics.newShader
	function love.graphics.newShader(pixel, vertex)
		local status, err = love.graphics.validateShader(true, pixel, vertex)
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
		end
		return love.graphics.newShader_old(pixel, vertex)
	end
end

lib.shaders = { }

--blur, 7-Kernel, only red channel
lib.shaders.blur = love.graphics.newShader(lib.root .. "/shaders/blur.glsl")

--combines AO, applies distance fog
lib.shaders.post = love.graphics.newShader(lib.root .. "/shaders/post.glsl")

--applies bloom at a given strength
lib.shaders.bloom = love.graphics.newShader(lib.root .. "/shaders/bloom.glsl")

--the cloud shader
lib.shaders.cloud = love.graphics.newShader(lib.root .. "/shaders/cloud.glsl")

--the sky and night sphere shader
lib.shaders.skyNight = love.graphics.newShader(lib.root .. "/shaders/skyNight.glsl")

--the sky sphere shader
lib.shaders.sky = love.graphics.newShader(lib.root .. "/shaders/sky.glsl")

--the shadow shader
lib.shaders.shadow = love.graphics.newShader(lib.root .. "/shaders/shadow.glsl")

--the shadow shader
lib.shaders.SSR = love.graphics.newShader(lib.root .. "/shaders/SSR.glsl")

--the shadow shader
lib.shaders.SSR_post = love.graphics.newShader(lib.root .. "/shaders/SSR_post.glsl")

function lib.loadShader(self)
	--the particle shader, draw textures at a given depth, also applies depth
	self.shaders.particle = love.graphics.newShader(
		(self.bloom_enabled and "#define BLOOM_ENABLED" or "") .. "\n" .. 
		love.filesystem.read(self.root .. "/shaders/particle.glsl")
	)

	--the ambient occlusion shader
	self.shaders.AO = love.graphics.newShader(
		"const int sampleCount = " .. self.AO_quality .. ";\n" ..
		love.filesystem.read(self.root .. "/shaders/AO.glsl")
	)
	
	--pass samples to the shader
	local f = { }
	for i = 1, self.AO_quality do
		local r = i / self.AO_quality * math.pi * 2
		local d = (0.5 + i % 4) / 4
		local range = 24
		f[#f+1] = {math.cos(r)*d*range / love.graphics.getWidth(), math.sin(r)*d*range / love.graphics.getHeight(), (1-d)^2 / self.AO_quality}
	end
	self.shaders.AO:send("samples", unpack(f))
end

--store all main shaders
lib.mainShaders = { }
function lib.clearShaders(self)
	self.mainShaders = { }
end

--returns a fitting shader for the current material and meshtype
function lib.getShaderInfo(self, mat, meshType, obj)
	local dat = {
		meshType = meshType,
		variant = mat.shader or "default",
		
		combined = false,
		arrayImage = meshType == "textured_array",
		
		reflections_day = (obj and obj.reflections_day or mat.reflections_day or (meshType ~= "flat" or mat.reflections) and self.sky) and not self.SSR_enabled,
		reflections_night = (obj and obj.reflections_night or mat.reflections_night or (meshType ~= "flat" or mat.reflections) and self.night) and not self.SSR_enabled,
		
		tex_albedo = mat.tex_albedo ~= nil,
		tex_normal = mat.tex_normal ~= nil,
		tex_roughness = mat.tex_roughness ~= nil,
		tex_metallic = mat.tex_metallic ~= nil,
		tex_ao = mat.tex_ao ~= nil,
		tex_emission = mat.tex_emission ~= nil,
	}
	
	local ID = (dat.combined and 0 or 1) + (dat.arrayImage and 0 or 2) + (dat.reflections_day and 0 or 4) + (dat.reflections_night and 0 or 8)
		+ (dat.tex_albedo and 0 or 16) + (dat.tex_normal and 0 or 32) + (dat.tex_roughness and 0 or 64) + (dat.tex_metallic and 0 or 128) + (dat.tex_ao and 0 or 256) + (dat.tex_emission and 0 or 512)
	local str = table.concat({dat.meshType, dat.variant, ID}, "_")
	
	if not self.mainShaders[str] then
		self.mainShaders[str] = dat
	end
	
	return self.mainShaders[str]
end

--returns a full shader based on the shaderInfo and lighting count
_RENDERER = love.graphics.getRendererInfo()
function lib.getShader(self, info)
	if not info.shader then
		--construct shader
		local code = "#pragma language glsl3\n" ..
			((self.AO_enabled or self.SSR_enabled) and "#define AO_ENABLED\n" or "") ..
			(self.shadow_enabled and "#define SHADOWS_ENABLED\n" or "") ..
			(self.bloom_enabled and "#define BLOOM_ENABLED\n" or "") ..
			(self.SSR_enabled and "#define SSR_ENABLED\n" or "") ..
			
			"const int DEPTH_CANVAS_ID = " .. (1) .. ";\n" ..
			"const int BLOOM_CANVAS_ID = " .. ((self.AO_enabled or self.SSR_enabled) and 2 or 1) .. ";\n" ..
			"const int NORMAL_CANVAS_ID = " .. (self.bloom_enabled and 3 or 2) .. ";\n" ..
			"const int REFLECTINESS_CANVAS_ID = " .. (self.bloom_enabled and 4 or 3) .. ";\n"
			
		if info.meshType == "flat" then
			code = code ..
				(info.reflections_day and "#define REFLECTIONS_DAY\n" or "") ..
				(info.reflections_night and "#define REFLECTIONS_NIGHT\n" or "") ..
				
				(info.variant == "wind" and "#define VARIANT_WIND\n" or "") ..
				
				(self.max_lights > 0 and "#define LIGHTING\n" or "") ..
				(self.max_lights > 0 and "const int MAX_LIGHTS = " .. self.max_lights .. ";\n" or "") ..
				"\n" .. 
				love.filesystem.read(self.root .. "/shaders/shader_flat.glsl")
		else
			code = code ..
				(info.arrayImage and "#define ARRAY_IMAGE\n" or "") ..
				(info.combined and "#define TEX_COMBINED\n" or "") ..
				
				(info.reflections_day and "#define REFLECTIONS_DAY\n" or "") ..
				(info.reflections_night and "#define REFLECTIONS_NIGHT\n" or "") ..
				
				(info.variant == "wind" and "#define VARIANT_WIND\n" or "") ..
				
				(info.tex_albedo and "#define TEX_ALBEDO\n" or "") ..
				(info.tex_normal and "#define TEX_NORMAL\n" or "") ..
				(info.tex_roughness and "#define TEX_ROUGHNESS\n" or "") ..
				(info.tex_metallic and "#define TEX_METALLIC\n" or "") ..
				(info.tex_ao and "#define TEX_AO\n" or "") ..
				(info.tex_emission and "#define TEX_EMISSION\n" or "") ..
				
				(self.max_lights > 0 and "#define LIGHTING\n" or "") ..
				(self.max_lights > 0 and "const int MAX_LIGHTS = " .. self.max_lights .. ";\n" or "") ..
				"\n" .. 
				love.filesystem.read(self.root .. "/shaders/shader.glsl")
		end
		
		local ok, shader = pcall(love.graphics.newShader, code:gsub("	", ""))
		if ok then
			info.shader = shader
		else
			love.filesystem.write("shader.glsl", code)
			error(shader)
		end
	end
	
	info.shader = info.shader
	
	return info
end