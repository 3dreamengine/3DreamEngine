--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

--rendering stats
lib.stats = {
	shadersInUse = 0,
	materialDraws = 0,
	draws = 0,
	averageFPS = 60,
}

local identityMatrix = mat4:getIdentity()

local sortPosition = vec3(0, 0, 0)
local function sortFunction(a, b)
	return (a.pos - sortPosition):lengthSquared() > (b.pos - sortPosition):lengthSquared()
end

--use the filled drawTable to build a scene
--a scene is a subset of the draw table, ordered and prepared for rendering
function lib:buildScene(cam)
	local scene = { }
	
	--add to scene
	for d,s in ipairs(self.drawTable) do
		local mat = s.s.material
		local dist = (s.pos - cam.pos):length()
		local LoD = s.s.LoD or s.obj.LoD
		local level = LoD and math.min(math.floor(dist / self.LoDDistance * 10)+1, 9)
		if not LoD or LoD[level] then
			if cam.noFrustumCheck or not self.frustumCheck or not s.s.boundingBox or self:inFrustum(cam, s.pos, s.s.boundingBox.size) then
				--group shader and materials together to reduce shader switches
				if not scene[s.s.shader] then
					scene[s.s.shader] = { }
				end
				if not scene[s.s.shader][mat] then
					scene[s.s.shader][mat] = { }
				end
				
				--add
				table.insert(scene[s.s.shader][mat], s)
				
				--reflections
				local reflection = s.s.reflection or s.obj.reflection
				if reflection then
					self.reflections[s.s.reflection or s.obj.reflection] = {
						dist = dist,
						obj = s.s.reflection and s.s or s.obj,
						pos = reflection.pos or s.pos,
					}
				end
			end
		end
	end
	
	--sort tables for materials requiring sorting
	--note that no sorting among same meshes occur, since alpha blending between identical objects do not matter anyways
	if self.alphaBlendMode == "alpha" then
		sortPosition = cam.pos
		for shader, shaderGroup in pairs(scene) do
			for material, materialGroup in pairs(shaderGroup) do
				table.sort(materialGroup, sortFunction)
			end
		end
	end
	
	return scene
end

