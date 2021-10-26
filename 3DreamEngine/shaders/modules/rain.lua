local sh = { }

sh.type = "module"

sh.drops = { }
sh.rain = 0.0
sh.wetness = 0.0
sh.resolution = 512
sh.isRaining = true
sh.strength = 3
sh.adaptRain = 0.1
sh.wetness_increase = 0.02
sh.wetness_decrease = 0.01

local root = (string.match((...), "(.*[/\\])") or "") .. "rain/"

function sh:init(dream)
	sh.object_rain = dream:loadObject(root .. "rain", "Phong")
	
	--rain textures
	self.tex_rain = { }
	for i = 1, 5 do
		self.tex_rain[i] = love.graphics.newImage(root .. "rain_" .. i .. ".png")
		self.tex_rain[i]:setWrap("repeat")
	end
	
	--splash textures
	self.tex_splash = love.graphics.newImage(root .. "splash.png")
	self.tex_wetness = love.graphics.newImage(root .. "wetness.png")
	
	self.tex_wetness:setWrap("repeat")
	
	--normal canvas
	self.canvas_rain = love.graphics.newCanvas(self.resolution, self.resolution, {format = "rgba16f"})
	self.canvas_rain:setWrap("repeat")
	
	--clear normal canvas
	love.graphics.setCanvas(self.canvas_rain)
	love.graphics.clear(0.0, 0.0, 1.0)
	love.graphics.setCanvas()
	
	--rain
	self.shader_rain = love.graphics.newShader(root .. "rain.glsl")
	self.shader_splashes = love.graphics.newShader(root .. "splashes.glsl")
end

function sh:constructDefines(dream)
	return [[
		extern Image splashes;
		extern Image tex_wetness;
		extern float wetness;
	]]
end

function sh:constructPixel(dream, mat)
	return [[
		vec3 rainNormal = normalize(Texel(splashes, VertexPos.xz).xyz);
		
		float rainNoise = Texel(tex_wetness, VertexPos.xz * 0.17).r;
		float rain = clamp((normal.y * 1.1 - 0.1) * clamp(wetness * 1.5 - rainNoise + (1.0 - rainNormal.z) * 2.0, 0.0, 1.0), 0.0, 1.0);
	]]
end

function sh:constructPixelPost(dream)
	return [[
		#ifdef TEX_NORMAL
			vec3 reflectVecRain = reflect(viewVec, normalize(normal * 0.25 + TBN * rainNormal.xyz * rain));
			col = mix(col, reflection(reflectVecRain, 0.0), rain * 0.25);
		#else
			vec3 reflectVecRain = reflect(viewVec, normalize(normal + rainNormal.xzy * rain));
			col = mix(col, reflection(reflectVecRain, 0.0), rain * 0.25);
		#endif
	]]
end

function sh:constructVertex(dream)
	
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("splashes", sh.canvas_rain)
	shader:send("tex_wetness", sh.tex_wetness)
	shader:send("wetness", sh.wetness)
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)

end

function sh:render(dream, cam, canvases, scene)
	love.graphics.push("all")
	
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
	love.graphics.setDepthMode("less", false)
	
	local t = self.tex_rain[self.strength]
	local translate = vec3(math.floor(cam.pos.x), math.floor(cam.pos.y), math.floor(cam.pos.z))
	
	love.graphics.setShader(self.shader_rain)
	self.shader_rain:send("time", love.timer.getTime() * 3.0)
	self.shader_rain:send("transformProj", cam.transformProj)
	self.shader_rain:send("transform", mat4:getIdentity():translate(translate))
	self.shader_rain:send("rain", self.rain)
	
	self.object_rain.objects.Plane.mesh:setTexture(t)
	love.graphics.draw(self.object_rain.objects.Plane.mesh)
	
	love.graphics.pop()
end

function sh:jobCreator(dream)
	dream:addOperation(self.jobExecuter)
end

function sh.jobExecuter()
	local delta = love.timer.getDelta()
	
	local lastRender = sh.rain > 0
	if sh.isRaining then
		sh.rain = math.min(1.0, sh.rain + delta * sh.adaptRain)
		sh.wetness = math.min(1.0, sh.wetness + delta * sh.wetness_increase)
	else
		sh.rain = math.max(0.0, sh.rain - delta * sh.adaptRain)
		sh.wetness = math.max(0.0, sh.wetness - delta * sh.wetness_decrease * (0.5 + sh.wetness))
	end
	
	--add drops
	if math.random() < delta * 10 * sh.strength * sh.rain then
		sh.drops[#sh.drops+1] = {
			x = math.random(),
			y = math.random(),
			size = 0.5 + math.random(),
			time = -0.5,
		}
	end
	
	--update drops
	for i = #sh.drops, 1, -1 do
		local s = sh.drops[i]
		s.time = s.time + delta * 2.0
		if s.time > 2.0 then
			table.remove(sh.drops, i)
		end
	end
	
	--splash texture
	if sh.rain > 0 or lastRender then
		love.graphics.push("all")
		love.graphics.setCanvas(sh.canvas_rain)
		love.graphics.setBlendMode("add", "premultiplied")
		love.graphics.clear(0.0, 0.0, 1.0)
		if sh.rain > 0 then
			love.graphics.setShader(sh.shader_splashes)
			local w, h = sh.canvas_rain:getDimensions()
			for d,s in ipairs(sh.drops) do
				sh.shader_splashes:send("time", s.time)
				
				local wx = (s.x > 0.5 and (s.x - 1.0) or (s.x + 1.0))
				local wy = (s.y > 0.5 and (s.y - 1.0) or (s.y + 1.0))
				
				love.graphics.draw(sh.tex_splash, s.x * w, s.y * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
				love.graphics.draw(sh.tex_splash, s.x * w, wy * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
				love.graphics.draw(sh.tex_splash, wx * w, s.y * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
				love.graphics.draw(sh.tex_splash, wx * w, wy * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
			end
		end
		love.graphics.pop()
	end
end

return sh