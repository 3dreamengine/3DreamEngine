--[[
#weather extension
provides some basic features to simulate dynamic weather
--]]

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

--helper function to set 
function sky:setDaytime(sun, time, dream)
	local c = #self.sunlight
	
	--time, 0.0 is sunrise, 0.5 is sunset
	self.sky_time = time % 1.0
	self.sky_day = time % c
	
	--position
	sun.direction = mat4:getRotateY(self.sun_rotation) * mat4:getRotateZ(self.sun_offset) * vec3(
		0,
		math.sin(self.sky_time * math.pi * 2),
		-math.cos(self.sky_time * math.pi * 2)
	):normalize()
	
	--current sample
	local p = self.sky_time * c
	
	--direct sun color
	sun.color = (
		self.sunlight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.sunlight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
	
	--sky color
	--todo rename and make more accessable
	dream.sun_ambient = (
		self.skylight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.skylight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
end
function sky:getDaytime()
	return self.sky_time, self.sky_day
end

function sky:setWeather(rain)
	--make this more a demo function
	self.weather_rain = rain
	
	--mist level
	self.weather_mist = 1.0
	
	--set fog
	--self:setFog(self.weather_mist * 0.005, self.sky_color, 1.0)
	
	--set rainbow
	local strength = math.max(0.0, self.weather_mist * (1.0 - self.weather_rain * 2.0))
	self:setRainbow(strength)
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
	return self.rainbow_dir:unpack()
end

function sky.render(dream, transformProj, camTransform, transformScale)
	local self = sky
	
	--look for suns
	local sun
	for _,l in ipairs(dream.lighting) do
		if l.typ == "sun" then
			sun = l
		end
	end
	
	--simple wilkie hosek sky
	love.graphics.setShader(self.shaders.sky)
	self.shaders.sky:send("transformProj", transformProj)
	self.shaders.sky:send("time", self.sky_time)
	
	self.shaders.sky:send("stars", self.textures.stars)
	self.shaders.sky:send("starsStrength", -math.sin(self.sky_time * math.pi * 2))
	self.shaders.sky:send("starsTransform", mat4:getRotateX(love.timer.getTime() * 0.0025):subm())
	
	self.shaders.sky:send("rainbow", self.textures.rainbow)
	self.shaders.sky:send("rainbowStrength", self.rainbow_strength * (sun and sun.brightness or 0))
	self.shaders.sky:send("rainbowSize", self.rainbow_size)
	self.shaders.sky:send("rainbowThickness", 1 / self.rainbow_thickness)
	self.shaders.sky:send("rainbowDir", {self.rainbow_dir:unpack()})
	
	local color = self.weather_rain * 0.75
	local darkBlue = vec3(30, 40, 60):normalize()
	self.sky_color = darkBlue * 0.2 * color + vec3(0.6, 0.8, 1.0) * (1.0 - color)
	love.graphics.setColor((self.sky_color or vec3(0, 0, 0)):unpack())
	local mesh = dream.object_cube.meshes.Cube.mesh
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
	self.shaders.moon:send("up", {(up * size):unpack()})
	self.shaders.moon:send("right", {(right * size):unpack()})
	self.shaders.moon:send("InstanceCenter", {(sun and -sun.direction or vec3(1, 1, 1)):unpack()})
	self.shaders.moon:send("sun", {math.cos(self.sky_day / 30 * math.pi * 2), math.sin(self.sky_day / 30 * math.pi * 2), 0})
	self.shaders.moon:send("normalTex", self.textures.moon_normal)
	
	dream.object_plane.meshes.Plane.mesh:setTexture(self.textures.moon)
	
	--suns
	for _,l in ipairs(dream.lighting) do
		local size = 1 / (2.0 + math.sin(self.sky_time * math.pi * 2.0))
		
		love.graphics.setColor(l.color * l.brightness)
		love.graphics.setBlendMode("add")
		
		love.graphics.setShader(self.shaders.sun)
		
		self.shaders.sun:send("transformProj", transformProj)
		self.shaders.sun:send("up", {(up * size):unpack()})
		self.shaders.sun:send("right", {(right * size):unpack()})
		self.shaders.sun:send("InstanceCenter", {(l.direction):unpack()})
		
		dream.object_plane.meshes.Plane.mesh:setTexture(self.textures.sun)
		
		love.graphics.draw(dream.object_plane.meshes.Plane.mesh)
		
		love.graphics.setBlendMode("alpha")
	end
	
	--clouds
	if #self.clouds > 0 then
		love.graphics.setShader(self.shaders.clouds)
		self.shaders.clouds:send("transformProj", transformProj)
		
		self.shaders.clouds:send("sunColor", {(sun and (sun.color * sun.brightness * 0.25) or vec3(1.0, 1.0, 1.0)):unpack()})
		
		self.shaders.clouds:send("sunVec", sun and sun.direction or vec3(0, 1, 0))
		
		for _,cloud in ipairs(self.clouds) do
			self.shaders.clouds:send("clouds", cloud.texture)
			self.shaders.clouds:send("cloudsTransform", mat4:getRotateY((cloud.roration or 0) + love.timer.getTime() * (cloud.rotationDelta)):subm())
			
			love.graphics.setColor(cloud.color or {1, 1, 1})
			local mesh = dream.object_cube.meshes.Cube.mesh
			love.graphics.draw(mesh)
		end
	end
end

sky:setWeather(0.5)
sky:setRainbow(0.0)
sky:setRainbowDir(vec3(1.0, -0.25, 1.0))

--clouds
sky:setClouds({
	{
		texture = love.graphics.newCubeImage(root .. "/res/clouds_high.png"),
		rotation = 0,
		rotationDelta = -0.001,
		color = {1.0, 1.0, 1.0},
	},
	{
		texture = love.graphics.newCubeImage(root .. "/res/clouds_low.png"),
		rotation = 0,
		rotationDelta = 0.002,
		color = {1.0, 1.0, 1.0},
	},
})

return sky