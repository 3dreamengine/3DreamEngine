--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

function lib:renderSky(transformProj)
	love.graphics.push("all")
	if self.sky_cube then
		love.graphics.setShader(self.shaders.sky)
		self.shaders.sky:send("transformProj", transformProj)
		self.shaders.sky:send("sky", self.sky_cube)
		love.graphics.draw(self.object_cube.objects.Cube.mesh)
	elseif self.sky_hdri then
		--given hdri sphere
		love.graphics.setShader(self.shaders.sky_hdri)
		self.shaders.sky_hdri:send("exposure", self.sky_hdri_exposure)
		self.shaders.sky_hdri:send("transformProj", transformProj * mat4:getRotateY(love.timer.getTime()*0.01))
		self.object_sky.objects.Sphere.mesh:setTexture(self.sky_hdri)
		love.graphics.draw(self.object_sky.objects.Sphere.mesh)
	else
		--simple wilkie hosek sky
		love.graphics.setShader(self.shaders.sky_WilkieHosek)
		self.shaders.sky_WilkieHosek:send("transformProj", transformProj)
		self.shaders.sky_WilkieHosek:send("time", self.sky_time)
		love.graphics.setColor(self.sky_color:unpack())
		self.object_sky.objects.Sphere.mesh:setTexture(self.textures:get("sky"))
		love.graphics.draw(self.object_sky.objects.Sphere.mesh)
		
		--stars
		if self.stars_enabled then
			local stars = -math.sin(self.sky_time * math.pi * 2)
			if stars > 0 then
				local starTex = self:getTexture(self.textures.stars_hdri)
				if starTex then
					love.graphics.setBlendMode("add", "premultiplied")
					love.graphics.setShader(self.shaders.sky_hdri)
					self.shaders.sky_hdri:send("exposure", stars)
					self.shaders.sky_hdri:send("transformProj", transformProj)
					self.object_sky.objects.Sphere.mesh:setTexture(starTex)
					love.graphics.draw(self.object_sky.objects.Sphere.mesh)
				end
			end
		end
		
		--moon and sun
		if self.sunMoon_enabled then
			--moon
			for sunMoon = 1, 2 do
				local x, y, z = (-self.sun):normalize():unpack()
				local l = math.sqrt(x^2+z^2)
				
				local a2 = self.sky_time * math.pi * 2.0 + (sunMoon-1) * math.pi
				local c2 = math.cos(a2)
				local s2 = math.sin(a2)
				
				local a1 = self.sun_offset
				local c1 = math.cos(a1)
				local s1 = math.sin(a1)
				
				local distance = sunMoon == 1 and 4.0 or (2.0 + math.sin(self.sky_time * math.pi * 2.0))
				local transform = mat4:getIdentity():translate(0, 0, distance):rotateX(a2):rotateZ(a1)
				
				if sunMoon == 1 then
					local moon = self:getTexture(self.textures.moon)
					local moon_normal = self:getTexture(self.textures.moon_normal)
					
					if moon and moon_normal then
						love.graphics.setColor(1.0, 1.0, 1.0)
						love.graphics.setBlendMode("alpha")
						love.graphics.setShader(self.shaders.billboard_moon)
						self.shaders.billboard_moon:send("transform", transform)
						self.shaders.billboard_moon:send("transformProj", transformProj)
						self.shaders.billboard_moon:send("normalTex", moon_normal)
						self.shaders.billboard_moon:send("sun", {math.cos(self.sky_day / 30 * math.pi * 2), math.sin(self.sky_day / 30 * math.pi * 2), 0})
						self.object_plane.objects.Plane.mesh:setTexture(moon)
					end
				else
					local sun = self:getTexture(self.textures.sun)
					
					if sun then
						love.graphics.setColor(self.sun_color)
						love.graphics.setBlendMode("add")
						love.graphics.setShader(self.shaders.billboard_sun)
						self.shaders.billboard_sun:send("transform", transform)
						self.shaders.billboard_sun:send("transformProj", transformProj)
						self.object_plane.objects.Plane.mesh:setTexture(sun)
					end
				end
				love.graphics.draw(self.object_plane.objects.Plane.mesh)
			end
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
			self.shaders.clouds:send("roughnessOffset", {love.timer.getTime() * 0.01, love.math.noise(love.timer.getTime() * 0.01)})
			
			self.shaders.clouds:send("scale", self.clouds_scale)
			self.shaders.clouds:send("scale_base", self.clouds_scale / 27.0)
			
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