--[[
#part of the 3DreamEngine by Luke100000
jobs.lua - processes all kind of side tasks (shadows, blurring ambient lighting, rendering sky dome, ...)
--]]

local lib = _3DreamEngine

local timeRequirement = { }
local executionsPerSecond = { }
local executions = { }
local times = { }

local pointShadowProjectionMatrix
do
	local n = 0.01
	local f = 1000.0
	local fov = 90
	local scale = math.tan(fov/2*math.pi/180)
	local r = scale * n
	local l = -r
	
	pointShadowProjectionMatrix = mat4(
		2*n / (r-l),   0,              (r+l) / (r-l),     0,
		0,             -2*n / (r - l),  (r+l) / (r-l),     0,
		0,             0,              -(f+n) / (f-n),    -2*f*n / (f-n),
		0,             0,              -1,                0
	)
end

local lookNormals = {
	vec3(1, 0, 0),
	vec3(-1, 0, 0),
	vec3(0, -1, 0),
	vec3(0, 1, 0),
	vec3(0, 0, 1),
	vec3(0, 0, -1),
}

local blurVecs = {
	{
		{1.0, 0.0, 0.0},
		{0.0, 0.0, -1.0},
		{0.0, -1.0, 0.0},
		{0.0, 0.0, 1.0},
	},
	{
		{-1.0, 0.0, 0.0},
		{0.0, 0.0, 1.0},
		{0.0, -1.0, 0.0},
		{0.0, 0.0, 1.0},
	},
	{
		{0.0, 1.0, 0.0},
		{1.0, 0.0, 0.0},
		{0.0, 0.0, 1.0},
		{1.0, 0.0, 0.0},
	},
	{
		{0.0, -1.0, 0.0},
		{1.0, 0.0, 0.0},
		{0.0, 0.0, -1.0},
		{1.0, 0.0, 0.0},
	},
	{
		{0.0, 0.0, 1.0},
		{1.0, 0.0, 0.0},
		{0.0, -1.0, 0.0},
		{1.0, 0.0, 0.0},
	},
	{
		{0.0, 0.0, -1.0},
		{-1.0, 0.0, 0.0},
		{0.0, -1.0, 0.0},
		{1.0, 0.0, 0.0},
	},
}

local identityMatrix = mat4:getIdentity()

local blurCanvases = { }
function lib.blurCubeMap(self, cube, level)
	local f = cube:getFormat()
	local resolution = math.ceil(cube:getWidth() / self.reflection_downsample)
	
	--create canvases if needed
	blurCanvases[f] = blurCanvases[f] or { }
	if not blurCanvases[f][resolution] then
		blurCanvases[f][resolution] = { }
	end
	if not blurCanvases[f][resolution][level] then
		local size = resolution / 2^(level-1)
		blurCanvases[f][resolution][level] = love.graphics.newCanvas(size, size, {format = f, readable = true, msaa = 0, type = "2d", mipmaps = "none"})
	end
	
	--blurring
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setBlendMode("replace", "premultiplied")
	
	local can = blurCanvases[f][resolution][level]
	local res = can:getWidth()
	for side = 1, 6 do
		love.graphics.setCanvas(can)
		love.graphics.setShader(self.shaders.blur_cube)
		self.shaders.blur_cube:send("tex", cube)
		self.shaders.blur_cube:send("scale", 1.0 / res)
		self.shaders.blur_cube:send("normal", blurVecs[side][1])
		self.shaders.blur_cube:send("dirX", blurVecs[side][2])
		self.shaders.blur_cube:send("dirY", blurVecs[side][3])
		self.shaders.blur_cube:send("lod", (level - 2.0))
		love.graphics.rectangle("fill", 0, 0, res, res)
		
		--paste
		love.graphics.setCanvas(cube, side, level)
		love.graphics.setShader()
		love.graphics.draw(can, 0, 0, 0, self.reflection_downsample)
	end
	
	love.graphics.pop()
end

local drops = { }

