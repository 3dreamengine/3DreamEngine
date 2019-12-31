--[[
#part of the 3DreamEngine by Luke100000
present.lua - final presentation of drawn objects, orders objects to decrease shader switches, also draws sky sphere, clouds, ...
--]]

local lib = _3DreamEngine

lib.stats = {
	shadersInUse = 0,
	draws = 0,
	perShader = { },
}
function lib.present(self, noDepth, noSky)
	if noDepth and noSky ~= false then noSky = true end
	
	--render shadow
	if self.shadow_enabled then
		love.graphics.setCanvas({self.canvas_shadow, depthstencil = self.canvas_shadow_depth})
		love.graphics.clear({255, 0, 0, 0}, {255, 255, 255, 255})
		love.graphics.setMeshCullMode("none")
		self.shaders.shadow:send("transformProj", self.shaderVars_transformProjShadow)
		love.graphics.setDepthMode("less", true)
		love.graphics.setShader(self.shaders.shadow)
		for shaderInfo, s in pairs(self.drawTable) do
			for material, tasks in pairs(s) do
				if shaderInfo.variant ~= "wind" then
					for i,v in pairs(tasks) do
						
						self.shaders.shadow:send("transform", v[1])
						
						--final draw
						love.graphics.draw(v[2].mesh)
					end
				end
			end
		end
		love.graphics.setShader()
		love.graphics.setCanvas()
	end
	
	
	for i = 1, self.anaglyph3D and 2 or 1 do
		lib.stats.shadersInUse = 0
		lib.stats.materialDraws = 0
		lib.stats.draws = 0
		lib.stats.perShader = { }
		
		local transformProj = i == 1 and self.shaderVars_transformProj or self.shaderVars_transformProj_2
		local clearColor = not self.anaglyph3D and {1, 1, 1} or i == 1 and {1, 0, 0} or {0, 1, 1}
		
		--clear canvas
		if self.bloom_enabled then
			if self.AO_enabled then
				love.graphics.setCanvas({self.canvas, self.canvas_z, self.canvas_bloom, self.SSR_enabled and self.canvas_normal or nil, self.SSR_enabled and self.canvas_reflectiness or nil, depthstencil = self.canvas_depth})
				love.graphics.clear({0, 0, 0, 0}, {255, 255, 255, 255}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0})
			else
				love.graphics.setCanvas({self.canvas, self.canvas_bloom, depthstencil = self.canvas_depth})
				love.graphics.clear({0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0})
			end
		else
			if self.AO_enabled then
				love.graphics.setCanvas({self.canvas, self.canvas_z, self.SSR_enabled and self.canvas_normal or nil, self.SSR_enabled and self.canvas_reflectiness or nil, depthstencil = self.canvas_depth})
				love.graphics.clear({0, 0, 0, 0}, {255, 255, 255, 255}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0})
			else
				love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
				love.graphics.clear({0, 0, 0, 0}, {255, 255, 255, 255})
			end
		end
		
		--sky
		if not noSky then
			love.graphics.setColor(clearColor)
			
			if self.sky then
				local transform = matrix{
					{1, 0, 0, self.shaderVars_viewPos[1]},
					{0, 1, 0, self.shaderVars_viewPos[2]},
					{0, 0, 1, self.shaderVars_viewPos[3]},
					{0, 0, 0, 1},
				}
				
				love.graphics.setDepthMode("less", false)
				love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
				
				local timeFac = 1.0 - (math.cos(self.dayTime*math.pi*2)*0.5+0.5)
				local color = self:getDayLight(self.dayTime, 0.25)
				color[4] = 1.0
				
				love.graphics.push("all")
				love.graphics.setColor(self.color_ambient[1] * self.color_ambient[4], self.color_ambient[2] * self.color_ambient[4], self.color_ambient[3] * self.color_ambient[4])
				if self.night then
					love.graphics.setShader(self.shaders.skyNight)
					self.shaders.skyNight:send("cam", transformProj * transform)
					self.shaders.skyNight:send("color", color)
					self.shaders.skyNight:send("time", timeFac)
					love.graphics.draw(self.object_sky.objects.Sphere.mesh)
				else
					love.graphics.setShader(self.shaders.sky)
					self.shaders.sky:send("cam", transformProj * transform)
					self.shaders.sky:send("color", color)
					love.graphics.draw(self.object_sky.objects.Sphere.mesh)
				end
				love.graphics.pop()
			end
			
			--clouds
			if self.clouds then
				local transform = matrix{
					{100, 0, 0, self.shaderVars_viewPos[1]},
					{0, 100, 0, self.shaderVars_viewPos[2] + 100},
					{0, 0, 100, self.shaderVars_viewPos[3]},
					{0, 0, 0, 1},
				}
				
				love.graphics.setDepthMode("less", false)
				love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
				love.graphics.setShader(self.shaders.cloud)
				
				self.shaders.cloud:send("density", self.cloudDensity)
				self.shaders.cloud:send("time", love.timer.getTime() / 1000)
				self.shaders.cloud:send("cam", transformProj * transform)
				
				love.graphics.draw(self.object_clouds.objects.Cube.mesh)
			end
		end
		
		--set canvas
		if self.bloom_enabled then
			if self.AO_enabled then
				love.graphics.setCanvas({self.canvas, self.canvas_z, self.canvas_bloom, self.SSR_enabled and self.canvas_normal or nil, self.SSR_enabled and self.canvas_reflectiness or nil, depthstencil = self.canvas_depth})
			else
				love.graphics.setCanvas({self.canvas, self.canvas_bloom, depthstencil = self.canvas_depth})
			end
		else
			if self.AO_enabled then
				love.graphics.setCanvas({self.canvas, self.canvas_z, self.SSR_enabled and self.canvas_normal or nil, self.SSR_enabled and self.canvas_reflectiness or nil, depthstencil = self.canvas_depth})
			else
				love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
			end
		end
		
		--two steps, once for solid and once for transparent objects
		for step = 1, 2 do
			if noDepth then
				love.graphics.setDepthMode()
			else
				love.graphics.setDepthMode("less", step == 1)
			end
			for shaderInfo, s in pairs(self.drawTable) do
				--lighting
				local light = { }
				local pos = { }
				local count = 0
				for d,s in ipairs(self.lighting) do
					s.used = false
				end
				for i = 1, self.lighting_max do
					local best
					local bestV = 0
					for d,s in ipairs(self.lighting) do
						if not s.used then
							local v = 1000 / (10+math.sqrt((s.x-self.currentCam.x)^2 + (s.y-self.currentCam.y)^2 + (s.z-self.currentCam.z)^2)) * s.importance * math.sqrt(s.r^2+s.g^2+s.b^2)
							if v > bestV then
								bestV = v
								best = s
							end
						end
					end
					if best then
						best.used = true
						light[#light+1] = {best.r, best.g, best.b, best.meter}
						pos[#pos+1] = {best.x, best.y, best.z}
						count = count + 1
					else
						break
					end
				end
				
				local shader = self:getShader(shaderInfo, count)
				love.graphics.setShader(shader.shader)		
				
				if count > 0 then
					shader.shader:send("lightColor", unpack(light))
					shader.shader:send("lightPos", unpack(pos))
				end
				
				--ambient lighting
				shader.shader:send("ambient", {self.color_ambient[1] * self.color_ambient[4], self.color_ambient[2] * self.color_ambient[4], self.color_ambient[3] * self.color_ambient[4], 1.0})
				
				--camera
				shader.shader:send("viewPos", self.shaderVars_viewPos)
				shader.shader:send("transformProj", transformProj)
				
				if self.shadow_enabled then
					shader.shader:send("transformProjShadow", self.shaderVars_transformProjShadow)
					shader.shader:send("tex_shadow", self.canvas_shadow_depth)
				end
				
				--for each material
				for material, tasks in pairs(s) do
					if step == 1 and material.color[4] == 1 or step == 2 and material.color[4] ~= 1 then
						--draw objects
						for i,v in pairs(tasks) do
							--update mesh data if required
							if material.update then
								material:update(v[2], v[6])
							end
							
							if shader.reflections_day then
								local timeFac = 1.0 - (math.cos(self.dayTime*math.pi*2)*0.5+0.5)
								local color = self:getDayLight(self.dayTime, 0.25)
								color[4] = nil
								
								shader.shader:send("background_day", self.resourceLoader:getTexture(material.reflections_day or v[6].reflections_day or self.sky) or self.textures.default_emission)
								
								if shader.reflections_night then
									shader.shader:send("background_color", color)
									shader.shader:send("background_time", timeFac)
									
									shader.shader:send("background_night", self.resourceLoader:getTexture(material.reflections_night or v[6].reflections_night or material.reflections_day or v[6].reflections_day or self.night or self.sky))
								end
							end	
							
							--set textures
							if shader.meshType == "flat" then
								shader.shader:send("emission", material.emission or (shader.emission and 1.0 or 0.0))
							else
								local tex = shader.arrayImage and self.textures_array or self.textures
								if shader.tex_albedo then
									v[2].mesh:setTexture(self.resourceLoader:getTexture(material.tex_albedo) or tex.default_albedo)
								else
									shader.shader:send("albedo", material.albedo and {material.albedo[1], material.albedo[2], material.albedo[3], material.albedo[4] or 1.0} or {0.5, 0.5, 0.5, 1.0})
								end
								
								if shader.tex_normal then
									shader.shader:send("tex_normal", self.resourceLoader:getTexture(material.tex_normal) or tex.default_normal)
								else
									shader.shader:send("normalT", material.normal or {0, 0, 1.0})
								end
								
								if shader.tex_roughness then
									shader.shader:send("tex_roughness", self.resourceLoader:getTexture(material.tex_roughness) or tex.default_roughness)
								else
									shader.shader:send("roughness", material.roughness or 0.5)
								end
								
								if shader.tex_metallic then
									shader.shader:send("tex_metallic", self.resourceLoader:getTexture(material.tex_metallic) or tex.default_metallic)
								else
									shader.shader:send("metallic", material.metallic or 0)
								end
								
								if shader.tex_emission then
									shader.shader:send("tex_emission", self.resourceLoader:getTexture(material.tex_emission) or tex.default_emission)
								else
									shader.shader:send("emission", material.emission or 0)
								end
								
								if shader.tex_ao then
									shader.shader:send("tex_ao", self.resourceLoader:getTexture(material.tex_ao) or tex.default_ao)
								else
									shader.shader:send("ao", material.ao or 1.0)
								end
							end
							
							if shader.variant == "wind" then
								shader.shader:send("shader_wind_strength", material.shader_wind_strength or 1.0)
								shader.shader:send("shader_wind_scale", material.shader_wind_scale or 1.0)
								shader.shader:send("wind", love.timer.getTime() * (material.shader_wind_speed or 1.0))
							end
							
							love.graphics.setMeshCullMode(v[2].noBackFaceCulling and "none" or "back")
							love.graphics.setColor(v[3], v[4], v[5])
							
							shader.shader:send("transform", v[1]^"T")
							
							--final draw
							love.graphics.draw(v[2].mesh)
							
							lib.stats.draws = lib.stats.draws + 1
							lib.stats.perShader[shader] = (lib.stats.perShader[shader] or 0) + 1
						end
						lib.stats.materialDraws = lib.stats.materialDraws+ 1
					end
				end
				lib.stats.shadersInUse = lib.stats.shadersInUse + 0.5
			end
		end
		
		
		--particles
		if self.bloom_enabled then
			love.graphics.setCanvas({self.canvas, self.canvas_bloom, depthstencil = self.canvas_depth})
		else
			love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
		end
		
		table.sort(self.particles, function(a, b) return a[5] > b[5] end)
		love.graphics.setShader(self.shaders.particle)
		for d,s in ipairs(self.particles) do
			self.shaders.particle:send("depth", s[5])
			self.shaders.particle:send("emission", s[8])
			self.shaders.particle:send("tex_emission", s[9] or s[1])
			
			if s[2] then
				local _, _, w, h = s[2]:getViewport()
				love.graphics.draw(s[1], s[2], (s[3]+1)*love.graphics.getWidth()/2, (s[4]+1)*love.graphics.getHeight()/2, s[7], s[6], s[6], w/2, h/2)
			else
				love.graphics.draw(s[1], (s[3]+1)*love.graphics.getWidth()/2, (s[4]+1)*love.graphics.getHeight()/2, s[7], s[6], s[6], s[1]:getWidth()/2, s[1]:getHeight()/2)
			end
		end
		
		
		love.graphics.setDepthMode()
		love.graphics.origin()
		love.graphics.setColor(1, 1, 1)
		
		--Ambient Occlusion (SSAO)
		if self.AO_enabled then
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.setCanvas(self.canvas_blur_1)
			love.graphics.clear()
			love.graphics.setShader(self.shaders.AO)
			love.graphics.draw(self.canvas_z, 0, 0, 0, self.AO_resolution)
			love.graphics.setShader(self.shaders.blur)
			self.shaders.blur:send("size", {1/self.canvas_blur_1:getWidth(), 1/self.canvas_blur_1:getHeight()})
			
			for i = 1, self.AO_quality_smooth do
				self.shaders.blur:send("vstep", 1.0)
				self.shaders.blur:send("hstep", 0.0)
				love.graphics.setCanvas(self.canvas_blur_2)
				love.graphics.clear()
				love.graphics.draw(self.canvas_blur_1)
				
				self.shaders.blur:send("vstep", 0.0)
				self.shaders.blur:send("hstep", 1.0)
				love.graphics.setCanvas(self.canvas_blur_1)
				love.graphics.clear()
				love.graphics.draw(self.canvas_blur_2)
			end
			
			love.graphics.setCanvas()
			love.graphics.setShader(self.shaders.post)
			self.shaders.post:send("AO", self.canvas_blur_1)
			self.shaders.post:send("strength", love.keyboard.isDown("f9") and 0.0 or self.AO_strength)
			self.shaders.post:send("depth", self.canvas_z)
			self.shaders.post:send("fog", self.fog)
			love.graphics.setColor(clearColor)
			love.graphics.setBlendMode(i == 2 and "add" or "alpha")
			love.graphics.draw(self.canvas)
			love.graphics.setBlendMode("alpha")
			love.graphics.setShader()
		else
			love.graphics.setShader()
			love.graphics.setCanvas()
			love.graphics.setColor(clearColor)
			love.graphics.setBlendMode(i == 2 and "add" or "alpha")
			love.graphics.draw(self.canvas)
			love.graphics.setBlendMode("alpha")
		end
		
		--bloom
		if self.bloom_enabled and not love.keyboard.isDown("f9") then
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.setCanvas(self.canvas_bloom_1)
			love.graphics.clear()
			love.graphics.draw(self.canvas_bloom, 0, 0, 0, self.bloom_resolution)
			
			love.graphics.setShader(self.shaders.blur)
			self.shaders.blur:send("size", {1/self.canvas_bloom_1:getWidth(), 1/self.canvas_bloom_1:getHeight()})
			
			local strength = self.bloom_size * self.bloom_resolution / math.sqrt(self.bloom_quality)
			for i = 1, self.bloom_quality do
				self.shaders.blur:send("vstep", strength)
				self.shaders.blur:send("hstep", 0.0)
				love.graphics.setCanvas(self.canvas_bloom_2)
				love.graphics.clear()
				love.graphics.draw(self.canvas_bloom_1)
				
				self.shaders.blur:send("vstep", 0.0)
				self.shaders.blur:send("hstep", strength)
				love.graphics.setCanvas(self.canvas_bloom_1)
				love.graphics.clear()
				love.graphics.draw(self.canvas_bloom_2)
			end
			
			love.graphics.setCanvas()
			love.graphics.setShader(shader)
			love.graphics.setBlendMode("add", "premultiplied")
			love.graphics.setShader(self.shaders.bloom)
			self.shaders.bloom:send("strength", self.bloom_strength)
			love.graphics.setColor(clearColor)
			love.graphics.draw(self.canvas_bloom_1, 0, 0, 0, 1 / self.bloom_resolution)
			love.graphics.setShader()
			love.graphics.setBlendMode("alpha")
		end
	end
	
	if love.keyboard.isDown("f8") and self.shadow_enabled then
		love.graphics.setCanvas()
		love.graphics.setShader()
		love.graphics.draw(self.canvas_shadow, 0, 0, 0, 256 / self.canvas_shadow_depth:getWidth())
	end
	
	if not love.keyboard.isDown("f7") and self.SSR_enabled then
		love.graphics.setCanvas(self.canvas_SSR_post)
		love.graphics.clear()
		love.graphics.setShader(self.shaders.SSR)
		self.shaders.SSR:send("depth", self.canvas_z)
		self.shaders.SSR:send("camTransformInverse", self.shaderVars_camTransformInverse)
		love.graphics.draw(self.canvas_normal, 0, 0, 0, self.SSR_resolution)
		love.graphics.setCanvas()
		
		love.graphics.setShader(self.shaders.SSR_post)
		self.shaders.SSR_post:send("diffuse", self.canvas)
		self.shaders.SSR_post:send("normal", self.canvas_normal)
		self.shaders.SSR_post:send("reflectiness", self.canvas_reflectiness)
		
		local dayTex = self.resourceLoader:getTexture(self.sky) or self.textures.default_emission
		local nightTex = self.resourceLoader:getTexture(self.night or self.sky) or self.textures.default_emission
		
		self.shaders.SSR_post:send("background_day", dayTex)
		
		if dayTex == dayTex then
			local timeFac = 1.0 - (math.cos(self.dayTime*math.pi*2)*0.5+0.5)
			local color = self:getDayLight(self.dayTime, 0.25)
			color[4] = nil
			
			self.shaders.SSR_post:send("background_color", color)
			self.shaders.SSR_post:send("background_time", timeFac)
			
			self.shaders.SSR_post:send("background_night", nightTex)
		else
			self.shaders.SSR_post:send("background_color", {1.0, 1.0, 1.0})
			self.shaders.SSR_post:send("background_time", 1.0)
			
			self.shaders.SSR_post:send("background_night", dayTex)
		end
		
		love.graphics.draw(self.canvas_SSR_post, 0, 0, 0, 1/self.SSR_resolution)
		love.graphics.setShader()
	end
end