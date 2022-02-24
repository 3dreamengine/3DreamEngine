--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

function lib:addLight(light)
	table.insert(self.lighting, light)
end

function lib:addNewLight(...)
	self:addLight(self:newLight(...))
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


--todo the frustum culling code fails for close objects, a constant factor "fix" it but it's not fixing the actual problem
local perspectiveWarpFactor = 1.5

--optimized plane frustum check
local cache = { }
function lib:inFrustum(cam, pos, radius, id)
	radius = radius * perspectiveWarpFactor
	
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

--4 times slower but performs correct clamping to the edge
--code translated and adapted from www.geometrictools.com
function lib:getBarycentricClamped(x, y, x1, y1, x2, y2, x3, y3)
	local diffX = x1 - x
	local diffY = y1 - y
	local edge1X = x2 - x1
	local edge1Y = y2 - y1
	local edge2X = x3 - x1
	local edge2Y = y3 - y1
	local a00 = edge1X^2 + edge1Y^2
	local a01 = edge1X * edge2X + edge1Y * edge2Y
	local a11 = edge2X^2 + edge2Y^2
	local b0 = diffX * edge1X + diffY * edge1Y
	local b1 = diffX * edge2X + diffY * edge2Y
	local det = a00 * a11 - a01 * a01
	local t1 = a01 * b1 - a11 * b0
	local t2 = a01 * b0 - a00 * b1

	if t1 + t2 <= det then
		if t1 < 0 then
			if t2 < 0 then
				if b0 < 0 then
					t2 = 0
					if -b0 >= a00 then
						t1 = 1
					else
						t1 = -b0 / a00
					end
				else
					t1 = 0
					if b1 >= 0 then
						t2 = 0
					elseif -b1 >= a11 then
						t2 = 1
					else
						t2 = -b1 / a11
					end
				end
			else
				t1 = 0
				if b1 >= 0 then
					t2 = 0
				elseif -b1 >= a11 then
					t2 = 1
				else
					t2 = -b1 / a11
				end
			end
		elseif t2 < 0 then
			t2 = 0
			if b0 >= 0 then
				t1 = 0
			elseif -b0 >= a00 then
				t1 = 1
			else
				t1 = -b0 / a00
			end
		else
			local invDet = 1 / det
			t1 = t1 * invDet
			t2 = t2 * invDet
		end
	else
		if t1 < 0 then
			local tmp0 = a01 + b0
			local tmp1 = a11 + b1
			if tmp1 > tmp0 then
				local numer = tmp1 - tmp0
				local denom = a00 - 2 * a01 + a11
				if numer >= denom then
					t1 = 1
					t2 = 0
				else
					t1 = numer / denom
					t2 = 1 - t1
				end
			else
				t1 = 0
				if tmp1 <= 0 then
					t2 = 1
				elseif b1 >= 0 then
					t2 = 0
				else
					t2 = -b1 / a11
				end
			end
		elseif t2 < 0 then
			local tmp0 = a01 + b1
			local tmp1 = a00 + b0
			if tmp1 > tmp0 then
				local numer = tmp1 - tmp0
				local denom = a00 - 2 * a01 + a11
				if numer >= denom then
					t2 = 1
					t1 = 0
				else
					t2 = numer / denom
					t1 = 1 - t2
				end
			else
				t2 = 0
				if tmp1 <= 0 then
					t1 = 1
				elseif b0 >= 0 then
					t1 = 0
				else
					t1 = -b0 / a00
				end
			end
		else
			local numer = a11 + b1 - a01 - b0
			if numer <= 0 then
				t1 = 0
				t2 = 1
			else
				local denom = a00 - 2 * a01 + a11
				if numer >= denom then
					t1 = 1
					t2 = 0
				else
					t1 = numer / denom
					t2 = 1 - t1
				end
			end
		end
	end
	
	return 1 - t1 - t2, t1, t2
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

function lib:decodeBoundaryBox(bb)
	return {
		first = vec3(bb.first),
		second = vec3(bb.second),
		center = vec3(bb.center),
		size = bb.size,
		initialized = bb.initialized
	}
end

function lib:blurCanvas(canvas, strength, iterations, mask)
	local temp = self:getTemporaryCanvas(canvas)
	local sh = lib:getBasicShader("blur")
	love.graphics.push("all")
	love.graphics.reset()
	if mask then
		love.graphics.setColorMask(unpack(mask))
	end
	love.graphics.setBlendMode("replace", "premultiplied")
	love.graphics.setShader(sh)
	
	for i = iterations, 1, -1 do
		sh:send("dir", {2^(i-1) / canvas:getWidth() * strength, 0})
		love.graphics.setCanvas(temp)
		love.graphics.draw(canvas)
		
		sh:send("dir", {0, 2^(i-1) / canvas:getHeight() * strength})
		love.graphics.setCanvas(canvas)
		love.graphics.draw(temp)
	end
	love.graphics.pop()
end

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

--if the system supports 6+ multicanvas (which most modern systems do) we can use the faster variant
function lib:getTemporaryCanvas(canvas, half)
	local id = canvas:getWidth() .. canvas:getFormat() .. canvas:getHeight() .. (half and "H" or "F")
	if not self.canvasCache[id] then
		self.canvasCache[id] = love.graphics.newCanvas(canvas:getWidth() / (half and 2 or 1), canvas:getHeight() / (half and 2 or 1), {
			format = canvas:getFormat(),
			readable = canvas:isReadable(),
			msaa = canvas:getMSAA(),
			type = canvas:getTextureType(),
			mipmaps = canvas:getMipmapMode()})
	end
	return self.canvasCache[id]
