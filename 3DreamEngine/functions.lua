--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

function lib.resize(self, w, h)
	local msaa = 4
	self.canvas = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = msaa})
	self.canvas_depth = love.graphics.newCanvas(w, h, {format = "depth16", readable = false, msaa = msaa})
	if self.AO_enabled then
		self.canvas_z = love.graphics.newCanvas(w, h, {format = "r16f", readable = true, msaa = msaa})
		self.canvas_blur_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		self.canvas_blur_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		
		if lib.reflections_enabled then
			self.canvas_normal = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = msaa})
		end
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
	
	local direct = {c1[1] * (1-f) + c2[1] * f, c1[2] * (1-f) + c2[2] * f, c1[3] * (1-f) + c2[3] * f, math.min(1, c1[4] * (1-f) + c2[4] * f)}
	direct[1] = 1.0 * (1-strength) + direct[1] * strength
	direct[2] = 1.0 * (1-strength) + direct[2] * strength
	direct[3] = 1.0 * (1-strength) + direct[3] * strength
	
	local ambient = {direct[1], direct[2], direct[3], 0.25}
	
	return direct, ambient
end