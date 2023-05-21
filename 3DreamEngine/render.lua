--[[
#part of the 3DreamEngine by Luke100000
--]]

---@type Dream
local lib = _3DreamEngine
local vec3 = lib.vec3

--rendering stats
lib.stats = {
	vertices = 0,
	shaderSwitches = 0,
	materialSwitches = 0,
	reflectionSwitches = 0,
	draws = 0,
}

---@private
function lib:buildScene(shadowPass, dynamic, alpha, cam, blacklist, frustumCheck, canvases, light, isSun)
	self.delton:start("scene")
	
	--use a scene here
	local scene = self:newScene(shadowPass, dynamic, alpha, cam, blacklist, frustumCheck, canvases, light, isSun)
	
	for _, pair in ipairs(self.renderTasks) do
		if pair[1].isMesh then
			scene:addMesh(pair[1], pair[2], lib.defaultReflection)
		elseif pair[2] then
			scene:addObject(pair[1], pair[2], true)
		else
			scene:add(pair[1])
		end
	end
	
	local tasks = scene:getIterator()
	
	self.delton:stop()
	
	return tasks
end

--sends fog relevant data to the given shader
local function sendFogData(shader)
	local direction = vec3()
	local color = vec3()
	for _, light in ipairs(lib.lighting) do
		if light.typ == "sun" then
			direction = light.direction
			color = light.color
		end
	end
	
	shader:send("fog_density", lib.fog_density)
	shader:send("fog_color", lib.fog_color)
	shader:send("fog_sun", direction)
	shader:send("fog_sunColor", color)
	shader:send("fog_scatter", lib.fog_scatter)
	shader:send("fog_min", lib.fog_min)
	shader:send("fog_max", lib.fog_max)
end

--improve speed of uniform check
local function hasUniform(shaderObject, name)
	local uniforms = shaderObject.uniforms
	if uniforms[name] == nil then
		uniforms[name] = shaderObject.shader:hasUniform(name)
	end
	return uniforms[name]
end

--checks if this uniform exists and sends
local function checkAndSend(shader, name, value)
	if shader:hasUniform(name) then
		shader:send(name, value)
	end
end

--checks if this uniform exists and sends if not already cached
local function checkAndSendCached(shaderObject, name, value)
	if hasUniform(shaderObject, name) and shaderObject.cache[name] ~= value then
		shaderObject.shader:send(name, value)
		shaderObject.cache[name] = value
	end
end

