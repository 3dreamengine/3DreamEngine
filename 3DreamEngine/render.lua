--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

--rendering stats
lib.stats = {
	shadersInUse = 0,
	materialDraws = 0,
	draws = 0,
}

local sortPosition = vec3(0, 0, 0)
local function sortFunction(a, b)
	return (a.pos - sortPosition):lengthSquared() > (b.pos - sortPosition):lengthSquared()
end

--use the filled drawTable to build a scene
--a scene is a subset of the draw table, ordered and prepared for rendering
--typ is the scene typ and may be 'render', 'shadows' or 'reflections'
function lib:buildScene(cam, typ, blacklist)
	local sceneSolid = { }
	local sceneAlpha = typ ~= "shadows" and { } or false
	local noFrustumCheck = cam.noFrustumCheck or not self.frustumCheck
	
	--add to scene
	local LoDFactor = 10 / self.LoDDistance
	for sc,_ in pairs(self.scenes) do
		for _,task in ipairs(sc.tasks) do
			if not blacklist or not (blacklist[task.obj] or blacklist[task.s]) then
				local LoD = task.s.LoD or task.obj.LoD
				if not LoD or LoD[math.min( math.floor((task.pos - cam.pos):length() * LoDFactor)+1, 9 )] then
					if noFrustumCheck or not task.s.boundingBox or self:inFrustum(cam, task.pos, task.s.boundingBox.size) then
						local mat = task.s.material
						local scene = mat.alpha and sceneAlpha or sceneSolid
						if scene then
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
							if typ == "render" then
								local reflection = task.s.reflection or task.obj.reflection
								if reflection and reflection.canvas then
									self.reflections[task.s.reflection or task.obj.reflection] = {
										dist = (task.pos - cam.pos):length(),
										obj = task.s.reflection and task.s or task.obj,
										pos = reflection.pos or task.pos,
									}
								end
							end
						end
					end
				end
			end
		end
	end
	
	--sort tables for materials requiring sorting
	if sceneAlpha then
		sortPosition = cam.pos
		for shader, shaderGroup in pairs(sceneAlpha) do
			for material, materialGroup in pairs(shaderGroup) do
				table.sort(materialGroup, sortFunction)
			end
		end
	end
	
	return sceneSolid, sceneAlpha
end

