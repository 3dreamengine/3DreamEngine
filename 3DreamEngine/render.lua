--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

--rendering stats
lib.stats = {
	vertices = 0,
	shadersInUse = 0,
	materialsUsed = 0,
	draws = 0,
}

--sorting function for the alpha pass
local function sortFunction(a, b)
	return a:getDistance() > b:getDistance()
end

function lib:buildScene(typ, dynamic, alpha, cam, blacklist, frustumCheck, noSmallObjects)
	self.delton:start("scene")
	
	--preprocess scenes to group together shader
	local groups = { }
	for sc, _ in pairs(self.scenes) do
		for dyn = dynamic == false and 2 or 1, dynamic == true and 1 or 2 do
			for shaderID, shaderGroup in pairs(sc.tasks[typ][dyn][alpha and 1 or 2]) do
				for materialID, materialGroup in pairs(shaderGroup) do
					if not groups[shaderID] then
						groups[shaderID] = { }
					end
					if groups[shaderID][materialID] then
						table.insert(groups[shaderID][materialID], materialGroup)
					else
						groups[shaderID][materialID] = {materialGroup}
					end
				end
			end
		end
	end
	
	--build sorted scene list
	local scene = { }
	for shaderID, shaderGroup in pairs(groups) do
		for materialID, materialGroups in pairs(shaderGroup) do
			for _, materialGroup in ipairs(materialGroups) do
				for _, task in pairs(materialGroup) do
					local mesh = task:getMesh()
					if mesh.mesh and (not blacklist or not blacklist[mesh]) and (not noSmallObjects or mesh.farVisibility ~= false) then
						if not frustumCheck or not mesh.boundingBox.initialized or self:inFrustum(cam, task:getPos(), task:getSize(), mesh.rID) then
							task:setShaderID(shaderID)
							table.insert(scene, task)
						end
					end
				end
			end
		end
	end
	
	--sort tables for materials requiring sorting
	if alpha then
		self.delton:start("sort")
		for d,task in ipairs(scene) do
			local dist = (task:getPos() - cam.pos):lengthSquared()
			task:setDistance(dist)
		end
		table.sort(scene, sortFunction)
		self.delton:stop()
	end
	
	self.delton:stop()
	return scene
end

--sends fog relevant data to the given shader
local function sendFogData(shader)
	local direction = vec3()
	local color = vec3()
	for _,light in ipairs(lib.lighting) do
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
function hasUniform(shaderObject, name)
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
function checkAndSendCached(shaderObject, name, value)
	if hasUniform(shaderObject, name) and shaderObject.cache[name] ~= value then
		shaderObject.shader:send(name, value)
		shaderObject.cache[name] = value
	end
end