---Render the scene onto a canvas set using a specific view camera
---@param cam DreamCamera
---@param canvases DreamCanvases
---@param dynamic boolean
---@param isShadow boolean
---@param blacklist table<string, boolean>
---@private
function lib:render(cam, canvases, dynamic, isShadow, blacklist)
	self.delton:start("prepare")
	
	--update required acceleration data
	local frustumCheck = self.frustumCheck and not cam.noFrustumCheck
	if frustumCheck then
		cam:updateFrustumPlanes()
	end
	
	local light
	
	if isShadow then
		love.graphics.push("all")
		love.graphics.reset()
		love.graphics.setMeshCullMode("none")
		love.graphics.setDepthMode("less", true)
		love.graphics.setBlendMode("darken", "premultiplied")
		love.graphics.setCanvas(canvases)
		love.graphics.clear(255, 255, 255, 255)
	else
		--and set canvases
		love.graphics.push("all")
		if canvases.mode ~= "direct" then
			love.graphics.reset()
			love.graphics.setCanvas({ canvases.color, canvases.depth, depthstencil = canvases.depthBuffer })
			
			love.graphics.setDepthMode()
			love.graphics.clear(false, false, true)
		end
		
		--render sky
		self:renderSky(cam.transformProjOrigin, cam:getInvertedTransform(), (cam.near + cam.far) / 4)
		
		--get light setup
		light = self:getLightOverview(cam)
	end
	
	self.delton:stop()
	
	--start both passes
	for pass = 1, canvases.alphaPass and 2 or 1 do
		--current state
		local shader
		local shaderObject
		local lastMaterial
		local lastReflection
		local sessionID = math.random()
		
		--setup final scene
		local scene
		if isShadow then
			scene = self:buildScene(true, dynamic, false, cam, blacklist, frustumCheck, { }, nil, cam.sun)
		else
			scene = self:buildScene(false, dynamic, pass == 2, cam, nil, frustumCheck, canvases, light)
			
			--only first pass writes depth
			love.graphics.setDepthMode("less", pass == 1)
			
			--set correct blend mode
			if canvases.refractions and pass == 2 then
				love.graphics.setBlendMode("alpha", "premultiplied")
			else
				love.graphics.setBlendMode("alpha", "alphamultiply")
			end
			
			--set alpha pass canvases
			if canvases.mode ~= "direct" and pass == 2 then
				if canvases.refractions then
					--refractions only
					love.graphics.setCanvas({ canvases.colorAlpha, canvases.distortion, depthstencil = canvases.depthBuffer })
					love.graphics.clear(true, false, false)
				else
					--disable depth
					love.graphics.setCanvas({ canvases.color, depthstencil = canvases.depthBuffer })
				end
			end
		end
		
		--start rendering
		self.delton:start("render")
		for t in scene do
			---@type DreamTask
			local task = t
			
			local mesh = task:getMesh()
			local objectMesh, instanceCount = mesh:getMesh()
			if objectMesh then
				local nextShaderObject = task:getShader()
				
				--set active shader
				if shaderObject ~= nextShaderObject then
					lastMaterial = false
					lastReflection = false
					
					shaderObject = nextShaderObject
					shader = shaderObject.shader
					if shaderObject.sessionID ~= sessionID then
						shaderObject.session = { }
						shaderObject.cache = shaderObject.cache or { }
					end
					love.graphics.setShader(shader)
					
					if not shaderObject.session.init then
						shaderObject.session.init = true
						
						if not isShadow then
							--light setup
							self:sendLightUniforms(light, shaderObject)
							
							--fog
							if hasUniform(shaderObject, "fog_density") then
								sendFogData(shader)
							end
							
							--framebuffer
							if hasUniform(shaderObject, "depthTexture") then
								shader:send("depthTexture", canvases.depth)
							end
							
							checkAndSendCached(shaderObject, "exposure", self.exposure)
							checkAndSendCached(shaderObject, "ambient", self.sun_ambient)
						end
						
						--camera
						shader:send("transformProj", cam.transformProj)
						if hasUniform(shaderObject, "viewPos") then
							checkAndSendCached(shaderObject, "viewPos", cam.viewPosition)
						end
						
						--shader
						shaderObject.pixelShader:perShader(shaderObject)
						shaderObject.vertexShader:perShader(shaderObject)
						shaderObject.worldShader:perShader(shaderObject)
					end
					
					self.stats.shaderSwitches = self.stats.shaderSwitches + 1
				end
				
				--set active material
				local material = mesh.material
				if lastMaterial ~= material then
					lastMaterial = material
					
					--alpha
					checkAndSendCached(shaderObject, "alphaCutoff", material.alphaCutoff)
					
					if isShadow then
						if hasUniform(shaderObject, "alphaTexture") then
							shaderObject.shader:send("alphaTexture", self:getImage(material.albedoTexture) or self.textures.default)
						end
					else
						checkAndSendCached(shaderObject, "translucency", material.translucency)
						
						--shader
						shaderObject.pixelShader:perMaterial(shaderObject, material)
						shaderObject.vertexShader:perMaterial(shaderObject, material)
						shaderObject.worldShader:perMaterial(shaderObject, material)
						
						--culling
						love.graphics.setMeshCullMode(material.cullMode)
					end
					
					self.stats.materialSwitches = self.stats.materialSwitches + 1
				end
				
				--reflection
				if not isShadow and shaderObject.reflection then
					local ref = task:getReflection()
					local tex = type(ref) == "table" and (ref.image or ref.canvas) or (self.defaultReflection and self.defaultReflectionCanvas) or self.textures.skyFallback
					if lastReflection ~= tex then
						if type(ref) == "table" and ref.canvas then
							self.reflections[ref] = ref.position or task:getPosition()
						end
						
						lastReflection = tex
						
						shader:send("backgroundTexture", tex)
						shader:send("reflectionsLevels", (ref and ref.levels or self.reflectionsLevels) - 1)
						
						--box for local cubemaps
						if ref and ref.first then
							shader:send("reflectionsBoxed", true)
							shader:send("reflectionsCenter", ref.center)
							shader:send("reflectionsFirst", ref.first)
							shader:send("reflectionsSecond", ref.second)
						else
							shader:send("reflectionsBoxed", false)
						end
						
						self.stats.reflectionSwitches = self.stats.reflectionSwitches + 1
					end
				end
				
				--object transformation
				shader:send("transform", task:getTransform())
				
				--sprite instancing specific
				if hasUniform(shaderObject, "up") then
					local v = mesh.vertical or 0
					local right = vec3(cam.transform[1], cam.transform[5] * (1 - mesh.vertical), cam.transform[9]):normalize()
					local up = vec3(cam.transform[2], cam.transform[6], cam.transform[10]):normalize()
					up = (up * (1 - v) + vec3(0, v, 0)):normalize()
					
					shader:send("up", up)
					shader:send("right", right)
					shader:send("front", right:cross(up):normalize())
				end
				
				--per task
				shaderObject.pixelShader:perTask(shaderObject, task)
				shaderObject.vertexShader:perTask(shaderObject, task)
				shaderObject.worldShader:perTask(shaderObject, task)
				
				--render
				if instanceCount then
					love.graphics.drawInstanced(objectMesh, instanceCount)
				else
					love.graphics.draw(objectMesh)
				end
				
				--stats
				self.stats.draws = self.stats.draws + 1
				mesh.meshVertexCount = mesh.meshVertexCount or objectMesh:getVertexCount()
				self.stats.vertices = self.stats.vertices + mesh.meshVertexCount
			end
		end
		self.delton:stop()
	end
	
	--godrays
	if not isShadow then
		if dynamic ~= false and self.godrays_enabled and canvases.depth then
			self:renderGodrays(light, canvases, cam)
		end
	end
	
	love.graphics.pop()
