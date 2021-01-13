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
	local IDs = {
		[(dynamic ~= true and 0 or 2) + (alpha and 2 or 1)] = true,
		[(dynamic ~= false and 2 or 0) + (alpha and 2 or 1)] = true,
	}
	
	--preprocess scenes to group together shader
	local t = love.timer.getTime()
	local groups = { }
	for sc, _ in pairs(self.scenes) do
		for ID, _ in pairs(IDs) do
			for shaderID, shaderGroup in pairs(sc.tasks[typ][ID]) do
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
					local subObj = task:getSubObj()
					local obj = subObj.obj
					if (not blacklist or not (blacklist[obj] or blacklist[subObj])) and (not noSmallObjects or subObj.farVisibility ~= false and obj.farVisibility ~= false) then
						if subObj.loaded and subObj.mesh then
							if not frustumCheck or not subObj.boundingBox.initialized or self:planeInFrustum(cam, task:getPos(), task:getSize(), subObj.rID) then
								task:setShaderID(shaderID)
								scene[#scene+1] = task
							end
						else
							subObj:request()
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
	shader:send("fog_density", lib.fog_density)
	shader:send("fog_color", lib.fog_color)
	shader:send("fog_sun", lib.sun)
	shader:send("fog_sunColor", lib.sun_color)
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

--render the scene onto a canvas set using a specific view camera
function lib:render(canvases, cam, reflections)
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
	
	--update required acceleration data
	local frustumCheck = self.frustumCheck and not cam.noFrustumCheck
	if frustumCheck then
		cam:updateFrustumPlanes()
	end
	
	--get light setup
	local light = self:getLightOverview(cam)
	
	self.delton:stop()
	
	--current state
	local shader
	local shaderObject
	local shaderEntry
	local lastShader
	local lastMaterial
	local lastReflection
	
	--start both passes
	for pass = 1, canvases.alphaPass and 2 or 1 do
		--setup final scene
		local scene = self:buildScene("render", dynamic, pass == 2, cam, blacklist, frustumCheck)
		
		if #scene > 0 or canvases.firstAlphaFrame then
			canvases.firstAlphaFrame = true
			
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
		end
		
		--start rendering
		self.delton:start("render")
		for d,task in ipairs(scene) do
			local subObj = task:getSubObj()
			local shaderID = task:getShaderID()
			local obj = subObj.obj
			
			--reflections
			if not reflections then
				local ref = subObj.reflection or obj.reflection
				if ref and ref.canvas then
					self.reflections[ref] = {
						dist = (task:getPos(subObj) - cam.pos):length(),
						obj = subObj.reflection and subObj or obj,
						pos = ref.pos or task:getPos(subObj),
					}
				end
			end
			
			--set active shader
			if lastShader ~= shaderID then
				lastShader = shaderID
				lastMaterial = false
				lastReflection = false
				self.delton:start("shader")
				
				shaderObject = self:getRenderShader(shaderID, subObj, pass, canvases, light, false, false)
				shaderEntry = self.shaderLibrary.base[shaderObject.shaderType]
				shader = shaderObject.shader
				love.graphics.setShader(shader)
				
				--light setup
				self:sendLightUniforms(light, shaderObject)
				
				--output settings
				if hasUniform(shaderObject, "dataAlpha") then
					shader:send("dataAlpha", dataAlpha)
				end
				
				--shader
				shaderEntry:perShader(self, shaderObject)
				for d,s in pairs(shaderObject.modules) do
					s:perShader(self, shaderObject)
				end
				
				--fog
				if hasUniform(shaderObject, "fog_density") then
					sendFogData(shader)
				end
				
				--framebuffer
				if hasUniform(shaderObject, "tex_depth") then
					shader:send("tex_depth", canvases.depth)
					shader:send("tex_color", canvases.color)
					shader:send("screenScale", {1 / canvases.width, 1 / canvases.height})
				end
				
				if hasUniform(shaderObject, "gamma") then shader:send("gamma", self.gamma) end
				if hasUniform(shaderObject, "exposure") then shader:send("exposure", self.exposure) end
				
				--camera
				shader:send("transformProj", cam.transformProj)
				if hasUniform(shaderObject, "viewPos") then
					shader:send("viewPos", viewPos)
				end
				
				if not shaderObject.reflection then
					shader:send("ambient", self.sun_ambient)
				end
				
				self.delton:stop()
				self.stats.shadersInUse = self.stats.shadersInUse + 1
			end
			
			--set active material
			local material = subObj.material
			if lastMaterial ~= material then
				lastMaterial = material
				--self.delton:start("material")
				
				--alpha
				if hasUniform(shaderObject, "dither") then
					if material.dither == nil then
						shader:send("dither", self.dither and 1 or 0)
					else
						shader:send("dither", material.dither and 1 or 0)
					end
				end
				
				--ior
				if hasUniform(shaderObject, "ior") then
					shader:send("ior", 1.0 / material.ior)
				end
				
				if hasUniform(shaderObject, "translucent") then
					shader:send("translucent", material.translucent)
				end
				
				--shader
				shaderEntry:perMaterial(self, shaderObject, material)
				for d,s in pairs(shaderObject.modules) do
					s:perMaterial(self, shaderObject, material)
				end
				
				--culling
				love.graphics.setMeshCullMode(canvases.cullMode or material.cullMode or "back")
				
				--self.delton:stop()
				self.stats.materialsUsed = self.stats.materialsUsed + 1
			end
			
			--reflection
			if shaderObject.reflection then
				local ref = subObj.reflection or obj.reflection or (type(self.sky_reflection) == "table" and self.sky_reflection)
				local tex = ref and (ref.image or ref.canvas) or self.sky_reflection and self.sky_reflectionCanvas or self.textures.sky_fallback
				if lastReflection ~= tex then
					lastReflection = tex
					self.delton:start("reflection")
					
					shader:send("tex_background", tex)
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
					
					self.delton:stop()
				end
			end
			
			--object transformation
			shader:send("transform", task:getTransform())
			
			--shader
			shaderEntry:perTask(self, shaderObject, task, task)
			for d,s in pairs(shaderObject.modules) do
				s:perTask(self, shaderObject, subObj, task, task)
			end
			
			--render
			love.graphics.setColor(task:getColor())
			love.graphics.draw(subObj.mesh)
			
			--stats
			self.stats.draws = self.stats.draws + 1
			--self.stats.vertices = self.stats.vertices + subObj.vertexCount
		end
		self.delton:stop()
	end
	
	love.graphics.setColor(1.0, 1.0, 1.0)
	
	--particles on the alpha pass
	if dynamic ~= false then
		self.delton:start("particles")
		for e = 1, 2 do
			local emissive = e == 1
			
			--batches
			if self.particleBatchesActive[emissive] then
				local shaderObject = lib:getParticlesShader(canvases, light, emissive)
				local shader = shaderObject.shader
				love.graphics.setShader(shader)
				
				shader:send("transformProj", cam.transformProj)
				if hasUniform(shaderObject, "viewPos") then shader:send("viewPos", {cam.pos:unpack()}) end
				if hasUniform(shaderObject, "gamma") then shader:send("gamma", self.gamma) end
				if hasUniform(shaderObject, "exposure") then shader:send("exposure", self.exposure) end
				
				--light if using forward lighting
				self:sendLightUniforms(light, shaderObject)
				
				--fog
				if hasUniform(shaderObject, "fog_density") then
					sendFogData(shader)
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
						if hasUniform(shaderObject, "tex_emission") then
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
				if hasUniform(shaderObject, "viewPos") then shader:send("viewPos", {cam.pos:unpack()}) end
				if hasUniform(shaderObject, "gamma") then shader:send("gamma", self.gamma) end
				if hasUniform(shaderObject, "exposure") then shader:send("exposure", self.exposure) end
				
				--light if using forward lighting
				self:sendLightUniforms(light, shaderObject)
				
				--fog
				if hasUniform(shaderObject, "fog_density") then
					sendFogData(shader)
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
					if hasUniform(shaderObject, "tex_emission") then
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
	end
	
	love.graphics.pop()
end

--only renders a depth variant
function lib:renderShadows(cam, canvas, blacklist, dynamic, noSmallObjects)
	self.delton:start("renderShadows")
	
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setMeshCullMode("none")
	love.graphics.setDepthMode("less", true)
	love.graphics.setBlendMode("darken", "premultiplied")
	love.graphics.setCanvas(canvas)
	
	--second pass for dynamics
	if dynamic then
		love.graphics.setColorMask(false, true, false, false)
	else
		love.graphics.setColorMask(true, false, false, false)
	end
	love.graphics.clear(255, 255, 255, 255)
	
	--love shader friendly
	local viewPos = {cam.pos:unpack()}
	
	--update required acceleration data
	local frustumCheck = self.frustumCheck and not cam.noFrustumCheck
	if frustumCheck then
		cam:updateFrustumPlanes()
	end
	
	--current state
	local shader
	local shaderObject
	local shaderEntry
	local lastShader
	local lastMaterial
	
	--get scene
	local scene = self:buildScene("shadows", dynamic, false, cam, blacklist, frustumCheck, noSmallObjects)
	
	--start rendering
	for d,task in ipairs(scene) do
		local subObj = task:getSubObj()
		local shaderID = task:getShaderID()
		local obj = subObj.obj
		
		--set active shader
		if lastShader ~= shaderID then
			lastShader = shaderID
			lastMaterial = false
			lastReflection = false
			
			shaderObject = self:getRenderShader(shaderID, subObj, pass, { }, nil, true, false)
			shaderEntry = self.shaderLibrary.base[shaderObject.shaderType]
			shader = shaderObject.shader
			love.graphics.setShader(shader)
			
			shader:send("mode", cam.sun and true or false)
			
			--camera
			shader:send("transformProj", cam.transformProj)
			if hasUniform(shaderObject, "viewPos") then
				shader:send("viewPos", viewPos)
			end
		end
		
		--set active material
		local material = subObj.material
		if lastMaterial ~= material then
			lastMaterial = material
			--TODO alpha texture
		end
		
		--object transformation
		shader:send("transform", task:getTransform())
		
		--shader
		shaderEntry:perTask(self, shaderObject, task, task)
		for d,s in pairs(shaderObject.modules) do
			s:perTask(self, shaderObject, subObj, task, task)
		end
		
		--render
		love.graphics.setColor(task:getColor())
		love.graphics.draw(subObj.mesh)
	end
	
	love.graphics.pop()
	self.delton:stop()
	
	return scene
end

--full render, including bloom, fxaa, exposure and gamma correction
function lib:renderFull(cam, canvases, reflections)
	love.graphics.push("all")
	if canvases.mode ~= "direct" then
		love.graphics.reset()
	end
	
	--render
	self.delton:start("render")
	self:render(canvases, cam, reflections)
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
			s:render(self, cam, canvases)
		end
	end
	self.delton:stop()
	
	--final
	love.graphics.pop()
	if canvases.mode == "normal" then
		local shader = self:getFinalShader(canvases)
		
		love.graphics.setShader(shader)
		
		checkAndSend(shader, "canvas_depth", canvases.depth)
		
		checkAndSend(shader, "canvas_bloom", canvases.bloom_1)
		checkAndSend(shader, "canvas_ao", canvases.AO_1)
		
		checkAndSend(shader, "canvas_alpha", canvases.colorAlpha)
		checkAndSend(shader, "canvas_alphaData", canvases.dataAlpha)
		
		checkAndSend(shader, "canvas_exposure", self.canvas_exposure)
		
		checkAndSend(shader, "transformInverse", cam.transformProj:invert())
		checkAndSend(shader, "viewPos", cam.pos)
		
		checkAndSend(shader, "gamma", self.gamma)
		checkAndSend(shader, "exposure", self.exposure)
		
		if shader:hasUniform("fog_density") then
			sendFogData(shader)
		end
		
		love.graphics.draw(canvases.color)
		love.graphics.setShader()
	end
end

local sum = 0
local count = 0

function lib:present(cam, canvases, lite)
	self.delton:start("present")
	
	--result canvases
	canvases = canvases or self.canvases
	
	--extract camera position and normal
	cam = cam or self.cam
	local i = cam.transform:invert()
	cam.pos = vec3(i[4], i[8], i[12])
	cam.normal = vec3(-i[3], -i[7], -i[11]):normalize()
	
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
		
		--optimized matrix multiplikation by removing constants
		--looks like a mess, but its only the opengl projection multiplied by the camera
		local b = cam.transform
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
		if love.keyboard.isDown(".") then
			self.delton:present()
		end
		if love.keyboard.isDown(",") then
			self.deltonLoad:step()
			self.deltonLoad:present()
		end
	end
end