--render the scene onto a canvas set using a specific view camera
function lib:render(canvases, cam)
	self.delton:start("prepare")
	
	--and set canvases
	love.graphics.push("all")
	if canvases.mode ~= "direct" then
		love.graphics.reset()
	end
	
	--clear depth
	if canvases.mode ~= "direct" then
		love.graphics.setCanvas({canvases.color, canvases.depth, depthstencil = canvases.depth_buffer})
		
		love.graphics.setDepthMode()
		love.graphics.clear(false, false, true)
	end
	
	--render sky
	self:renderSky(cam.transformProjOrigin, cam:getInvertedTransform(), (cam.near + cam.far) / 2)
	
	--update required acceleration data
	local frustumCheck = self.frustumCheck and not cam.noFrustumCheck
	if frustumCheck then
		cam:updateFrustumPlanes()
	end
	
	--get light setup
	local light = self:getLightOverview(cam)
	
	self.delton:stop()
	
	--current state
	local lastMaterial
	local lastReflection
	local sessionID = math.random()
	
	--start both passes
	for pass = 1, canvases.alphaPass and 2 or 1 do
		local shader
		local shaderObject
		local lastShader
		
		--setup final scene
		local scene = self:buildScene("render", dynamic, pass == 2, cam, nil, frustumCheck)
		
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
				love.graphics.setCanvas({canvases.colorAlpha, canvases.distortion, depthstencil = canvases.depth_buffer})
				love.graphics.clear(true, false, false)
			else
				--disable depth
				love.graphics.setCanvas({canvases.color, depthstencil = canvases.depth_buffer})
			end
		end
		
		--start rendering
		self.delton:start("render")
		for d,task in ipairs(scene) do
			local mesh = task:getMesh()
			local shaderID = task:getShaderID()
			
			--reflections
			local ref = task:getReflection()
			if ref and ref.canvas then
				self.reflections[ref] = ref.pos or task:getPos(mesh)
			end
			
			--set active shader
			if lastShader ~= shaderID then
				lastShader = shaderID
				lastMaterial = false
				lastReflection = false
				self.delton:start("shader")
				
				shaderObject = self:getRenderShader(shaderID, mesh, pass, canvases, light, false)
				shader = shaderObject.shader
				if shaderObject.sessionID ~= sessionID then
					shaderObject.session = { }
					shaderObject.cache = shaderObject.cache or { }
				end
				love.graphics.setShader(shader)
				
				if not shaderObject.session.init then
					shaderObject.session.init = true
					
					--light setup
					self:sendLightUniforms(light, shaderObject)
					
					--output settings
					if hasUniform(shaderObject, "dataAlpha") then
						shader:send("dataAlpha", dataAlpha)
					end
					
					--shader
					shaderObject.pixelShader:perShader(self, shaderObject)
					shaderObject.vertexShader:perShader(self, shaderObject)
					shaderObject.worldShader:perShader(self, shaderObject)
					
					--fog
					if hasUniform(shaderObject, "fog_density") then
						sendFogData(shader)
					end
					
					--framebuffer
					if hasUniform(shaderObject, "depthTexture") then
						shader:send("depthTexture", canvases.depth)
					end
					
					checkAndSendCached(shaderObject, "exposure", self.exposure)
					
					--camera
					shader:send("transformProj", cam.transformProj)
					checkAndSendCached(shaderObject, "viewPos", cam.pos)
					
					checkAndSendCached(shaderObject, "ambient", self.sun_ambient)
				end
				
				self.delton:stop()
				self.stats.shadersInUse = self.stats.shadersInUse + 1
			end
			
			--set active material
			local material = mesh.material
			if lastMaterial ~= material then
				lastMaterial = material
				
				--alpha
				checkAndSendCached(shaderObject, "dither", material.dither and 1 or 0)
				
				checkAndSendCached(shaderObject, "translucent", material.translucent)
				
				--shader
				shaderObject.pixelShader:perMaterial(self, shaderObject, material)
				shaderObject.vertexShader:perMaterial(self, shaderObject, material)
				shaderObject.worldShader:perMaterial(self, shaderObject, material)
				
				--culling
				love.graphics.setMeshCullMode(canvases.cullMode or material.cullMode or "back")
				
				self.stats.materialsUsed = self.stats.materialsUsed + 1
			end
			
			--reflection
			if shaderObject.reflection then
				local ref = task:getReflection() or (type(self.defaultReflection) == "table" and self.defaultReflection)
				local tex = ref and (ref.image or ref.canvas) or self.defaultReflection and self.defaultReflectionCanvas or self.textures.skyFallback
				if lastReflection ~= tex then
					lastReflection = tex
					
					shader:send("backgroundTexture", tex)
					shader:send("reflectionsLevels", (ref and ref.levels or self.reflectionsLevels) - 1)
					
					--box for local cubemaps
					if ref and ref.first then
						shader:send("reflectionsBoxed", true)
						shader:send("reflectionsPos", ref.pos)
						shader:send("reflectionsFirst", ref.first)
						shader:send("reflectionsSecond", ref.second)
					else
						shader:send("reflectionsBoxed", false)
					end
				end
			end
			
			--object transformation
			shader:send("transform", task:getTransform())
			
			--shader
			if not mesh.shadersInitialized then
				mesh:initShaders()
			end
			
			--per task
			shaderObject.pixelShader:perTask(self, shaderObject, task)
			shaderObject.vertexShader:perTask(self, shaderObject, task)
			shaderObject.worldShader:perTask(self, shaderObject, task)
			
			--render
			local objectMesh = mesh:getMesh("mesh")
			local instanceMesh = mesh:getMesh("instanceMesh")
			if instanceMesh then
				objectMesh:attachAttribute("InstanceRotation0", instanceMesh, "perinstance")
				objectMesh:attachAttribute("InstanceRotation1", instanceMesh, "perinstance")
				objectMesh:attachAttribute("InstanceRotation2", instanceMesh, "perinstance")
				objectMesh:attachAttribute("InstancePosition", instanceMesh, "perinstance")
				love.graphics.drawInstanced(objectMesh, instanceMesh:getVertexCount())
			else
				love.graphics.draw(objectMesh)
			end
			
			--stats
			self.stats.draws = self.stats.draws + 1
			mesh.meshVertexCount = mesh.meshVertexCount or objectMesh:getVertexCount()
			self.stats.vertices = self.stats.vertices + mesh.meshVertexCount
		end
		self.delton:stop()
		
		
		--particles on the alpha pass
		if dynamic ~= false then
			love.graphics.setColor(1.0, 1.0, 1.0)
			self.delton:start("particles")
			for ID, batches in pairs(self.particleBatches[pass]) do
				local emissive = ID == 2 or ID == 4
				local distortion = ID == 3 or ID == 4
				
				--batches
				local shaderObject = lib:getParticlesShader(pass, canvases, light, emissive, distortion)
				local shader = shaderObject.shader
				shaderObject.cache = shaderObject.cache or { }
				love.graphics.setShader(shader)
				
				shader:send("transformProj", cam.transformProj)
				if hasUniform(shaderObject, "viewPos") then shader:send("viewPos", cam.pos) end
				checkAndSendCached(shaderObject, "exposure", self.exposure)
				checkAndSendCached(shaderObject, "ambient", self.sun_ambient)
				
				--light
				self:sendLightUniforms(light, shaderObject)
				
				--fog
				if hasUniform(shaderObject, "fog_density") then
					sendFogData(shader)
				end
				
				--render particle batches
				for batch,_ in pairs(batches) do
					local v = 1.0 - batch.vertical
					local right = vec3(cam.transform[1], cam.transform[2] * v, cam.transform[3]):normalize()
					local up = vec3(cam.transform[5] * v, cam.transform[6], cam.transform[7] * v)
					shader:send("up", up)
					shader:send("right", right)
					
					--emission texture
					if hasUniform(shaderObject, "emissionTexture") then
						shader:send("emissionTexture", batch.emissionTexture)
					end
					
					--distortion texture
					if hasUniform(shaderObject, "distortionTexture") then
						shader:send("distortionTexture", batch.distortionTexture)
					end
					
					batch:present(cam.pos)
				end
			end
			
			--single particles on the alpha pass
			for ID, p in pairs(self.particles[pass]) do
				local emissive = ID == 2 or ID == 4
				local distortion = ID == 3 or ID == 4
				
				local shaderObject = lib:getParticlesShader(pass, canvases, light, emissive, distortion, true)
				local shader = shaderObject.shader
				shaderObject.cache = shaderObject.cache or { }
				love.graphics.setShader(shader)
				
				shader:send("transformProj", cam.transformProj)
				if hasUniform(shaderObject, "viewPos") then shader:send("viewPos", cam.pos) end
				checkAndSendCached(shaderObject, "exposure", self.exposure)
				checkAndSendCached(shaderObject, "ambient", self.sun_ambient)
				
				--light if using forward lighting
				self:sendLightUniforms(light, shaderObject)
				
				--fog
				if hasUniform(shaderObject, "fog_density") then
					sendFogData(shader)
				end
				
				--render particles
				for d,s in ipairs(p) do
					local v = 1 - s.vertical
					local right = vec3(cam.transform[1], cam.transform[2] * v, cam.transform[3]):normalize()
					local up = vec3(cam.transform[5] * v, cam.transform[6], cam.transform[7] * v)
					
					shader:send("up", up)
					shader:send("right", right)
					
					--position, size and emission multiplier
					shader:send("InstanceCenter", s.position)
					shader:send("InstanceEmission", s.emission)
					
					--emission texture
					if hasUniform(shaderObject, "emissionTexture") then
						shader:send("emissionTexture", s.emissionTexture)
					end
					
					--emission texture
					if hasUniform(shaderObject, "distortionTexture") then
						shader:send("distortionTexture", s.distortionTexture)
						shader:send("InstanceDistortion", s.distortion)
					end
					
					--draw
					love.graphics.setColor(s.color)
					if s.quad then
						love.graphics.draw(s.texture, s.quad, 0, 0, s.transform[1], s.transform[2], s.transform[3], s.transform[4], s.transform[5])
					else
						love.graphics.draw(s.texture, 0, 0, s.transform[1], s.transform[2], s.transform[3], s.transform[4], s.transform[5])
					end
				end
			end
			self.delton:stop()
		end
	end
	
	--godrays
	if dynamics ~= false and self.godrays_enabled and canvases.depth then
		self:renderGodrays(light, canvases, cam)
	end
	
	love.graphics.pop()