--render the scene onto a canvas set using a specific view camera
function lib:render(sceneSolid, sceneAlpha, canvases, cam, noSky)
	self.delton:start("prepare")
	
	--love shader friendly
	local viewPos = {cam.pos:unpack()}
	
	--clear and set canvases
	love.graphics.push("all")
	if not canvases.direct then
		love.graphics.reset()
	end
	
	if canvases.direct then
		if not noSky then
			self:renderSky(cam.transformProjOrigin)
		end
	else
		if noSky then
			love.graphics.setCanvas(canvases.color)
			love.graphics.clear()
		else
			--render sky
			love.graphics.setCanvas(canvases.color)
			self:renderSky(cam.transformProjOrigin)
		end
	end
	
	--clear
	if not canvases.direct then
		love.graphics.setCanvas({canvases.depth, depthstencil = canvases.depth_buffer})
		love.graphics.clear(255, 255, 255)
		if canvases.deferred and pass == 1 then
			love.graphics.setCanvas({canvases.position, canvases.normaö, canvases.material, canvases.albedo})
			love.graphics.clear()
		end
	end
	
	--prepare lighting
	local lighting, lightRequirements = self:getLightOverview(cam, canvases.deferred)
	self.delton:stop()
	
	--start both passes
	for pass = 1, 2 do
		local scene = pass == 1 and sceneSolid or sceneAlpha
		local noLight = canvases.deferred and pass == 1 or #lighting == 0
		
		--only first pass writes depth
		love.graphics.setDepthMode("less", pass == 1)
		love.graphics.setBlendMode("alpha")
		
		--set canvases
		if not canvases.direct then
			if canvases.deferred and pass == 1 then
				love.graphics.setCanvas({canvases.color, canvases.depth, canvases.position, canvases.normal, canvases.material, canvases.albedo, depthstencil = canvases.depth_buffer})
			else
				love.graphics.setCanvas({canvases.color, canvases.depth, depthstencil = canvases.depth_buffer})
			end
		end
		
		--final draw
		for shaderInfo, shaderGroup in pairs(scene) do
			self.delton:start("shader")
			local shader = noLight and self:getShader(shaderInfo, false) or self:getShader(shaderInfo, lighting, lightRequirements)
			
			--output settings
			love.graphics.setShader(shader)
			shader:send("ditherAlpha", pass == 1)
			
			--shader
			local shaderEntry = self.shaderLibrary.base[shaderInfo.shaderType]
			shaderEntry:perShader(self, shader, shaderInfo)
			for d,s in pairs(shaderInfo.modules) do
				s:perShader(self, shader, shaderInfo)
			end
			
			--light if using forward lighting
			if not noLight then
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
		
		--light
		if canvases.deferred and pass == 1 then
			local types = { }
			local batches = { }
			for _,s in ipairs(self.lighting) do
				s.active = true
				
				local typ = s.typ .. "_" .. (s.shadow and "shadow" or "simple")
				types[typ] = (types[typ] or 0) + 1
				
				local dat = dream.shaderLibrary.light[typ]
				local b = batches[#batches]
				if not b or b.typ ~= typ or #b >= (dat.batchable and self.max_lights or 1) then
					batches[#batches+1] = {typ = typ}
				end
				
				table.insert(batches[#batches], s)
			end
			
			--render light batches
			love.graphics.setCanvas(canvases.color)
			love.graphics.setBlendMode("add")
			love.graphics.setDepthMode()
			local lastTyp
			for _,batch in ipairs(batches) do
				local dat = dream.shaderLibrary.light[batch.typ]
				local shader = self.lightShaders[batch.typ]
				
				if lastTyp ~= batch.typ then
					lastTyp = batch.typ
					love.graphics.setShader(shader)
					shader:send("tex_position", canvases.position)
					shader:send("tex_normal", canvases.normal)
					shader:send("tex_material", canvases.material)
				end
				
				lib:sendLightUniforms(batch, {[batch.typ] = #batch}, shader, batch.typ)
				love.graphics.draw(canvases.albedo)
			end
			love.graphics.setBlendMode("alpha")
		end
	end
	
	--particles
	self.delton:start("particles")
	love.graphics.setShader(self.shaders.particle)
	self.shaders.particle:send("transform", cam.transformProj)
	
	for d,s in pairs(self.particles) do
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
	
	self.delton:stop()
	
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
			--this should be part of the materials visibility settings, then masked out by the scene builder
			if not material.alpha and material.shadow ~= false then
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
	if not canvases.direct then
		love.graphics.reset()
	end
	
	--generate scene
	self.delton:start("scene")
	local sceneSolid, sceneAlpha = self:buildScene(cam, "render", blacklist)
	self.delton:stop()
	
	--render
	self.delton:start("render")
	self:render(sceneSolid, sceneAlpha, canvases, cam, noSky)
	self.delton:stop()
	
	if canvases.direct then
		love.graphics.pop()
		return
	end
	
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
	if canvases.postEffects and self.bloom_enabled then
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
	
	if shader:hasUniform("fog_density") then
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
		0,             2*n / (t - b) * (canvases.direct and 1 or -1),  (t+b) / (t-b),     0,
		0,             0,              -(f+n) / (f-n),    -2*f*n / (f-n),
		0,             0,              -1,                0
	)
	
	--camera transformation
	cam.transformProj = projection * cam.transform
	local m = cam.transform
	cam.transformProjOrigin = projection * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)
	cam.aspect = aspect
	self.lastUsedCam = cam
	
	--process render jobs
	self.delton:start("jobs")
	self:executeJobs()
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