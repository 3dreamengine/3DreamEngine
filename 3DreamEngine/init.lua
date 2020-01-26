--[[
#3DreamEngine - 3D library by Luke100000
#Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local lib = { }

if love.filesystem.read("debugEnabled") == "true" then
	_DEBUGMODE = true
end

_3DreamEngine = lib
lib.root = (...)
require((...) .. "/functions")
require((...) .. "/shader")
require((...) .. "/loader")
require((...) .. "/present")
require((...) .. "/particlesystem")
require((...) .. "/libs/saveTable")
matrix = require((...) .. "/libs/matrix")

lib.ffi = require("ffi")


--loader
lib.loader = { }
for d,s in pairs(love.filesystem.getDirectoryItems((...) .. "/loader")) do
	require((...) .. "/loader/" .. s:sub(1, #s-4))
end

_3DreamEngine = nil

--supported canvas formats
lib.canvasFormats = love.graphics and love.graphics.getCanvasFormats() or { }

--sun
lib.sun = {-0.3, 0.6, 0.5}
lib.color_ambient = {1.0, 1.0, 1.0, 0.25}
lib.color_sun = {1.0, 1.0, 1.0, 1.0}

--field of view
lib.fov = 90

--distance fog
lib.fog = 0.0
lib.near = lib.canvasFormats["depth32f"] and 0.1 or lib.canvasFormats["depth24"] and 0.25 or 0.5
lib.far = lib.canvasFormats["depth32f"] and 1000 or lib.canvasFormats["depth24"] and 750 or 500

--root directory of objects
lib.objectDir = ""

--settings
lib.AO_enabled = true
lib.AO_strength = 0.75
lib.AO_quality = 16
lib.AO_quality_smooth = 1
lib.AO_resolution = 0.75

lib.bloom_enabled = true
lib.bloom_size = 12.0
lib.bloom_quality = 6
lib.bloom_resolution = 0.5
lib.bloom_strength = 4.0

lib.SSR_enabled = false

lib.textures_mipmaps = true
lib.textures_filter = "linear"

lib.msaa = 4
lib.max_lights = 16

lib.shadow_enabled = false
lib.shadow_resolution = 4096
lib.shadow_distance = 30

lib.anaglyph3D = false
lib.anaglyph3D_eyeDistance = 0.05

lib.lighting_max = 16
lib.nameDecoder = "blender"

if love.graphics then
	lib.object_light = lib:loadObject(lib.root .. "/objects/light")
	lib.object_clouds = lib:loadObject(lib.root .. "/objects/clouds_high", {meshType = "textured"})
	lib.object_sky = lib:loadObject(lib.root .. "/objects/sky", {meshType = "textured"})
	
	lib.textures = {
		default_albedo = love.graphics.newImage(lib.root .. "/res/default_albedo.png"),
		default_normal = love.graphics.newImage(lib.root .. "/res/default_normal.png"),
		default_roughness = love.graphics.newImage(lib.root .. "/res/default_roughness.png"),
		default_metallic = love.graphics.newImage(lib.root .. "/res/default_metallic.png"),
		default_ao = love.graphics.newImage(lib.root .. "/res/default_ao.png"),
		default_emission = love.graphics.newImage(lib.root .. "/res/default_emission.png"),
	}
	
	if love.graphics.getTextureTypes()["array"] then
		lib.textures_array = {
			default_albedo = love.graphics.newArrayImage({lib.root .. "/res/default_albedo.png"}),
			default_normal = love.graphics.newArrayImage({lib.root .. "/res/default_normal.png"}),
			default_roughness = love.graphics.newArrayImage({lib.root .. "/res/default_roughness.png"}),
			default_metallic = love.graphics.newArrayImage({lib.root .. "/res/default_metallic.png"}),
			default_ao = love.graphics.newArrayImage({lib.root .. "/res/default_ao.png"}),
			default_emission = love.graphics.newArrayImage({lib.root .. "/res/default_emission.png"}),
		}
	end
end

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

--default camera
lib.cam = lib:newCam()
lib.currentCam = lib.cam

function lib.resize(self, w, h)
	self.canvas = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = 0})
	self.canvas_depth = love.graphics.newCanvas(w, h, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = true, msaa = 0})
	self.canvas_normal = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = 0})
	self.canvas_position = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = 0})
	
	--screen space ambient occlusion
	if self.AO_enabled then
		self.canvas_ao_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		self.canvas_ao_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
	end
	
	--bloom
	if self.bloom_enabled then
		local ok = pcall(function()
			self.canvas_bloom = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = 0})
		end)
		if ok then
			self.canvas_bloom_1 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = "normal", readable = true, msaa = 0})
			self.canvas_bloom_2 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = "normal", readable = true, msaa = 0})
		else
			self.bloom_enabled = false
			print("r8 canvas creation failed, bloom deactivated")
		end
	end
	
	--screen space reflections
	if self.SSR_enabled then
		self.canvas_reflectiness = love.graphics.newCanvas(w, h, {format = self.canvasFormats["r8"] and "r8" or "normal", readable = true, msaa = 0})
	end
	
	--shadows
	if self.shadow_enabled then
		self.canvas_shadow_depth = love.graphics.newCanvas(self.shadow_resolution, self.shadow_resolution, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = true, msaa = 0})
		
		self.canvas_shadow_depth:setDepthSampleMode("greater")
		self.canvas_shadow_depth:setFilter("linear", "linear", 1)
		
		--dummy canvas
		self.canvas_shadow = love.graphics.newCanvas(self.shadow_resolution, self.shadow_resolution, {format = self.canvasFormats["r8"] and "r8" or "normal", readable = true, msaa = 0})
	end
	
	self:loadShader()