--render the scene onto a canvas set using a specific view camera
function lib:render(scene, canvases, cam, pass, blacklist)
	self.delton:start("prepare")
	local deferred_lighting = canvases.deferred_lighting and pass == 1
	
	--love shader friendly
	local viewPos = {cam.pos:unpack()}
	local normal = {cam.normal:unpack()}
	
	--clear and set canvases
	love.graphics.push("all")
	love.graphics.reset()
	
	if pass == 2 and canvases.alphaBlendMode == "average" then
		--average blende mode
		love.graphics.setCanvas({canvases.color_pass2, canvases.data_pass2, self.refraction_enabled and canvases.normal_pass2 or nil})
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setCanvas({canvases.color_pass2, canvases.data_pass2, self.refraction_enabled and canvases.normal_pass2 or nil, depthstencil = canvases.depth_buffer})
	elseif deferred_lighting then
		--deferred lighting
		love.graphics.setCanvas({canvases.color, canvases.albedo, canvases.normal, canvases.position, canvases.material, depthstencil = canvases.depth_buffer})
		love.graphics.clear({0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 255, 0})
	else
		--classic forward rendering
		love.graphics.setCanvas({canvases.color, pass == 1 and canvases.depth or nil, depthstencil = canvases.depth_buffer})
		if pass == 1 then
			love.graphics.clear({0, 0, 0, 0}, {255, 0, 0, 0})
		end
	end
	
	--set correct blendmode
	if pass == 2 and canvases.alphaBlendMode == "average" then
		love.graphics.setBlendMode("add", "premultiplied")
	else
		love.graphics.setBlendMode("alpha")
	end
	
	--only first pass writes depth
	love.graphics.setDepthMode("less", pass == 1)
	
	--prepare lighting
	local lighting, lightRequirements = self:getLightOverview(cam, deferred_lighting)
	self.delton:stop()
	
	--final draw
	for shaderInfo, shaderGroup in pairs(scene) do
		self.delton:start("shader")
		local shader = self:getShader(shaderInfo, lightRequirements)
		
		--output settings
		love.graphics.setShader(shader)
		shader:send("deferred_lighting", deferred_lighting)
		shader:send("average_alpha", pass == 2 and canvases.alphaBlendMode == "average")
		shader:send("useAlphaDither", canvases.alphaBlendMode == "dither")
		shader:send("pass", canvases.alphaBlendMode == "disabled" and 0 or pass == 1 and -1 or 1)
		
		--lookup texture for PBR
		if shader:hasUniform("brdfLUT") then
			shader:send("brdfLUT", self.textures.brdfLUT)
		end
		
		--rain resources
		if shader:hasUniform("rain_splashes") then
			shader:send("rain_splashes", self.canvas_rain)
			shader:send("rain_tex_wetness", self.textures.wetness)
			shader:send("rain_wetness", self.rain_wetness)
		end
		
		--light if using forward lighting
		if not deferred_lighting and #lighting > 0 then
			self:sendLightUniforms(lighting, lightRequirements, shader, lighting)
		end
		
		--camera
		shader:send("transformProj", cam.transformProj)
		if shader:hasUniform("viewPos") then
			shader:send("viewPos", viewPos)
		end
		
		--for each material
		for material, materialGroup in pairs(shaderGroup) do
			self.delton:start("material")
			local tex = shaderInfo.arrayImage and self.textures_array or self.textures
			
			--ior
			if shader:hasUniform("ior") then
				shader:send("ior", 1.0 / material.ior)
			end
			
			--set material data dependend on shader
			if shaderInfo.shaderType == "color" then
				shader:send("emission", material.emission or 0.0)
				shader:send("glossiness", material.glossiness)
			elseif shaderInfo.shaderType == "color_lookup" then
				shader:send("tex_lookup", material.tex_lookup)
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
			
			--additional, shared resources
			if shaderInfo.shaderType == "PBR" or shaderInfo.shaderType == "Phong" then
				shader:send("tex_albedo", self:getTexture(material.tex_albedo) or tex.default)
				if shaderInfo.tex_normal then
					shader:send("tex_normal", self:getTexture(material.tex_normal) or tex.default_normal)
				end
				if shaderInfo.tex_emission then
					shader:send("tex_emission", self:getTexture(material.tex_emission) or tex.default)
				end
				shader:send("color_emission", material.emission or (shaderInfo.tex_emission and {5.0, 5.0, 5.0}) or {0.0, 0.0, 0.0})
			end
			
			--optional vertex shader information
			if shaderInfo.vertexShader == "wind" then
				shader:send("shader_wind_strength", material.shader_wind_strength or 1.0)
				shader:send("shader_wind_scale", material.shader_wind_scale or 1.0)
				shader:send("shader_wind", love.timer.getTime() * (material.shader_wind_speed or 1.0))
			end
			
			--culling
			love.graphics.setMeshCullMode(canvases.cullMode or material.cullMode or (material.alpha and self.refraction_disableCulling) and "none" or "back")
			
			--draw objects
			for _,task in pairs(materialGroup) do
				if not blacklist or not (blacklist[task.obj] or blacklist[task.s]) then
					self.delton:start("object")
					
					--sky texture
					if shaderInfo.reflection then
						local ref = task.s.reflection and task.s.reflection.canvas or task.obj.reflection and task.obj.reflection.canvas or self.canvas_sky
						shader:send("tex_background", ref or self.textures.sky_fallback)
						shader:send("reflections_levels", self.reflections_levels-1)
					else
						shader:send("ambient", self.sun_ambient)
					end
					
					--color
					if shader:hasUniform("color_albedo") then
						shader:send("color_albedo", (material.tex_albedo and {1.0, 1.0, 1.0, 1.0} or material.color and {material.color[1], material.color[2], material.color[3], material.color[4] or 1.0} or {1.0, 1.0, 1.0, 1.0}) * task.color)
					end
					
					--object transformation
					shader:send("transform", task.transform or identityMatrix)
					
					--render
					self.delton:start("draw")
					love.graphics.draw(task.s.mesh)
					self.delton:stop()
					
					self.stats.draws = self.stats.draws + 1
					self.delton:stop()
				end
			end
			self.stats.materialDraws = self.stats.materialDraws + 1
			self.delton:stop()
		end
		self.stats.shadersInUse = self.stats.shadersInUse + 1
		self.delton:stop()
	end
	love.graphics.setColor(1.0, 1.0, 1.0)
	
	--lighting
	self.delton:start("deffered")
	if deferred_lighting then
		self:renderDeferredLight(lighting, lightRequirements, canvases, cam)
	end
	self.delton:stop()
	
	--particles
	if pass ~= 2 then
		self.delton:start("particles")
		love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
		love.graphics.setDepthMode("less", false)
		love.graphics.setBlendMode("alpha")
		love.graphics.setShader(self.shaders.particle)
		
		table.sort(self.particles, function(a, b) return a[5] > b[5] end)
		
		local sz = (canvases.width + canvases.height) / 2
		
		for d,s in ipairs(self.particles) do
			local p = cam.transformProj * vec4(s[3], s[4], s[5], 1.0)
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
		self.delton:stop()
	end
	
	love.graphics.pop()
