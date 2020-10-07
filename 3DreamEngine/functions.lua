--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

function lib:resetLight(noDayLight)
	self.lighting = { }
	
	if not noDayLight then
		local l = self.sun:normalize()
		local c = self.sun_color
		
		self.sunObject.x = l[1]
		self.sunObject.y = l[2]
		self.sunObject.z = l[3]
		self.sunObject.r = c[1]
		self.sunObject.g = c[2]
		self.sunObject.b = c[3]
		
		self:addLight(self.sunObject)
	end
end

function lib:addLight(light)
	self.lighting[#self.lighting+1] = light
end

function lib:addNewLight(...)
	self:addLight(self:newLight(...))
end

function lib:split(text, sep)
	local sep, fields = sep or ":", { }
	local pattern = string.format("([^%s]+)", sep)
	text:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function lib:lookAt(eye, at, up)
	up = up or vec3(0.0, 1.0, 0.0)
	
	zaxis = (at - eye):normalize()
	xaxis = zaxis:cross(up):normalize()
	yaxis = xaxis:cross(zaxis)

	zaxis = -zaxis
	
	return mat4(
		xaxis.x, xaxis.y, xaxis.z, -xaxis:dot(eye),
		yaxis.x, yaxis.y, yaxis.z, -yaxis:dot(eye),
		zaxis.x, zaxis.y, zaxis.z, -zaxis:dot(eye),
		0, 0, 0, 1
	)
end

--add tangents to a 3Dream vertex format
--x, y, z, shaderData, nx, ny, nz, materialID, u, v, tx, ty, tz, btx, bty, btz
function lib:calcTangents(o)
	o.tangents = { }
	for i = 1, #o.vertices do
		o.tangents[i] = {0, 0, 0}
	end
	
	for i,f in ipairs(o.faces) do
		--vertices
		local v1 = o.vertices[f[1]]
		local v2 = o.vertices[f[2]]
		local v3 = o.vertices[f[3]]
		
		--tex coords
		local uv1 = o.texCoords[f[1]]
		local uv2 = o.texCoords[f[2]]
		local uv3 = o.texCoords[f[3]]
		
		local tangent = { }
		
		local edge1 = {v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]}
		local edge2 = {v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]}
		local edge1uv = {uv2[1] - uv1[1], uv2[2] - uv1[2]}
		local edge2uv = {uv3[1] - uv1[1], uv3[2] - uv1[2]}
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
			end
			
			--sum up tangents to smooth across shared vertices
			for i = 1, 3 do
				o.tangents[f[i]][1] = o.tangents[f[i]][1] + tangent[1]
				o.tangents[f[i]][2] = o.tangents[f[i]][2] + tangent[2]
				o.tangents[f[i]][3] = o.tangents[f[i]][3] + tangent[3]
			end
		end
	end
	
	--normalize
	for i,f in ipairs(o.tangents) do
		local l = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
		f[1] = f[1] / l
		f[2] = f[2] / l
		f[3] = f[3] / l
	end	
	
	--complete smoothing step
	for i,f in ipairs(o.tangents) do
		local n = o.normals[i]
		
		--Gram-Schmidt orthogonalization
		local dot = (f[1] * n[1] + f[2] * n[2] + f[3] * n[3])
		f[1] = f[1] - n[1] * dot
		f[2] = f[2] - n[2] * dot
		f[3] = f[3] - n[3] * dot
		
		local l = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
		f[1] = f[1] / l
		f[2] = f[2] / l
		f[3] = f[3] / l
	end
end

function lib:HSVtoRGB(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	
	if i % 6 == 0 then
		return v, t, p
	elseif i % 6 == 1 then
		return q, v, p
	elseif i % 6 == 2 then
		return p, v, t
	elseif i % 6 == 3 then
		return p, q, v
	elseif i % 6 == 4 then
		return t, p, v
	else
		return v, p, q
	end
end

function lib:RGBtoHSV(r, g, b)
	local h, s, v
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)

	local v = max
	local delta = max - min
	if max ~= 0 then
		s = delta / max
	else
		r, g, b = 0, 0, 0
		s = 0
		h = -1
		return h, s, 0.0
	end
	
	if r == max then
		h = (g - b) / delta
	elseif g == max then
		h = 2 + (b - r) / delta
	else
		h = 4 + (r - g) / delta
	end
	
	h = h * 60 / 360
	if h < 0 then
		h = h + 1
	elseif delta == 0 then
		h = 0
	end
	
	return h, s, v
end

