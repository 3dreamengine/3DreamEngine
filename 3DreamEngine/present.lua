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
function lib.present(self)
	lib.stats.shadersInUse = 0
	lib.stats.materialDraws = 0
	lib.stats.draws = 0
	lib.stats.perShader = { }
	
	--clear canvas
	if self.AO_enabled then
		if self.reflections_enabled then
			love.graphics.setCanvas({self.canvas, self.canvas_z, self.canvas_normal, depthstencil = self.canvas_depth})
		else
			love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
		end
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
	end
	
	--clear canvas
	love.graphics.clear({0, 0, 0, 0}, {255, 255, 255, 255}, {0, 0, 0, 0})
	
	--sky
	if self.sky then
		local transform = matrix{
			{50, 0, 0, 0},
			{0, 50, 0, 0},
			{0, 0, 50, 0},
			{0, 0, 0, 1},
		}
		
		love.graphics.setDepthMode("less", false)
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
		
		local timeFac = 1.0 - (math.cos(self.dayTime*math.pi*2)*0.5+0.5)
		local color = self:getDayLight(self.dayTime, 0.25)
		color[4] = 1.0
		
		if self.night then
			love.graphics.setShader(self.shaderSkyNight)
			self.shaderSkyNight:send("cam", self.shaderVars_cam * transform)
			self.shaderSkyNight:send("color", color)
			self.shaderSkyNight:send("time", timeFac)
			love.graphics.draw(self.object_sky.objects.Cube.mesh)
		else
			love.graphics.setShader(self.shaderSky)
			self.shaderSky:send("cam", self.shaderVars_cam * transform)
			self.shaderSky:send("color", color)
			love.graphics.draw(self.object_sky.objects.Cube.mesh)
		end
	end
	
	--clouds
	if self.clouds then
		local transform = matrix{
			{100, 0, 0, 0},
			{0, 100, 0, 0},
			{0, 0, 100, 0},
			{0, 100, 0, 1},
		}
		
		love.graphics.setDepthMode("less", false)
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
		love.graphics.setShader(self.shaderCloud)
		
		self.shaderCloud:send("density", self.cloudDensity)
		self.shaderCloud:send("time", love.timer.getTime() / 1000)
		self.shaderCloud:send("transform", transform)
		self.shaderCloud:send("cam", self.shaderVars_cam)
		
		love.graphics.draw(self.object_clouds.objects.Cube.mesh)
	end
	
	--set canvas
	if self.AO_enabled then
		if self.reflections_enabled then
			love.graphics.setCanvas({self.canvas, self.canvas_z, self.canvas_normal, depthstencil = self.canvas_depth})
		else
			love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
		end
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
	end
	
	--two steps, once for solid and once for transparent objects
	for step = 1, 2 do
		if self.noDepth then
			love.graphics.setDepthMode()
		else
			love.graphics.setDepthMode("less", step == 1)
		end
		for shaderName, s in pairs(self.drawTable) do
			local shader = self.shaders[shaderName]
			love.graphics.setShader(shader)
			
			--lighting
			if shaderName:find("light") then
				local light = { }
				local pos = { }
				for i = 1, self.lighting_max do
					pos[i] = {self.lighting[i][1], self.lighting[i][2], self.lighting[i][3]}
					light[i] = {self.lighting[i][4] * self.lighting[i][7], self.lighting[i][5] * self.lighting[i][7], self.lighting[i][6] * self.lighting[i][7]}
					light[i][4] = math.sqrt(light[i][1]^2 + light[i][2]^2 + light[i][3]^2)
				end
				shader:send("lightColor", unpack(light))
				shader:send("lightPos", unpack(pos))
			end
			
			--wind
			if shaderName:find("wind") then
				shader:send("wind", love.timer.getTime())
			end
			
			--sun color and direction
			shader:send("ambient", {self.color_ambient[1] * self.color_ambient[4], self.color_ambient[2] * self.color_ambient[4], self.color_ambient[3] * self.color_ambient[4], 1.0})
			shader:send("sunColor", {self.color_sun[1] * self.color_sun[4], self.color_sun[2] * self.color_sun[4], self.color_sun[3] * self.color_sun[4], 1.0})
			shader:send("sun", self.shaderVars_sun)
			
			--camera
			shader:send("camV", self.shaderVars_camV)
			shader:send("cam", self.shaderVars_cam)
			if self.reflections_enabled then
				shader:send("cam3", self.shaderVars_cam3)
			end
			
			--for each material
			for material, tasks in pairs(s) do
				if step == 1 and material.color[4] == 1 or step == 2 and material.color[4] ~= 1 then
					--diffuse texture already bound to mesh!
					--set spec textures
					if shaderName == "textured_light_pixel_spec" then
						shader:send("tex_spec", s.tex_spec)
					end
					
					--draw objects
					for i,v in pairs(tasks) do
						love.graphics.setMeshCullMode(v[3].noBackFaceCulling and "none" or "back")
						love.graphics.setColor(v[4], v[5], v[6])
						
						shader:send("transform", v[1])
						shader:send("rotate", v[2])
						
						--final draw
						love.graphics.draw(v[3].mesh)
						
						lib.stats.draws = lib.stats.draws + 1
						lib.stats.perShader[shaderName] = (lib.stats.perShader[shaderName] or 0) + 1
					end
					lib.stats.materialDraws = lib.stats.materialDraws+ 1
				end
			end
			lib.stats.shadersInUse = lib.stats.shadersInUse + 0.5
		end
	end
	
	--lines
	if self.lineTable[1] then
		love.graphics.setShader()
		love.graphics.setDepthMode()
		for d,s in ipairs(self.lineTable) do
			love.graphics.setLineWidth(8)
			love.graphics.setColor(s[3], s[4], s[5])
			
			local p1 = self.shaderVars_cam * matrix({s[1]})^"T"
			local p2 = self.shaderVars_cam * matrix({s[2]})^"T"
			
			p1 = (p1^"T")[1]
			p2 = (p2^"T")[1]
			
			love.graphics.line((p1[1]+1)*love.graphics.getWidth()/2, (p1[2]+1)*love.graphics.getHeight()/2,
				(p2[1]+1)*love.graphics.getWidth()/2, (p2[2]+1)*love.graphics.getHeight()/2)
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
		love.graphics.setShader(self.post)
		self.post:send("AO", self.canvas_blur_1)
		self.post:send("strength", love.keyboard.isDown("f9") and 0.0 or self.AO_strength)
		self.post:send("depth", self.canvas_z)
		self.post:send("fog", self.fog)
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