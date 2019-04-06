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
l3d = require("3DreamEngine")

--settings
l3d.objectDir = "objects/"	--root directory of objects

l3d.fov = 90				--field of view (10 < fov < 180)

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_strength = 0.5		--blend strength
l3d.AO_quality = 24			--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 1	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.5		--resolution factor

l3d.lighting_enabled = false	--enable lighting
l3d.lighting_max = 4		--max light sources

--inits (applies settings)
l3d:init()

--loads a object
yourObject = l3d:loadObject("objectName")

--prepare for rendering
--if cam is nil, it uses the default cam (l3d.cam)
--noDepth disables the depth buffer, useful for gui elements
l3d:prepare(cam, noDepth)

--draw
--obj can be either the entire object, or an object inside the file (obj.objects.yourObject)
l3d:draw(obj, x, y, z, sx, sy, sz, rotX, rotY, rotZ)

--finish render session, it is possible to render several times per frame
l3d:present()

--update camera postion
l3d.cam = {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0}

--update sun vector
l3d.sun = {0.3, -0.6, 0.5}

--update sun color
l3d.color_ambient = {0.25, 0.25, 0.25}
l3d.color_sun = {1.5, 1.5, 1.5}

--or use the inbuilt sky sphere and clouds
l3d.cloudDensity = 0.6
l3d.clouds = love.graphics.newImage("clouds.jpg")
l3d.sky = love.graphics.newImage("sky.jpg")
l3d.night = love.graphics.newImage("night.jpg")

--add this line somewhere in the draw or update loop to automatically set lighting based on dayTime
l3d.color_sun, l3d.color_ambient = l3d:getDayLight()

--dayTime = 0 -> midnight, dayTime 0.5 -> noon, loops
l3d.dayTime = love.timer.getTime() * 0.05

--update light sources
--make sure to set all unused light sources to 0
--3DreamEngine sorts the table, so indices might change
l3d.lighting = { }
for i = 1, l3d.lighting_max do
	l3d.lighting[i] = {0, 0, 0, 0, 0, 0, 0}
end
l3d.lighting[1] = {posX, posY, posZ, red, green, blue, strength}
--]]

local lib = { }

_3DreamEngine = lib
lib.root = (...)
require((...) .. "/functions")
require((...) .. "/shader")
require((...) .. "/loader")
require((...) .. "/collision")
matrix = require((...) .. "/matrix")
_3DreamEngine = nil

lib.cam = {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, normal = {0, 0, 0}}
lib.sun = {0.3, -0.6, -0.5}

lib.color_ambient = {1.0, 1.0, 1.0, 0.25}
lib.color_sun = {1.0, 1.0, 1.0, 1.5}

--per pixel lighting
lib.pixelPerfect = false

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

lib.lighting_enabled = false
lib.lighting_max = 4

lib.reflections_enabled = false
	