function lib.executeJobs(self, cam)
	local t = love.timer.getTime()
	local dt = love.timer.getDelta()
	local timeAvailable = 5.0 / 1000
	local operations = { }
	
	--re render sky cube
	if self.sky_enabled then
		operations[#operations+1] = {"sky", 1.0}
		
		--blur sky reflection cubemap
		for level = 2, self.reflections_levels do
			local id = "cubemap_sky" .. level
			local time = times[id]
			if (times["sky"] or 0) > (time or 0) then
				operations[#operations+1] = {"cubemap", time and (1.0 / level) or 1.0, id, self.canvas_sky, level}
			end
		end
	end
	
	--re check exposure
	if self.autoExposure_enabled and (t - (times["autoExposure"] or 0)) > self.autoExposure_interval then
		operations[#operations+1] = {"autoExposure", 0.25}
	end
	
	--rain
	operations[#operations+1] = {"rain", 1.0}
	
	--shadows
	for d,s in ipairs(self.lighting) do
		if s.shadow and s.active then
			if s.shadow.typ == "sun" then
				local pos = vec3(s.x, s.y, s.z):normalize()
				for cascade = 1, 3 do
					if not s.shadow.static or not s.shadow.done[cascade] then
						local id = "shadow_sun_" .. tostring(s.shadow) .. tostring(cascade)
						operations[#operations+1] = {"shadow_sun", 1.0 / 2^cascade, id, s, pos, cascade}
					end
				end
			elseif s.shadow.typ == "point" then
				local pos = vec3(s.x, s.y, s.z)
				local dist = (pos - cam.pos):length() / 10.0 + 1.0
				
				if not s.shadow.static or not s.shadow.done[1] then
					local id = "shadow_point_" .. tostring(s.shadow)
					operations[#operations+1] = {"shadow_point", s.shadow.priority / dist, id, s, pos}
				end
			end
		end
	end
	
	--reflections
	for reflection, task in pairs(self.reflections_last) do
		--render reflections
		for face = 1, 6 do
			if not reflection.static or not reflection.done[face] then
				local id = "reflections_" .. (reflection.id + face)
				operations[#operations+1] = {"reflections", reflection.priority / (task.dist / 10 + 1), id, task.obj, task.pos, face}
			end
		end
		
		--blur mipmaps
		for level = 2, self.reflections_levels do
			local id_blur = "cubemap_" .. (reflection.id + level)
			if (times[id] or 0) > (times[id_blur] or 0) then
				operations[#operations+1] = {"cubemap", times[id_blur] and (1.0 / level) or 1.0, id_blur, reflection.canvas, level}
			end
		end
	end
	
	--sort operations based on priority and time since last execution
	table.sort(operations, function(a, b) return a[2] * (t - (times[a[3] or a[1]] or 0)) > b[2] * (t - (times[b[3] or b[1]] or 0)) end)
	
	--debug
	if _DEBUGMODE and love.keyboard.isDown("#") then
		--measure the total priority, this is an approximation for the outstanding work
		local total = 0
		for d,s in ipairs(operations) do
			total = total + (t - (times[s[3] or s[1]] or t))
		end
		
		--print approximate time requirement
		print(string.format("%.2f ms behind, %d operations in queue, %.2f ms per step available", total * 1000, #operations, timeAvailable * 1000))
		for d,s in pairs(timeRequirement) do
			print(string.format("\t%s: %0.2f ms", d, s*1000))
		end
		
		--print execution per second
		print("e/s:")
		for d,s in pairs(executionsPerSecond) do
			print(string.format("\t%s: %.2f/s", d, s))
		end
		
		--print execution per second
		print("e total:")
		for d,s in pairs(executions) do
			print(string.format("\t%s: %d", d, s))
		end
		
		print("queue:")
		for d,s in ipairs(operations) do
			print(string.format("\t%s\tpriority: %.2f\tdelta: %.2f ms", s[1], s[2], (t - (times[s[3] or s[1]] or 0)) * 1000))
		end
		print()
		
		os.exit()
	end
	
	--execute operations
	while operations[1] do
		local o = operations[1]
		table.remove(operations, 1)
		
		--remember time stamp
		local delta = t - (times[o[3] or o[1]] or t)
		times[o[3] or o[1]] = t
		
		local time = love.timer.getTime()
		if o[1] == "sky" then
			love.graphics.push("all")
			love.graphics.reset()
			love.graphics.setDepthMode()
			
			local pos = vec3(0.0, 0.0, 0.0)
			local transformations = {
				pointShadowProjectionMatrix * self:lookAt(pos, lookNormals[1], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, lookNormals[2], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, lookNormals[3], vec3(0, 0, -1)),
				pointShadowProjectionMatrix * self:lookAt(pos, lookNormals[4], vec3(0, 0, 1)),
				pointShadowProjectionMatrix * self:lookAt(pos, lookNormals[5], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, lookNormals[6], vec3(0, -1, 0)),
			}
			
			for side = 1, 6 do
				love.graphics.setBlendMode("replace", "premultiplied")
				love.graphics.setCanvas(self.canvas_sky, side)
				love.graphics.clear(1.0, 1.0, 1.0)
				love.graphics.setDepthMode()
				
				--sky sphere
				if self.sky_hdri then
					love.graphics.setShader(self.shaders.sky_hdri)
					self.shaders.sky_hdri:send("exposure", self.sky_hdri_exposure)
					self.shaders.sky_hdri:send("transformProj", transformations[side])
					self.object_sky.objects.Sphere.mesh:setTexture(self.sky_hdri)
					love.graphics.draw(self.object_sky.objects.Sphere.mesh)
				else
					love.graphics.setShader(self.shaders.sky_WilkieHosek)
					self.shaders.sky_WilkieHosek:send("transformProj", transformations[side])
					self.shaders.sky_WilkieHosek:send("time", self.sky_time)
					love.graphics.setColor(self.sky_color:unpack())
					self.object_sky.objects.Sphere.mesh:setTexture(self.textures.sky)
					love.graphics.draw(self.object_sky.objects.Sphere.mesh)
					
					--stars
					if self.stars_enabled then
						local stars = -math.sin(self.sky_time * math.pi * 2)
						if stars > 0 then
							local starTex = self:getTexture(self.textures.stars_hdri)
							if starTex then
								love.graphics.setBlendMode("add", "premultiplied")
								love.graphics.setShader(self.shaders.sky_hdri)
								self.shaders.sky_hdri:send("exposure", stars)
								self.shaders.sky_hdri:send("transformProj", transformations[side])
								self.object_sky.objects.Sphere.mesh:setTexture(starTex)
								love.graphics.draw(self.object_sky.objects.Sphere.mesh)
							end
						end
					end
					
					--moon and sund
					if self.sunMoon_enabled then
						--moon
						for sunMoon = 1, 2 do
							local x, y, z = (-self.sun):normalize():unpack()
							local l = math.sqrt(x^2+z^2)
							
							local a2 = self.sky_time * math.pi * 2.0 + (sunMoon-1) * math.pi
							local c2 = math.cos(a2)
							local s2 = math.sin(a2)
							
							local a1 = self.sun_offset
							local c1 = math.cos(a1)
							local s1 = math.sin(a1)
							
							local distance = sunMoon == 1 and 4.0 or (2.0 + math.sin(self.sky_time * math.pi * 2.0))
							local transform = mat4:getIdentity():translate(0, 0, distance):rotateX(a2):rotateZ(a1)
							
							if sunMoon == 1 then
								local moon = self:getTexture(self.textures.moon)
								local moon_normal = self:getTexture(self.textures.moon_normal)
								
								if moon and moon_normal then
									love.graphics.setColor(1.0, 1.0, 1.0)
									love.graphics.setBlendMode("alpha")
									love.graphics.setShader(self.shaders.billboard_moon)
									self.shaders.billboard_moon:send("transform", transform)
									self.shaders.billboard_moon:send("transformProj", transformations[side])
									self.shaders.billboard_moon:send("normalTex", moon_normal)
									self.shaders.billboard_moon:send("sun", {math.cos(self.sky_day / 30 * math.pi * 2), math.sin(self.sky_day / 30 * math.pi * 2), 0})
									self.object_plane.objects.Plane.mesh:setTexture(moon)
								end
							else
								local sun = self:getTexture(self.textures.sun)
								
								if sun then
									love.graphics.setColor(self.sun_color)
									love.graphics.setBlendMode("add")
									love.graphics.setShader(self.shaders.billboard_sun)
									self.shaders.billboard_sun:send("transform", transform)
									self.shaders.billboard_sun:send("transformProj", transformations[side])
									self.object_plane.objects.Plane.mesh:setTexture(sun)
								end
							end
							love.graphics.draw(self.object_plane.objects.Plane.mesh)
						end
					end
					
					--clouds
					if self.clouds_enabled and side ~= 3 then
						love.graphics.setBlendMode("alpha")
						
						love.graphics.setShader(self.shaders.clouds)
						self.shaders.clouds:send("sunColor", {(self.sun_color * 3.0):unpack()})
						self.shaders.clouds:send("ambientColor", {(self.sun_color * 2.0):unpack()})
						self.shaders.clouds:send("sunVec", {self.sun:normalize():unpack()})
						self.shaders.clouds:send("scale", self.clouds_scale)
						self.shaders.clouds:send("time", {love.timer.getTime() * 0.001, 0.0})
						
						self.shaders.clouds:send("threshold", self.clouds_threshold)
						self.shaders.clouds:send("thresholdInverted", 1.0 / (1.0 - math.min(0.99, self.clouds_threshold)))
						
						self.shaders.clouds:send("thresholdPackets", self.clouds_thresholdPackets)
						self.shaders.clouds:send("thresholdInvertedPackets", 1.0 / (1.0 - math.min(0.99, self.clouds_thresholdPackets)))
						
						self.shaders.clouds:send("packets", self.clouds_packets)
						self.shaders.clouds:send("weight", self.clouds_weight)
						self.shaders.clouds:send("sharpness", self.clouds_sharpness)
						self.shaders.clouds:send("detail", self.clouds_detail)
						self.shaders.clouds:send("thickness", self.clouds_thickness)
						
						self.object_cube.objects.Cube.mesh:setTexture(self.textures.clouds_rough)
						self.textures.clouds_rough:setWrap("repeat")
						
						self.shaders.clouds:send("tex_packets", self.textures.clouds_packets)
						self.textures.clouds_packets:setWrap("repeat")
						
						self.shaders.clouds:send("transformProj", transformations[side])
						love.graphics.draw(self.object_cube.objects.Cube.mesh)
					end
				end
			end
			
			love.graphics.pop()
		elseif o[1] == "cubemap" then
			self:blurCubeMap(o[4], o[5])
		elseif o[1] == "autoExposure" then
			love.graphics.push("all")
			love.graphics.reset()
			
			--vignette and downscale
			local c = self.canvas_exposure
			love.graphics.setCanvas(c)
			self.shaders.autoExposure:send("targetBrightness", self.autoExposureTargetBrightness)
			self.shaders.autoExposure:send("adaptionFactor", self.autoExposureAdaptionFactor)
			love.graphics.setShader(self.shaders.autoExposure)
			love.graphics.draw(self.canvases.final, 0, 0, 0, c:getWidth() / self.canvases.width, c:getHeight() / self.canvases.height)
			love.graphics.setShader()
			
			--fetch
			local f = self.autoExposure_adaptionSpeed * math.sqrt(self.autoExposure_interval)
			love.graphics.setBlendMode("alpha", "premultiplied")
			love.graphics.setCanvas(self.canvas_exposure_fetch)
			love.graphics.setColor(1, 1, 1, f)
			love.graphics.draw(self.canvas_exposure, 0, 0, 0, 1 / self.autoExposure_resolution)
			love.graphics.pop()
		elseif o[1] == "shadow_sun" then
			local cascade = o[6]
			o[4].shadow.lastPos = o[5]
			
			--create new canvases if necessary
			if not o[4].shadow.canvases then
				o[4].shadow.canvases = { }
			end
			
			--render
			local r = self.shadow_distance / 2 * (self.shadow_factor ^ (cascade-1))
			local t = self.shadow_distance / 2 * (self.shadow_factor ^ (cascade-1))
			local l = -r
			local b = -t
			
			local n = 1.0
			local f = 100
			
			local projection = mat4(
				2 / (r - l),	0,	0,	-(r + l) / (r - l),
				0, -2 / (t - b), 0, -(t + b) / (t - b),
				0, 0, -2 / (f - n), -(f + n) / (f - n),
				0, 0, 0, 1
			)
			
			local shadowCam = self:newCam()
			shadowCam.noFrustumCheck = true
			shadowCam.pos = cam.pos
			shadowCam.normal = o[5]
			shadowCam.transform = self:lookAt(cam.pos + shadowCam.normal * f * 0.5, cam.pos, vec3(0.0, 1.0, 0.0))
			shadowCam.transformProj = projection * shadowCam.transform
			o[4].shadow["transformation_" .. cascade] = shadowCam.transformProj
			o[4].shadow.canvases[cascade] = o[4].shadow.canvases[cascade] or self:newShadowCanvas("sun", o[4].shadow.res)
			
			local scene = self:buildScene(shadowCam)
			self:renderShadows(scene, shadowCam, {depthstencil = o[4].shadow.canvases[cascade]}, o[4].blacklist)
			
			o[4].shadow.done[cascade] = true
		elseif o[1] == "shadow_point" then
			local pos = o[5]
			o[4].shadow.lastPos = pos
			
			local transformations = {
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[1], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[2], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[3], vec3(0, 0, -1)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[4], vec3(0, 0, 1)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[5], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[6], vec3(0, -1, 0)),
			}
			
			--create new canvases if necessary
			if not o[4].shadow.canvas then
				time = love.timer.getTime()
				o[4].shadow.canvas = self:newShadowCanvas("point", o[4].shadow.res)
			end
			
			--render
			for face = 1, 6 do
				local shadowCam = self:newCam(transformations[face], pos, lookNormals[face])
				local scene = self:buildScene(shadowCam)
				self:renderShadows(scene, shadowCam, {{o[4].shadow.canvas, face = face}}, o[4].blacklist)
			end
			
			o[4].shadow.done[1] = true
		elseif o[1] == "reflections" then
			local pos = o[5]
			local face = o[6]
			
			local transformations = {
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[1], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[2], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[3], vec3(0, 0, -1)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[4], vec3(0, 0, 1)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[5], vec3(0, -1, 0)),
				pointShadowProjectionMatrix * self:lookAt(pos, pos + lookNormals[6], vec3(0, -1, 0)),
			}
			
			--prepare
			love.graphics.push("all")
			love.graphics.reset()
			local cam = self:newCam(transformations[face], pos, lookNormals[face])
			local canvas = o[4].reflection.canvas
			love.graphics.setCanvas({{canvas, face = face}})
			o[4].reflection.canvas = nil
			
			--render
			lib:renderFull(cam, self.canvases_reflections, false, {[o[4]] = true})
			
			o[4].reflection.canvas = canvas
			love.graphics.pop()
			
			o[4].reflection.done[face] = true
		elseif o[1] == "rain" then
			local lastRender = self.rain_rain > 0
			if self.rain_isRaining then
				self.rain_rain = math.min(1.0, self.rain_rain + delta * self.rain_adaptRain)
				self.rain_wetness = math.min(1.0, self.rain_wetness + delta * self.rain_wetness_increase)
			else
				self.rain_rain = math.max(0.0, self.rain_rain - delta * self.rain_adaptRain)
				self.rain_wetness = math.max(0.0, self.rain_wetness - delta * self.rain_wetness_decrease * (0.5 + self.rain_wetness))
			end
			
			if self.rain_enabled then
				--add drops
				if math.random() < delta * 10 * self.rain_strength * self.rain_rain then
					drops[#drops+1] = {
						x = math.random(),
						y = math.random(),
						size = 0.5 + math.random(),
						time = -0.5,
					}
				end
				
				--update drops
				for i = #drops, 1, -1 do
					local s = drops[i]
					s.time = s.time + dt * 2.0
					if s.time > 2.0 then
						table.remove(drops, i)
					end
				end
				
				--splash texture
				if self.rain_rain > 0 or lastRender then
					love.graphics.push("all")
					love.graphics.setCanvas(self.canvas_rain)
					love.graphics.setBlendMode("add", "premultiplied")
					love.graphics.clear(0.0, 0.0, 1.0)
					if self.rain_rain > 0 then
						love.graphics.setShader(self.shaders.rain_splashes)
						local w, h = self.canvas_rain:getDimensions()
						for d,s in ipairs(drops) do
							self.shaders.rain_splashes:send("time", s.time)
							
							local wx = (s.x > 0.5 and (s.x - 1.0) or (s.x + 1.0))
							local wy = (s.y > 0.5 and (s.y - 1.0) or (s.y + 1.0))
							
							love.graphics.draw(self.textures.splash, s.x * w, s.y * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
							love.graphics.draw(self.textures.splash, s.x * w, wy * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
							love.graphics.draw(self.textures.splash, wx * w, s.y * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
							love.graphics.draw(self.textures.splash, wx * w, wy * h, 0, s.size * (1.0 + s.time), nil, 32, 32)
						end
					end
					love.graphics.pop()
				end
			end
		end
		
		--executions per second
		if delta > 0 then
			local eps = 1 / delta
			executionsPerSecond[o[1]] = (executionsPerSecond[o[1]] or eps) * 0.9 + eps * 0.1
		end
		
		--measure time to adjust
		local delta = math.min(love.timer.getTime() - time, 1 / 10)
		timeRequirement[o[1]] = (timeRequirement[o[1]] or delta) * 0.9 + delta * 0.1
		executions[o[1]] = (executions[o[1]] or 0) + 1
		
		--limit processing time
		timeAvailable = timeAvailable - (timeRequirement[o[1]] or 1 / 1000)
		if timeAvailable <= 0 then
			break
		end
	end
	
	local delta = love.timer.getTime() - t
	self.jobRenderTime = self.jobRenderTime + delta
end