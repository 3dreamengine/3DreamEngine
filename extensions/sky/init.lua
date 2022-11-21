--[[
#weather extension
provides some basic features to simulate dynamic weather
--]]

local dream = _3DreamEngine

local sky = { }

local root = (...)

--get color of sun based on sunrise sky texture
sky.sunlight = require(root .. "/sunlight")
sky.skylight = require(root .. "/skylight")

sky.textures = {
	sky = love.graphics.newImage(root .. "/res/sky.png"),
	moon = love.graphics.newImage(root .. "/res/moon.png"),
	moon_normal = love.graphics.newImage(root .. "/res/moon_normal.png"),
	sun = love.graphics.newImage(root .. "/res/sun.png"),
	rainbow = love.graphics.newImage(root .. "/res/rainbow.png"),
	stars = love.graphics.newCubeImage(root .. "/res/stars.png"),
}

sky.shaders = {
	clouds = love.graphics.newShader(root .. "/shaders/clouds.glsl"),
	moon = love.graphics.newShader(root .. "/shaders/moon.glsl"),
	sky = love.graphics.newShader(root .. "/shaders/sky.glsl"),
	sun = love.graphics.newShader(root .. "/shaders/sun.glsl"),
}

--sets clouds and settings
function sky:setClouds(clouds)
	self.clouds = clouds or { }
end
function sky:getClouds()
	return self.clouds
end

function sky:setSkyColor(c)
	if type(c) == "number" then
		local color = c * 0.75
		local darkBlue = vec3(30, 40, 60):normalize()
		local lightBlue = vec3(0.6, 0.8, 1.0) * 1.5
		self.skyColor = darkBlue * 0.3 * color + lightBlue * (1.0 - color)
	else
		self.skyColor = c
	end
end
function sky:getSkyColor()
	return self.skyColor
end

function sky:setSunOffset(offset, rotation)
	self.sun_offset = offset
	self.sun_rotation = rotation
end
function sky:getSunOffset()
	return self.sun_offset, self.sun_rotation
end


--helper function to set sun and time
sky.time = 0
sky.day = 0
function sky:setDaytime(sun, time)
	local c = #self.sunlight
	
	--time, 0.0 is sunrise, 0.5 is sunset
	self.time = time % 1.0
	self.day = time % c
	
	--position
	sun.direction = mat4.getRotateY(self.sun_rotation) * mat4.getRotateZ(self.sun_offset) * vec3(
			0,
			math.sin(self.time * math.pi * 2),
			-math.cos(self.time * math.pi * 2)
	):normalize()
	
	--current sample
	local p = self.time * c
	
	--direct sun color
	sun.color = (
			self.sunlight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
					self.sunlight[math.max(1, math.min(c, math.ceil(p + 1)))] * (p % 1)
	)
	
	--sky color
	--todo rename and make more accessible
	_3DreamEngine.sun_ambient = (
			self.skylight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
					self.skylight[math.max(1, math.min(c, math.ceil(p + 1)))] * (p % 1)
	)
end
function sky:getDaytime()
	return self.time, self.day
end

--rainbow
function sky:setRainbow(strength, size, thickness)
	self.rainbow_strength = strength
	self.rainbow_size = size or self.rainbow_size or math.cos(42 / 180 * math.pi)
	self.rainbow_thickness = thickness or self.rainbow_thickness or 0.2
end
function sky:getRainbow()
	return self.rainbow_strength, self.rainbow_size, self.rainbow_thickness
end

function sky:setRainbowDir(v)
	self.rainbow_dir = v:normalize()
end
function sky:getRainbowDir()
	return self.rainbow_dir
end

