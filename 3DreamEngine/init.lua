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
dream.objectDir = "objects"      --root directory of objects

dream.fov = 90                   --field of view (10 < fov < 180)

dream.AO_enabled = true          --ambient occlusion?
dream.AO_strength = 0.5          --blend strength
dream.AO_quality = 24            --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 1      --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.5        --resolution factor

dream.enable_reflections = false --uses the sky sphere to simulate reflections, the materials .reflections value has to be true (in case of .obj objects add "reflections true" to the .mtl material), if enabled, it uses the specular value (constant material value on flat shading or specular texture, default 0.5) for reflection value

dream.lighting_max = 16          --max light sources, depends on GPU, has no performance impact if sources are unused

dream.nameDecoder = "blender"    --blender/none automatically renames objects, blender exports them as ObjectName_meshType.ID, but only ObjectName is relevant

--inits (applies settings)
dream:init()

--loads a object
yourObject = dream:loadObject("objectName", args)

--where args is a table with additional settings
--	splitMaterials = (boolean, false by default, has to be true if your object contains several (diffuse) textures)
--	raster = (boolean or integer, default to true (equals to 2), enables object splitting
--	forceTextured = uses textured mode (which includes normal tangent values, ...),
--	noMesh = load eberything, but skip mesh loading
--	cleanup = (boolean, default true) clean up memory by deleting faces and vertex data

--the name of the object (set by "o" inside .obj, in blender it is the name of the vertex data inside an object) can contain information:
--  if it contains REMOVE, it will not be used. Their use can be frames, particle emitters, helper objects, ...)
--  if it contains LAMP_name where name is a custom ID, it will not be loaded, but instead an entry in object.lights will be made (name, x, y, z), can be used to set static lights more easy.
--prefixed, for example Icosphere_LAMP_myName are valid and will be ignored.

--loads a lazy object
yourObject = dream:loadObjectLazy("objectName", args)

--and load it step by step, for example slowly in the background
while not yourObject.loaded do
	yourObject:resume()
end

--or add it to the master loader, priority is an int between 1 and inf, default is 3
dream.resourceLoader:add(yourObject[, priority])

--and update the loader in love.update(), maxTime if the time available in ms, default 1 ms. Peaks may occur. Average total time per call is maxTime + 3ms (since worst case time can exceed maxTime)
dream.resourceLoader:update(maxTime)

--transform the object
yourObject:reset()
yourObject:translate(x, y, z)
yourObject:scale(x, y, z)
yourObject:rotateX(angle)
yourObject:rotateY(angle)
yourObject:rotateZ(angle)

--update camera postion (transformations as yourObject)
dream.cam:reset()
dream.cam:translate(x, y, z)

--if you want an own camera use
yourCam = dream:newCam()
--and pass it to dream:prepare

--update sun position/vector
dream.sun = {-0.3, 0.6, -0.5}

--update sun color
dream.color_ambient = {0.25, 0.25, 0.25}
dream.color_sun = {1.5, 1.5, 1.5}

--use the inbuilt sky sphere and clouds
dream.cloudDensity = 0.6
dream.clouds = love.graphics.newImage("clouds.jpg")
dream.sky = love.graphics.newImage("sky.jpg")
dream.night = love.graphics.newImage("night.jpg") --can be nil to only have daytime

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
dream:prepare(cam)

--draw
--obj can be either the entire object, or an object inside the file (obj.objects.yourObject)
dream:draw(obj, x, y, z, sx, sy, sz)

--finish render session, it is possible to render several times per frame
--noDepth disables the depth buffer, useful for gui elements
--if noDepth is enabled, noSky will be true too by default
dream:present(noDepth, noSky)

#extend .obj
The .mtl file usually exported with .obj will be loaded automatically.
To use more 3DreamEngine specific features (disable automatic texture loading, particle system, wind animation ...) a .3de file is required.

example file:
--3DreamEngine material properties file
return {
	Grass = { --extend material Grass
		reflections = true, --metalic reflections (using specular value)
		shader = "wind", --shader affecting the entire object
		shaderInfo = 1.0,
		particleSystems = { --add particleSystems
			{ --first system
				objects = { --add objects, they have to be in the same directory as the scene (sub directories like particles/grass work too)
					["grass"] = 20,
				},
				randomSize = {0.75, 1.25}, --randomize the particle size
				randomRotation = true, --randomize the rotation
				normal = 0.9, --align to 90% with its emitters surface normal
				shader = "wind", --use the wind shader
				shaderInfo = "grass", --tell the wind shader to behave like grass, the amount of waving depends on its Y-value
				--shaderInfo = 0.2, --or use a constant float
			},
		}
	},
}
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
require((...) .. "/boneManager")
require((...) .. "/saveTable")