end

function lib.init(self)
	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
	
	self:clearShaders()
	self:loadShader()
	
	self.lighting = { }
	
	if self.clouds then
		self.clouds:setWrap("repeat")
		self.object_clouds.objects.Cube.mesh:setTexture(self.clouds)
	end
	
	if self.sky then
		self.sky:setWrap("repeat")
		self.object_sky.objects.Sphere.mesh:setTexture(self.sky)
		if self.night then
			self.night:setWrap("repeat")
			self.shaders.skyNight:send("night", self.night)
		end
	end
end

function lib.prepare(self, c, noDepth)
	self.noDepth = noDepth
	
	local cam = c == false and self:newCam() or c or self.cam
	self.currentCam = cam
	
	self.shaderVars_viewPos = -self.currentCam.transform^"T" * (matrix{{self.currentCam.transform[1][4], self.currentCam.transform[2][4], self.currentCam.transform[3][4], self.currentCam.transform[4][4]}}^"T")
	self.shaderVars_viewPos = {self.shaderVars_viewPos[1][1], self.shaderVars_viewPos[2][1], self.shaderVars_viewPos[3][1]}
	
	local n = self.near
	local f = self.far
	local fov = self.fov
	local S = 1 / (math.tan(fov/2*math.pi/180))
	
	--perspective
	local projection = matrix{
		{S,	0,	0,	0},
		{0,	-S/love.graphics.getHeight()*love.graphics.getWidth(),	0,	0},
		{0,	0,	-f/(f-n),	-(f*n)/(f-n)},
		{0,	0,	-1,	0},
	}
	
	local camRot = self.currentCam.transform:copy()
	camRot[4][2] = 0
	camRot[4][3] = 0
	camRot[4][4] = 0
	camRot[2][4] = 0
	camRot[3][4] = 0
	camRot[4][4] = 0
	
	--camera normal
	local normal = self.currentCam.transform^"T" * (matrix{{0, 0, 1, 0}}^"T")
	cam.normal = {-normal[1][1], -normal[2][1], -normal[3][1]}
	
	--camera transformation
	if self.anaglyph3D then
		local offsetX = self.currentCam.transform^"T" * (matrix{{self.anaglyph3D_eyeDistance/2, 0, 0, 0}}^"T")
		local offset = camRot * matrix{{0, 0, 0, offsetX[1][1]}, {0, 0, 0, offsetX[2][1]}, {0, 0, 0, offsetX[3][1]}, {0, 0, 0, 0}}
		self.shaderVars_transformProj = projection * (self.currentCam.transform + offset)
		
		local offsetX = self.currentCam.transform^"T" * (matrix{{-self.anaglyph3D_eyeDistance/2, 0, 0, 0}}^"T")
		local offset = camRot * matrix{{0, 0, 0, offsetX[1][1]}, {0, 0, 0, offsetX[2][1]}, {0, 0, 0, offsetX[3][1]}, {0, 0, 0, 0}}
		self.shaderVars_transformProj_2 = projection * (self.currentCam.transform + offset)
	else
		self.shaderVars_transformProj = projection * self.currentCam.transform
	end
	
	--shadow
	if self.shadow_enabled then
		--orthographic
		local r = self.shadow_distance/2
		local t = self.shadow_distance/2
		local l = -r
		local b = -t
		
		local n = 0.1
		local f = 100
		
		local projection = matrix{
			{2 / (r - l),	0,	0,	-(r + l) / (r - l)},
			{0, -2 / (t - b), 0, -(t + b) / (t - b)},
			{0, 0, -2 / (f - n), -(f + n) / (f - n)},
			{0, 0, 0, 1},
		}
		
		local cam2 = self:newCam()
		local sun = self.sun
		
		cam2:translate(-self.cam.normal[1]*self.shadow_distance*0.5, -self.cam.normal[2]*self.shadow_distance*0.5, -self.cam.normal[3]*self.shadow_distance*0.5)
		cam2:translate(-self.shaderVars_viewPos[1], -self.shaderVars_viewPos[2], -self.shaderVars_viewPos[3])
		
		cam2:rotateY(math.atan2(sun[1], sun[3]))
		cam2:rotateX(math.atan2(sun[2], math.sqrt(sun[1]^2 + sun[3]^2)))
		
		cam2:translate(0, 0, -self.shadow_distance/2)
		
		self.shaderVars_transformProjShadow = projection * cam2.transform
	end
	
	--clear draw table
	self.drawTable = { }
	self.particles = { }
	self.particleCounter = 0
	
	--show light sources
	if self.showLightSources then
		for d,s in ipairs(self.lighting) do
			love.graphics.setColor(s.r, s.g, s.b)
			self:draw(self.object_light, s.x, s.y, s.z, 0.2, nil, nil)
		end
		love.graphics.setColor(1, 1, 1, 1)
	end