lib.object_light = lib:loadObject(lib.root .. "/objects/light")
lib.object_clouds = lib:loadObject(lib.root .. "/objects/clouds_high", false, false, true)
lib.object_sky = lib:loadObject(lib.root .. "/objects/sky", false, false, true)
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
	if self.reflections_enabled then
		self.AO_enabled = true
	end	
	if not self.lighting_enabled then
		self.pixelPerfect = false
	end
	
	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
	self:loadShader()
	
	self.lighting = { }
	for i = 1, self.lighting_max do
		self.lighting[i] = {0, 0, 0, 0, 0, 0, 0}
	end
	
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
	
	--lighting
	self.lighting_totalPower = 0
	if self.lighting_enabled then
		table.sort(self.lighting, function(a, b) return a[7] > b[7] end)
		for d,s in ipairs(self.lighting) do
			self.lighting_totalPower = self.lighting_totalPower + s[7]
		end
	end
	
	local cam = c == false and {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, normal = {0, 0, 0}} or c or self.cam
	
	local sun = {-self.sun[1], -self.sun[2], -self.sun[3]}
	
	local l = math.sqrt(sun[1]^2 + sun[2]^2 + sun[3]^2)
	sun[1] = sun[1] / l
	sun[2] = sun[2] / l
	sun[3] = sun[3] / l
	
	self.shaderVars_sun = sun
	self.shaderVars_camV = {cam.x, cam.y, cam.z}
	
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
	self.shaderVars_cam = res
	
	if self.reflections_enabled then
		local c = math.cos(cam.rz or 0)
		local s = math.sin(cam.rz or 0)
		local rotZ = matrix{
			{c, s, 0},
			{-s, c, 0},
			{0, 0, 1},
		}
		
		local c = math.cos(cam.ry or 0)
		local s = math.sin(cam.ry or 0)
		local rotY = matrix{
			{c, 0, -s},
			{0, 1, 0},
			{s, 0, c},
		}
		
		local c = math.cos(cam.rx or 0)
		local s = math.sin(cam.rx or 0)
		local rotX = matrix{
			{1, 0, 0},
			{0, c, -s},
			{0, s, c},
		}
		local res = rotZ * rotX * rotY
		self.shaderVars_cam3 = res
	end
	
	--camera normal
	local normal = rotY * rotX * (matrix{{0, 0, 1, 0}}^"T")
	cam.normal = {normal[1][1], normal[2][1], -normal[3][1]}
	
	--clear draw table
	lib.drawTable = { }
	
	--show light sources
	if self.lighting_enabled and self.showLightSources then
		for d,s in ipairs(self.lighting) do
			love.graphics.setColor(s[4], s[5], s[6])
			self:draw(self.object_light, s[1], s[2], s[3], s[7]*0.1, nil, nil)
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
	
	for d,s in pairs(obj.objects or {obj}) do
		local shaderName_1 = (s.material.tex_diffuse and "textured" or "flat") .. (s.shader == "wind" and "_wind" or "")
		local shaderName_2 = self.lighting_totalPower > 0 and ((s.material.tex_diffuse and "textured" or "flat") .. "_light") .. (s.shader == "wind" and "_wind" or "")
		local shaderName_3 = self.pixelPerfect and self.lighting_totalPower > 0 and ((s.material.tex_diffuse and "textured" or "flat") .. "_light_pixel") .. (s.shader == "wind" and "_wind" or "")
		local shaderName
		if self.shaders[shaderName_3] then
			shaderName = shaderName_3
		elseif self.shaders[shaderName_2] then
			shaderName = shaderName_2
		else
			shaderName = shaderName_1
		end
		
		--insert intro draw todo list
		if not lib.drawTable[shaderName] then
			lib.drawTable[shaderName] = { }
		end
		if not lib.drawTable[shaderName][s.material] then
			lib.drawTable[shaderName][s.material] = { }
		end
		local r, g, b = love.graphics.getColor()
		table.insert(lib.drawTable[shaderName][s.material], {
			rotZ*rotY*rotX*translate,
			rotZ3*rotY3*rotX3,
			s,
			r, g, b,
		})
	end
end