lib.textures = require((...) .. "/textures")

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

if love.filesystem.read("debugEnabled") == "true" then
	_DEBUGMODE = true
end


--loader
lib.loader = { }
for d,s in pairs(love.filesystem.getDirectoryItems((...) .. "/loader")) do
	require((...) .. "/loader/" .. s:sub(1, #s-4))
end

matrix = require((...) .. "/matrix")
_3DreamEngine = nil

--sun
lib.sun = {-0.3, 0.6, 0.5}
lib.color_ambient = {1.0, 1.0, 1.0, 0.25}
lib.color_sun = {1.0, 1.0, 1.0, 1.5}

--field of view
lib.fov = 90

--distance fog
lib.fog = 0.0
lib.near = 0.1
lib.far = 500

--root directory of objects
lib.objectDir = "objects/"

--settings
lib.AO_enabled = true
lib.AO_strength = 0.5
lib.AO_quality = 24
lib.AO_quality_smooth = 1
lib.AO_resolution = 0.5

lib.reflections_enabled = false

lib.lighting_max = 16

lib.nameDecoder = "blender"

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
	
	local cam = c == false and self:newCam() or c or self.cam
	self.currentCam = cam
	
	local sun = {self.sun[1], self.sun[2], self.sun[3]}
	sun[1] = sun[1] * 1000
	sun[2] = sun[2] * 1000
	sun[3] = sun[3] * 1000
	
	self.shaderVars_sun = sun
	self.shaderVars_viewPos = -self.currentCam.transform^"T" * (matrix{{self.currentCam.transform[1][4], self.currentCam.transform[2][4], self.currentCam.transform[3][4], self.currentCam.transform[4][4]}}^"T")
	self.shaderVars_viewPos = {self.shaderVars_viewPos[1][1], self.shaderVars_viewPos[2][1], self.shaderVars_viewPos[3][1]}
	
	local n = lib.near
	local f = lib.far
	local fov = self.fov
	local S = 1 / (math.tan(fov/2*math.pi/180))
	
	local projection = matrix{
		{S,	0,	0,	0},
		{0,	-S/love.graphics.getHeight()*love.graphics.getWidth(),	0,	0},
		{0,	0,	-f/(f-n),	-(f*n)/(f-n)},
		{0,	0,	-1,	0},
	}
	
	--camera transformation
	self.shaderVars_transformProj = projection * self.currentCam.transform
	
	--camera normal
	local normal = self.currentCam.transform^"T" * (matrix{{0, 0, 1, 0}}^"T")
	--print(normal[1][1], normal[2][1], -normal[3][1]) io.flush()
	cam.normal = {normal[1][1], normal[2][1], normal[3][1]}
	
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

function lib.reset(obj)
	obj.transform = matrix{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
end

function lib.translate(obj, x, y, z)
	local translate = matrix{
		{1, 0, 0, x},
		{0, 1, 0, y},
		{0, 0, 1, z},
		{0, 0, 0, 1},
	}
	obj.transform = translate * obj.transform
end

function lib.scale(obj, x, y, z)
	local scale = matrix{
		{x, 0, 0, 0},
		{0, y or x, 0, 0},
		{0, 0, z or x, 0},
		{0, 0, 0, 1},
	}
	obj.transform = scale * obj.transform
end

function lib.rotateX(obj, rx)
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

function lib.rotateY(obj, ry)
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

function lib.rotateZ(obj, rz)
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

function lib.newCam(self)
	return {
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
		
		reset = self.reset,
		translate = self.translate,
		scale = self.scale,
		rotateX = self.rotateX,
		rotateY = self.rotateY,
		rotateZ = self.rotateZ,
	}
end

lib.cam = lib:newCam()
lib.currentCam = lib.cam

lib.drawTable = { }
function lib.draw(self, obj, x, y, z, sx, sy, sz)
	x = x or 0
	y = y or 0
	z = z or 0
	local transform = matrix{
		{sx or 1, 0, 0, x},
		{0, sy or sx or 1, 0, y},
		{0, 0, sz or sx or 1, z},
		{0, 0, 0, 1},
	}
	
	local bones
	if obj.bones then
		bones = { }
		for d,s in pairs(obj.bones) do
			bones[d] = {
				x = 0,
				y = 0,
				z = 0,
				rotation = matrix{
					{1, 0, 0},
					{0, 1, 0},
					{0, 0, 1},
				}
			}
		end
		
		--move
		local todo = {obj.bones.root.mountedBy}
		while #todo > 0 do
			local old = todo
			todo = { }
			for _,sp in ipairs(old) do
				for _,d in ipairs(sp) do
					local s = obj.bones[d]
					local ms = obj.bones[s.mount]
					todo[#todo+1] = s.mountedBy
					if s.mount ~= "root" then
						--move
						local ox, oy, oz = unpack(bones[s.mount].rotation * (matrix{{s.x - ms.x, s.y - ms.y, s.z - ms.z}}^"T"))
						bones[d].x = bones[s.mount].x + ox[1]
						bones[d].y = bones[s.mount].y + oy[1]
						bones[d].z = bones[s.mount].z + oz[1]
						
						local rx, ry, rz = s.rotationX, s.rotationY, s.rotationZ
						
						--local space
						local cc = math.cos(s.initRotationX)
						local ss = math.sin(s.initRotationX)
						local rotX = matrix{
							{1, 0, 0},
							{0, cc, -ss},
							{0, ss, cc},
						}
						
						local cc = math.cos(s.initRotationY)
						local ss = math.sin(s.initRotationY)
						local rotY = matrix{
							{cc, 0, -ss},
							{0, 1, 0},
							{ss, 0, cc},
						}
						
						local localSpace = rotY * rotX
						
						--to local space
						bones[d].rotation = localSpace * bones[d].rotation
						
						
						--rotate
						local cc = math.cos(rx or 0)
						local ss = math.sin(rx or 0)
						local rotX = matrix{
							{1, 0, 0},
							{0, cc, -ss},
							{0, ss, cc},
						}
						
						local cc = math.cos(ry or 0)
						local ss = math.sin(ry or 0)
						local rotY = matrix{
							{cc, 0, -ss},
							{0, 1, 0},
							{ss, 0, cc},
						}
						
						local cc = math.cos(rz or 0)
						local ss = math.sin(rz or 0)
						local rotZ = matrix{
							{cc, ss, 0},
							{-ss, cc, 0},
							{0, 0, 1},
						}
						
						bones[d].rotation = rotX * rotY * rotZ * bones[d].rotation
						
						--back to global space
						bones[d].rotation = localSpace:transpose() * bones[d].rotation
						
						
						--add mount bone rotation
						bones[d].rotation = bones[s.mount].rotation * bones[d].rotation
					end
				end
			end
		end
		
		for d,s in pairs(obj.bones) do
			local b = bones[d]
			local r = b.rotation
			
			local rotate = matrix{
				{r[1][1], r[1][2], r[1][3], 0},
				{r[2][1], r[2][2], r[2][3], 0},
				{r[3][1], r[3][2], r[3][3], 0},
				{0, 0, 0, 1},
			}
			
			local center = matrix{
				{1, 0, 0, -s.x},
				{0, 1, 0, -s.y},
				{0, 0, 1, -s.z},
				{0, 0, 0, 1},
			}
			
			local translate = matrix{
				{1, 0, 0, b.x},
				{0, 1, 0, b.y},
				{0, 0, 1, b.z},
				{0, 0, 0, 1},
			}
			
			bones[d] = translate * rotate * center
		end
	end
	
	local levelOfAbstraction = math.floor(math.sqrt((self.currentCam.x-x)^2 + (self.currentCam.y-y)^2 + (self.currentCam.z-z)^2) / 20) - 1
	local t = obj.objects or {obj}
	for d,s in pairs(t) do
		if (not s.simple or not t[s.super] or not t[s.super].loaded) and s.mesh and (not s.particleSystem or levelOfAbstraction <= 2) then
			for i = 1, levelOfAbstraction do
				s = t[s.simpler] or s
			end
			
			--insert intro draw todo list
			local shaderInfo = self:getShaderInfo(s.material.tex_diffuse and "textured" or "flat", s.material.shader or s.shader, s.material.tex_normal, s.material.tex_specular, s.material.reflections)
			if not lib.drawTable[shaderInfo] then
				lib.drawTable[shaderInfo] = { }
			end
			if not lib.drawTable[shaderInfo][s.material] then
				lib.drawTable[shaderInfo][s.material] = { }
			end
			local r, g, b = love.graphics.getColor()
			table.insert(lib.drawTable[shaderInfo][s.material], {
				(transform * (bones and (obj.transform * bones[d]) or obj.transform or 1))^"T",
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