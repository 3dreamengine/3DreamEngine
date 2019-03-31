--[[
#3DreamEngine - 3D library by Luke100000
loads simple .obj files
supports obj atlas (see usage)
renders models using flat shading
supports ambient occlusion and fog


#Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#usage
--load the matrix and the 3D lib
matrix = require("matrix")
l3d = require("3DreamEngine")

--settings
l3d.flat = true				--flat shading or textured? (not implemented yet)
l3d.objectDir = "objects/"	--root directory of objects
lib.pathToNoiseTex = "noise.png"	--path to noise texture

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_quality = 24			--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 1	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.5		--resolution factor

--inits (applies settings)
l3d:init()

--loads a object
yourObject = l3d:loadObject("objectName")

--prepare for rendering
--if cam is nil, it uses the default cam (l3d.cam)
--noDepth disables the depth buffer
l3d:prepare(cam, noDepth)

--draw
l3d:draw(model, x, y, z, sx, sy, sz, rot, tilt)

--finish render session, it is possible to render several times per frame
l3d:present()

--update camera postion
lib.cam = {x = 0, y = 0, z = 0, rot = 0, tilt = 0}

--update sun position
lib.sun = {0.3, -0.6, -0.5}

--update sun color
lib.color_ambient = {0.25, 0.25, 0.25}
lib.color_sun = {1.5, 1.5, 1.5}
--]]

local lib = { }

_3DreamEngine = lib
require((...) .. "/functions")
require((...) .. "/shader")
require((...) .. "/loader")
matrix = require((...) .. "/matrix")
_3DreamEngine = nil

lib.cam = {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, normal = {0, 0, 0}}
lib.sun = {0.3, -0.6, -0.5}

lib.color_ambient = {0.25, 0.25, 0.25}
lib.color_sun = {1.5, 1.5, 1.5}

--no textures, textures not fully working yet
lib.flat = true

--root directory of objects
lib.objectDir = "objects/"
lib.pathToNoiseTex = "noise.png"

--settings
lib.AO_enabled = true
lib.AO_quality = 24
lib.AO_quality_smooth = 1
lib.AO_resolution = 0.5

function lib.init(self)
	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
	self:loadShader()
end

function lib.prepare(self, c, noDepth)
	if self.AO_enabled then
		love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
	end
	love.graphics.clear()
	
	love.graphics.setShader(self.shader)
	if not noDepth then
		love.graphics.setDepthMode("less", true)
	end
	
	self.shader:send("ambient", {self.color_ambient[1], self.color_ambient[2], self.color_ambient[3], 1.0})
	self.shader:send("sunColor", {self.color_sun[1], self.color_sun[2], self.color_sun[3], 1.0})
	
	local cam = c == false and {x = 0, y = 0, z = 0, tilt = 0, rot = 0} or c or self.cam
	
	local sun = {math.cos(love.timer.getTime()), 0.3, math.sin(love.timer.getTime())}
	local sun = {-self.sun[1], -self.sun[2], -self.sun[3]}
	local l = math.sqrt(sun[1]^2 + sun[2]^2 + sun[3]^2)
	sun[1] = sun[1] / l
	sun[2] = sun[2] / l
	sun[3] = sun[3] / l
	self.shader:send("sun", sun)
	
	self.shader:send("camV", {cam.x, cam.y, cam.z})
	
	local c = math.cos(cam.rz or 0)
	local s = math.sin(cam.rz or 0)
	local rotZ = matrix{
		{c, s, 0, 0},
		{-s, c, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(cam.ry or 0)
	local s = math.sin(cam.ry or 0)
	local rotY = matrix{
		{c, 0, -s, 0},
		{0, 1, 0, 0},
		{s, 0, c, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(cam.rx or 0)
	local s = math.sin(cam.rx or 0)
	local rotX = matrix{
		{1, 0, 0, 0},
		{0, c, -s, 0},
		{0, s, c, 0},
		{0, 0, 0, 1},
	}
	
	local n = 1
	local f = 10
	local fov = 90
	local S = 1 / (math.tan(fov/2*math.pi/180))
	
	local projection = matrix{
		{S,	0,	0,	0},
		{0,	S/600*800,	0,	0},
		{0,	0,	-(f/(f-n)),	-1},
		{0,	0,	-(f*n)/(f-n),	0},
	}
	
	local translate = matrix{
		{1, 0, 0, -cam.x},
		{0, 1, 0, -cam.y},
		{0, 0, 1, -cam.z},
		{0, 0, 0, 1},
	}
	
	local res = projection * rotZ * rotX * rotY * translate
	self.shader:send("cam", res)
	
	--camera normal
	local normal = rotY * rotX * (matrix{{0, 0, 1, 0}}^"T")
	cam.normal = {normal[1][1], normal[2][1], -normal[3][1]}
end

function lib.draw(self, obj, x, y, z, sx, sy, sz, rx, ry, rz)
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	local rotZ = matrix{
		{c, s, 0, 0},
		{-s, c, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	local rotY = matrix{
		{c, 0, -s, 0},
		{0, 1, 0, 0},
		{s, 0, c, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	local rotX = matrix{
		{1, 0, 0, 0},
		{0, c, -s, 0},
		{0, s, c, 0},
		{0, 0, 0, 1},
	}
	
	local translate = matrix{
		{sx or 1, 0, 0, 0},
		{0, sy or sx or 1, 0, 0},
		{0, 0, sz or sx or 1, 0},
		{x, y, z, 1},
	}
	
	--self.shader:send("rot", rotX)
	self.shader:send("transform", rotZ*rotY*rotX*translate)
	
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	local rotZ3 = matrix{
		{c, s, 0},
		{-s, c, 0},
		{0, 0, 1},
	}
	
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	local rotY3 = matrix{
		{c, 0, -s},
		{0, 1, 0},
		{s, 0, c},
	}
	
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	local rotX3 = matrix{
		{1, 0, 0},
		{0, c, -s},
		{0, s, c},
	}
	self.shader:send("rotate", rotZ3*rotY3*rotX3)
	
	love.graphics.draw(obj.mesh)
end

function lib.present(self)
	love.graphics.setDepthMode()
	love.graphics.origin()
	
	if self.AO_enabled then
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(self.canvas_blur_1)
		love.graphics.clear()
		love.graphics.setShader(lib.AO)
		lib.AO:send("noiseOffset", {self.cam.ry, self.cam.rz})
		love.graphics.draw(self.canvas_z, 0, 0, 0, self.AO_resolution)
		love.graphics.setShader(self.blur)
		self.blur:send("size", {1/self.canvas_blur_1:getWidth(), 1/self.canvas_blur_1:getHeight()})
		
		for i = 1, self.AO_quality_smooth do
			self.blur:send("vstep", 1.0)
			self.blur:send("hstep", 0.0)
			love.graphics.setCanvas(self.canvas_blur_2)
			love.graphics.clear()
			love.graphics.draw(self.canvas_blur_1)
			
			self.blur:send("vstep", 0.0)
			self.blur:send("hstep", 1.0)
			love.graphics.setCanvas(self.canvas_blur_1)
			love.graphics.clear()
			love.graphics.draw(self.canvas_blur_2)
		end
		
		love.graphics.setCanvas()
		love.graphics.setBlendMode("alpha")
		love.graphics.setShader(self.post)
		self.post:send("AO", self.canvas_blur_1)
		self.post:send("depth", self.canvas_z)
		self.post:send("fog", 0.001)
		love.graphics.draw(self.canvas)
		love.graphics.setShader()
	else
		love.graphics.setShader()
		love.graphics.setCanvas()
		love.graphics.draw(self.canvas)
	end
end

return lib