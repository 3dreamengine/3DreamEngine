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
		local status, err = love.graphics.validateShader(_RENDERER == "OpenGL ES", pixel, vertex)
		if not status then
			print()
			print("-----------------")
			print("SHADER ERROR")
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
	for _,flat in ipairs({true, false}) do
		self.mainShaders[flat] = { }
		for _,variant in ipairs({"default", "wind"}) do
			self.mainShaders[flat][variant] = { }
			for _,normal in ipairs({true, false}) do
				self.mainShaders[flat][variant][normal] = { }
				for _,specular in ipairs({true, false}) do
					self.mainShaders[flat][variant][normal][specular] = { }
					for _,emission in ipairs({true, false}) do
						self.mainShaders[flat][variant][normal][specular][emission] = { }
						for _,arrayImage in ipairs({true, false}) do
							self.mainShaders[flat][variant][normal][specular][emission][arrayImage] = { }
							for _,reflections_day in ipairs({true, false}) do
								self.mainShaders[flat][variant][normal][specular][emission][arrayImage][reflections_day] = { }
								for _,reflections_night in ipairs({true, false}) do
									self.mainShaders[flat][variant][normal][specular][emission][arrayImage][reflections_day][reflections_night] = {
										flat = flat,
										variant = variant,
										normal = normal,
										specular = specular,
										emission = emission,
										arrayImage = arrayImage,
										reflections_day = reflections_day,
										reflections_night = reflections_night,
										shaders = { },
									}
								end
							end
						end
					end
				end
			end
		end
	end
end

--returns a fitting shader for the current material and meshtype
function lib.getShaderInfo(self, mat, meshType, obj)
	return self.mainShaders[meshType == "flat" and true or false][mat.shader or "default"][(meshType == "textured_normal" or meshType == "textured_array_normal") and mat.tex_normal and true or false][meshType ~= "flat" and mat.tex_specular and true or false][meshType ~= "flat" and mat.tex_emission and true or false][meshType == "textured_array_normal" or meshType == "textured_array"][(obj and obj.reflections_day or mat.reflections_day or mat.reflections and self.sky) and true or false][(obj and obj.reflections_night or mat.reflections_night or mat.reflections and self.night) and true or false]
end

--returns a full shader based on the shaderInfo and lighting count
_RENDERER = love.graphics.getRendererInfo()
function lib.getShader(self, info, lightings)
	if not info.shaders[lightings] then
		--construct shader
		local code = "#pragma language glsl3\n" ..
			(self.render == "OpenGL ES" and "#define OPENGL_ES\n" or "") ..
			(info.flat and "#define FLAT_SHADING\n" or "") ..
			(info.normal and "#define TEX_NORMAL\n" or "") ..
			(info.specular and "#define TEX_SPECULAR\n" or "") ..
			(info.emission and "#define TEX_EMISSION\n" or "") ..
			(self.AO_enabled and "#define AO_ENABLED\n" or "") ..
			(self.shadow_enabled and "#define SHADOWS_ENABLED\n" or "") ..
			(self.bloom_enabled and "#define BLOOM_ENABLED\n" or "") ..
			(info.arrayImage and "#define ARRAY_IMAGE\n" or "") ..
			(info.reflections_day and "#define REFLECTIONS_DAY\n" or "") ..
			(info.reflections_night and "#define REFLECTIONS_NIGHT\n" or "") ..
			(info.variant == "wind" and "#define VARIANT_WIND\n" or "") ..
			(lightings > 0 and "#define LIGHTING\n" or "") ..
			(lightings > 0 and "const int lightCount = " .. lightings .. ";\n" or "") ..
			"\n" .. 
			love.filesystem.read(self.root .. "/shaders/shader.glsl")
		
		local ok, shader = pcall(love.graphics.newShader, code)
		if ok then
			info.shaders[lightings] = shader
		else
			love.filesystem.write("shader.glsl", code)
			error(shader)
		end
	end
	
	info.shader = info.shaders[lightings]
	
	return info
end