end

--only renders a depth variant
function lib:renderShadows(cam, canvas, blacklist, dynamic, noSmallObjects, smoothShadows)
	self.delton:start("renderShadows")
	
	--update required acceleration data
	local frustumCheck = self.frustumCheck and not cam.noFrustumCheck
	if frustumCheck then
		cam:updateFrustumPlanes()
	end
	
	--get scene
	local scene = self:buildScene("shadows", dynamic, false, cam, blacklist, frustumCheck, noSmallObjects)
	
	--current state
	local shader
	local shaderObject
	local lastShader
	local lastMaterial
	
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setMeshCullMode("none")
	love.graphics.setDepthMode("less", true)
	love.graphics.setBlendMode("darken", "premultiplied")
	love.graphics.setCanvas(canvas)
	
	--second pass for dynamics
	if dynamic then
		love.graphics.setColorMask(false, true, false, false)
	elseif dynamic == false then
		love.graphics.setColorMask(true, false, false, false)
	end
	love.graphics.clear(255, 255, 255, 255)
	
	--start rendering
	for d,task in ipairs(scene) do
		local mesh = task:getMesh()
		local shaderID = task:getShaderID()
		
		--set active shader
		if lastShader ~= shaderID then
			lastShader = shaderID
			lastMaterial = false
			lastReflection = false
			
			shaderObject = self:getRenderShader(shaderID, mesh, pass, { }, nil, true, cam.sun)
			shader = shaderObject.shader
			shaderObject.session = { }
			love.graphics.setShader(shader)
			
			--camera
			shader:send("transformProj", cam.transformProj)
			if hasUniform(shaderObject, "viewPos") then
				shader:send("viewPos", cam.pos)
			end
			
			shaderObject.pixelShader:perShader(self, shaderObject)
			shaderObject.vertexShader:perShader(self, shaderObject)
			shaderObject.worldShader:perShader(self, shaderObject)
		end
		
		--set active material
		local material = mesh.material
		if lastMaterial ~= material then
			lastMaterial = material
			
			if hasUniform(shaderObject, "alphaTexture") then
				shaderObject.shader:send("alphaTexture", self:getImage(material.albedoTexture) or self.textures.default)
			end
		end
		
		--object transformation
		shader:send("transform", task:getTransform())
		
		--shader
		shaderObject.pixelShader:perTask(self, shaderObject, task)
		shaderObject.vertexShader:perTask(self, shaderObject, task)
		shaderObject.worldShader:perTask(self, shaderObject, task)
		
		--render
		local objectMesh = mesh:getMesh("mesh")
		local instanceMesh = mesh:getMesh("instanceMesh")
		if instanceMesh then
			objectMesh:attachAttribute("InstanceRotation0", instanceMesh, "perinstance")
			objectMesh:attachAttribute("InstanceRotation1", instanceMesh, "perinstance")
			objectMesh:attachAttribute("InstanceRotation2", instanceMesh, "perinstance")
			objectMesh:attachAttribute("InstancePosition", instanceMesh, "perinstance")
			love.graphics.drawInstanced(objectMesh, instanceMesh:getVertexCount())
		else
			love.graphics.draw(objectMesh)
		end
	end
	
	love.graphics.pop()
	self.delton:stop()
	
	return scene