end

---Full render, including bloom, fxaa and exposure
---@private
function lib:renderFull(cam, canvases, dynamic)
	love.graphics.push("all")
	if canvases.mode ~= "direct" then
		love.graphics.reset()
	end
	
	--render
	self.delton:start("render")
	self:render(cam, canvases, dynamic)
	self.delton:stop()
	
	--direct rendering has no post effects
	if canvases.mode == "direct" then
		love.graphics.pop()
		return
	end
	
	--Ambient Occlusion (SSAO)
	if self.AO_enabled then
		love.graphics.setCanvas(canvases.AO_1)
		love.graphics.clear()
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setShader(self:getBasicShader("SSAO"))
		love.graphics.draw(canvases.depth, 0, 0, 0, self.AO_resolution)
		
		--blur
		if self.AO_blur then
			love.graphics.setShader(self:getBasicShader("blur"))
			self:getBasicShader("blur"):send("dir", { 1.0 / canvases.AO_1:getWidth(), 0.0 })
			love.graphics.setCanvas(canvases.AO_2)
			love.graphics.clear()
			love.graphics.draw(canvases.AO_1)
			
			self:getBasicShader("blur"):send("dir", { 0.0, 1.0 / canvases.AO_1:getHeight() })
			
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
		elseif canvases.mode == "lite" then
			--without final and blur, draw directly on color
			love.graphics.setShader(self:getBasicShader("rrr1"))
			love.graphics.setCanvas(canvases.color)
			love.graphics.setBlendMode("multiply", "premultiplied")
			love.graphics.draw(canvases.AO_1, 0, 0, 0, 1 / self.AO_resolution)
		end
	end
	
	--bloom
	if canvases.mode == "normal" and self.bloom_enabled then
		--down sample
		love.graphics.setCanvas(canvases.bloom_1)
		love.graphics.clear()
		
		--color
		local shader = self:getBasicShader("bloom")
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
		
		--auto choose
		local quality = self.bloom_quality
		if quality < 0 then
			quality = math.floor(math.log(self.bloom_resolution * self.bloom_size * canvases.width) - 1.4)
		end
		
		--blur
		local shader = self:getBasicShader("blur")
		love.graphics.setShader(shader)
		for i = quality, 0, -1 do
			local size = 2 ^ i / 2 ^ quality * self.bloom_size * canvases.width * self.bloom_resolution / 11
			
			shader:send("dir", { size / canvases.bloom_1:getWidth(), 0 })
			love.graphics.setCanvas(canvases.bloom_2)
			love.graphics.clear()
			love.graphics.draw(canvases.bloom_1)
			
			shader:send("dir", { 0, size / canvases.bloom_1:getHeight() })
			love.graphics.setCanvas(canvases.bloom_1)
			love.graphics.clear()
			love.graphics.draw(canvases.bloom_2)
		end
	end
	
	--final
	love.graphics.pop()
	if canvases.mode == "normal" then
		local shader = self:getFinalShader(canvases)
		
		love.graphics.setShader(shader)
		
		checkAndSend(shader, "canvas_depth", canvases.depth)
		
		checkAndSend(shader, "canvas_bloom", canvases.bloom_1)
		checkAndSend(shader, "canvas_ao", canvases.AO_1)
		
		checkAndSend(shader, "canvas_alpha", canvases.colorAlpha)
		checkAndSend(shader, "canvas_distortion", canvases.distortion)
		
		checkAndSend(shader, "canvas_exposure", self.canvas_exposure)
		
		checkAndSend(shader, "transformInverse", cam.transformProj:invert())
		checkAndSend(shader, "viewPos", cam.viewPosition)
		
		checkAndSend(shader, "exposure", self.exposure)
		
		if shader:hasUniform("fog_density") then
			sendFogData(shader)
		end
		
		love.graphics.draw(canvases.color)
		love.graphics.setShader()
	end