function lib:decodeObjectName(name)
	if self.nameDecoder == "blender" then
		local last, f = 0, false
		while last and string.find(name, "_", last+1) do
			f, last = string.find(name, "_", last+1)
		end
		return name:sub(1, f and (f-1) or #name)
	else
		return name
	end
end

function lib:pointToPixel(point, cam, canvases)
	cam = cam or self.cam
	canvases = canvases or self.canvases
	
	local p = cam.transformProj * vec4(point[1], point[2], point[3], 1.0)
	
	return vec3((p[1] / p[4] + 1) * canvases.width/2, (p[2] / p[4] + 1) * canvases.height/2, p[3])
end

function lib:pixelToPoint(point, cam, canvases)
	cam = cam or self.cam
	canvases = canvases or self.canvases
	
	local inv = cam.transformProj:invert()
	
	--(-1, 1) normalized coords
	local x = (point[1] * 2 / canvases.width - 1)
	local y = (point[2] * 2 / canvases.height - 1)
	
	--projection onto the far and near plane
	local near = inv * vec4(x, y, -1, 1)
	local far = inv * vec4(x, y, 1, 1)
	
	--perspective divice
	near = near / near.w
	far = far / far.w
	
	--normalized depth
	local depth = (point[3] - cam.near) / (cam.far - cam.near)
	
	--interpolate between planes based on depth
	return vec3(near) * (1.0 - depth) + vec3(far) * depth
end

function lib:setDaytime(time)
	--time, 0.0 is sunrise, 0.5 is sunset
	self.sky_time = time % 1.0
	self.sky_day = math.floor(time % 30.0)
	
	--position
	self.sun = mat4:getRotateZ(self.sun_offset) * vec3(
		0,
		math.sin(self.sky_time * math.pi * 2),
		-math.cos(self.sky_time * math.pi * 2)
	):normalize()
	
	local c = #self.sunlight
	local p = self.sky_time * c
	self.sun_color_raw = (
		self.sunlight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.sunlight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
	self.sun_color = self.sun_color_raw
	
	self.sun_ambient_raw = (
		self.skylight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.skylight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
	self.sun_ambient = self.sun_ambient_raw
end

--0 is the happiest day ever and 1 the end of the world
function lib:setWeather(rain, temp)
	rain = rain or 0.0
	temp = temp or (1.0 - rain)
	
	self.weather_rain = rain
	self.weather_temperature = temp
	
	--blue-darken ambient and sun color
	local color = rain * 0.75
	local darkBlue = vec3(30, 40, 60):normalize() * self.sun_color:length()
	self.sun_color = darkBlue * 0.2 * color + self.sun_color * (1.0 - color)
	self.sun_ambient = darkBlue * 0.1 * color + self.sun_ambient * (1.0 - color)
	self.sky_color = darkBlue * 0.25 * color + vec3(1.0, 1.0, 1.0) * (1.0 - color)
	
	--set module settings
	self:getShaderModule("rain").isRaining = rain > 0.4
	self:getShaderModule("rain").strength = math.ceil(math.clamp((rain-0.4) / 0.6 * 5.0, 0.001, 5.0))
end

function lib:inFrustum(cam, pos, radius)
	local dir = pos - cam.pos
	local dist = dir:length()
	
	--check if within bounding sphere as the angle check fails on close distance
	if dist < radius * 2 + 0.5 then
		return true
	end
	
	--the additional margin visible due to its size
	local margin = radius / dist / math.pi * 2
	
	--the visible angle based on fov
	local angle = cam.fov / 180 * (1.0 + (cam.aspect - 1.0) * 0.25)
	
	--if it is within this threshold
	return (dir / dist):dot(cam.normal) > 1.0 - angle - margin
end

--get the collision data from a mesh
--it moves the collider to its bounding box center, transform therefore should not be changed directly
local hashes = { }
local function hash(a, b)
	return math.min(a, b) * 9999 + math.max(a, b)
end
function lib:getCollisionData(object)
	--its a subobject
	local n = { }
	
	--data required by the collision extension
	n.typ = "mesh"
	n.transform = object.boundingBox and object.boundingBox.center or vec3(0, 0, 0)
	n.boundary = 0
	
	if object.transform then
		n.transform = object.transform * n.transform
	end
	
	--data
	n.faces = { }
	n.normals = { }
	n.edges = { }
	n.point = vec3(0, 0, 0)
	
	hashes = { }
	for d,s in ipairs(object.faces) do
		--vertices
		local a = (object.transform and object.transform * vec3(object.vertices[s[1]]) or vec3(object.vertices[s[1]])) - n.transform
		local b = (object.transform and object.transform * vec3(object.vertices[s[2]]) or vec3(object.vertices[s[2]])) - n.transform
		local c = (object.transform and object.transform * vec3(object.vertices[s[3]]) or vec3(object.vertices[s[3]])) - n.transform
		
		--face normal
		local normal = (b-a):cross(c-a):normalize()
		table.insert(n.normals, normal)
		
		n.point = a
		
		--boundary
		n.boundary = math.max(n.boundary, a:length(), b:length(), c:length())
		
		--face
		table.insert(n.faces, {a, b, c})
		
		--edges
		local id
		id = hash(s[1], s[2])
		if not hashes[id] then
			table.insert(n.edges, {a, b})
			hashes[id] = true
		end
		
		id = hash(s[1], s[3])
		if not hashes[id] then
			table.insert(n.edges, {a, c})
			hashes[id] = true
		end
		
		id = hash(s[2], s[3])
		if not hashes[id] then
			table.insert(n.edges, {b, c})
			hashes[id] = true
		end
	end
	
	return n
end

do
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
	
	function lib.blurCubeMap(self, cube, level)
		local f = cube:getFormat()
		local resolution = math.ceil(cube:getWidth() / 2)
		
		--create canvases if needed
		self.cache.blurCubeMap = self.cache.blurCubeMap or { }
		local cache = self.cache.blurCubeMap
		cache[f] = cache[f] or { }
		if not cache[f][resolution] then
			cache[f][resolution] = { }
		end
		if not cache[f][resolution][level] then
			local size = math.ceil(resolution / math.max(1, 2^(level-1)))
			cache[f][resolution][level] = love.graphics.newCanvas(size, size, {format = f, readable = true, msaa = 0, type = "2d", mipmaps = "none"})
		end
		
		--blurring
		love.graphics.push("all")
		love.graphics.reset()
		love.graphics.setBlendMode("replace", "premultiplied")
		
		local can = cache[f][resolution][level]
		local res = can:getWidth()
		for side = 1, 6 do
			love.graphics.setCanvas(can)
			love.graphics.setShader(self.shaders.blur_cube)
			self.shaders.blur_cube:send("tex", cube)
			self.shaders.blur_cube:send("strength", 0.025)
			self.shaders.blur_cube:send("scale", 1.0 / res)
			self.shaders.blur_cube:send("normal", blurVecs[side][1])
			self.shaders.blur_cube:send("dirX", blurVecs[side][2])
			self.shaders.blur_cube:send("dirY", blurVecs[side][3])
			self.shaders.blur_cube:send("lod", level - 2.0)
			love.graphics.rectangle("fill", 0, 0, res, res)
			
			--paste
			love.graphics.setCanvas(cube, side, level)
			love.graphics.setShader()
			love.graphics.draw(can, 0, 0, 0, 2)
		end
		
		love.graphics.pop()
	end
end

function lib:takeScreenshot()
	if love.keyboard.isDown("lctrl") then
		love.system.openURL(love.filesystem.getSaveDirectory() .. "/screenshots")
	else
		love.filesystem.createDirectory("screenshots")
		if not screenShotThread then
			screenShotThread = love.thread.newThread([[
				require("love.image")
				channel = love.thread.getChannel("screenshots")
				while true do
					local screenshot = channel:demand()
					screenshot:encode("png", "screenshots/screen_" .. tostring(os.time()) .. ".png")
				end
			]]):start()
		end
		love.graphics.captureScreenshot(love.thread.getChannel("screenshots"))
	end
end

function lib:take3DScreenshot(pos, resolution, path)
	local lookNormals = self.lookNormals
	resolution = resolution or 512
	local canvases = self:newCanvasSet(resolution, resolution, 8, self.deferred, false)
	local results = love.graphics.newCanvas(resolution, resolution, {format = "rgba16f", type = "cube", mipmaps = "manual"})
	
	--view matrices
	local transformations = {
		self:lookAt(pos, pos + lookNormals[1], vec3(0, -1, 0)),
		self:lookAt(pos, pos + lookNormals[2], vec3(0, -1, 0)),
		self:lookAt(pos, pos + lookNormals[3], vec3(0, 0, -1)),
		self:lookAt(pos, pos + lookNormals[4], vec3(0, 0, 1)),
		self:lookAt(pos, pos + lookNormals[5], vec3(0, -1, 0)),
		self:lookAt(pos, pos + lookNormals[6], vec3(0, -1, 0)),
	}
	
	--render all faces
	for face = 1, 6 do
		love.graphics.push("all")
		love.graphics.reset()
		love.graphics.setCanvas({{results, face = face}})
		love.graphics.clear()
		
		--render
		local cam = self:newCam(transformations[face], self.cubeMapProjection, pos, lookNormals[face])
		lib:renderFull(cam, canvases, false)
		
		love.graphics.pop()
	end
	
	--blur cubemap
	for level = 2, results:getMipmapCount() do
		self:blurCubeMap(results, level)
	end
	
	--export mimg data
	cimg:export(results, path or "results.cimg")
end

--global shader modules
lib.activeShaderModules = { }
lib.allActiveShaderModules = { }
function lib:activateShaderModule(name)
	self.activeShaderModules[name] = true
end
function lib:deactivateShaderModule(name)
	self.activeShaderModules[name] = nil
end
function lib:getShaderModule(name)
	return self.shaderLibrary.module[name]
end
function lib:isShaderModuleActive(name)
	return self.activeShaderModules[name]
end