--[[
#part of the 3DreamEngine by Luke100000
a collection of lighting helper functions for the rendering process
--]]

local lib = _3DreamEngine

function lib:getLightOverview(cam, deferred_lighting)
	if deferred_lighting then
		--no further selection required
		for d,s in ipairs(self.lighting) do
			s.active = true
		end
		return self.lighting
	else
		--select the most important lights
		for d,s in ipairs(self.lighting) do
			s.active = false
			s.priority = s.brightness * (s.meter == 0 and 100.0 or 1.0) * (s.shadow and 2.0 or 1.0) / (cam.pos - vec3(s.x, s.y, s.z)):length()
		end
		table.sort(self.lighting, function(a, b) return a.priority > b.priority end)
		
		--keep track of light count per type to construct shader
		local lighting = { }
		local lightRequirements = {
			simple = 0,
			point_shadow = 0,
			sun_shadow = 0,
		}
		for d,s in ipairs(self.lighting) do
			s.active = true
			if not s.shadow then
				lighting[#lighting+1] = s
				lightRequirements.simple = lightRequirements.simple + 1
			elseif s.shadow and s.shadow.typ == "point" then
				lighting[#lighting+1] = s
				lightRequirements.point_shadow = lightRequirements.point_shadow + 1
			elseif s.shadow and s.shadow.typ == "sun" then
				lighting[#lighting+1] = s
				lightRequirements.sun_shadow = lightRequirements.sun_shadow + 1
			end
			
			if #lighting == self.max_lights then
				break
			end
		end
		return lighting, lightRequirements
	end
end

function lib:sendLightUniforms(lighting, lightRequirements, shader, lighting)
	if lightRequirements.simple > 0 then
		shader:send("lightCount", #lighting)
	end
	
	--current light id
	local count = 0
	
	--fill light buffers
	local lightColor = { }
	local lightPos = { }
	local lightMeter = { }
	for i = 1, self.max_lights do
		lightColor[i] = {0, 0, 0}
		lightPos[i] = {0, 0, 0}
		lightMeter[i] = 0
	end
	
	--sun lighting
	for d,s in ipairs(lighting) do
		if s.shadow and s.shadow.typ == "sun" then
			local enable = 0.0
			if s.shadow.canvases and s.shadow.canvases[3] then
				shader:send("transformProjShadow_" .. count .. "_1", s.shadow.transformation_1)
				shader:send("transformProjShadow_" .. count .. "_2", s.shadow.transformation_2)
				shader:send("transformProjShadow_" .. count .. "_3", s.shadow.transformation_3)
				shader:send("tex_shadow_1_" .. count, s.shadow.canvases[1])
				shader:send("tex_shadow_2_" .. count, s.shadow.canvases[2])
				shader:send("tex_shadow_3_" .. count, s.shadow.canvases[3])
				enable = 1.0
			end
			
			count = count + 1
			
			lightColor[count] = {s.r * s.brightness * enable, s.g * s.brightness * enable, s.b * s.brightness * enable}
			lightPos[count] = {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z}
			lightMeter[count] = s.meter
		end
	end
	
	--sun lighting settings
	if lightRequirements.sun_shadow > 0 then
		shader:send("factor", self.shadow_factor)
		shader:send("shadowDistance", 2 / self.shadow_distance)
		shader:send("texelSize", 1.0 / self.shadow_resolution)
	end
	
	--point lighting
	for d,s in ipairs(lighting) do
		if s.shadow and s.shadow.typ == "point" then
			local enable = 0.0
			if s.shadow.canvas then
				shader:send("tex_shadow_" .. count, s.shadow.canvas)
				enable = 1.0
			end
			
			count = count + 1
			
			lightColor[count] = {s.r * s.brightness * enable, s.g * s.brightness * enable, s.b * s.brightness * enable}
			lightPos[count] = {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z}
			lightMeter[count] = s.meter
		end
	end
	
	--point lighting without shadow
	for d,s in ipairs(lighting) do
		if not s.shadow then
			count = count + 1
			
			lightColor[count] = {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness}
			lightPos[count] = {s.x, s.y, s.z}
			lightMeter[count] = s.meter
		end
	end
	
	--general settings
	shader:send("lightColor", unpack(lightColor))
	shader:send("lightPos", unpack(lightPos))
	if lightRequirements.simple > 0 or lightRequirements.point_shadow > 0 then
		shader:send("lightMeter", unpack(lightMeter))
	end
end

function lib:renderDeferredLight(lighting, lightRequirements, canvases, cam)
	local viewPos = {cam.pos:unpack()}
	local normal = {cam.normal:unpack()}
	
	love.graphics.setCanvas(canvases.color)
	love.graphics.setBlendMode("add")
	
	--batched point source, no shadow
	love.graphics.setShader(self.shaders.light)
	self.shaders.light:send("viewPos", viewPos)
	self.shaders.light:send("tex_normal", canvases.normal)
	self.shaders.light:send("tex_position", canvases.position)
	self.shaders.light:send("tex_material", canvases.material)
	
	local n = {0, 0, 0}
	local pos = { }
	local color = { }
	local meter = { }
	for i = 1, self.max_lights do
		color[i] = n
		pos[i] = n
		meter[i] = 0
	end
	
	local i = 0
	for d,s in ipairs(lighting) do
		if not s.shadow then
			i = i + 1
			
			color[i] = {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness}
			pos[i] = {s.x, s.y, s.z}
			meter[i] = s.meter
			
			if i == self.max_lights or d == #self.lighting then
				self.shaders.light:send("lightColor", unpack(color))
				self.shaders.light:send("lightPos", unpack(pos))
				self.shaders.light:send("lightMeter", unpack(meter))
				self.shaders.light:send("lightCount", i)
				love.graphics.draw(canvases.albedo)
				i = 0
			end
		end
	end
	
	--sun, with shadow
	love.graphics.setShader(self.shaders.shadow_sun)
	self.shaders.shadow_sun:send("viewPos", viewPos)
	self.shaders.shadow_sun:send("tex_normal", canvases.normal)
	self.shaders.shadow_sun:send("tex_position", canvases.position)
	self.shaders.shadow_sun:send("tex_material", canvases.material)
	
	self.shaders.shadow_sun:send("factor", self.shadow_factor)
	self.shaders.shadow_sun:send("shadowDistance", 2 / self.shadow_distance)
	self.shaders.shadow_sun:send("texelSize", 1.0 / self.shadow_resolution)
	
	for d,s in ipairs(lighting) do
		if s.shadow and s.shadow.typ == "sun" and s.shadow.canvases and s.shadow.canvases[3] then
			self.shaders.shadow_sun:send("transformProjShadow_1", s.shadow.transformation_1)
			self.shaders.shadow_sun:send("transformProjShadow_2", s.shadow.transformation_2)
			self.shaders.shadow_sun:send("transformProjShadow_3", s.shadow.transformation_3)
			self.shaders.shadow_sun:send("tex_shadow_1", s.shadow.canvases[1])
			self.shaders.shadow_sun:send("tex_shadow_2", s.shadow.canvases[2])
			self.shaders.shadow_sun:send("tex_shadow_3", s.shadow.canvases[3])
			
			self.shaders.shadow_sun:send("lightColor", {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness})
			self.shaders.shadow_sun:send("lightPos", {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z})
			love.graphics.draw(canvases.albedo)
		end
	end
	
	--point, with shadow
	if self.shadow_smooth then
		--smooth shadows
		canvases.shadow_temp = canvases.shadow_temp or love.graphics.newCanvas(math.floor(canvases.width * self.shadow_smooth_downScale), math.floor(canvases.height * self.shadow_smooth_downScale), {format = "r8", mipmaps = "manual"})
		
		--pre smoothing
		if self.shadow_smoother then
			canvases.shadow_temp_blur = canvases.shadow_temp_blur or love.graphics.newCanvas(math.floor(canvases.width * self.shadow_smooth_downScale), math.floor(canvases.height * self.shadow_smooth_downScale), {format = "r8", mipmaps = "none"})
		end
		
		for d,s in ipairs(lighting) do
			if s.shadow and s.shadow.typ == "point" and s.shadow.canvas then
				--render shadow
				love.graphics.setCanvas(canvases.shadow_temp)
				love.graphics.setBlendMode("replace")
				love.graphics.setShader(self.shaders.shadow_point_smooth_pre)
				self.shaders.shadow_point_smooth_pre:send("tex_position", canvases.position)
				self.shaders.shadow_point_smooth_pre:send("tex_shadow", s.shadow.canvas)
				self.shaders.shadow_point_smooth_pre:send("lightPos", {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z})
				love.graphics.draw(canvases.albedo, 0, 0, 0, self.shadow_smooth_downScale)
				love.graphics.setCanvas()
				
				--blur
				if self.shadow_smoother then
					love.graphics.setShader(self.shaders.blur_shadow)
					self.shaders.blur_shadow:send("tex_depth", canvases.normal)
					self.shaders.blur_shadow:send("size", s.shadow.size * 4.0)
					
					love.graphics.setCanvas(canvases.shadow_temp_blur)
					self.shaders.blur_shadow:send("dir", {2 / canvases.width / self.shadow_smooth_downScale, 0})
					love.graphics.draw(canvases.shadow_temp)
					
					love.graphics.setCanvas(canvases.shadow_temp)
					self.shaders.blur_shadow:send("dir", {0, 2 / canvases.height / self.shadow_smooth_downScale})
					love.graphics.draw(canvases.shadow_temp_blur)
					love.graphics.setCanvas()
				end
				canvases.shadow_temp:generateMipmaps()
				
				--lighten
				love.graphics.setCanvas(canvases.color)
				love.graphics.setBlendMode("add")
				love.graphics.setShader(self.shaders.shadow_point_smooth)
				self.shaders.shadow_point_smooth:send("viewPos", viewPos)
				self.shaders.shadow_point_smooth:send("tex_normal", canvases.normal)
				self.shaders.shadow_point_smooth:send("tex_position", canvases.position)
				self.shaders.shadow_point_smooth:send("tex_material", canvases.material)
				self.shaders.shadow_point_smooth:send("tex_shadow", canvases.shadow_temp)
				self.shaders.shadow_point_smooth:send("lightColor", {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness})
				self.shaders.shadow_point_smooth:send("lightPos", {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z})
				self.shaders.shadow_point_smooth:send("lightMeter", s.meter)
				self.shaders.shadow_point_smooth:send("size", s.shadow.size * 16.0)
				self.shaders.shadow_point_smooth:send("baseSize", self.shadow_smoother and 0.0 or (s.shadow.size * 4.0))
				love.graphics.draw(canvases.albedo)
			end
		end
	else
		love.graphics.setShader(self.shaders.shadow_point)
		self.shaders.shadow_point:send("viewPos", viewPos)
		self.shaders.shadow_point:send("tex_normal", canvases.normal)
		self.shaders.shadow_point:send("tex_position", canvases.position)
		self.shaders.shadow_point:send("tex_material", canvases.material)
		
		for d,s in ipairs(lighting) do
			if s.shadow and s.shadow.typ == "point" and s.shadow.canvas then
				self.shaders.shadow_point:send("tex_shadow", s.shadow.canvas)
				
				self.shaders.shadow_point:send("lightColor", {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness})
				self.shaders.shadow_point:send("lightPos", {s.shadow.lastPos.x, s.shadow.lastPos.y, s.shadow.lastPos.z})
				self.shaders.shadow_point:send("lightMeter", s.meter)
				
				love.graphics.draw(canvases.albedo)
			end
		end
	end
end