lib.stats = {
	shadersInUse = 0,
	draws = 0,
	perShader = { },
}
function lib.present(self)
	lib.stats.shadersInUse = 0
	lib.stats.materialDraws = 0
	lib.stats.draws = 0
	lib.stats.perShader = { }
	
	if self.AO_enabled then
		if self.reflections_enabled then
			love.graphics.setCanvas({self.canvas, self.canvas_z, self.canvas_normal, depthstencil = self.canvas_depth})
		else
			love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
		end
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
	end
	
	love.graphics.clear({0, 0, 0, 0}, {255, 255, 255, 255}, {0, 0, 0, 0})
	
	--two steps, once for solid and once for transparent
	for step = 1, 2 do
		if self.noDepth then
			love.graphics.setDepthMode()
		else
			love.graphics.setDepthMode("less", step == 1)
		end
		for shaderName, s in pairs(self.drawTable) do
			local shader = self.shaders[shaderName]
			love.graphics.setShader(shader)
			lib.stats.perShader[shaderName] = 0
			
			--lighting
			if shaderName:find("light") then
				local light = { }
				local pos = { }
				for i = 1, self.lighting_max do
					pos[i] = {self.lighting[i][1], self.lighting[i][2], self.lighting[i][3]}
					light[i] = {self.lighting[i][4] * self.lighting[i][7], self.lighting[i][5] * self.lighting[i][7], self.lighting[i][6] * self.lighting[i][7]}
					light[i][4] = math.sqrt(light[i][1]^2 + light[i][2]^2 + light[i][3]^2)
				end
				shader:send("lightColor", unpack(light))
				shader:send("lightPos", unpack(pos))
			end
			
			--wind
			if shaderName:find("wind") then
				shader:send("wind", love.timer.getTime())
			end
			
			shader:send("ambient", {self.color_ambient[1] * self.color_ambient[4], self.color_ambient[2] * self.color_ambient[4], self.color_ambient[3] * self.color_ambient[4], 1.0})
			shader:send("sunColor", {self.color_sun[1] * self.color_sun[4], self.color_sun[2] * self.color_sun[4], self.color_sun[3] * self.color_sun[4], 1.0})
			
			shader:send("sun", self.shaderVars_sun)
			
			shader:send("camV", self.shaderVars_camV)
			shader:send("cam", self.shaderVars_cam)
			
			if self.reflections_enabled then
				shader:send("cam3", self.shaderVars_cam3)
			end
			
			for material, tasks in pairs(s) do
				if step == 1 and material.color[4] == 1 or step == 2 and material.color[4] ~= 1 then
					--diffuse texture already bound to mesh!
					--set spec textures
					if shaderName == "textured_light_pixel_spec" then
						shader:send("tex_spec", s.tex_spec)
					end
					
					for i,v in pairs(tasks) do
						love.graphics.setMeshCullMode(v[3].noBackFaceCulling and "none" or "back")
						
						love.graphics.setColor(v[4], v[5], v[6])
						
						shader:send("transform", v[1])
						shader:send("rotate", v[2])
						
						--final draw
						love.graphics.draw(v[3].mesh)
						
						lib.stats.draws = lib.stats.draws + 1
						lib.stats.perShader[shaderName] = lib.stats.perShader[shaderName] + 1
					end
					lib.stats.materialDraws = lib.stats.materialDraws+ 1
				end
			end
			lib.stats.shadersInUse = lib.stats.shadersInUse + 0.5
		end
	end
	
	--sky
	if self.sky then
		local transform = matrix{
			{50, 0, 0, 0},
			{0, 50, 0, 0},
			{0, 0, 50, 0},
			{0, 0, 0, 1},
		}
		
		love.graphics.setDepthMode("less", false)
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
		
		local timeFac = math.cos(self.dayTime*math.pi*2)*0.5+0.5
		local color = self:getDayLight(self.dayTime, 0.2)
		color[4] = 1.0
		
		if self.night then
			love.graphics.setShader(self.shaderSkyNight)
			self.shaderSkyNight:send("cam", self.shaderVars_cam * transform)
			self.shaderSkyNight:send("color", color)
			self.shaderSkyNight:send("time", timeFac)
			love.graphics.draw(self.object_sky.objects.Cube.mesh)
		else
			love.graphics.setShader(self.shaderSky)
			self.shaderSky:send("cam", self.shaderVars_cam * transform)
			self.shaderSky:send("color", color)
			love.graphics.draw(self.object_sky.objects.Cube.mesh)
		end
	end
	
	--clouds
	if self.clouds then
		local transform = matrix{
			{100, 0, 0, 0},
			{0, 100, 0, 0},
			{0, 0, 100, 0},
			{0, 100, 0, 1},
		}
		
		love.graphics.setDepthMode("less", false)
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
		love.graphics.setShader(self.shaderCloud)
		
		self.shaderCloud:send("density", self.cloudDensity)
		self.shaderCloud:send("time", love.timer.getTime() / 1000)
		self.shaderCloud:send("transform", transform)
		self.shaderCloud:send("cam", self.shaderVars_cam)
		
		love.graphics.draw(self.object_clouds.objects.Cube.mesh)
	end
	
	love.graphics.setDepthMode()
	love.graphics.origin()
	love.graphics.setColor(1, 1, 1)
	
	if self.AO_enabled then
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(self.canvas_blur_1)
		love.graphics.clear()
		love.graphics.setShader(self.AO)
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
		self.post:send("strength", love.keyboard.isDown("f9") and 0.0 or self.AO_strength)
		self.post:send("depth", self.canvas_z)
		self.post:send("fog", self.fog)
		love.graphics.draw(self.canvas)
		love.graphics.setShader()
	else
		love.graphics.setShader()
		love.graphics.setCanvas()
		love.graphics.draw(self.canvas)
	end
	
	if love.keyboard.isDown("f8") then
		love.graphics.draw(self.canvas_blur_1)
	end
end

return lib