end

--full render, including bloom, fxaa and exposure
function lib:renderFull(cam, canvases)
	love.graphics.push("all")
	if canvases.mode ~= "direct" then
		love.graphics.reset()
	end
	
	--render
	self.delton:start("render")
	self:render(canvases, cam)
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
			self:getBasicShader("blur"):send("dir", {1.0 / canvases.AO_1:getWidth(), 0.0})
			love.graphics.setCanvas(canvases.AO_2)
			love.graphics.clear()
			love.graphics.draw(canvases.AO_1)
			
			self:getBasicShader("blur"):send("dir", {0.0, 1.0 / canvases.AO_1:getHeight()})
			
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
		
		--autochoose
		local quality = self.bloom_quality
		if quality < 0 then
			quality = math.floor(math.log(self.bloom_resolution * self.bloom_size * canvases.width)-1.4)
		end
		
		--blur
		local shader = self:getBasicShader("blur")
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
		checkAndSend(shader, "canvas_alphaData", canvases.dataAlpha)
		
		checkAndSend(shader, "canvas_exposure", self.canvas_exposure)
		
		checkAndSend(shader, "transformInverse", cam.transformProj:invert())
		checkAndSend(shader, "viewPos", cam.pos)
		
		checkAndSend(shader, "exposure", self.exposure)
		
		if shader:hasUniform("fog_density") then
			sendFogData(shader)
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
	cam.pos = vec3(cam.transform[4], cam.transform[8], cam.transform[12])
	cam.normal = vec3(-cam.transform[3], -cam.transform[7], -cam.transform[11]):normalize()
	
	--perspective transform
	do
		local n = cam.near
		local f = cam.far
		local fov = cam.fov
		local scale = math.tan(fov*math.pi/360)
		local aspect = canvases.width / canvases.height
		local r = scale * n * aspect
		local t = scale * n
		local m = canvases.mode == "direct" and 1 or -1
		
		--optimized matrix multiplication by removing constants
		--looks like a mess, but its only the opengl projection multiplied by the camera
		local b = cam.transform:invert()
		local a1 = n / r
		local a6 = n / t * m
		local fn1 = 1 / (f-n)
		local a11 = -(f+n) * fn1
		local a12 = -2*f*n * fn1
		
		cam.transformProj = mat4(
			a1 * b[1],   a1 * b[2],     a1 * b[3],     a1 * b[4],
			a6 * b[5],   a6 * b[6],     a6 * b[7],     a6 * b[8],
			a11 * b[9],  a11 * b[10],   a11 * b[11],   a11 * b[12] + a12,
			-b[9],       -b[10],        -b[11],        -b[12]
		)
		
		cam.transformProjOrigin = mat4(
			a1 * b[1],   a1 * b[2],    a1 * b[3],    0.0,
			a6 * b[5],   a6 * b[6],    a6 * b[7],    0.0,
			a11 * b[9],  a11 * b[10],  a11 * b[11],  a12,
			-b[9],       -b[10],       -b[11],       0.0
		)
		
		cam.aspect = aspect
		self.lastUsedCam = cam
	end
	
	--process render jobs
	if not lite then
		self.delton:start("jobs")
		self:executeJobs()
		self.delton:stop()
	end
	
	--render
	self.delton:start("renderFull")
	self:renderFull(cam, canvases)
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
			for d,s in pairs(canvases) do
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