end

--only renders a depth variant
function lib:renderShadows(scene, cam, canvas, blacklist)
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setMeshCullMode("none")
	love.graphics.setDepthMode("less", true)
	love.graphics.setBlendMode("darken", "premultiplied")
	
	love.graphics.setCanvas(canvas)
	love.graphics.clear(255, 255, 255, 255)
	
	love.graphics.setShader(self.shaders.shadow)
	self.shaders.shadow:send("viewPos", {cam.pos:unpack()})
	self.shaders.shadow:send("transformProj", cam.transformProj)
	
	for shaderInfo, shaderGroup in pairs(scene) do
		for material, materialGroup in pairs(shaderGroup) do
			if (material.color[4] or 1.0) > 0.75 and material.shadow ~= false then
				for _,task in pairs(materialGroup) do
					if not blacklist or not (blacklist[task.obj] or blacklist[task.s]) then
						self.shaders.shadow:send("transform", task.transform or identityMatrix)
						love.graphics.draw(task.s.mesh)
					end
				end
			end
		end
	end
	
	love.graphics.pop()
end

--full render, including bloom, fxaa, exposure and gamma correction
function lib:renderFull(cam, canvases, noSky, blacklist)
	love.graphics.push("all")
	love.graphics.reset()
	
	--generate scene
	self.delton:start("scene")
	local scene = self:buildScene(cam, pass)
	self.delton:stop()
	
	--first pass
	self.delton:start("first")
	self:render(scene, canvases, cam, 1, blacklist)
	self.delton:stop()
	
	--second (alpha) pass
	self.delton:start("second")
	if canvases.alphaBlendMode == "average" or canvases.alphaBlendMode == "alpha" then
		self:render(scene, canvases, cam, 2, blacklist)
	end
	self.delton:stop()
	
	--weather
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
	love.graphics.setDepthMode("less", false)
	local t = self.textures["rain_" .. self.rain_strength]
	t:setWrap("repeat")
	self.object_rain.objects.Plane.mesh:setTexture(t)
	love.graphics.setShader(self.shaders.rain)
	
	local translate = vec3(math.floor(cam.pos.x), math.floor(cam.pos.y), math.floor(cam.pos.z))
	self.shaders.rain:send("time", love.timer.getTime() * 5.0)
	self.shaders.rain:send("transformProj", cam.transformProj)
	self.shaders.rain:send("transform", mat4:getIdentity():translate(translate))
	self.shaders.rain:send("rain", self.rain_rain)
	love.graphics.draw(self.object_rain.objects.Plane.mesh)
	
	--Ambient Occlusion (SSAO)
	if self.AO_enabled then
		love.graphics.setCanvas(canvases.AO_1)
		love.graphics.clear()
		love.graphics.setBlendMode("replace", "premultiplied")
		
		love.graphics.setShader(canvases.deferred_lighting and self.shaders.SSAO_def or self.shaders.SSAO)
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
		love.graphics.setCanvas(canvases.canvas_bloom_1)
		love.graphics.clear()
		love.graphics.setShader(self.shaders.bloom)
		self.shaders.bloom:send("strength", self.bloom_strength)
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.draw(canvases.color, 0, 0, 0, self.bloom_resolution)
		
		--blur
		love.graphics.setShader(self.shaders.blur)
		for i = 1, 0, -1 do
			local size = (self.bloom_size * self.bloom_resolution) * 5 ^ i
			
			self.shaders.blur:send("dir", {size / canvases.canvas_bloom_1:getWidth(), 0})
			love.graphics.setCanvas(canvases.canvas_bloom_2)
			love.graphics.clear()
			love.graphics.draw(canvases.canvas_bloom_1)
			
			self.shaders.blur:send("dir", {0, size / canvases.canvas_bloom_1:getHeight()})
			love.graphics.setCanvas(canvases.canvas_bloom_1)
			love.graphics.clear()
			love.graphics.draw(canvases.canvas_bloom_2)
		end
	end
	
	--SSR
	if self.SSR_enabled and canvases.deferred_lighting then
		love.graphics.setCanvas(canvases.canvas_SSR_1)
		love.graphics.setBlendMode("replace", "premultiplied")
		
		local shader = self:getSSRShader(canvases)
		love.graphics.setShader(shader)
		
		if shader:hasUniform("canvas_albedo") then shader:send("canvas_albedo", canvases.albedo) end
		if shader:hasUniform("canvas_normal") then shader:send("canvas_normal", canvases.normal) end
		if shader:hasUniform("canvas_position") then shader:send("canvas_position", canvases.position) end
		if shader:hasUniform("canvas_material") then shader:send("canvas_material", canvases.material) end
		
		if shader:hasUniform("canvas_bloom") then shader:send("canvas_bloom", canvases.canvas_bloom_1) end
		if shader:hasUniform("canvas_ao") then shader:send("canvas_ao", canvases.AO_1) end
		if shader:hasUniform("canvas_SSR") then shader:send("canvas_SSR", self.canvas_SSR) end
		
		if shader:hasUniform("transformInverse") then shader:send("transformInverse", cam.transformProj:invert()) end
		if shader:hasUniform("transform") then shader:send("transform", cam.transformProj) end
		if shader:hasUniform("viewPos") then shader:send("viewPos", cam.pos) end
		
		if shader:hasUniform("canvas_sky") then shader:send("canvas_sky", self.canvas_sky) end
		if shader:hasUniform("ambient") then shader:send("ambient", self.sun_ambient) end
		
		if shader:hasUniform("brdfLUT") then shader:send("brdfLUT", self.textures.brdfLUT) end
		
		love.graphics.draw(canvases.color, 0, 0, 0, self.SSR_resolution)
		
		--blur
		love.graphics.setShader(self.shaders.blur_SSR)
		self.shaders.blur_SSR:send("roughness", canvases.material)
		
		for i = 1, 0, -1 do
			local size = 5 ^ i
			
			love.graphics.setCanvas(canvases.canvas_SSR_2)
			self.shaders.blur_SSR:send("dir", {size / canvases.width / self.SSR_resolution, 0.0})
			love.graphics.draw(canvases.canvas_SSR_1)
			
			love.graphics.setCanvas(canvases.canvas_SSR_1)
			self.shaders.blur_SSR:send("dir", {0.0, size / canvases.height / self.SSR_resolution})
			love.graphics.draw(canvases.canvas_SSR_2)
		end
	end
	
	--final
	local shader = self:getFinalShader(canvases, noSky)
	love.graphics.pop()
	
	--render to final canvas instead
	if canvases.final then
		love.graphics.push("all")
		love.graphics.origin()
		love.graphics.setCanvas(canvases.final)
		love.graphics.clear()
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
	
	if shader:hasUniform("canvas_bloom") then shader:send("canvas_bloom", canvases.canvas_bloom_1) end
	if shader:hasUniform("canvas_ao") then shader:send("canvas_ao", canvases.AO_1) end
	if shader:hasUniform("canvas_SSR") then shader:send("canvas_SSR", canvases.canvas_SSR_1) end
	
	if shader:hasUniform("canvas_exposure") then shader:send("canvas_exposure", self.canvas_exposure_fetch) end
	
	if shader:hasUniform("transformInverse") then shader:send("transformInverse", cam.transformProj:invert()) end
	if shader:hasUniform("transformInverseSubM") then shader:send("transformInverseSubM", cam.transformProj:subm():invert()) end
	if shader:hasUniform("transform") then shader:send("transform", cam.transformProj) end
	if shader:hasUniform("viewNormal") then shader:send("viewNormal", cam.normal) end
	if shader:hasUniform("viewPos") then shader:send("viewPos", cam.pos) end
	
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

