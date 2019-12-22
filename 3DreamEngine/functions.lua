--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

function lib.newCam(self)
	local c = {
		transform = matrix{
			{1, 0, 0, 0},
			{0, 1, 0, 0},
			{0, 0, 1, 0},
			{0, 0, 0, 1},
		},
		
		normal = {0, 0, 0},
		
		x = 0,
		y = 0,
		z = 0,
	}
	
	setmetatable(c, self.operations)
	
	return c
end

function lib.resetLight(self, noDayLight)
	if noDayLight then
		self.lighting = { }
	else
		local l = math.sqrt(self.sun[1]^2 + self.sun[2]^2 + self.sun[3]^2)
		self.lighting = {
			{
				x = self.sun[1] / l,
				y = self.sun[2] / l,
				z = self.sun[3] / l,
				r = self.color_sun[1] / math.sqrt(self.color_sun[1]^2 + self.color_sun[2]^2 + self.color_sun[3]^2) * self.color_sun[4],
				g = self.color_sun[2] / math.sqrt(self.color_sun[1]^2 + self.color_sun[2]^2 + self.color_sun[3]^2) * self.color_sun[4],
				b = self.color_sun[3] / math.sqrt(self.color_sun[1]^2 + self.color_sun[2]^2 + self.color_sun[3]^2) * self.color_sun[4],
				meter = 0.0,
				importance = math.huge,
			},
		}
	end
end

function lib.addLight(self, posX, posY, posZ, red, green, blue, brightness, meter, importance)
	self.lighting[#self.lighting+1] = {
		x = posX,
		y = posY,
		z = posZ,
		r = red / math.sqrt(red^2+green^2+blue^2) * (brightness or 10.0),
		g = green / math.sqrt(red^2+green^2+blue^2) * (brightness or 10.0),
		b = blue / math.sqrt(red^2+green^2+blue^2) * (brightness or 10.0),
		meter = meter or 1.0,
		importance = importance or 1.0,
	}
end

lib.operations = { }
lib.operations.__index = lib.operations