end

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
	
	local t = obj.objects or {obj}
	for d,s in pairs(t) do
		if not s.disabled then
			--insert intro draw todo list
			if s.mesh then
				local shaderInfo = self:getShaderInfo(s.material, s.meshType, obj)
				if not lib.drawTable[shaderInfo] then
					lib.drawTable[shaderInfo] = { }
				end
				if not lib.drawTable[shaderInfo][s.material] then
					lib.drawTable[shaderInfo][s.material] = { }
				end
				local r, g, b = love.graphics.getColor()
				table.insert(lib.drawTable[shaderInfo][s.material], {
					(transform * (obj.transform or 1))^"T",
					s,
					r, g, b,
					obj,
				})
			end
		end
	end
end

function lib.drawParticle(self, tex, quad, x, y, z, size, rot, emission, emissionTexture)
	if type(quads) == "number" then
		self:drawParticle(tex, false, x, y, z, size, rot)
		return
	end
	
	local transformProj = self.shaderVars_transformProj
	
	local pz = transformProj[3][1] * x + transformProj[3][2] * y + transformProj[3][3] * z + transformProj[3][4]
	if pz > 0.075 then
		local pw = transformProj[4][1] * x + transformProj[4][2] * y + transformProj[4][3] * z + transformProj[4][4]
		local px = (transformProj[1][1] * x + transformProj[1][2] * y + transformProj[1][3] * z + transformProj[1][4]) / pw
		local py = (transformProj[2][1] * x + transformProj[2][2] * y + transformProj[2][3] * z + transformProj[2][4]) / pw
		
		self.particleCounter = self.particleCounter + 1
		self.particles[self.particleCounter] = {tex, quad, px, py, pz / pw, (size or 1.0) / pz, rot or 0.0, emission or 0.0, emissionTexture}
	end
end

return lib