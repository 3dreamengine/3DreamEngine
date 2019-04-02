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