function sky.render(transformProj, camTransform)
	local self = sky
	
	--look for suns
	local sun
	for _, l in ipairs(dream.lighting) do
		if l.typ == "sun" then
			sun = l
		end
	end
	
	--simple wilkie hosek sky
	love.graphics.setShader(self.shaders.sky)
	self.shaders.sky:send("transformProj", transformProj)
	self.shaders.sky:send("time", self.time)
	
	self.shaders.sky:send("stars", self.textures.stars)
	self.shaders.sky:send("starsStrength", -math.sin(self.time * math.pi * 2))
	self.shaders.sky:send("starsTransform", mat4.getRotateX(love.timer.getTime() * 0.0025):subm())
	
	self.shaders.sky:send("rainbow", self.textures.rainbow)
	self.shaders.sky:send("rainbowStrength", self.rainbow_strength * (sun and sun.brightness or 0))
	self.shaders.sky:send("rainbowSize", self.rainbow_size)
	self.shaders.sky:send("rainbowThickness", 1 / self.rainbow_thickness)
	self.shaders.sky:send("rainbowDir", self.rainbow_dir)
	
	love.graphics.setColor(self.skyColor)
	local mesh = dream.cubeObject.meshes.Cube:getMesh()
	mesh:setTexture(self.textures.sky)
	love.graphics.draw(mesh)
	
	local right = vec3(camTransform[1], camTransform[2], camTransform[3]):normalize()
	local up = vec3(camTransform[5], camTransform[6], camTransform[7])
	
	--moon
	local size = 0.25
	
	love.graphics.setColor(1.0, 1.0, 1.0)
	love.graphics.setBlendMode("alpha")
	
	love.graphics.setShader(self.shaders.moon)
	
	self.shaders.moon:send("transformProj", transformProj)
	self.shaders.moon:send("up", up * size)
	self.shaders.moon:send("right", right * size)
	self.shaders.moon:send("InstanceCenter", sun and -sun.direction or vec3(1, 1, 1))
	self.shaders.moon:send("sun", { math.cos(self.day / 30 * math.pi * 2), math.sin(self.day / 30 * math.pi * 2), 0 })
	self.shaders.moon:send("normalTex", self.textures.moon_normal)
	
	dream.planeObject.meshes.Plane:getMesh():setTexture(self.textures.moon)
	love.graphics.draw(dream.planeObject.meshes.Plane:getMesh())
	
	--suns
	for _, l in ipairs(dream.lighting) do
		if l.typ == "sun" then
			local size = 1 / (2.0 + math.sin(self.time * math.pi * 2.0))
			
			love.graphics.setColor(l.color * l.brightness)
			love.graphics.setBlendMode("add")
			
			love.graphics.setShader(self.shaders.sun)
			
			self.shaders.sun:send("transformProj", transformProj)
			self.shaders.sun:send("up", up * size)
			self.shaders.sun:send("right", right * size)
			self.shaders.sun:send("InstanceCenter", l.direction)
			
			dream.planeObject.meshes.Plane:getMesh():setTexture(self.textures.sun)
			
			love.graphics.draw(dream.planeObject.meshes.Plane:getMesh())
			
			love.graphics.setBlendMode("alpha")
		end
	end
	
	--clouds
	if #self.clouds > 0 then
		love.graphics.setShader(self.shaders.clouds)
		self.shaders.clouds:send("transformProj", transformProj)
		
		self.shaders.clouds:send("sunColor", sun and (sun.color * sun.brightness) or vec3(1.0, 1.0, 1.0))
		
		self.shaders.clouds:send("sunVec", sun and sun.direction or vec3(0, 1, 0))
		
		for _, cloud in ipairs(self.clouds) do
			self.shaders.clouds:send("clouds", cloud.texture)
			self.shaders.clouds:send("cloudsTransform", mat4.getRotateY((cloud.roration or 0) + love.timer.getTime() * (cloud.rotationDelta)):subm())
			
			love.graphics.setColor(cloud.color or { 1, 1, 1 })
			local mesh = dream.cubeObject.meshes.Cube.mesh
			love.graphics.draw(mesh)
		end
	end
end

sky:setSkyColor(0.0)
sky:setRainbow(0.0)
sky:setRainbowDir(vec3(1.0, -0.25, 1.0))
sky:setSunOffset(0, 0)

--clouds
sky:setClouds({
	{
		texture = love.graphics.newCubeImage(root .. "/res/clouds_high.png"),
		rotation = 0,
		rotationDelta = -0.001,
		color = { 1.0, 1.0, 1.0 },
	},
	{
		texture = love.graphics.newCubeImage(root .. "/res/clouds_low.png"),
		rotation = 0,
		rotationDelta = 0.002,
		color = { 1.0, 1.0, 1.0 },
	},
})

return sky