--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

function lib:renderSky(transformProj, camTransform, transformScale)
	transformProj = transformProj * mat4:getScale(transformScale or 500)
	
	love.graphics.push("all")
	if not self.sky_texture then
		love.graphics.clear()
	elseif type(self.sky_texture) == "userdata" and self.sky_texture:getTextureType() == "cube" then
		--cubemap
		local shader = self:getShader("sky_cube")
		love.graphics.setShader(shader)
		shader:send("transformProj", transformProj)
		shader:send("sky", self.sky_texture)
		love.graphics.draw(self.object_cube.objects.Cube.mesh)
	elseif type(self.sky_texture) == "userdata" and self.sky_texture:getTextureType() == "2d" then
		--HDRI
		local shader = self:getShader("sky_hdri")
		love.graphics.setShader(shader)
		shader:send("exposure", self.sky_hdri_exposure)
		shader:send("transformProj", transformProj)
		self.object_sky.objects.Sphere.mesh:setTexture(self.sky_texture)
		love.graphics.draw(self.object_sky.objects.Sphere.mesh)
	else
		--sky dome
		lib.skyInUse = true
		lib.initTextures:sky()
		
		--simple wilkie hosek sky
		local shader = self:getShader("sky")
		love.graphics.setShader(shader)
		shader:send("transformProj", transformProj)
		shader:send("time", self.sky_time)
		shader:send("sunColor", self.sun_color)
		shader:send("cloudsBrightness", self.sun_color:length() * self.clouds_upper_density)
		
		shader:send("clouds", self.textures.clouds_top)
		shader:send("cloudsTransform", mat4:getRotateY(love.timer.getTime() * self.clouds_upper_rotation):subm())
		
		shader:send("stars", self.textures.stars)
		shader:send("starsStrength", -math.sin(self.sky_time * math.pi * 2))
		shader:send("starsTransform", mat4:getRotateX(love.timer.getTime() * 0.0025):subm())
		
		shader:send("rainbow", self.textures.rainbow)
		shader:send("rainbowStrength", self.rainbow_strength * self.sun_color:length())
		shader:send("rainbowSize", self.rainbow_size)
		shader:send("rainbowThickness", 1 / self.rainbow_thickness)
		shader:send("rainbowDir", {self.rainbow_dir:unpack()})
		
		love.graphics.setColor(self.sky_color:unpack())
		self.object_cube.objects.Cube.mesh:setTexture(self.textures.sky)
		love.graphics.draw(self.object_cube.objects.Cube.mesh)
		
		--moon
		for sunMoon = 1, 2 do
			local size = sunMoon == 1 and 0.25 or 0.5 / (2.0 - math.sin(self.sky_time * math.pi * 2.0))
			local right = vec3(camTransform[1], camTransform[2], camTransform[3]):normalize() * size
			local up = vec3(camTransform[5], camTransform[6], camTransform[7]) * size
			
			if sunMoon == 1 then
				local moon = self:getTexture(self.textures.moon)
				local moon_normal = self:getTexture(self.textures.moon_normal)
				
				if moon and moon_normal then
					love.graphics.setColor(1.0, 1.0, 1.0)
					love.graphics.setBlendMode("alpha")
					
					local shader = self:getShader("billboard_moon")
					love.graphics.setShader(shader)
					
					shader:send("transformProj", transformProj)
					shader:send("up", {up:unpack()})
					shader:send("right", {right:unpack()})
					shader:send("InstanceCenter", {(-self.sun):unpack()})
					shader:send("sun", {math.cos(self.sky_day / 30 * math.pi * 2), math.sin(self.sky_day / 30 * math.pi * 2), 0})
					shader:send("normalTex", moon_normal)
					
					self.object_plane.objects.Plane.mesh:setTexture(moon)
				end
			else
				local sun = self:getTexture(self.textures.sun)
				
				if sun then
					love.graphics.setColor(self.sun_color)
					love.graphics.setBlendMode("add")
					
					local shader = self:getShader("billboard_sun")
					love.graphics.setShader(shader)
					
					shader:send("transformProj", transformProj)
					shader:send("up", {up:unpack()})
					shader:send("right", {right:unpack()})
					shader:send("InstanceCenter", {(self.sun):unpack()})
					
					self.object_plane.objects.Plane.mesh:setTexture(sun)
				end
			end
			love.graphics.draw(self.object_plane.objects.Plane.mesh)
		end
		
		--clouds
		if self.clouds_enabled then
			love.graphics.setBlendMode("alpha")
			
			local shader = self:getShader("clouds")
			love.graphics.setShader(shader)
			shader:send("sunColor", {(self.sun_color * 4.0):unpack()})
			shader:send("ambientColor", {(self.sun_ambient + vec3(0.5, 0.5, 0.5) * (1.0 - self.sun_color:length())):unpack()})
			
			local sun = self.sun:normalize()
			shader:send("sunVec", {sun:unpack()})
			shader:send("sunStrength", math.max(0.0, 1.0 - math.abs(sun.y) * (sun.y > 0 and 3.0 or 10.0)) * 10.0)
			shader:send("offset", self.clouds_pos)
			
			--stretch
			local a = math.atan2(lib.clouds_wind.y, lib.clouds_wind.x) + lib.clouds_angle
			local strength = lib.clouds_wind:length() * lib.clouds_stretch_wind + lib.clouds_stretch
			if strength < 0 then
				a = a + math.pi / 2
				strength = -strength
			end
			local stretch = {
				self.clouds_scale / (1.0 + math.abs(math.cos(a)) * strength),
				self.clouds_scale / (1.0 + math.abs(math.sin(a)) * strength)
			}
			
			shader:send("scale", stretch)
			shader:send("scale_base", self.clouds_scale / 17.0)
			shader:send("scale_roughness", self.clouds_scale * 0.7)
			shader:send("base_impact", 0.5 + self.weather_temperature * 5.0)
			
			self.textures.clouds_base:setWrap("repeat")
			shader:send("tex_base", self.textures.clouds_base)
			
			self.object_cube.objects.Cube.mesh:setTexture(self.cloudCanvas)
			self.cloudCanvas:setWrap("repeat")
			
			shader:send("transformProj", transformProj)
			love.graphics.draw(self.object_cube.objects.Cube.mesh)
		end
	end
	love.graphics.pop()
end