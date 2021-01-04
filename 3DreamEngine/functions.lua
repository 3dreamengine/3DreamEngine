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
	
	local zaxis = (at - eye):normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	return mat4(
		xaxis.x, xaxis.y, xaxis.z, -xaxis:dot(eye),
		yaxis.x, yaxis.y, yaxis.z, -yaxis:dot(eye),
		-zaxis.x, -zaxis.y, -zaxis.z, zaxis:dot(eye),
		0, 0, 0, 1
	)
end

function lib:lookInDirection(at, up)
	up = up or vec3(0.0, 1.0, 0.0)
	
	local zaxis = at:normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	return mat4(
		xaxis.x, xaxis.y, xaxis.z, 0.0,
		yaxis.x, yaxis.y, yaxis.z, 0.0,
		-zaxis.x, -zaxis.y, -zaxis.z, 0.0,
		0, 0, 0, 1
	)
end

--add tangents to a 3Dream vertex format
--x, y, z, shaderData, nx, ny, nz, materialID, u, v, tx, ty, tz, btx, bty, btz
local empty = {0, 0, 0}
function lib:calcTangents(o)
	o.tangents = { }
	for i = 1, #o.vertices do
		o.tangents[i] = {0, 0, 0, 0}
	end
	
	for i,f in ipairs(o.faces) do
		--vertices
		local v1 = o.vertices[f[1]] or empty
		local v2 = o.vertices[f[2]] or empty
		local v3 = o.vertices[f[3]] or empty
		
		--tex coords
		local uv1 = o.texCoords[f[1]] or empty
		local uv2 = o.texCoords[f[2]] or empty
		local uv3 = o.texCoords[f[3]] or empty
		
		local tangent = { }
		
		local edge1 = {v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]}
		local edge2 = {v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]}
		local edge1uv = {uv2[1] - uv1[1], uv2[2] - uv1[2]}
		local edge2uv = {uv3[1] - uv1[1], uv3[2] - uv1[2]}
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			--handle clockwise-uvs
			local clockwise = mat3(uv1[1], uv1[2], 1, uv2[1], uv2[2], 1, uv3[1], uv3[2], 1):det() > 0
			
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
			end
			
			--sum up tangents to smooth across shared vertices
			for i = 1, 3 do
				o.tangents[f[i]][1] = o.tangents[f[i]][1] + tangent[1]
				o.tangents[f[i]][2] = o.tangents[f[i]][2] + tangent[2]
				o.tangents[f[i]][3] = o.tangents[f[i]][3] + tangent[3]
				o.tangents[f[i]][4] = o.tangents[f[i]][4] + (clockwise and 1 or 0)
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
	if self.nameDecoder then
		local n = string.match(name, self.nameDecoder)
		return n or name
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

--prepares a camera to support plane frustum checks
function lib:getFrustumPlanes(m)
	local planes = {vec4(), vec4(), vec4(), vec4(), vec4(), vec4()}
	for i = 1, 4 do
		planes[1][i] = m[12 + i] + m[0 + i]
		planes[2][i] = m[12 + i] - m[0 + i]
		planes[3][i] = m[12 + i] + m[4 + i]
		planes[4][i] = m[12 + i] - m[4 + i]
		planes[5][i] = m[12 + i] + m[8 + i]
		planes[6][i] = m[12 + i] - m[8 + i]
	end
	return planes
end

--optimized plane frustum check
local cache = { }
function lib:planeInFrustum(cam, pos, radius, id)
	local c = cache[id]
	if c then
		local plane = cam.planes[c]
		local dist = plane[1] * pos[1] + plane[2] * pos[2] + plane[3] * pos[3] + plane[4]
		if dist + radius < 0.0 then
			return false
		end
		cache[id] = nil
	end
	
	for i = 1, 4 do
		if i ~= c then
			local plane = cam.planes[i]
			local dist = plane[1] * pos[1] + plane[2] * pos[2] + plane[3] * pos[3] + plane[4]
			if dist + radius < 0.0 then
				cache[id] = i
				return false
			end
		end
	end
	return true
end

function lib:getBarycentric(x, y, x1, y1, x2, y2, x3, y3)
	local det = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
	local w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / det
	local w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / det
	local w3 = 1 - w1 - w2
	return w1, w2, w3
end

function lib:newBoundaryBox(initialized)
	return {
		first = vec3(math.huge, math.huge, math.huge),
		second = vec3(-math.huge, -math.huge, -math.huge),
		center = vec3(0.0, 0.0, 0.0),
		size = 0,
		initialized = initialized or false
	}
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
		local shader = self:getShader("blur_cube")
		for side = 1, 6 do
			love.graphics.setCanvas(can)
			love.graphics.setShader(shader)
			shader:send("tex", cube)
			shader:send("strength", 0.025)
			shader:send("scale", 1.0 / res)
			shader:send("normal", blurVecs[side][1])
			shader:send("dirX", blurVecs[side][2])
			shader:send("dirY", blurVecs[side][3])
			shader:send("lod", level - 2.0)
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
	local canvases = self:newCanvasSet(self.renderSet, resolution, resolution)
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
		local scene = self:buildScene(cam, canvases, "render")
		
		lib:renderFull(scene, cam, canvases)
		
		love.graphics.pop()
	end
	
	--blur cubemap
	for level = 2, results:getMipmapCount() do
		self:blurCubeMap(results, level)
	end
	
	--export cimg data
	cimg:export(results, path or "results.cimg")
end

--view normals
lib.lookNormals = {
	vec3(1, 0, 0),
	vec3(-1, 0, 0),
	vec3(0, -1, 0),
	vec3(0, 1, 0),
	vec3(0, 0, 1),
	vec3(0, 0, -1),
}

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