--[[
#3DreamEngine - 3D library by Luke100000
loads simple .obj files
supports obj atlas (see usage)
renders models using flat shading or textures
supports ambient occlusion and fog


#Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#usage
--loads the lib
dream = require("3DreamEngine")

--settings
dream.objectDir = "objects/"     --root directory of objects

dream.fov = 90                   --field of view (10 < fov < 180)

dream.AO_enabled = true          --ambient occlusion?
dream.AO_strength = 0.5          --blend strength
dream.AO_quality = 24            --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 1      --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.5        --resolution factor

dream.lighting_max = 16          --max light sources, depends on GPU, has no performance impact if sources are unused

--inits (applies settings)
dream:init()

--loads a object
yourObject = dream:loadObject("objectName", args)

--where args is a table with additional settings
--	splitMaterials =(boolean, false by default, has to be true if your object contains several (diffuse) textures)
--	rasterMargin = (boolean or integer, default to true (equals to 2), enables object splitting
--	forceTextured = uses textured mode (which includes normal tangent values, ...),
--	noMesh = load eberything, but skip mesh loading
--	cleanup = (boolean, default true) clean up memory by deleting faces and vertex data

--loads a lazy object
yourObject = dream:loadObjectLazy("objectName", args)

--and load it step by step
yourObject:resume()

--or add it to the master loader, priority is an int between 1 and inf, default is 3
dream.resourceLoader:add(yourObject[, priority])

--and update the loader in love.update(), maxTime if the time available in ms, default 1 ms. Peaks may occur. Average total time per call is maxTime + 3ms (since worst case time can exceed maxTime)
dream.resourceLoader:update(maxTime)

--update camera postion
dream.cam = {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0}

--update sun position/vector
dream.sun = {-0.3, 0.6, -0.5}

--update sun color
dream.color_ambient = {0.25, 0.25, 0.25}
dream.color_sun = {1.5, 1.5, 1.5}

--or use the inbuilt sky sphere and clouds
dream.cloudDensity = 0.6
dream.clouds = love.graphics.newImage("clouds.jpg")
dream.sky = love.graphics.newImage("sky.jpg")
dream.night = love.graphics.newImage("night.jpg")

--add this line somewhere in the draw or update loop to automatically set lighting based on dayTime
dream.color_sun, dream.color_ambient = dream:getDayLight()

--dayTime = 0 -> midnight, dayTime 0.5 -> noon, loops
dream.dayTime = love.timer.getTime() * 0.05

--resets light sources (noDayLight to true if the sun should not be added automatically)
dream:resetLight(noDayLight)

--add light, note that in case of exceeding the max light sources it only uses the most relevant sources, based on distance and brightness
dream:addLight(posX, posY, posZ, red, green, blue, brightness)

--prepare for rendering
--if cam is nil, it uses the default cam (dream.cam)
--noDepth disables the depth buffer, useful for gui elements
dream:prepare(cam, noDepth)

--draw
--obj can be either the entire object, or an object inside the file (obj.objects.yourObject)
dream:draw(obj, x, y, z, sx, sy, sz, rotX, rotY, rotZ)

--finish render session, it is possible to render several times per frame
dream:present()
--]]

local lib = { }

_3DreamEngine = lib
lib.root = (...)
require((...) .. "/functions")
require((...) .. "/shader")
require((...) .. "/loader")
require((...) .. "/present")
require((...) .. "/collision")
require((...) .. "/particlesystem")


--loader
lib.loader = { }
for d,s in pairs(love.filesystem.getDirectoryItems((...) .. "/loader")) do
	require((...) .. "/loader/" .. s:sub(1, #s-4))
end

matrix = require((...) .. "/matrix")
_3DreamEngine = nil

lib.cam = {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, normal = {0, 0, 0}}
lib.currentCam = lib.cam

--sun
lib.sun = {-0.3, 0.6, 0.5}
lib.color_ambient = {1.0, 1.0, 1.0, 0.25}
lib.color_sun = {1.0, 1.0, 1.0, 1.5}

--field of view
lib.fov = 90

--distance fog
lib.fog = 0.0

--root directory of objects
lib.objectDir = "objects/"

--settings
lib.AO_enabled = true
lib.AO_strength = 0.5
lib.AO_quality = 24
lib.AO_quality_smooth = 1
lib.AO_resolution = 0.5

lib.lighting_max = 16

lib.object_light = lib:loadObject(lib.root .. "/objects/light")
lib.object_clouds = lib:loadObject(lib.root .. "/objects/clouds_high", {forceTextured = true})
lib.object_sky = lib:loadObject(lib.root .. "/objects/sky", {forceTextured = true})
lib.texture_missing = love.graphics.newImage(lib.root .. "/missing.png")

--set lib clouds to an cloud texture (noise, tilable) to enable clouds
lib.clouds = false
lib.cloudDensity = 0.5

--set sky sphere (set sky and night to the textures) (if night is nil/false it will only use day)
--time is the factor between sky and night textures (0 is sky) (only works with night tetxure set)
--color can be used to manually set color (vec4), or when set to true it uses realistic lighting
lib.sky = false
lib.night = false
lib.time = 0
lib.color = true

--used as default value for getDayLight() and for the skysphere
lib.dayTime = 0

function lib.init(self)
	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
	self:loadShader()
	
	self.lighting = { }
	
	if self.clouds then
		self.clouds:setWrap("repeat")
		self.object_clouds.objects.Cube.mesh:setTexture(self.clouds)
	end
	
	if self.sky then
		self.sky:setWrap("repeat")
		self.object_sky.objects.Cube.mesh:setTexture(self.sky)
		if self.night then
			self.night:setWrap("repeat")
			self.shaderSkyNight:send("night", self.night)
		end
	end
end

function lib.prepare(self, c, noDepth)
	self.noDepth = noDepth
	
	local cam = c == false and {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, normal = {0, 0, 0}} or c or self.cam
	self.currentCam = cam
	
	local sun = {self.sun[1], self.sun[2], self.sun[3]}
	sun[1] = sun[1] * 1000
	sun[2] = sun[2] * 1000
	sun[3] = sun[3] * 1000
	
	self.shaderVars_sun = sun
	self.shaderVars_viewPos = {cam.x, cam.y, cam.z}
	
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
	local fov = self.fov
	local S = 1 / (math.tan(fov/2*math.pi/180))
	
	local projection = matrix{
		{S,	0,	0,	0},
		{0,	-S/love.graphics.getHeight()*love.graphics.getWidth(),	0,	0},
		{0,	0,	-f/(f-n),	-1},
		{0,	0,	-(f*n)/(f-n),	0},
	}
	
	local translate = matrix{
		{1, 0, 0, -cam.x},
		{0, 1, 0, -cam.y},
		{0, 0, 1, -cam.z},
		{0, 0, 0, 1},
	}
	
	--camera transformation
	self.shaderVars_transformProj = projection * rotZ * rotX * rotY * translate
	
	--camera normal
	local normal = rotY * rotX * (matrix{{0, 0, 1, 0}}^"T")
	cam.normal = {normal[1][1], normal[2][1], -normal[3][1]}
	
	--clear draw table
	lib.drawTable = { }
	
	--show light sources
	if self.lighting_enabled and self.showLightSources then
		for d,s in ipairs(self.lighting) do
			love.graphics.setColor(s.r, s.g, s.b)
			self:draw(self.object_light, s.x, s.y, s.z, 0.2, nil, nil)
		end
		love.graphics.setColor(1, 1, 1, 1)
	end
end

lib.drawTable = { }
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
	
	local levelOfAbstraction = math.floor(math.sqrt((self.cam.x-x)^2 + (self.cam.y-y)^2 + (self.cam.z-z)^2) / 20) - 1
	
	local t = obj.objects or {obj}
	for d,s in pairs(t) do
		if (not s.simple or not t[s.super] or not t[s.super].meshLoaded) and s.mesh and (not s.particleSystem or levelOfAbstraction <= 2) then
			for i = 1, levelOfAbstraction do
				s = t[s.simpler] or s
			end
			
			--insert intro draw todo list
			local shaderInfo = self:getShaderInfo(s.material.tex_diffuse and "textured" or "flat", s.shader, s.material.tex_normal, s.material.tex_specular)
			if not lib.drawTable[shaderInfo] then
				lib.drawTable[shaderInfo] = { }
			end
			if not lib.drawTable[shaderInfo][s.material] then
				lib.drawTable[shaderInfo][s.material] = { }
			end
			local r, g, b = love.graphics.getColor()
			table.insert(lib.drawTable[shaderInfo][s.material], {
				rotZ*rotY*rotX*translate,
				s,
				r, g, b,
			})
		end
	end
end

function lib.resetLight(self, noDayLight)
	if noDayLight then
		self.lighting = { }
	else
		self.lighting = {
			{
				x = self.sun[1] * 1000,
				y = self.sun[2] * 1000,
				z = self.sun[3] * 1000,
				r = self.color_sun[1] / math.sqrt(self.color_sun[1]^2 + self.color_sun[2]^2 + self.color_sun[3]^2) * self.color_sun[4] * 0.02,
				g = self.color_sun[2] / math.sqrt(self.color_sun[1]^2 + self.color_sun[2]^2 + self.color_sun[3]^2) * self.color_sun[4] * 0.02,
				b = self.color_sun[3] / math.sqrt(self.color_sun[1]^2 + self.color_sun[2]^2 + self.color_sun[3]^2) * self.color_sun[4] * 0.02,
				meter = 1/100000,
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
		meter = 1.0 / (meter or 1.0),
		importance = importance or 1.0,
	}
end

return lib