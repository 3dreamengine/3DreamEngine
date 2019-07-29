--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
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
	
	lib.stats.shadersInUse = 0
	lib.stats.materialDraws = 0
	lib.stats.draws = 0
	lib.stats.perShader = { }
	
	--clear canvas
	if self.AO_enabled then
		love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
	end
	
	--clear canvas
	love.graphics.clear({0, 0, 0, 0}, {255, 255, 255, 255}, {0, 0, 0, 0})
	
	--sky
	if not noSky then
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
			
			if self.night then
				love.graphics.setShader(self.shaderSkyNight)
				self.shaderSkyNight:send("cam", self.shaderVars_transformProj * transform)
				self.shaderSkyNight:send("color", color)
				self.shaderSkyNight:send("time", timeFac)
				love.graphics.draw(self.object_sky.objects.Cube.mesh)
			else
				love.graphics.setShader(self.shaderSky)
				self.shaderSky:send("cam", self.shaderVars_transformProj * transform)
				self.shaderSky:send("color", color)
				love.graphics.draw(self.object_sky.objects.Cube.mesh)
			end
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
			love.graphics.setShader(self.shaderCloud)
			
			self.shaderCloud:send("density", self.cloudDensity)
			self.shaderCloud:send("time", love.timer.getTime() / 1000)
			self.shaderCloud:send("cam", self.shaderVars_transformProj * transform)
			
			love.graphics.draw(self.object_clouds.objects.Cube.mesh)
		end
	end
	
	--set canvas
	if self.AO_enabled then
		love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
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
			
			local shader = self:getShader(shaderInfo.typ, shaderInfo.variant, shaderInfo.normal, shaderInfo.specular, shaderInfo.reflections, count)
			love.graphics.setShader(shader.shader)
			
			if shader.reflections_enabled then
				local timeFac = 1.0 - (math.cos(self.dayTime*math.pi*2)*0.5+0.5)
				local color = self:getDayLight(self.dayTime, 0.25)
				
				shader.shader:send("background_day", self.sky)
				
				if shader.reflections_enabled_night then
					shader.shader:send("background_color", color)
					shader.shader:send("background_time", timeFac)
					
					shader.shader:send("background_night", self.night or self.sky)
				end
			end			
			
			if count > 0 then
				shader.shader:send("lightColor", unpack(light))
				shader.shader:send("lightPos", unpack(pos))
			end
			
			--wind
			if shader.variant == "wind" then
				shader.shader:send("wind", love.timer.getTime())
			end
			
			--ambient lighting
			shader.shader:send("ambient", {self.color_ambient[1] * self.color_ambient[4], self.color_ambient[2] * self.color_ambient[4], self.color_ambient[3] * self.color_ambient[4], 1.0})
			
			--camera
			if count > 0 then
				shader.shader:send("viewPos", self.shaderVars_viewPos)
			end
			shader.shader:send("transformProj", self.shaderVars_transformProj)
			
			--for each material
			for material, tasks in pairs(s) do
				if step == 1 and material.color[4] == 1 or step == 2 and material.color[4] ~= 1 then
					--diffuse texture already bound to mesh!
					if shader.specular and count > 0 then
						shader.shader:send("tex_specular", self.resourceLoader:getTexture(material.tex_specular) or self.texture_missing)
					end
					if shader.normal and count > 0 then
						shader.shader:send("tex_normal", self.resourceLoader:getTexture(material.tex_normal) or self.texture_missing)
					end
					
					shader.shader:send("alphaThreshold", material.alphaThreshold or 0.0)
					
					--draw objects
					for i,v in pairs(tasks) do
						if not v[2].diffuseConnected then
							if v[2].material.tex_diffuse then
								local tex, final = self.resourceLoader:getTexture(v[2].material.tex_diffuse)
								if tex ~= v[2].tex_diffuse_last then
									v[2].mesh:setTexture(tex)
								end
								if final then
									v[2].diffuseConnected = true
								end
							else
								v[2].diffuseConnected = true
							end
						end
						
						love.graphics.setMeshCullMode(v[2].noBackFaceCulling and "none" or "back")
						love.graphics.setColor(v[3], v[4], v[5])
						
						shader.shader:send("transform", v[1])
						
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
	
	love.graphics.setDepthMode()
	love.graphics.origin()
	love.graphics.setColor(1, 1, 1)
	
	--Ambient Occlusion (SSAO)
	if self.AO_enabled then
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(self.canvas_blur_1)
		love.graphics.clear()
		love.graphics.setShader(self.AO)
		love.graphics.draw(self.canvas_z, 0, 0, 0, self.AO_resolution)
		love.graphics.setShader(self.blur)
		self.blur:send("size", {1/self.canvas_blur_1:getWidth(), 1/self.canvas_blur_1:getHeight()})
		
		for i = 1, self.AO_quality_smooth do
			self.blur:send("vstep", 1.0)
			self.blur:send("hstep", 0.0)
			love.graphics.setCanvas(self.canvas_blur_2)
			love.graphics.clear()
			love.graphics.draw(self.canvas_blur_1)
			
			self.blur:send("vstep", 0.0)
			self.blur:send("hstep", 1.0)
			love.graphics.setCanvas(self.canvas_blur_1)
			love.graphics.clear()
			love.graphics.draw(self.canvas_blur_2)
		end
		
		love.graphics.setCanvas()
		love.graphics.setBlendMode("alpha")
		local shader = self.post
		love.graphics.setShader(shader)
		shader:send("AO", self.canvas_blur_1)
		shader:send("strength", love.keyboard.isDown("f9") and 0.0 or self.AO_strength)
		shader:send("depth", self.canvas_z)
		shader:send("fog", self.fog)
		love.graphics.draw(self.canvas)
		love.graphics.setShader()
	else
		love.graphics.setShader()
		love.graphics.setCanvas()
		love.graphics.draw(self.canvas)
	end
	
	--show blur canvas for debug
	if love.keyboard.isDown("f8") then
		love.graphics.draw(self.canvas_blur_1)
	end
end