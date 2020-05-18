--[[
#part of the 3DreamEngine by Luke100000
present.lua - final presentation of drawn objects, orders objects to decrease shader switches, handles light sources, ...
--]]

local lib = _3DreamEngine
lib.stats = {
	shadersInUse = 0,
	materialDraws = 0,
	draws = 0,
	averageFPS = 60,
}

function lib.render(self, canvases, transformProj, pass, viewPos, lookNormal, blacklist)
	local deferred_lighting = canvases.deferred_lighting and pass ~= 2
	viewPos = {viewPos.x, viewPos.y, viewPos.z}
	lookNormal = {lookNormal.x, lookNormal.y, lookNormal.z}
	
	--clear and set canvases
	love.graphics.push("all")
	love.graphics.reset()
	if pass == 2 then
		love.graphics.setCanvas({canvases.color_pass2, canvases.data_pass2, self.refraction_enabled and canvases.normal_pass2 or nil})
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setCanvas({canvases.color_pass2, canvases.data_pass2, self.refraction_enabled and canvases.normal_pass2 or nil, depthstencil = canvases.depth_buffer})
	else
		if deferred_lighting then
			love.graphics.setCanvas({canvases.color, canvases.albedo, canvases.normal, canvases.position, canvases.material, depthstencil = canvases.depth_buffer})
		else
			love.graphics.setCanvas({canvases.color, canvases.depth, depthstencil = canvases.depth_buffer})
		end
		love.graphics.clear(0, 0, 0, 0)
	end
	
	--set correct blendmode
	if pass == 2 then
		love.graphics.setBlendMode("add", "premultiplied")
	else
		love.graphics.setBlendMode("alpha")
	end
	love.graphics.setDepthMode("less", pass ~= 2)
	
	--prepare lighting
	local lighting
	local lightRequirements = {
		simple = 0,
		point_shadow = 0,
		sun_shadow = 0,
	}
	if deferred_lighting then
		lighting = self.lighting
		for d,s in ipairs(lighting) do
			s.active = true
		end
	else
		for d,s in ipairs(self.lighting) do
			s.active = false
			s.priority = s.brightness * (s.meter == 0 and 100.0 or 1.0) * (s.shadow and 2.0 or 1.0)
		end
		table.sort(self.lighting, function(a, b) return a.priority > b.priority end)
		
		lighting = { }
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
	end
	
	--fill light buffers if required
	local lightColor = { }
	local lightPos = { }
	local lightMeter = { }
	if not deferred_lighting then
		for i = 1, self.max_lights do
			lightColor[i] = {0, 0, 0}
			lightPos[i] = {0, 0, 0}
			lightMeter[i] = 0
		end
	end
	
	--final draw
	for shaderInfo,s in pairs(self.drawTable) do
		local shader = self:getShader(shaderInfo, not deferred_lighting and lightRequirements)
		love.graphics.setShader(shader)
		shader:send("deferred_lighting", deferred_lighting)
		shader:send("second_pass", pass == 2)
		
		if shader:hasUniform("brdfLUT") then
			shader:send("brdfLUT", self.textures.brdfLUT)
		end
		
		if shader:hasUniform("rain_splashes") then
			shader:send("rain_splashes", self.canvas_rain)
			shader:send("rain_tex_wetness", self.textures.wetness)
			shader:send("rain_wetness", self.rain_wetness)
		end
		
		--light if using forward lighting
		if not deferred_lighting and #lighting > 0 then
			if lightRequirements.simple > 0 then
				shader:send("lightCount", #lighting)
			end
			local count = 0
			
			for d,s in ipairs(lighting) do
				if s.shadow and s.shadow.typ == "sun" then
					local enable = 0.0
					if s.shadow.canvases then
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
			
			for d,s in ipairs(lighting) do
				if s.shadow and s.shadow.typ == "point" then
					local enable = 0.0
					if self.shadow_quality ~= "low" then
						shader:send("size_" .. count, s.shadow.size)
					end
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
			
			for d,s in ipairs(lighting) do
				if not s.shadow then
					count = count + 1
					
					lightColor[count] = {s.r * s.brightness, s.g * s.brightness, s.b * s.brightness}
					lightPos[count] = {s.x, s.y, s.z}
					lightMeter[count] = s.meter
				end
			end
			
			shader:send("lightColor", unpack(lightColor))
			shader:send("lightPos", unpack(lightPos))
			
			if lightRequirements.simple > 0 or lightRequirements.point_shadow > 0 then
				shader:send("lightMeter", unpack(lightMeter))
			end
		end
		
		--camera
		shader:send("transformProj", transformProj)
		if shader:hasUniform("viewPos") then
			shader:send("viewPos", viewPos)
		end
		
		if lightRequirements.sun_shadow > 0 then
			shader:send("factor", self.shadow_factor)
			shader:send("shadowDistance", self.shadow_distance / 2)
			shader:send("texelSize", 1.0 / self.shadow_resolution)
		end
		
		--for each material
		for material, tasks in pairs(s) do
			if pass == 3 or not material.alpha and pass == 1 or material.alpha and pass == 2 then
				local tex = shaderInfo.arrayImage and self.textures_array or self.textures
				
				--set textures
				if pass == 2 then
					shader:send("ior", 1.0 / material.ior)
				end
				
				if shaderInfo.shaderType == "color" then
					shader:send("emission", material.emission or 0.0)
					shader:send("glossiness", material.glossiness)
				elseif shaderInfo.shaderType == "color_extended" then
					
				elseif shaderInfo.shaderType == "color_material" then
					shader:send("tex_material", self:getTexture(material.tex_material) or self:getTexture("examples/3DreamCreator/materials/3Dmaterials/rock.png") or tex.default)
				elseif shaderInfo.shaderType == "PBR" then
					shader:send("tex_combined", self:getTexture(material.tex_combined) or tex.default)
					shader:send("color_combined", {material.tex_roughness and 1.0 or material.roughness or 0.5, material.tex_metallic and 1.0 or material.metallic or 0.5, 1.0})
				elseif shaderInfo.shaderType == "Phong" then
					shader:send("tex_combined", self:getTexture(material.tex_combined) or tex.default)
					shader:send("color_combined", {material.tex_glossiness and 1.0 or material.glossiness or 0.5, material.tex_specular and 1.0 or material.specular or 0.5, 1.0})
				end
				
				--shared resources
				if shaderInfo.shaderType == "PBR" or shaderInfo.shaderType == "Phong" then
					shader:send("tex_albedo", self:getTexture(material.tex_albedo) or tex.default)
					shader:send("color_albedo", material.tex_albedo and {1.0, 1.0, 1.0, 1.0} or material.color and {material.color[1], material.color[2], material.color[3], material.color[4] or 1.0} or {1.0, 1.0, 1.0, 1.0})
					
					if shaderInfo.tex_normal then
						shader:send("tex_normal", self:getTexture(material.tex_normal) or tex.default_normal)
					end
					
					if shaderInfo.tex_emission then
						shader:send("tex_emission", self:getTexture(material.tex_emission) or tex.default)
					end
					
					shader:send("color_emission", material.emission or (shaderInfo.tex_emission and {5.0, 5.0, 5.0}) or {0.0, 0.0, 0.0})
				end
				
				--draw objects
				for i,v in pairs(tasks) do
					if not blacklist or not blacklist[v[6]] then
						--sky texture
						if shaderInfo.reflection then
							local ref = v[6].reflection and v[6].reflection.canvas or self.canvas_sky
							shader:send("tex_background", ref)
							shader:send("reflections_levels", self.reflections_levels-1)
						else
							shader:send("ambient", self.sun_ambient)
						end
						
						--update mesh data if required
						if material.update then
							material:update(v[2], v[6])
						end
						
						--optional vertex shader information
						if shaderInfo.vertexShader == "wind" then
							shader:send("shader_wind_strength", material.shader_wind_strength or 1.0)
							shader:send("shader_wind_scale", material.shader_wind_scale or 1.0)
							shader:send("shader_wind", love.timer.getTime() * (material.shader_wind_speed or 1.0))
						end
						
						shader:send("transform", v[1])
						
						love.graphics.setMeshCullMode(canvases.cullMode or material.cullMode or (material.alpha and self.refraction_disableCulling) and "none" or "back")
						love.graphics.setColor(v[3], v[4], v[5])
						love.graphics.draw(v[2].mesh)
						
						self.stats.draws = self.stats.draws + 1
					end
				end
				self.stats.materialDraws = self.stats.materialDraws + 1
			end
		end
		self.stats.shadersInUse = self.stats.shadersInUse + 1
	end
	love.graphics.setColor(1.0, 1.0, 1.0)
	
	--lighting
	if deferred_lighting then
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
		self.shaders.shadow_sun:send("shadowDistance", self.shadow_distance / 2)
		self.shaders.shadow_sun:send("texelSize", 1.0 / self.shadow_resolution)
		
		for d,s in ipairs(lighting) do
			if s.shadow and s.shadow.typ == "sun" and s.shadow.canvases then
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
					
					if self.shadow_quality ~= "low" then
						self.shaders.shadow_point:send("size", s.shadow.size)
					end
					love.graphics.draw(canvases.albedo)
				end
			end
		end
	end
	
	
	--particles
	if pass ~= 2 then
		love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
		love.graphics.setDepthMode("less", false)
		love.graphics.setBlendMode("alpha")
		love.graphics.setShader(self.shaders.particle)
		
		table.sort(self.particles, function(a, b) return a[5] > b[5] end)
		
		local sz = (canvases.width + canvases.height) / 2
		
		for d,s in ipairs(self.particles) do
			local p = transformProj * vec4(s[3], s[4], s[5], 1.0)
			if p[3] > 0 then
				p[1] = p[1] / p[4]
				p[2] = p[2] / p[4]
				
				self.shaders.particle:send("depth", p[3] / p[4])
				self.shaders.particle:send("emission", s[8])
				self.shaders.particle:send("tex_emission", s[9] or s[1])
				
				p[3] = p[3] + self.cam.near
				if s[2] then
					local _, _, w, h = s[2]:getViewport()
					love.graphics.draw(s[1], s[2], (p[1]+1)*canvases.width/2, (p[2]+1)*canvases.height/2, s[7], s[6] * sz / p[3], s[6] * sz / p[3], w/2, h/2)
				else
					love.graphics.draw(s[1], (p[1]+1)*canvases.width/2, (p[2]+1)*canvases.height/2, s[7], s[6] * sz / p[3], s[6] * sz / p[3], s[1]:getWidth()/2, s[1]:getHeight()/2)
				end
			end
		end
		
		love.graphics.setDepthMode()
	end
	
	love.graphics.pop()
end

--sky
function lib.renderSky(self, transformProj, viewPos)
	if self.sky_enabled then
		love.graphics.push("all")
		love.graphics.setDepthMode()
		love.graphics.setShader(self.shaders.sky)
		self.shaders.sky:send("cam", transformProj)
		self.shaders.sky:send("transform", mat4:getIdentity():translate(unpack(viewPos)))
		self.shaders.sky:send("sky", self.canvas_sky)
		love.graphics.draw(self.object_skybox.objects.Cube.mesh)
		love.graphics.pop()
	end
end

--full render, including bloom, fxaa, exposure and gamma correction
function lib.renderFull(self, transformProj, canvases, noSky, viewPos, normal, blacklist)
	love.graphics.push("all")
	love.graphics.reset()
	
	--first pass
	self:render(canvases, transformProj, canvases.secondPass and 1 or 3, viewPos, normal, blacklist)
	
	--second pass
	if canvases.secondPass then
		self:render(canvases, transformProj, 2, viewPos, normal, blacklist)
	end
	
	--Ambient Occlusion (SSAO)
	if self.AO_enabled then
		love.graphics.setCanvas(canvases.AO_1)
		love.graphics.clear()
		love.graphics.setBlendMode("replace", "premultiplied")
		
		love.graphics.setShader(canvases.deferred_lighting and self.shaders.SSAO_normal or self.shaders.SSAO)
		love.graphics.draw(canvases.deferred_lighting and canvases.material or canvases.depth, 0, 0, 0, self.AO_resolution)
		
		--blur
		love.graphics.setShader(self.shaders.blur)
		
		self.shaders.blur:send("dir", {1.0 / canvases.AO_1:getWidth(), 0.0})
		love.graphics.setCanvas(canvases.AO_2)
		love.graphics.clear()
		love.graphics.draw(canvases.AO_1)
		
		self.shaders.blur:send("dir", {0.0, 1.0 / canvases.AO_1:getHeight()})
		love.graphics.setCanvas(canvases.AO_1)
		love.graphics.clear()
		love.graphics.draw(canvases.AO_2)
	end
	
	--bloom
	if canvases.postEffects_enabled and self.bloom_enabled then
		--down sample
		love.graphics.setCanvas(self.canvas_bloom_1)
		love.graphics.clear()
		love.graphics.setShader(self.shaders.bloom)
		self.shaders.bloom:send("strength", self.bloom_strength)
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.draw(canvases.color, 0, 0, 0, self.bloom_resolution)
		
		--blur
		love.graphics.setShader(self.shaders.blur)
		for i = 1, 0, -1 do
			local size = (self.bloom_size * self.bloom_resolution) * 5 ^ i
			
			self.shaders.blur:send("dir", {size / self.canvas_bloom_1:getWidth(), 0})
			love.graphics.setCanvas(self.canvas_bloom_2)
			love.graphics.clear()
			love.graphics.draw(self.canvas_bloom_1)
			
			self.shaders.blur:send("dir", {0, size / self.canvas_bloom_1:getHeight()})
			love.graphics.setCanvas(self.canvas_bloom_1)
			love.graphics.clear()
			love.graphics.draw(self.canvas_bloom_2)
		end
	end
	
	--SSR
	if self.SSR_enabled and canvases.deferred_lighting then
		love.graphics.setCanvas(self.canvas_SSR_1)
		love.graphics.setBlendMode("replace", "premultiplied")
		
		local shader = self:getSSRShader(canvases)
		love.graphics.setShader(shader)
		
		if shader:hasUniform("canvas_albedo") then shader:send("canvas_albedo", canvases.albedo) end
		if shader:hasUniform("canvas_normal") then shader:send("canvas_normal", canvases.normal) end
		if shader:hasUniform("canvas_position") then shader:send("canvas_position", canvases.position) end
		if shader:hasUniform("canvas_material") then shader:send("canvas_material", canvases.material) end
		
		if shader:hasUniform("canvas_bloom") then shader:send("canvas_bloom", self.canvas_bloom_1) end
		if shader:hasUniform("canvas_ao") then shader:send("canvas_ao", canvases.AO_1) end
		if shader:hasUniform("canvas_SSR") then shader:send("canvas_SSR", self.canvas_SSR) end
		
		if shader:hasUniform("transformInverse") then shader:send("transformInverse", transformProj:invert()) end
		if shader:hasUniform("transform") then shader:send("transform", transformProj) end
		if shader:hasUniform("viewPos") then shader:send("viewPos", viewPos) end
		
		if shader:hasUniform("canvas_sky") then shader:send("canvas_sky", self.canvas_sky) end
		if shader:hasUniform("ambient") then shader:send("ambient", self.sun_ambient) end
		
		if shader:hasUniform("brdfLUT") then shader:send("brdfLUT", self.textures.brdfLUT) end
		
		love.graphics.draw(canvases.color, 0, 0, 0, self.SSR_resolution)
		
		--blur
		love.graphics.setShader(self.shaders.blur_SSR)
		self.shaders.blur_SSR:send("roughness", canvases.material)
		
		for i = 1, 0, -1 do
			local size = 5 ^ i
			
			love.graphics.setCanvas(self.canvas_SSR_2)
			self.shaders.blur_SSR:send("dir", {size / canvases.width / self.SSR_resolution, 0.0})
			love.graphics.draw(self.canvas_SSR_1)
			
			love.graphics.setCanvas(self.canvas_SSR_1)
			self.shaders.blur_SSR:send("dir", {0.0, size / canvases.height / self.SSR_resolution})
			love.graphics.draw(self.canvas_SSR_2)
		end
	end
	
	--weather
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
	love.graphics.setDepthMode("less", false)
	local t = self.textures["rain_" .. self.rain_strength]
	t:setWrap("repeat")
	self.object_rain.objects.Plane.mesh:setTexture(t)
	love.graphics.setShader(self.shaders.rain)
	
	local translate = vec3(math.floor(viewPos.x), math.floor(viewPos.y), math.floor(viewPos.z))
	
	self.shaders.rain:send("time", love.timer.getTime() * 5.0)
	self.shaders.rain:send("transformProj", transformProj)
	self.shaders.rain:send("transform", mat4:getIdentity():translate(translate))
	self.shaders.rain:send("rain", self.rain_rain)
	love.graphics.draw(self.object_rain.objects.Plane.mesh)
	
	
	--final
	local shader = self:getFinalShader(canvases, noSky)
	love.graphics.pop()
	
	--render to final canvas instead
	if canvases.final then
		love.graphics.push("all")
		love.graphics.origin()
		love.graphics.setCanvas(canvases.final)
	end
	
	love.graphics.setShader(shader)
	
	if shader:hasUniform("canvas_color_pass2") then shader:send("canvas_color_pass2", canvases.color_pass2) end
	if shader:hasUniform("canvas_albedo") then shader:send("canvas_albedo", canvases.albedo) end
	if shader:hasUniform("canvas_normal") then shader:send("canvas_normal", canvases.normal) end
	if shader:hasUniform("canvas_normal_pass2") then shader:send("canvas_normal_pass2", canvases.normal_pass2) end
	if shader:hasUniform("canvas_position") then shader:send("canvas_position", canvases.position) end
	if shader:hasUniform("canvas_depth") then shader:send("canvas_depth", canvases.depth) end
	if shader:hasUniform("canvas_data_pass2") then shader:send("canvas_data_pass2", canvases.data_pass2) end
	if shader:hasUniform("canvas_material") then shader:send("canvas_material", canvases.material) end
	
	if shader:hasUniform("canvas_bloom") then shader:send("canvas_bloom", self.canvas_bloom_1) end
	if shader:hasUniform("canvas_ao") then shader:send("canvas_ao", canvases.AO_1) end
	if shader:hasUniform("canvas_SSR") then shader:send("canvas_SSR", self.canvas_SSR_1) end
	
	if shader:hasUniform("canvas_exposure") then shader:send("canvas_exposure", self.canvas_exposure_fetch) end
	
	if shader:hasUniform("transformInverse") then shader:send("transformInverse", transformProj:invert()) end
	if shader:hasUniform("transform") then shader:send("transform", transformProj) end
	if shader:hasUniform("lookNormal") then shader:send("lookNormal", normal) end
	if shader:hasUniform("viewPos") then shader:send("viewPos", viewPos) end
	
	if shader:hasUniform("canvas_sky") then shader:send("canvas_sky", self.canvas_sky) end
	if shader:hasUniform("ambient") then shader:send("ambient", self.sun_ambient) end
	
	if shader:hasUniform("gamma") then shader:send("gamma", self.gamma) end
	if shader:hasUniform("exposure") then shader:send("exposure", self.exposure) end
	
	if shader:hasUniform("time") then shader:send("time", love.timer.getTime()) end
	
	if shader:hasUniform("fog_baseline") then shader:send("fog_baseline", self.fog_baseline) end
	if shader:hasUniform("fog_height") then shader:send("fog_height", 1 / self.fog_height) end
	if shader:hasUniform("fog_density") then shader:send("fog_density", self.fog_density) end
	if shader:hasUniform("fog_color") then shader:send("fog_color", self.fog_color) end
	
	love.graphics.draw(canvases.color)
	love.graphics.setShader()
	
	if canvases.final then
		love.graphics.pop()
		if not self.renderToFinalCanvas then
			love.graphics.draw(canvases.final)
		end
	end
end

function lib.presentLite(self, noSky, c, canvases)
	local cam = c or self.cam
	canvases = canvases or self.canvases
	self:renderFull(cam.transformProj, canvases, noSky, cam.viewPos, cam.normal)
end

function lib.present(self, noSky, c, canvases)
	self.stats.shadersInUse = 0
	self.stats.materialDraws = 0
	self.stats.draws = 0
	self.stats.averageFPS = self.stats.averageFPS * 0.99 + love.timer.getFPS() * 0.01
	
	canvases = canvases or self.canvases
	
	--prepare view
	local cam = c or self.cam
	
	--extract camera position and normal
	cam.viewPos = cam.transform:invert() * vec3(0.0, 0.0, 0.0)
	cam.normal = (cam.viewPos - cam.transform:invert() * vec3(0.0, 0.0, 1.0)):normalize()
	
	--perspective transform
	local n = cam.near
	local f = cam.far
	local fov = cam.fov
	local scale = math.tan(fov/2*math.pi/180)
	local aspect = canvases.width / canvases.height
	local r = aspect * scale * n
	local l = -r
	local t = scale * n
	local b = -t
	local projection = mat4(
		2*n / (r-l),   0,              (r+l) / (r-l),     0,
		0,             -2*n / (t - b),  (t+b) / (t-b),     0,
		0,             0,              -(f+n) / (f-n),    -2*f*n / (f-n),
		0,             0,              -1,                0
	)
	
	--camera transformation
	cam.transformProj = projection * cam.transform
	
	--process render jobs
	self:executeJobs(cam)
	
	--render
	self:renderFull(cam.transformProj, canvases, noSky, cam.viewPos, cam.normal)
	
	--debug
	local brightness = {
		data_pass2 = 0.25,
	}
	if love.keyboard.isDown(",") then
		local w = 400
		local x = 0
		local y = 0
		for d,s in pairs(canvases) do
			if type(s) == "userdata" and s:isReadable() then
				local b = brightness[d] or 1
				love.graphics.setColor(0, 0, 0)
				love.graphics.rectangle("fill", x * w, y * w, w, w / s:getWidth() * s:getHeight())
				love.graphics.setShader(self.shaders.replaceAlpha)
				self.shaders.replaceAlpha:send("alpha", b)
				love.graphics.setBlendMode("add")
				love.graphics.draw(s, x * w, y * w, 0, w / s:getWidth())
				love.graphics.setShader()
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(1, 1, 1)
				love.graphics.print(d, x * w, y * w)
				
				x = x + 1
				if x * w + w >= love.graphics.getWidth() then
					x = 0
					y = y + 1
				end
			end
		end
	end
end