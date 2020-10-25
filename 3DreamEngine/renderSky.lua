--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

function lib:renderSky(transformProj, camTransform)
	love.graphics.push("all")
	if not self.sky_texture then
		love.graphics.clear()
	elseif type(self.sky_texture) == "userdata" and self.sky_texture:getTextureType() == "cube" then
		--cubemap
		love.graphics.setShader(self.shaders.sky_cube)
		self.shaders.sky_cube:send("transformProj", transformProj)
		self.shaders.sky_cube:send("sky", self.sky_texture)
		love.graphics.draw(self.object_cube.objects.Cube.mesh)
	elseif type(self.sky_texture) == "userdata" and self.sky_texture:getTextureType() == "2d" then
		--HDRI
		love.graphics.setShader(self.shaders.sky_hdri)
		self.shaders.sky_hdri:send("exposure", self.sky_hdri_exposure)
		self.shaders.sky_hdri:send("transformProj", transformProj)
		self.object_sky.objects.Sphere.mesh:setTexture(self.sky_texture)
		love.graphics.draw(self.object_sky.objects.Sphere.mesh)
	else
		--sky dome
		lib.skyInUse = true
		lib.initTextures:sky()
		
		--simple wilkie hosek sky
		love.graphics.setShader(self.shaders.sky)
		self.shaders.sky:send("transformProj", transformProj)
		self.shaders.sky:send("time", self.sky_time)
		self.shaders.sky:send("sunColor", self.sun_color)
		self.shaders.sky:send("cloudsBrightness", self.sun_color:length() * self.clouds_upper_density)
		
		self.shaders.sky:send("clouds", self.textures.clouds_top)
		self.shaders.sky:send("cloudsTransform", mat4:getRotateY(love.timer.getTime() * self.clouds_upper_rotation):subm())
		
		self.shaders.sky:send("stars", self.textures.stars)
		self.shaders.sky:send("starsStrength", -math.sin(self.sky_time * math.pi * 2))
		self.shaders.sky:send("starsTransform", mat4:getRotateX(love.timer.getTime() * 0.0025):subm())
		
		self.shaders.sky:send("rainbow", self.textures.rainbow)
		self.shaders.sky:send("rainbowStrength", self.rainbow_strength * self.sun_color:length())
		self.shaders.sky:send("rainbowSize", self.rainbow_size)
		self.shaders.sky:send("rainbowThickness", 1 / self.rainbow_thickness)
		self.shaders.sky:send("rainbowDir", {self.rainbow_dir:unpack()})
		
		love.graphics.setColor(self.sky_color:unpack())
		self.object_sky.objects.Sphere.mesh:setTexture(self.textures.sky)
		love.graphics.draw(self.object_sky.objects.Sphere.mesh)
		
		--moon
		for sunMoon = 1, 2 do
			local distance = sunMoon == 1 and 4.0 or (2.0 + math.sin(self.sky_time * math.pi * 2.0))
			local right = vec3(camTransform[1], camTransform[2], camTransform[3]):normalize()
			local up = vec3(camTransform[5], camTransform[6], camTransform[7])
			
			if sunMoon == 1 then
				local moon = self:getTexture(self.textures.moon)
				local moon_normal = self:getTexture(self.textures.moon_normal)
				
				if moon and moon_normal then
					love.graphics.setColor(1.0, 1.0, 1.0)
					love.graphics.setBlendMode("alpha")
					
					local shader = self.shaders.billboard_moon
					love.graphics.setShader(shader)
					
					shader:send("transformProj", transformProj)
					shader:send("up", {up:unpack()})
					shader:send("right", {right:unpack()})
					shader:send("InstanceCenter", {(-self.sun*distance):unpack()})
					shader:send("sun", {math.cos(self.sky_day / 30 * math.pi * 2), math.sin(self.sky_day / 30 * math.pi * 2), 0})
					shader:send("normalTex", moon_normal)
					
					self.object_plane.objects.Plane.mesh:setTexture(moon)
				end
			else
				local sun = self:getTexture(self.textures.sun)
				
				if sun then
					love.graphics.setColor(self.sun_color)
					love.graphics.setBlendMode("add")
					
					local shader = self.shaders.billboard_sun
					love.graphics.setShader(shader)
					
					shader:send("transformProj", transformProj)
					shader:send("up", {up:unpack()})
					shader:send("right", {right:unpack()})
					shader:send("InstanceCenter", {(self.sun*distance):unpack()})
					
					self.object_plane.objects.Plane.mesh:setTexture(sun)
				end
			end
			love.graphics.draw(self.object_plane.objects.Plane.mesh)
		end
		
		--clouds
		if self.clouds_enabled then
			love.graphics.setBlendMode("alpha")
			
			love.graphics.setShader(self.shaders.clouds)
			self.shaders.clouds:send("sunColor", {(self.sun_color * 4.0):unpack()})
			self.shaders.clouds:send("ambientColor", {(self.sun_ambient + vec3(0.5, 0.5, 0.5) * (1.0 - self.sun_color:length())):unpack()})
			
			local sun = self.sun:normalize()
			self.shaders.clouds:send("sunVec", {sun:unpack()})
			self.shaders.clouds:send("sunStrength", math.max(0.0, 1.0 - math.abs(sun.y) * (sun.y > 0 and 3.0 or 10.0)) * 10.0)
			self.shaders.clouds:send("offset", self.clouds_pos)
			
			self.shaders.clouds:send("scale", self.clouds_scale)
			self.shaders.clouds:send("scale_base", self.clouds_scale / 17.0)
			self.shaders.clouds:send("scale_roughness", self.clouds_scale * 0.7)
			self.shaders.clouds:send("base_impact", 0.5 + self.weather_temperature * 5.0)
			
			self.textures.clouds_base:setWrap("repeat")
			self.shaders.clouds:send("tex_base", self.textures.clouds_base)
			
			self.object_cube.objects.Cube.mesh:setTexture(self.cloudCanvas)
			self.cloudCanvas:setWrap("repeat")
			
			self.shaders.clouds:send("transformProj", transformProj)
			love.graphics.draw(self.object_cube.objects.Cube.mesh)
		end
	end
	love.graphics.pop()
end