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
	
	--update required acceleration data
	if self.activeFrustum == self.inFrustum then
		cam:updateFrustumAngle(canvases.width and canvases.width / canvases.height or 1)
	elseif self.activeFrustum == self.planeInFrustum then
		cam:updateFrustumPlanes()
	end
	
	--add to scene
	local LODFactor = 10 / self.LODDistance
	local noFrustumCheck = cam.noFrustumCheck or not self.activeFrustum
	for sc,_ in pairs(self.scenes) do
		if not sc.visibility or sc.visibility[typ] then
			--get light setup per scene
			local light
			if typ ~= "shadow" then
				light = self:getLightOverview(cam)
				scene.lights[light.ID] = light
			end
			
			for _,task in ipairs(sc.tasks) do
				local obj = task:getObj()
				local subObj = task:getS()
				if not blacklist or not (blacklist[obj] or blacklist[subObj]) then
					local visibility = subObj.visibility or obj.visibility
					if not visibility or visibility[typ] then
						local mat = subObj.material
						if typ ~= "shadows" or mat.shadow ~= false then
							local solid = (mat.solid or not canvases.alphaPass) and 1 or 2
							local alpha = canvases.alphaPass and mat.alpha and typ ~= "shadows" and 2 or 1
							for pass = solid, alpha do
								local scene = (not canvases.alphaPass or pass == 1) and scene.solid or scene.alpha
								local LOD = subObj.LOD or obj.LOD
								if not LOD or LOD[math.min( math.floor((task:getPos() - cam.pos):length() * LODFactor) + 1, 9 )] then
									if noFrustumCheck or not subObj.boundingBox or self:activeFrustum(cam, task:getPos(), task:getSize(), subObj) then
										if subObj.loaded then
											local shader = self:getRenderShader(subObj, pass, canvases, light, typ == "shadows")
											local lightID = light.ID
											
											--group shader and materials together to reduce shader switches
											if not scene[shader] then
												scene[shader] = { }
											end
											
											if typ == "shadows" then
												table.insert(scene[shader], task)
											else
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
													local reflection = subObj.reflection or obj.reflection
													if reflection and reflection.canvas then
														self.reflections[reflection] = {
															dist = (task:getPos() - cam.pos):length(),
															obj = subObj.reflection and subObj or obj,
															pos = reflection.pos or task:getPos(),
														}
													end
												end
											end
										elseif subObj.request then
											subObj:request()
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
	
	--and set canvases
	love.graphics.push("all")
	if canvases.mode ~= "direct" then
		love.graphics.reset()
	end
	
	--clear canvases
	if canvases.mode ~= "direct" then
		love.graphics.setCanvas({canvases.color, canvases.depth, depthstencil = canvases.depth_buffer})
		love.graphics.setDepthMode()
		love.graphics.clear(false, false, true)
	end
	
	--render sky
	self:renderSky(cam.transformProjOrigin, cam.transform, (cam.near + cam.far) / 2)
	
	self.delton:stop()
	
	--start both passes
	for pass = 1, canvases.alphaPass and 2 or 1 do
		--only first pass writes depth
		love.graphics.setDepthMode("less", pass == 1)
		if canvases.averageAlpha and pass == 2 then
			love.graphics.setBlendMode("add")
		else
			love.graphics.setBlendMode("alpha", canvases.averageAlpha and "premultiplied" or "alphamultiply")
		end
		
		--set canvases
		local dataAlpha = canvases.averageAlpha and pass == 2
		if canvases.mode ~= "direct" then
			if dataAlpha then
				--average alpha
				love.graphics.setCanvas({canvases.colorAlpha, canvases.dataAlpha, depthstencil = canvases.depth_buffer})
				love.graphics.clear(true, false, false)
			elseif canvases.refractions and pass == 2 then
				--refractions only
				love.graphics.setCanvas({canvases.colorAlpha, depthstencil = canvases.depth_buffer})
				love.graphics.clear(true, false, false)
			end
		end
		
		--final draw
		for shaderObject, shaderGroup in pairs(pass == 1 and scene.solid or scene.alpha) do
			self.delton:start("shader")
			local shader = shaderObject.shader
			
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
				self:sendLightUniforms(scene.lights[lightID], shaderObject)
				
				--for each material
				for material, materialGroup in pairs(lightGroup) do
					self.delton:start("material")
					
					--alpha
					if shader:hasUniform("isSemi") then
						shader:send("isSemi", canvases.alphaPass and material.solid and material.alpha and 1 or 0)
					end
					if shader:hasUniform("dither") then
						if material.dither == nil then
							shader:send("dither", self.dither and 1 or 0)
						else
							shader:send("dither", material.dither and 1 or 0)
						end
					end
					
					--ior
					if shader:hasUniform("ior") then
						shader:send("ior", 1.0 / material.ior)
					end
					
					if shader:hasUniform("translucent") then
						shader:send("translucent", material.translucent)
					end
					
					--shader
					shaderEntry:perMaterial(self, shaderObject, material)
					for d,s in pairs(shaderObject.modules) do
						s:perMaterial(self, shaderObject, material)
					end
					
					--culling
					love.graphics.setMeshCullMode(canvases.cullMode or material.cullMode or "back")
					
					--draw objects
					for _,task in pairs(materialGroup) do
						local obj = task:getObj()
						local subObj = task:getS()
						
						--sky texture
						if shaderObject.reflection then
							local ref = subObj.reflection or obj.reflection or (type(self.sky_reflection) == "table" and self.sky_reflection)
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
						shader:send("transform", task:getTransform())
						
						--shader
						shaderEntry:perTask(self, shaderObject, task)
						for d,s in pairs(shaderObject.modules) do
							s:perTask(self, shaderObject, task)
						end
						
						--render
						love.graphics.setColor(task:getColor())
						love.graphics.draw(subObj.mesh)
						
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
	self.delton:start("renderShadows")
	
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setMeshCullMode("none")
	love.graphics.setDepthMode("less", true)
	love.graphics.setBlendMode("darken", "premultiplied")
	love.graphics.setCanvas(canvas)
	love.graphics.clear(255, 255, 255, 255)
	
	--love shader friendly
	local viewPos = {cam.pos:unpack()}
	
	--final draw
	for shaderObject, shaderGroup in pairs(scene.solid) do
		local shader = shaderObject.shader
		love.graphics.setShader(shader)
		
		--shader
		for d,s in pairs(shaderObject.modules) do
			s:perShader(self, shaderObject)
		end
		
		--camera
		shader:send("transformProj", cam.transformProj)
		if shader:hasUniform("viewPos") then
			shader:send("viewPos", viewPos)
		end
		
		--for each task
		for _, task in ipairs(shaderGroup) do
			--object transformation
			shader:send("transform", task:getTransform())
			
			--shader
			for d,s in pairs(shaderObject.modules) do
				s:perTask(self, shaderObject, task)
			end
			
			--render
			love.graphics.setColor(task:getColor())
			love.graphics.draw(task:getS().mesh)
		end
	end
	
	self.delton:stop()
	love.graphics.pop()