function lib.operations.reset(obj)
	obj.transform = matrix{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
end

function lib.operations.translate(obj, x, y, z)
	local translate = matrix{
		{1, 0, 0, x},
		{0, 1, 0, y},
		{0, 0, 1, z},
		{0, 0, 0, 1},
	}
	obj.transform = translate * obj.transform
end

function lib.operations.scale(obj, x, y, z)
	local scale = matrix{
		{x, 0, 0, 0},
		{0, y or x, 0, 0},
		{0, 0, z or x, 0},
		{0, 0, 0, 1},
	}
	obj.transform = scale * obj.transform
end

function lib.operations.rotateX(obj, rx)
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	local rotX = matrix{
		{1, 0, 0, 0},
		{0, c, -s, 0},
		{0, s, c, 0},
		{0, 0, 0, 1},
	}
	obj.transform = rotX * obj.transform
end

function lib.operations.rotateY(obj, ry)
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	local rotY = matrix{
		{c, 0, -s, 0},
		{0, 1, 0, 0},
		{s, 0, c, 0},
		{0, 0, 0, 1},
	}
	obj.transform = rotY * obj.transform
end

function lib.operations.rotateZ(obj, rz)
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	local rotZ = matrix{
		{c, s, 0, 0},
		{-s, c, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
	obj.transform = rotZ * obj.transform
end

function lib.split(self, text, sep)
	local sep, fields = sep or ":", { }
	local pattern = string.format("([^%s]+)", sep)
	text:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function lib.rotatePoint(self, x, y, rot)
	local c = math.cos(rot)
	local s = math.sin(rot)
	return x * c - y * s, x * s + y * c
end

lib.dayLightColors = {
	{50, 50, 253,	1},
	{86, 86, 251,	1},
	{134, 134, 250,	0.95},
	{180, 180, 250,	0.9},
	{217, 218, 252,	0.85},
	{250, 251, 255,	0.8},
	{254, 248, 238,	0.75},
	{249, 228, 199,	0.7},
	{245, 210, 161,	0.65},
	{242, 192, 126,	0.6},
	{238, 176, 89,	0.55},
	{236, 156, 57,	0.5},
	{239, 123, 42,	0.45},
	{243, 89, 31,	0.4},
	{247, 56, 19,	0.35},
	{251, 39, 25,	0.3},
}
for i = #lib.dayLightColors, 1, -1 do
	local c = lib.dayLightColors[i]
	lib.dayLightColors[#lib.dayLightColors+1] = {c[1], c[2], c[3], 0.25}
end
for i = #lib.dayLightColors, 1, -1 do
	local c = lib.dayLightColors[i]
	lib.dayLightColors[#lib.dayLightColors+1] = {c[1], c[2], c[3], c[4]}
end
for d,s in ipairs(lib.dayLightColors) do
	s[1] = s[1] / 255
	s[2] = s[2] / 255
	s[3] = s[3] / 255
end

--get the daylight color at a specific daytime, where 0 is midnight
function lib.getDayLight(self, time, strength)
	if not strength then
		strength = 0.1
	end
	if not time then
		time = self.dayTime
	end
	
	local c1 = self.dayLightColors[(math.floor(time*#self.dayLightColors) % #self.dayLightColors)+1]
	local c2 = self.dayLightColors[((math.floor(time*#self.dayLightColors)+1) % #self.dayLightColors)+1]
	local f = (time*#self.dayLightColors) % 1
	
	local direct = {c1[1] * (1-f) + c2[1] * f, c1[2] * (1-f) + c2[2] * f, c1[3] * (1-f) + c2[3] * f, math.min(1, c1[4] * (1-f) + c2[4] * f)}
	direct[1] = 1.0 * (1-strength) + direct[1] * strength
	direct[2] = 1.0 * (1-strength) + direct[2] * strength
	direct[3] = 1.0 * (1-strength) + direct[3] * strength
	
	local ambient = {direct[1], direct[2], direct[3], 0.25 + direct[4]*0.25}
	
	return direct, ambient
end

function lib.generateMipMaps(self, path)
	local dir, filename, filetyp = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	filename = filename:sub(1, #filename-#filetyp - (#filetyp > 0 and 1 or 0))
	
	love.filesystem.createDirectory(dir)
	
	love.graphics.push()
	love.graphics.reset()
	
	local img = love.graphics.newImage(path)
	local x, y = img:getWidth(), img:getHeight()
	local i = 0
	while x > 1 or y > 1 do
		x = math.max(1, math.floor(x/2))
		y = math.max(1, math.floor(y/2))
		i = i + 1
		
		local canv = love.graphics.newCanvas(x, y)
		love.graphics.setCanvas(canv)
		img:setFilter("nearest")
		love.graphics.draw(img, 0, 0, 0, 0.5 ^ i)
		img:setFilter("linear")
		love.graphics.draw(img, 0, 0, 0, 0.5 ^ i)
		love.graphics.setCanvas()
		
		canv:newImageData():encode("png", dir .. filename .. "_" .. i .. ".png")
	end
	
	love.graphics.pop()
end

--add tangents to a 3Dream vertex format
--x, y, z, shaderData, nx, ny, nz, materialID, u, v, tx, ty, tz, btx, bty, btz
function lib.calcTangents(self, finals, vertexMap)
	--expand uv if missing
	for d,f in ipairs(finals) do
		f[9] = f[9] or 0
		f[10] = f[10] or 0
		
		f[11] = 0
		f[12] = 0
		f[13] = 0
		f[14] = 0
		f[15] = 0
		f[16] = 0
	end
	
	--9-10 UV
	--5-7 Normal
	
	for f = 1, #vertexMap, 3 do
		local P1 = finals[vertexMap[f+0]]
		local P2 = finals[vertexMap[f+1]]
		local P3 = finals[vertexMap[f+2]]
		
		local tangent = { }
		local bitangent = { }
		
		local edge1 = {P2[1] - P1[1], P2[2] - P1[2], P2[3] - P1[3]}
		local edge2 = {P3[1] - P1[1], P3[2] - P1[2], P3[3] - P1[3]}
		local edge1uv = {P2[9] - P1[9], P2[10] - P1[10]}
		local edge2uv = {P3[9] - P1[9], P3[10] - P1[10]}
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
				bitangent[i] = (edge1[i] * edge2uv[1] - edge2[i] * edge1uv[1]) / cp
			end
			
			for i = 1, 3 do
				finals[vertexMap[f+i-1]][11] = finals[vertexMap[f+i-1]][11] + tangent[1]
				finals[vertexMap[f+i-1]][12] = finals[vertexMap[f+i-1]][12] + tangent[2]
				finals[vertexMap[f+i-1]][13] = finals[vertexMap[f+i-1]][13] + tangent[3]
				
				finals[vertexMap[f+i-1]][14] = finals[vertexMap[f+i-1]][14] + bitangent[1]
				finals[vertexMap[f+i-1]][15] = finals[vertexMap[f+i-1]][15] + bitangent[2]
				finals[vertexMap[f+i-1]][16] = finals[vertexMap[f+i-1]][16] + bitangent[3]
			end
		end
	end
	
	--normalize
	for d,f in ipairs(finals) do
		local o = 10
		local l = math.sqrt(f[1+o]^2 + f[2+o]^2 + f[3+o]^2)
		f[1+o] = f[1+o] / l
		f[2+o] = f[2+o] / l
		f[3+o] = f[3+o] / l
		
		local o = 13
		local l = math.sqrt(f[1+o]^2 + f[2+o]^2 + f[3+o]^2)
		f[1+o] = f[1+o] / l
		f[2+o] = f[2+o] / l
		f[3+o] = f[3+o] / l
	end	
	
	--complete smoothing step
	for d,f in ipairs(finals) do
		--Gram-Schmidt orthogonalization
		local dot = (f[11] * f[5] + f[12] * f[6] + f[13] * f[7])
		f[11] = f[11] - f[5] * dot
		f[12] = f[12] - f[6] * dot
		f[13] = f[13] - f[7] * dot
		
		local l = math.sqrt(f[11]^2 + f[12]^2 + f[13]^2)
		f[11] = f[11] / l
		f[12] = f[12] / l
		f[13] = f[13] / l
	end
end

function lib.HSVtoRGB(h, s, v)
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

function lib.RGBtoHSV(r, g, b)
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

function lib.decodeObjectName(self, name)
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