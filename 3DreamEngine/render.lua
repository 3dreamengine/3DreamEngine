--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

--rendering stats
lib.stats = {
	shadersInUse = 0,
	lightSetups = 0,
	materialDraws = 0,
	draws = 0,
}

local sortPosition = vec3(0, 0, 0)
local function sortFunction(a, b)
	return (a.pos - sortPosition):lengthSquared() > (b.pos - sortPosition):lengthSquared()
end

function lib:sendFogData(shader)
	shader:send("fog_density", self.fog_density)
	shader:send("fog_color", self.fog_color)
	shader:send("fog_sun", self.sun)
	shader:send("fog_sunColor", self.sun_color)
	shader:send("fog_scatter", self.fog_scatter)
	shader:send("fog_min", self.fog_min)
	shader:send("fog_max", self.fog_max)
end

--use active scenes, current canvas set, the usage type and an optional blacklist to create a final, ready to render scene
--typ is the final scene typ and may be 'render', 'shadows' or 'reflections'
function lib:buildScene(cam, canvases, typ, blacklist)
	local scene = {
		solid = { },
		alpha = typ ~= "shadows" and { } or false,
		lights = { }
	}
	
	--add to scene
	local LODFactor = 10 / self.LODDistance
	local noFrustumCheck = cam.noFrustumCheck or not self.frustumCheck
	for sc,_ in pairs(self.scenes) do
		if not sc.visibility or sc.visibility[typ] then
			--get light setup per scene
			local light = self:getLightOverview(cam)
			scene.lights[light.ID] = light
			
			for _,task in ipairs(sc.tasks) do
				if not blacklist or not (blacklist[task.obj] or blacklist[task.s]) then
					local visibility = task.s.visibility or task.obj.visibility
					if not visibility or visibility[typ] then
						local mat = task.s.material
						for pass = mat.solid and 1 or 2, mat.alpha and typ ~= "shadows" and 2 or 1 do
							local scene = pass == 1 and scene.solid or scene.alpha
							local LOD = task.s.LOD or task.obj.LOD
							if not LOD or LOD[math.min( math.floor((task.pos - cam.pos):length() * LODFactor) + 1, 9 )] then
								if noFrustumCheck or not task.s.boundingBox or self:inFrustum(cam, task.pos, task.s.boundingBox.size) then
									local shader = self:getShader(task.s, pass, canvases, light)
									local lightID = pass == 1 and canvases.deferred and "" or light.ID
									
									--group shader and materials together to reduce shader switches
									if not scene[shader] then
										scene[shader] = { }
									end
									if not scene[shader][lightID] then
										scene[shader][lightID] = { }
									end
									if not scene[shader][lightID][mat] then
										scene[shader][lightID][mat] = { }
									end
									
									--add
									table.insert(scene[shader][lightID][mat], task)
									
									--reflections
									if typ == "render" then
										local reflection = task.s.reflection or task.obj.reflection
										if reflection and reflection.canvas then
											self.reflections[reflection] = {
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
		end
	end
	
	--sort tables for materials requiring sorting
	if scene.alpha then
		sortPosition = cam.pos
		for shader, shaderGroup in pairs(scene.alpha) do
			for material, materialGroup in pairs(shaderGroup) do
				table.sort(materialGroup, sortFunction)
			end
		end
	end
	
	return scene
end

--render the scene onto a canvas set using a specific view camera
function lib:render(scene, canvases, cam)
	self.delton:start("prepare")
	
	--love shader friendly
	local viewPos = {cam.pos:unpack()}
	
	--clear and set canvases
	love.graphics.push("all")
	if not canvases.direct then
		love.graphics.reset()
	end
	
	--render sky
	if canvases.direct then
		self:renderSky(cam.transformProjOrigin, cam.transform)
	else
		--render sky
		love.graphics.setCanvas(canvases.color)
		self:renderSky(cam.transformProjOrigin, cam.transform)
	end
	
	--clear
	if not canvases.direct then
		love.graphics.setCanvas({canvases.depth, canvases.colorAlpha, canvases.dataAlpha, depthstencil = canvases.depth_buffer})
		love.graphics.clear({255, 255, 255, 255}, {0, 0, 0, 0}, {0, 0, 0, 0})
		if canvases.deferred then
			love.graphics.setCanvas(canvases.position, canvases.normal, canvases.material, canvases.albedo)
			love.graphics.clear(0, 0, 0, 0)
		end
	end
	
	--prepare lighting
	self.delton:stop()
	
	--start both passes
	for pass = 1, 2 do
		--only first pass writes depth
		love.graphics.setDepthMode("less", pass == 1)
		if canvases.averageAlpha and pass == 2 then
			love.graphics.setBlendMode("add")
		else
			love.graphics.setBlendMode("alpha", canvases.averageAlpha and "premultiplied" or "alphamultiply")
		end
		
		--set canvases
		local dataAlpha = canvases.averageAlpha and pass == 2
		if not canvases.direct then
			if canvases.deferred and pass == 1 then
				--deferred pass 1
				love.graphics.setCanvas({canvases.color, canvases.depth, canvases.position, canvases.normal, canvases.material, canvases.albedo, depthstencil = canvases.depth_buffer})
			elseif dataAlpha then
				--average alpha
				love.graphics.setCanvas({canvases.colorAlpha, canvases.dataAlpha, depthstencil = canvases.depth_buffer})
			elseif canvases.refractions and pass == 2 then
				--refractions only
				love.graphics.setCanvas({canvases.colorAlpha, canvases.depth, depthstencil = canvases.depth_buffer})
			else
				--no refractions or default pass
				love.graphics.setCanvas({canvases.color, canvases.depth, depthstencil = canvases.depth_buffer})
			end
		end
		
		--final draw
		for shaderObject, shaderGroup in pairs(pass == 1 and scene.solid or scene.alpha) do
			self.delton:start("shader")
			local shader = shaderObject.shader
			
			--pass
			shader:send("alphaPass", pass == 2)
			
			--output settings
			love.graphics.setShader(shader)
			if shader:hasUniform("dataAlpha") then
				shader:send("dataAlpha", dataAlpha)
			end
			
			--shader
			local shaderEntry = self.shaderLibrary.base[shaderObject.shaderType]
			shaderEntry:perShader(self, shaderObject)
			for d,s in pairs(shaderObject.modules) do
				s:perShader(self, shaderObject)
			end
			
			--fog
			if shader:hasUniform("fog_density") then
				self:sendFogData(shader)
			end
			
			--framebuffer
			if shader:hasUniform("tex_depth") then
				shader:send("tex_depth", canvases.depth)
				shader:send("tex_color", canvases.color)
				shader:send("screenScale", {1 / canvases.width, 1 / canvases.height})
			end
			
			if shader:hasUniform("gamma") then shader:send("gamma", self.gamma) end
			if shader:hasUniform("exposure") then shader:send("exposure", self.exposure) end
			
			--camera
			shader:send("transformProj", cam.transformProj)
			if shader:hasUniform("viewPos") then
				shader:send("viewPos", viewPos)
			end
			
			if not shaderObject.reflection then
				shader:send("ambient", self.sun_ambient)
			end
			
			--for each light setup
			for lightID, lightGroup in pairs(shaderGroup) do
				self.delton:start("light")
				
				--light if using forward lighting
				if not canvases.deferred or pass == 2 then
					self:sendLightUniforms(scene.lights[lightID], shaderObject)
				end
				
				--for each material
				for material, materialGroup in pairs(lightGroup) do
					self.delton:start("material")
					
					--alpha
					shader:send("isSemi", material.solid and material.alpha)
					
					--ior
					if shader:hasUniform("ior") then
						shader:send("ior", 1.0 / material.ior)
					end
					
					if shader:hasUniform("translucent") then
						shader:send("translucent", material.alpha and 1.0 or material.translucent)
					end
					
					--shader
					shaderEntry:perMaterial(self, shaderObject, material)
					for d,s in pairs(shaderObject.modules) do
						s:perMaterial(self, shaderObject, material)
					end
					
					--culling
					love.graphics.setMeshCullMode((pass == 2 and dream.alphaCullMode) or canvases.cullMode or material.cullMode or "back")
					
					--draw objects
					for _,task in pairs(materialGroup) do
						--sky texture
						if shaderObject.reflection then
							local ref = task.s.reflection or task.obj.reflection or (type(self.sky_reflection) == "table" and self.sky_reflection)
							local tex = ref and (ref.image or ref.canvas)
							if not tex and self.sky_reflection then
								--use sky dome
								tex = self.sky_reflectionCanvas
							end
							
							shader:send("tex_background", tex or self.textures.sky_fallback)
							shader:send("reflections_levels", (ref and ref.levels or self.reflections_levels) - 1)
							
							--box for local cubemaps
							if ref and ref.first then
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
						shaderEntry:perTask(self, shaderObject, task)
						for d,s in pairs(shaderObject.modules) do
							s:perTask(self, shaderObject, task)
						end
						
						--render
						love.graphics.setColor(task.color)
						love.graphics.draw(task.s.mesh)
						
						self.stats.draws = self.stats.draws + 1
					end
					self.stats.materialDraws = self.stats.materialDraws + 1
					self.delton:stop()
				end
				self.stats.lightSetups = self.stats.lightSetups + 1
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
				
				local dat = lib.shaderLibrary.light[typ]
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
				local dat = lib.shaderLibrary.light[batch.typ]
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
	
	--particles on the alpha pass
	self.delton:start("particles")
	local light = self:getLightOverview(cam)
	for e = 1, 2 do
		local emissive = e == 1
		
		--batches
		if self.particleBatchesActive[emissive] then
			local shaderObject = lib:getParticlesShader(canvases, light, emissive)
			local shader = shaderObject.shader
			love.graphics.setShader(shader)
			
			shader:send("transformProj", cam.transformProj)
			shader:send("dataAlpha", canvases.averageAlpha)
			if shader:hasUniform("viewPos") then shader:send("viewPos", {cam.pos:unpack()}) end
			if shader:hasUniform("gamma") then shader:send("gamma", self.gamma) end
			if shader:hasUniform("exposure") then shader:send("exposure", self.exposure) end
			
			--light if using forward lighting
			self:sendLightUniforms(light, shaderObject)
			
			--fog
			if shader:hasUniform("fog_density") then
				self:sendFogData(shader)
			end
			
			--render particle batches
			for batch,_ in pairs(self.particleBatches) do
				if (batch.emissionTexture and true or false) == emissive then
					local v = 1.0 - batch.vertical
					local right = vec3(cam.transform[1], cam.transform[2] * v, cam.transform[3]):normalize()
					local up = vec3(cam.transform[5] * v, cam.transform[6], cam.transform[7] * v)
					shader:send("up", {up:unpack()})
					shader:send("right", {right:unpack()})
					
					--emission texture
					if shader:hasUniform("tex_emission") then
						shader:send("tex_emission", batch.emissionTexture)
					end
					
					batch:present(cam.pos)
				end
			end
		end
		
		--single particles on the alpha pass
		local p = emissive and self.particlesEmissive or self.particles
		if p[1] then
			local shaderObject = lib:getParticlesShader(canvases, light, emissive, true)
			local shader = shaderObject.shader
			love.graphics.setShader(shader)
			
			shader:send("transformProj", cam.transformProj)
			shader:send("dataAlpha", canvases.averageAlpha)
			if shader:hasUniform("viewPos") then shader:send("viewPos", {cam.pos:unpack()}) end
			if shader:hasUniform("gamma") then shader:send("gamma", self.gamma) end
			if shader:hasUniform("exposure") then shader:send("exposure", self.exposure) end
			
			--light if using forward lighting
			self:sendLightUniforms(light, shaderObject)
			
			--fog
			if shader:hasUniform("fog_density") then
				self:sendFogData(shader)
			end
			
			--render particles
			for d,s in ipairs(p) do
				local nr = #s - 6
				local v = 1.0 - s[4 + nr]
				local right = vec3(cam.transform[1], cam.transform[2] * v, cam.transform[3]):normalize()
				local up = vec3(cam.transform[5] * v, cam.transform[6], cam.transform[7] * v)
				
				shader:send("up", {up:unpack()})
				shader:send("right", {right:unpack()})
				
				--position, size and emission multiplier
				shader:send("InstanceCenter", s[2 + nr])
				shader:send("InstanceEmission", s[5 + nr])
				
				--emission texture
				if shader:hasUniform("tex_emission") then
					shader:send("tex_emission", s[2])
				end
				
				--draw
				love.graphics.setColor(s[3 + nr])
				if s[1 + nr].getViewport then
					love.graphics.draw(s[1], s[1 + nr], 0, 0, unpack(s[6 + nr]))
				else
					love.graphics.draw(s[1], 0, 0, unpack(s[6 + nr]))
				end
			end
		end
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
	
	for shaderObject, shaderGroup in pairs(scene.solid) do
		for lightID, lightGroup in pairs(shaderGroup) do
			for material, materialGroup in pairs(lightGroup) do
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
	end
	
	love.graphics.pop()
end

--full render, including bloom, fxaa, exposure and gamma correction
function lib:renderFull(cam, canvases, blacklist)
	love.graphics.push("all")
	if not canvases.direct then
		love.graphics.reset()
	end
	
	--generate scene
	self.delton:start("scene")
	local scene = self:buildScene(cam, canvases, "render", blacklist)
	self.delton:stop()
	
	--render
	self.delton:start("render")
	self:render(scene, canvases, cam)
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
		if self.AO_blur then
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
	end
	
	--bloom
	if canvases.postEffects and self.bloom_enabled then
		--down sample
		love.graphics.setCanvas(canvases.bloom_1)
		love.graphics.clear()
		
		if canvases.averageAlpha then
			love.graphics.setShader(self.shaders.bloom_average)
			self.shaders.bloom_average:send("canvas_alpha", canvases.colorAlpha)
			self.shaders.bloom_average:send("canvas_alphaData", canvases.dataAlpha)
			self.shaders.bloom_average:send("strength", self.bloom_strength)
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.draw(canvases.color, 0, 0, 0, self.bloom_resolution)
		else
			love.graphics.setShader(self.shaders.bloom)
			self.shaders.bloom:send("strength", self.bloom_strength)
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.draw(canvases.color, 0, 0, 0, self.bloom_resolution)
			
			--also include alpha pass
			if canvases.colorAlpha then
				love.graphics.setBlendMode("alpha", "premultiplied")
				love.graphics.draw(canvases.colorAlpha, 0, 0, 0, self.bloom_resolution)
				love.graphics.setBlendMode("replace", "premultiplied")
			end
		end
		
		--blur
		love.graphics.setShader(self.shaders.blur)
		for i = 1, 0, -1 do
			local size = (self.bloom_size * self.bloom_resolution) * 5 ^ i
			
			self.shaders.blur:send("dir", {size / canvases.bloom_1:getWidth(), 0})
			love.graphics.setCanvas(canvases.bloom_2)
			love.graphics.clear()
			love.graphics.draw(canvases.bloom_1)
			
			self.shaders.blur:send("dir", {0, size / canvases.bloom_1:getHeight()})
			love.graphics.setCanvas(canvases.bloom_1)
			love.graphics.clear()
			love.graphics.draw(canvases.bloom_2)
		end
	end
	
	--additional render instructions
	self.delton:start("modules")
	for d,s in pairs(self.allActiveShaderModules) do
		if s.render then
			s:render(self, cam, canvases, scene)
		end
	end
	self.delton:stop()
	
	--final
	local shader = self:getFinalShader(canvases)
	love.graphics.pop()
	
	love.graphics.setShader(shader)
	
	if shader:hasUniform("canvas_depth") then shader:send("canvas_depth", canvases.depth) end
	
	if shader:hasUniform("canvas_bloom") then shader:send("canvas_bloom", canvases.bloom_1) end
	if shader:hasUniform("canvas_ao") then shader:send("canvas_ao", canvases.AO_1) end
	
	if shader:hasUniform("canvas_alpha") then shader:send("canvas_alpha", canvases.colorAlpha) end
	if shader:hasUniform("canvas_alphaData") then shader:send("canvas_alphaData", canvases.dataAlpha) end
	
	if shader:hasUniform("canvas_exposure") then shader:send("canvas_exposure", self.canvas_exposure) end
	
	if shader:hasUniform("transformInverse") then shader:send("transformInverse", cam.transformProj:invert()) end
	if shader:hasUniform("viewPos") then shader:send("viewPos", cam.pos) end
	
	if shader:hasUniform("gamma") then shader:send("gamma", self.gamma) end
	if shader:hasUniform("exposure") then shader:send("exposure", self.exposure) end
	
	if shader:hasUniform("fog_density") then
		self:sendFogData(shader)
	end
	
	love.graphics.draw(canvases.color)
	love.graphics.setShader()
end

function lib:presentLite(cam, canvases)
	cam = cam or self.cam
	canvases = canvases or self.canvases
	self:renderFull(cam, canvases)
end

function lib:present(cam, canvases)
	self.delton:start("present")
	self.stats.shadersInUse = 0
	self.stats.lightSetups = 0
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
	self:renderFull(cam, canvases)
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