end

--full render, including bloom, fxaa, exposure and gamma correction
function lib:renderFull(scene, cam, canvases)
	love.graphics.push("all")
	if canvases.mode ~= "direct" then
		love.graphics.reset()
	end
	
	--render
	self.delton:start("render")
	self:render(scene, canvases, cam)
	self.delton:stop()
	
	if canvases.mode == "direct" then
		love.graphics.pop()
		return
	end
	
	--Ambient Occlusion (SSAO)
	if self.AO_enabled then
		love.graphics.setCanvas(canvases.AO_1)
		love.graphics.clear()
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setShader(self:getShader("SSAO"))
		love.graphics.draw(canvases.depth, 0, 0, 0, self.AO_resolution)
		
		--blur
		if self.AO_blur then
			love.graphics.setShader(self:getShader("blur"))
			self:getShader("blur"):send("dir", {1.0 / canvases.AO_1:getWidth(), 0.0})
			love.graphics.setCanvas(canvases.AO_2)
			love.graphics.clear()
			love.graphics.draw(canvases.AO_1)
			
			self:getShader("blur"):send("dir", {0.0, 1.0 / canvases.AO_1:getHeight()})
			
			--without final, draw directly on color
			if canvases.mode == "normal" then
				love.graphics.setCanvas(canvases.AO_1)
				love.graphics.clear()
				love.graphics.draw(canvases.AO_2)
			else
				love.graphics.setCanvas(canvases.color)
				love.graphics.setBlendMode("multiply", "premultiplied")
				love.graphics.draw(canvases.AO_2, 0, 0, 0, 1 / self.AO_resolution)
			end
		elseif canvases.smode == "lite" then
			--without final and blur, draw directly on color
			love.graphics.setShader(self:getShader("rrr1"))
			love.graphics.setCanvas(canvases.color)
			love.graphics.setBlendMode("multiply", "premultiplied")
			love.graphics.draw(canvases.AO_1, 0, 0, 0, 1 / self.AO_resolution)
		end
	end
	
	--bloom
	if canvases.postEffects and self.bloom_enabled then
		--down sample
		love.graphics.setCanvas(canvases.bloom_1)
		love.graphics.clear()
		
		if canvases.averageAlpha then
			--required different fetch
			local shader = self:getShader("bloom_average")
			love.graphics.setShader(shader)
			shader:send("canvas_alpha", canvases.colorAlpha)
			shader:send("canvas_alphaData", canvases.dataAlpha)
			shader:send("strength", self.bloom_strength)
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.draw(canvases.color, 0, 0, 0, self.bloom_resolution)
		else
			--color
			local shader = self:getShader("bloom")
			love.graphics.setShader(shader)
			shader:send("strength", self.bloom_strength)
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.draw(canvases.color, 0, 0, 0, self.bloom_resolution)
			
			--also include alpha pass
			if canvases.colorAlpha then
				love.graphics.setBlendMode("alpha", "premultiplied")
				love.graphics.draw(canvases.colorAlpha, 0, 0, 0, self.bloom_resolution)
				love.graphics.setBlendMode("replace", "premultiplied")
			end
		end
		
		--autochoose
		local quality = self.bloom_quality
		if quality < 0 then
			quality = math.floor(math.log(self.bloom_resolution * self.bloom_size * canvases.width)-1.4)
		end
		
		--blur
		local shader = self:getShader("blur")
		love.graphics.setShader(shader)
		for i = quality, 0, -1 do
			local size = 2^i / 2^quality * self.bloom_size * canvases.width * self.bloom_resolution / 11
			
			shader:send("dir", {size / canvases.bloom_1:getWidth(), 0})
			love.graphics.setCanvas(canvases.bloom_2)
			love.graphics.clear()
			love.graphics.draw(canvases.bloom_1)
			
			shader:send("dir", {0, size / canvases.bloom_1:getHeight()})
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
	love.graphics.pop()
	if canvases.mode == "normal" then
		local shader = self:getFinalShader(canvases)
		
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
end