end

---Render or present the scene, depending on the canvas settings
---@param camera DreamCamera @ defaults to internal camera `dream.camera`
---@param canvases DreamCanvases @ defaults to internal canvases `dream.canvases`
---@param lite boolean @ when lite is enabled, no side tasks like shadow or reflection generations are executed
function lib:present(camera, canvases, lite)
	self.delton:start("present")
	
	if lite == nil then
		lite = canvases and true or false
	end
	
	--result canvases
	canvases = canvases or self.canvases
	
	--extract camera position and normal
	camera = camera or self.camera
	camera.position = vec3(camera.transform[4], camera.transform[8], camera.transform[12])
	camera.normal = vec3(-camera.transform[3], -camera.transform[7], -camera.transform[11]):normalize()
	camera.viewPosition = camera.position
	self.lastUsedCam = camera
	
	camera:applyProjectionTransform(canvases)
	
	--process render jobs
	if not lite then
		self.delton:start("jobs")
		self:executeJobs()
		self.delton:stop()
	end
	
	--render
	self.delton:start("renderFull")
	self:renderFull(camera, canvases)
	self.delton:stop()
	self.delton:stop()
	
	--debug
	if _DEBUGMODE then
		if love.keyboard.isDown(",") then
			local brightness = {
				data_pass2 = 0.25,
				depth = 0.1,
			}
			
			local w = 400
			local x = 0
			local y = 0
			local maxHeight = 0
			for d, s in pairs(canvases) do
				if type(s) == "userdata" and s:isReadable() then
					local b = brightness[d] or 1
					local h = w / s:getWidth() * s:getHeight()
					maxHeight = math.max(maxHeight, h)
					
					love.graphics.setColor(0, 0, 0)
					love.graphics.rectangle("fill", x * w, y, w, h)
					love.graphics.setShader(self:getBasicShader("replaceAlpha"))
					self:getBasicShader("replaceAlpha"):send("alpha", b)
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
		if love.keyboard.isDown(".") then
			self.delton:present()
		end
		if love.keyboard.isDown(",") then
			self.deltonLoad:step()
			self.deltonLoad:present()
		end
	end
end