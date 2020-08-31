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

local sortPosition = vec3(0, 0, 0)
local function sortFunction(a, b)
	return (a.pos - sortPosition):lengthSquared() > (b.pos - sortPosition):lengthSquared()
end

--use the filled drawTable to build a scene
--a scene is a subset of the draw table, ordered and prepared for rendering
--pass can be 0 (include all), 1 (includes solid or semi transparent materials), 2 (include semi and full transparent materials)
function lib:buildScene(cam, pass, blacklist)
	local scene = { }
	local noFrustumCheck = cam.noFrustumCheck or not self.frustumCheck
	
	--add to scene
	for d,task in ipairs(self.drawTable) do
		if not blacklist or not (blacklist[task.obj] or blacklist[task.s]) then
			local mat = task.s.material
			local alpha = mat.alpha or 0
			if pass == 0 or pass == 1 and alpha ~= 2 or pass == 2 and alpha ~= 0 then
				local dist = (task.pos - cam.pos):length()
				local LoD = task.s.LoD or task.obj.LoD
				if not LoD or LoD[ math.min(math.floor(dist / self.LoDDistance * 10)+1, 9) ] then
					if noFrustumCheck or not task.s.boundingBox or self:inFrustum(cam, task.pos, task.s.boundingBox.size) then
						--group shader and materials together to reduce shader switches
						if not scene[task.s.shader] then
							scene[task.s.shader] = { }
						end
						if not scene[task.s.shader][mat] then
							scene[task.s.shader][mat] = { }
						end
						
						--add
						table.insert(scene[task.s.shader][mat], task)
						
						--reflections
						local reflection = task.s.reflection or task.obj.reflection
						if reflection and reflection.canvas then
							self.reflections[task.s.reflection or task.obj.reflection] = {
								dist = dist,
								obj = task.s.reflection and task.s or task.obj,
								pos = reflection.pos or task.pos,
							}
						end
					end
				end
			end
		end
	end
	
	--sort tables for materials requiring sorting
	if self.alphaBlendMode == "alpha" and pass ~= 1 then
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
function lib:render(scene, canvases, cam, pass, noSky)
	self.delton:start("prepare")
	
	--love shader friendly
	local viewPos = {cam.pos:unpack()}
	
	--clear and set canvases
	love.graphics.push("all")
	love.graphics.reset()
	
	if pass == 2 and canvases.alphaBlendMode == "average" then
		--average blende mode
		love.graphics.setCanvas({canvases.color_pass2, canvases.data_pass2, self.refraction_enabled and canvases.normal_pass2 or nil})
		love.graphics.clear(0, 0, 0, 0)
		love.graphics.setCanvas({canvases.color_pass2, canvases.data_pass2, self.refraction_enabled and canvases.normal_pass2 or nil, depthstencil = canvases.depth_buffer})
	else
		--classic forward rendering
		if pass == 2 then
			love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
		else
			--clear depth canvas
			if noSky then
				love.graphics.setCanvas({canvases.color, canvases.depth, depthstencil = canvases.depth_buffer})
				love.graphics.clear({0, 0, 0, 0}, {255, 0, 0, 0})
			else
				love.graphics.setCanvas({canvases.depth, depthstencil = canvases.depth_buffer})
				love.graphics.clear(255, 0, 0, 0)
			end
			
			--render sky
			if not noSky then
				love.graphics.setCanvas(canvases.color)
				self:renderSky(cam.transformProjOrigin)
			end
			
			--set canvas
			love.graphics.setCanvas({canvases.color, pass == 1 and canvases.depth or nil, depthstencil = canvases.depth_buffer})
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
	local lighting, lightRequirements = self:getLightOverview(cam)
	self.delton:stop()
	
	--final draw
	for shaderInfo, shaderGroup in pairs(scene) do
		self.delton:start("shader")
		local shader = self:getShader(shaderInfo, lighting, lightRequirements)
		
		--output settings
		love.graphics.setShader(shader)
		shader:send("average_alpha", pass == 2 and canvases.alphaBlendMode == "average")
		shader:send("useAlphaDither", canvases.alphaBlendMode == "dither")
		shader:send("pass", canvases.alphaBlendMode == "disabled" and 0 or pass == 1 and -1 or 1)
		
		--shader
		local shaderEntry = self.shaderLibrary.base[shaderInfo.shaderType]
		local vertexEntry = self.shaderLibrary.vertex[shaderInfo.vertexShader]
		shaderEntry:perShader(self, shader, shaderInfo)
		vertexEntry:perShader(self, shader, shaderInfo)
		for d,s in pairs(shaderInfo.modules) do
			s:perShader(self, shader, shaderInfo)
		end
		
		--light if using forward lighting
		if #lighting > 0 then
			self:sendLightUniforms(lighting, lightRequirements, shader)
		end
		
		--camera
		shader:send("transformProj", cam.transformProj)
		if shader:hasUniform("viewPos") then
			shader:send("viewPos", viewPos)
		end
		
		if not shaderInfo.reflection then
			shader:send("ambient", self.sun_ambient)
		end
		
		--for each material
		for material, materialGroup in pairs(shaderGroup) do
			self.delton:start("material")
			
			--ior
			if shader:hasUniform("ior") then
				shader:send("ior", 1.0 / material.ior)
			end
			
			--shader
			shaderEntry:perMaterial(self, shader, shaderInfo, material)
			vertexEntry:perMaterial(self, shader, shaderInfo, material)
			for d,s in pairs(shaderInfo.modules) do
				s:perMaterial(self, shader, shaderInfo, material)
			end
			
			--culling
			love.graphics.setMeshCullMode(canvases.cullMode or material.cullMode or (material.alpha and self.refraction_disableCulling) and "none" or "back")
			
			--draw objects
			for _,task in pairs(materialGroup) do
				--sky texture
				if shaderInfo.reflection then
					local ref = task.s.reflection or task.obj.reflection or self.defaultReflection
					local tex = ref.image or ref.canvas
					assert(tex, "invalid reflection, make sure to use dream:newReflection()")
					
					shader:send("tex_background", tex)
					shader:send("reflections_levels", (ref.levels or self.reflections_levels) - 1)
					
					--box for local cubemaps
					if ref.first then
						shader:send("reflections_enabled", true)
						shader:send("reflections_pos", ref.pos)
						shader:send("reflections_first", ref.first)
						shader:send("reflections_second", ref.second)
					else
						shader:send("reflections_enabled", false)
					end
				end
				
				--object transformation
				shader:send("transform", task.transform)
				
				--shader
				shaderEntry:perObject(self, shader, shaderInfo, task)
				vertexEntry:perObject(self, shader, shaderInfo, task)
				for d,s in pairs(shaderInfo.modules) do
					s:perObject(self, shader, shaderInfo, task)
				end
				
				--render
				love.graphics.setColor(task.color)
				love.graphics.draw(task.s.mesh)
				
				self.stats.draws = self.stats.draws + 1
			end
			self.stats.materialDraws = self.stats.materialDraws + 1
			self.delton:stop()
		end
		self.stats.shadersInUse = self.stats.shadersInUse + 1
		self.delton:stop()
	end
	love.graphics.setColor(1.0, 1.0, 1.0)
	
	--particles
	if self.particlePresence[pass] then
		self.delton:start("particles")
		love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
		love.graphics.setDepthMode("less", false)
		love.graphics.setBlendMode("alpha")
		
		love.graphics.setShader(self.shaders.particle)
		self.shaders.particle:send("transform", cam.transformProj)
		
		for d,s in pairs(self.particles) do
			if d.pass == pass or pass == 0 then
				local right, up
				if self.vertical then
					up = vec3(0, 1, 0)
					right = vec3(right.x, 0, right.z):normalize()
				else
					right = vec3(cam.transform[1], cam.transform[2], cam.transform[3])
					up = vec3(cam.transform[5], cam.transform[6], cam.transform[7])
				end
				
				self.shaders.particle:send("up", {up:unpack()})
				self.shaders.particle:send("right", {right:unpack()})
				d:present(cam.pos)
			end
		end
		
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
						self.shaders.shadow:send("transform", task.transform)
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
	
	local secondPass = canvases.alphaBlendMode == "average" or canvases.alphaBlendMode == "alpha"
	
	--first pass
	self.delton:start("first")
	
	--generate scene
	self.delton:start("scene")
	local scene = self:buildScene(cam, secondPass and 1 or 0, blacklist)
	self.delton:stop()
	
	self:render(scene, canvases, cam, 1, noSky)
	self.delton:stop()
	
	--second (alpha) pass
	self.delton:start("second")
	if secondPass then
		self.delton:start("scene")
		local scene = self:buildScene(cam, 2, blacklist)
		self.delton:stop()
		
		self:render(scene, canvases, cam, 2)
	end
	self.delton:stop()
	
	--Ambient Occlusion (SSAO)
	if self.AO_enabled then
		love.graphics.setCanvas(canvases.AO_1)
		love.graphics.clear()
		love.graphics.setBlendMode("replace", "premultiplied")
		
		love.graphics.setShader(self.shaders.SSAO)
		love.graphics.draw(canvases.depth, 0, 0, 0, self.AO_resolution)
		
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
	
	--additional render instructions
	self.delton:start("modules")
	for d,s in pairs(self.allActiveShaderModules) do
		if s.render then
			s:render(self, cam, canvases, scene, noSky)
		end
	end
	self.delton:stop()
	
	--final
	local shader = self:getFinalShader(canvases)
	love.graphics.pop()
	
	love.graphics.setShader(shader)
	
	if shader:hasUniform("canvas_color_pass2") then shader:send("canvas_color_pass2", canvases.color_pass2) end
	if shader:hasUniform("canvas_data_pass2") then shader:send("canvas_data_pass2", canvases.data_pass2) end
	if shader:hasUniform("canvas_normal_pass2") then shader:send("canvas_normal_pass2", canvases.normal_pass2) end
	
	if shader:hasUniform("canvas_depth") then shader:send("canvas_depth", canvases.depth) end
	
	if shader:hasUniform("canvas_bloom") then shader:send("canvas_bloom", canvases.canvas_bloom_1) end
	if shader:hasUniform("canvas_ao") then shader:send("canvas_ao", canvases.AO_1) end
	if shader:hasUniform("canvas_SSR") then shader:send("canvas_SSR", canvases.canvas_SSR_1) end
	
	if shader:hasUniform("canvas_exposure") then shader:send("canvas_exposure", self.canvas_exposure_fetch) end
	
	if shader:hasUniform("transform") then shader:send("transform", cam.transformProj) end
	if shader:hasUniform("viewNormal") then shader:send("viewNormal", cam.normal) end
	if shader:hasUniform("viewPos") then shader:send("viewPos", cam.pos) end
	
	if shader:hasUniform("gamma") then shader:send("gamma", self.gamma) end
	if shader:hasUniform("exposure") then shader:send("exposure", self.exposure) end
	
	if shader:hasUniform("fog_distance") then
		shader:send("fog_distance", self.fog_distance)
		shader:send("fog_density", self.fog_density)
		shader:send("fog_color", self.fog_color)
	end
	
	love.graphics.draw(canvases.color)
	love.graphics.setShader()
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
	local m = cam.transform
	cam.transformProjOrigin = projection * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)
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
	
	self.delton:step()
	if _DEBUGMODE and love.keyboard.isDown(".") then
		self.delton:present()
	end
end