function lib:present(cam, canvases, lite)
	self.delton:start("present")
	
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
	local scale = math.tan(fov*math.pi/360)
	local aspect = canvases.width / canvases.height
	local r = scale * n * aspect
	local t = scale * n
	local m = canvases.mode == "direct" and 1 or -1
	local projection = mat4(
		n / r,     0,          0,                0,
		0,         n / t * m,  0,                0,
		0,         0,          -(f+n) / (f-n),   -2*f*n / (f-n),
		0,         0,          -1,               0
	)
	
	--camera transformation
	cam.transformProj = projection * cam.transform
	local m = cam.transform
	cam.transformProjOrigin = projection * mat4(m[1], m[2], m[3], 0.0, m[5], m[6], m[7], 0.0, m[9], m[10], m[11], 0.0, 0.0, 0.0, 0.0, 1.0)
	cam.aspect = aspect
	self.lastUsedCam = cam
	
	--generate scene
	self.delton:start("scene")
	local scene = self:buildScene(cam, canvases, "render", blacklist)
	self.delton:stop()
	
	--process render jobs
	if not lite then
		self.delton:start("jobs")
		self:executeJobs()
		self.delton:stop()
	end
	
	--render
	self.delton:start("renderFull")
	self:renderFull(scene, cam, canvases)
	self.delton:stop()
	self.delton:stop()
	
	--debug
	local brightness = {
		data_pass2 = 0.25,
		depth = 0.1,
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
				love.graphics.setShader(self:getShader("replaceAlpha"))
				self:getShader("replaceAlpha"):send("alpha", b)
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