function lib:presentLite(noSky, cam, canvases)
	cam = cam or self.cam
	canvases = canvases or self.canvases
	self:renderFull(cam, canvases, noSky)
end

function lib:present(noSky, cam, canvases)
	self.delton:start("present")
	self.stats.shadersInUse = 0
	self.stats.materialDraws = 0
	self.stats.draws = 0
	self.stats.averageFPS = self.stats.averageFPS * 0.99 + love.timer.getFPS() * 0.01
	
	--result canvases
	canvases = canvases or self.canvases
	
	--extract camera position and normal
	cam = cam or self.cam
	cam.pos = cam.transform:invert() * vec3(0.0, 0.0, 0.0)
	cam.normal = (cam.pos - cam.transform:invert() * vec3(0.0, 0.0, 1.0)):normalize()
	
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
	cam.aspect = aspect
	
	--process render jobs
	self.delton:start("jobs")
	self:executeJobs(cam)
	self.delton:stop()
	
	--render
	self.delton:start("renderFull")
	self:renderFull(cam, canvases, noSky)
	self.delton:stop()
	self.delton:stop()
	
	--debug
	local brightness = {
		data_pass2 = 0.25,
	}
	if _DEBUGMODE and love.keyboard.isDown(",") then
		local w = 400
		local x = 0
		local y = 0
		local maxHeight = 0
		for d,s in pairs(canvases) do
			if type(s) == "userdata" and s:isReadable() then
				local b = brightness[d] or 1
				local h = w / s:getWidth() * s:getHeight()
				maxHeight = math.max(maxHeight, h)
				
				love.graphics.setColor(0, 0, 0)
				love.graphics.rectangle("fill", x * w, y, w, h)
				love.graphics.setShader(self.shaders.replaceAlpha)
				self.shaders.replaceAlpha:send("alpha", b)
				love.graphics.setBlendMode("add")
				love.graphics.draw(s, x * w, y, 0, w / s:getWidth())
				love.graphics.setShader()
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(1, 1, 1)
				love.graphics.print(d, x * w, y)
				
				x = x + 1
				if x * w + w >= love.graphics.getWidth() then
					x = 0
					y = y + maxHeight
					maxHeight = 0
				end
			end
		end
	end
	
	if _DEBUGMODE and love.keyboard.isDown(".") then
		self.delton:present()
	end
	self.delton:step()
end