end

local function setMultiCubeMap(cube, level)
	love.graphics.setCanvas({
		{cube, face = 1, mipmap = level},
		{cube, face = 2, mipmap = level},
		{cube, face = 3, mipmap = level},
		{cube, face = 4, mipmap = level},
		{cube, face = 5, mipmap = level},
		{cube, face = 6, mipmap = level},
	})
end

if love.graphics.getSystemLimits().multicanvas >= 6 then
	function lib:blurCubeMap(cube, layers, strength, mask, blurFirst)
		local temp = self:getTemporaryCanvas(cube, not blurFirst)
		local shader = self:getBasicShader("blur_cube_multi")
		
		love.graphics.push("all")
		love.graphics.reset()
		if mask then
			love.graphics.setColorMask(unpack(mask))
		end
		love.graphics.setBlendMode("replace", "premultiplied")
		
		love.graphics.setShader(shader)
		shader:send("strength", strength or 0.1)
		
		for level = blurFirst and 1 or 2, layers do
			local res = cube:getWidth() / 2 ^ (level - 1)
			
			shader:send("scale", 1.0 / res)
			shader:send("lod", math.max(0, level - 2))
			shader:send("dir", 0.0)
			shader:send("tex", cube)
			setMultiCubeMap(temp, level - (blurFirst and 0 or 1))
			love.graphics.rectangle("fill", 0, 0, res, res)
			
			shader:send("dir", 1.0)
			shader:send("lod", level - (blurFirst and 1 or 2))
			shader:send("tex", temp)
			setMultiCubeMap(cube, level)
			love.graphics.rectangle("fill", 0, 0, res, res)
		end
		
		love.graphics.pop()
	end
else
	function lib:blurCubeMap(cube, layers, strength, mask, blurFirst)
		local temp = self:getTemporaryCanvas(cube, not blurFirst)
		local shader = self:getBasicShader("blur_cube")
		
		love.graphics.push("all")
		love.graphics.reset()
		if mask then
			love.graphics.setColorMask(unpack(mask))
		end
		love.graphics.setBlendMode("replace", "premultiplied")
		
		love.graphics.setShader(shader)
		shader:send("strength", strength or 0.1)
		
		for level = blurFirst and 1 or 2, layers do
			local res = cube:getWidth() / 2 ^ (level - 1)
			shader:send("scale", 1.0 / res)
			for side = 1, 6 do
				shader:send("normal", blurVecs[side][1])
				shader:send("dirX", blurVecs[side][2])
				shader:send("dirY", blurVecs[side][3])
				
				love.graphics.setCanvas(temp, side, level - (blurFirst and 0 or 1))
				shader:send("dir", 0.0)
				shader:send("tex", cube)
				shader:send("lod", math.max(0, level - 2))
				love.graphics.rectangle("fill", 0, 0, res, res)
				
				love.graphics.setCanvas(cube, side, level)
				shader:send("dir", 1.0)
				shader:send("tex", temp)
				shader:send("lod", level - (blurFirst and 1 or 2))
				love.graphics.rectangle("fill", 0, 0, res, res)
			end
		end
		
		love.graphics.pop()
	end
end

function lib:takeScreenshot()
	if love.keyboard.isDown("lctrl") then
		love.system.openURL(love.filesystem.getSaveDirectory() .. "/screenshots")
	else
		love.filesystem.createDirectory("screenshots")
		if not self.screenShotThread then
			self.screenShotThread = love.thread.newThread([[
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
		local cam = self:newCamera(transformations[face], self.cubeMapProjection, pos, lookNormals[face])
		lib:renderFull(cam, canvases, true)
		
		love.graphics.pop()
	end
	
	--blur cubemap
	self:blurCubeMap(results, results:getMipmapCount())
	
	--export cimg data
	cimg:export(results, path or "results.cimg")
	
	return results
end

function lib:HDRItoCubemap(hdri, resolution)
	local shader = self:getBasicShader("HDRItoCubemap")
	local canvas = love.graphics.newCanvas(resolution * 6, resolution)
	
	hdri:setWrap("repeat", "mirroredrepeat")
	
	love.graphics.push("all")
	love.graphics.setShader(shader)
	love.graphics.setCanvas(canvas)
	love.graphics.draw(hdri, 0, 0, 0, canvas:getWidth() / hdri:getWidth(), canvas:getHeight() / hdri:getHeight())
	love.graphics.pop()
	
	return canvas
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

--cubemap projection
local n = 0.01
local f = 1000.0
local fov = 90
local scale = math.tan(fov/2*math.pi/180)
local r = scale * n
local l = -r

lib.cubeMapProjection = mat4(
	2*n / (r-l),   0,              (r+l) / (r-l),     0,
	0,             -2*n / (r - l),  (r+l) / (r-l),     0,
	0,             0,              -(f+n) / (f-n),    -2*f*n / (f-n),
	0,             0,              -1,                0
)

function lib:removePostfix(t)
	local f = t:find(".", 0, true)
	return f and t:sub(1, f - 1) or t
end