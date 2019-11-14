--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

lib.canvasFormats = love.graphics and love.graphics.getCanvasFormats() or { }

function lib.resize(self, w, h)
	local msaa = 4
	self.canvas = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = msaa})
	self.canvas_depth = love.graphics.newCanvas(w, h, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = false, msaa = msaa})
	
	if self.AO_enabled then
		local ok = pcall(function()
			self.canvas_z = love.graphics.newCanvas(w, h, {format = "r16f", readable = true, msaa = msaa})
		end)
		if ok then
			self.canvas_blur_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
			self.canvas_blur_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		else
			self.AO_enabled = false
			print("r16f canvas creation failed, AO deactivated")
		end
	end
	
	if self.bloom_enabled then
		local ok = pcall(function()
			self.canvas_bloom = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = msaa})
		end)
		if ok then
			self.canvas_bloom_1 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = "normal", readable = true, msaa = 0})
			self.canvas_bloom_2 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = "normal", readable = true, msaa = 0})
		else
			self.bloom_enabled = false
			print("r8 canvas creation failed, bloom deactivated")
		end
	end
	
	if self.shadow_enabled then
		self.canvas_shadow_depth = love.graphics.newCanvas(self.shadow_resolution, self.shadow_resolution, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = false, msaa = 0})
		self.canvas_shadow = love.graphics.newCanvas(self.shadow_resolution, self.shadow_resolution, {format = "r16f", readable = true, msaa = 0})
		self.canvas_shadow:setWrap("clampzero")
		self.canvas_shadow:setFilter("linear")
	end
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
		strength = 0
	end
	if not time then
		time = self.dayTime
	end
	
	local c1 = self.dayLightColors[(math.floor(time*#self.dayLightColors) % #self.dayLightColors)+1]
	local c2 = self.dayLightColors[((math.floor(time*#self.dayLightColors)+1) % #self.dayLightColors)+1]
	local f = (time*#self.dayLightColors) % 1
	
	local direct = {c1[1] * (1-f) + c2[1] * f, c1[2] * (1-f) + c2[2] * f, c1[3] * (1-f) + c2[3] * f, 1.25 * math.min(1, c1[4] * (1-f) + c2[4] * f)}
	direct[1] = 1.0 * (1-strength) + direct[1] * strength
	direct[2] = 1.0 * (1-strength) + direct[2] * strength
	direct[3] = 1.0 * (1-strength) + direct[3] * strength
	
	local ambient = {direct[1], direct[2], direct[3], 0.1 + direct[4]*0.1}
	
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
	end
	
	for f = 1, #vertexMap, 3 do
		local P1 = finals[vertexMap[f+0]]
		local P2 = finals[vertexMap[f+1]]
		local P3 = finals[vertexMap[f+2]]
		local N1 = finals[vertexMap[f+0]]
		local N2 = finals[vertexMap[f+1]]
		local N3 = finals[vertexMap[f+2]]
		
		local tangent = { }
		local bitangent = { }
		
		local edge1 = {P2[1] - P1[1], P2[2] - P1[2], P2[3] - P1[3]}
		local edge2 = {P3[1] - P1[1], P3[2] - P1[2], P3[3] - P1[3]}
		local edge1uv = {N2[9] - N1[9], N2[10] - N1[10]}
		local edge2uv = {N3[9] - N1[9], N3[10] - N1[10]}
		
		local cp = edge1uv[2] * edge2uv[1] - edge1uv[1] * edge2uv[2]
		
		if cp ~= 0.0 then
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
				bitangent[i] = (edge2[i] * edge1uv[1] - edge1[i] * edge2uv[1]) / cp
			end
			
			local l = math.sqrt(tangent[1]^2+tangent[2]^2+tangent[3]^2)
			tangent[1] = tangent[1] / l
			tangent[2] = tangent[2] / l
			tangent[3] = tangent[3] / l
			
			local l = math.sqrt(bitangent[1]^2+bitangent[2]^2+bitangent[3]^2)
			bitangent[1] = bitangent[1] / l
			bitangent[2] = bitangent[2] / l
			bitangent[3] = bitangent[3] / l
			
			for i = 1, 3 do
				finals[vertexMap[f+i-1]][11] = (finals[vertexMap[f+i-1]][11] or 0) + tangent[1]
				finals[vertexMap[f+i-1]][12] = (finals[vertexMap[f+i-1]][12] or 0) + tangent[2]
				finals[vertexMap[f+i-1]][13] = (finals[vertexMap[f+i-1]][13] or 0) + tangent[3]
				
				finals[vertexMap[f+i-1]][14] = (finals[vertexMap[f+i-1]][14] or 0) + bitangent[1]
				finals[vertexMap[f+i-1]][15] = (finals[vertexMap[f+i-1]][15] or 0) + bitangent[2]
				finals[vertexMap[f+i-1]][16] = (finals[vertexMap[f+i-1]][16] or 0) + bitangent[3]
			end
		end
	end
	
	--complete smoothing step
	for d,f in ipairs(finals) do
		if f[11] then
			--Gram-Schmidt orthogonalization
			local dot = (f[11] * f[5] + f[12] * f[6] + f[13] * f[7])
			f[11] = f[11] - f[5] * dot
			f[12] = f[12] - f[6] * dot
			f[13] = f[13] - f[7] * dot
			
			local l = math.sqrt(f[11]^2+f[12]^2+f[13]^2)
			f[11] = -f[11] / l
			f[12] = -f[12] / l
			f[13] = -f[13] / l
			
			l = math.sqrt(f[14]^2+f[15]^2+f[16]^2)
			f[14] = f[14] / l
			f[15] = f[15] / l
			f[16] = f[16] / l
		end
	end
end