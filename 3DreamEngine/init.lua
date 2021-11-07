--[[
#3DreamEngine - 3D library by Luke100000
#Copyright 2020 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

local lib = { }

if love.filesystem.read("debugEnabled") == "true" then
	_DEBUGMODE = true
end

--load libraries
_G.mat2 = require((...) .. "/libs/luaMatrices/mat2")
_G.mat3 = require((...) .. "/libs/luaMatrices/mat3")
_G.mat4 = require((...) .. "/libs/luaMatrices/mat4")

_G.vec2 = require((...) .. "/libs/luaVectors/vec2")
_G.vec3 = require((...) .. "/libs/luaVectors/vec3")
_G.vec4 = require((...) .. "/libs/luaVectors/vec4")

_G.quat = require((...) .. "/libs/quat")
_G.cimg = require((...) .. "/libs/cimg")
_G.utils = require((...) .. "/libs/utils")
_G.packTable = require((...) .. "/libs/packTable")

--delton, disabled when not in debug mode
lib.delton = require((...) .. "/libs/delton"):new(512)
lib.deltonLoad = require((...) .. "/libs/delton"):new(1)
lib.deltonLoad.maxAge = 999999

if not _DEBUGMODE then
	lib.delton.start = function() end
	lib.delton.stop = lib.delton.start
	lib.delton.step = lib.delton.start
	lib.deltonLoad.start = function() end
	lib.deltonLoad.stop = lib.delton.start
	lib.deltonLoad.step = lib.delton.start
end

_3DreamEngine = lib
lib.root = (...)

--shader node types
lib.shaderNodes = { }
for _,group in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/nodes")) do
	for _,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/nodes/" .. group)) do
		local typ = s:sub(1, #s-4)
		local n = require(lib.root .. "/nodes/" .. group .. "/" .. typ)
		n.typ = typ
		n.group = group
		lib.shaderNodes[typ] = n
	end
end

--load sub modules
require((...) .. "/functions")
require((...) .. "/bufferFunctions")
require((...) .. "/settings")
require((...) .. "/classes")
require((...) .. "/shader")
require((...) .. "/loader")
require((...) .. "/materials")
require((...) .. "/resources")
require((...) .. "/render")
require((...) .. "/renderLight")
require((...) .. "/renderGodrays")
require((...) .. "/renderSky")
require((...) .. "/jobs")
require((...) .. "/particlesystem")
require((...) .. "/particles")
require((...) .. "/3doExport")
require((...) .. "/animations")
require((...) .. "/bake")

--file loader
lib.loader = { }
for d,s in pairs(love.filesystem.getDirectoryItems((...) .. "/loader")) do
	lib.loader[s:sub(1, #s-4)] = require((...) .. "/loader/" .. s:sub(1, #s-4))
end

--get color of sun based on sunrise sky texture
lib.sunlight = require(lib.root .. "/res/sunlight")
lib.skylight = require(lib.root .. "/res/skylight")

--supported canvas formats
lib.canvasFormats = love.graphics and love.graphics.getCanvasFormats() or { }

--default material library
lib.materialLibrary = { }
lib.objectLibrary = { }

--default settings
lib:setAO(32, 0.75, false)
lib:setBloom(-1)
lib:setFog()
lib:setFogHeight()
lib:setDaytime(0.3)
lib:setGamma(false)
lib:setExposure(1.0)
lib:setMaxLights(16)
lib:setNameDecoder("(.*)_.*")
lib:setFrustumCheck(true, false)
lib:setLODDistance(20)
lib:setGodrays(16, false)
lib:setDistortionMargin(true)

--shadows
lib:setShadowResolution(1024 * 4, 512)
lib:setShadowSmoothing(false)
lib:setShadowCascade(8, 4)

--loader settings
lib:setResourceLoader(true, true)
lib:setJobHandlerSlots(1)
lib:setSmoothLoading(1 / 1000)
lib:setSmoothLoadingBufferSize(128)
lib:setMipmaps(true)

--sun
lib:setSunOffset(0.0, 0,0)
lib:setSunShadow(true, "dynamic")

--weather
lib:setWeather(0.5)
lib:setRainbow(0.0)
lib:setRainbowDir(vec3(1.0, -0.25, 1.0))

--sky
lib:setReflection(true)
lib:setSky(true)
lib:setSkyReflectionFormat(512, "rgba16f", 4)

--clouds
lib:setClouds(true)
lib:setWind(0.005, 0.0)
lib:setCloudsStretch(0, 20, 0)
lib:setCloudsAnim(0.01, 0.25)
lib:setUpperClouds(true)

--auto exposure
lib:setAutoExposure(false)

--canvas set settings
lib.renderSet = lib:newSetSettings()
lib.renderSet:setPostEffects(true)
lib.renderSet:setRefractions(true)
lib.renderSet:setMode("normal")

lib.reflectionsSet = lib:newSetSettings()
lib.reflectionsSet:setMode("direct")

lib.mirrorSet = lib:newSetSettings()
lib.mirrorSet:setMode("lite")

lib.shadowSet = lib:newSetSettings()

--default camera
lib.cam = lib:newCam()

--default scene
lib.scene = lib:newScene()

--hardcoded mipmap count, do not change
lib.reflections_levels = 6

--default objects
lib.object_sky = lib:loadObject(lib.root .. "/objects/sky")
lib.object_cube = lib:loadObject(lib.root .. "/objects/cube")
lib.object_plane = lib:loadObject(lib.root .. "/objects/plane")

--default textures
local pix = love.image.newImageData(2, 2)
lib.textures = {
	default = love.graphics.newImage(lib.root .. "/res/default.png"),
	godray = love.graphics.newImage(lib.root .. "/res/godray.png"),
	default_normal = love.graphics.newImage(lib.root .. "/res/default_normal.png"),
	sky_fallback = love.graphics.newCubeImage({pix, pix, pix, pix, pix, pix}),
}
lib.textures.godray:setWrap("repeat", "repeat")

lib.textures.noise = love.graphics.newImage(lib.root .. "/res/noise.png")
lib.textures.noise:setWrap("repeat")

lib.textures.foam = love.graphics.newImage(lib.root .. "/res/foam.png")
lib.textures.foam:setWrap("repeat")

--load textures once actually needed
lib.initTextures = { }
function lib.initTextures:PBR()
	if not self.PBR_done then
		self.PBR_done = true
		lib.textures.brdfLUT = love.graphics.newImage(lib.root .. "/res/brdfLut.png")
	end
end

function lib.initTextures:sky()
	if not self.sky_done then
		self.sky_done = true
		
		lib.textures.sky = love.graphics.newImage(lib.root .. "/res/sky.png")
		lib.textures.moon = love.graphics.newImage(lib.root .. "/res/moon.png")
		lib.textures.moon_normal = love.graphics.newImage(lib.root .. "/res/moon_normal.png")
		lib.textures.sun = love.graphics.newImage(lib.root .. "/res/sun.png")
		lib.textures.rainbow = love.graphics.newImage(lib.root .. "/res/rainbow.png")
		
		lib.textures.clouds = lib.textures.clouds or love.graphics.newImage(lib.root .. "/res/clouds.png")
		lib.textures.clouds_base = love.graphics.newImage(lib.root .. "/res/clouds_base.png")
		lib.textures.clouds_base:setWrap("repeat")
		lib.textures.clouds_top = love.graphics.newCubeImage(lib.root .. "/res/clouds_top.png")
		lib.textures.stars = love.graphics.newCubeImage(lib.root .. "/res/stars.png")
		
		lib.textures.clouds:setFilter("nearest")
	end
end

--a canvas set is used to render a scene to
function lib:newCanvasSet(settings, w, h)
	local set = { }
	w = w or settings.resolution
	h = h or settings.resolution
	
	--settings
	set.shaderID = settings.shaderID
	set.width = w
	set.height = h
	set.msaa = settings.msaa
	set.mode = settings.mode
	set.postEffects = settings.postEffects and settings.mode == "normal"
	set.refractions = settings.alphaPass and settings.refractions and settings.mode == "normal"
	set.format = settings.format
	set.alphaPass = settings.alphaPass
	
	if settings.mode ~= "direct" then
		--depth
		set.depth_buffer = love.graphics.newCanvas(w, h, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = false, msaa = set.msaa})
		
		--temporary HDR color
		set.color = love.graphics.newCanvas(w, h, {format = settings.format, readable = true, msaa = set.msaa})
		
		--additional color if using refractions
		if set.refractions then
			set.colorAlpha = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = set.msaa})
			set.distortion = love.graphics.newCanvas(w, h, {format = "rg16f", readable = true, msaa = set.msaa})
		end
		
		--depth
		set.depth = love.graphics.newCanvas(w, h, {format = "r16f", readable = true, msaa = set.msaa})
	end
	
	--screen space ambient occlusion blurring canvases
	if self.AO_enabled and settings.mode ~= "direct" then
		set.AO_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		if self.AO_blur then
			set.AO_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		end
	end
	
	--post effects
	if set.postEffects then
		--bloom blurring canvases
		if self.bloom_enabled then
			set.bloom_1 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = settings.format, readable = true, msaa = 0})
			set.bloom_2 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = settings.format, readable = true, msaa = 0})
		end
	end
	
	return set
end

--release set and free memory
function lib:unloadCanvasSet(set)
	if set then
		for d,s in pairs(set) do
			if type(set) == "userdata" and set.release then
				set:release()
			end
		end
	end
end

--load canvases
function lib.resize(self, w, h)
	--fully unload previous sets
	self:unloadCanvasSet(self.canvases)
	self:unloadCanvasSet(self.canvases_reflections)
	
	--canvases sets
	self.canvases = self:newCanvasSet(self.renderSet, w, h)
	self.canvases_reflections = self:newCanvasSet(self.reflectionsSet)
	self.canvases_mirror = self:newCanvasSet(self.mirrorSet, w, h)
	
	--sky box
	if self.sky_reflection == true then
		self.sky_reflectionCanvas = love.graphics.newCanvas(self.sky_resolution, self.sky_resolution, {format = self.sky_format, readable = true, msaa = 0, type = "cube", mipmaps = "manual"})
	else
		self.sky_reflectionCanvas = false
	end
	
	self:loadShader()
	self:initJobs()
end

--applies settings and load canvases
function lib.init(self, w, h)
	if self.renderSet.mode == "direct" then
		local width, height, flags = love.window.getMode()
		if flags.depth == 0 then
			print("Direct render is enabled, but there is no depth buffer! Using 16-bit depth from now on.")
			love.window.updateMode(width, height, {depth = 16})
		end
	end
	
	if self.autoExposure_enabled and self.renderSet.mode == "direct" then
		print("Autoexposure does not work with direct render! Autoexposure has been disabled.")
		self:setAutoExposure(false)
	end
	
	self:resize(w or love.graphics.getWidth(), h or love.graphics.getHeight())
	
	--reset shader
	self:loadShader()
	
	--reset lighting
	self.lighting = { }
	
	--create sun shadow if requested
	--TODO sun strength should receive setting
	self.sunObject = lib:newLight("sun", 1, 1, 1, 1, 1, 1, 5)
	if self.sun_shadow then
		self.sunObject.shadow = lib:newShadow("sun", self.sun_static)
	else
		self.sunObject.shadow = nil
	end
end

--clears the current scene
function lib:prepare()
	self.scenes = { }
	
	lib:drawScene(self.scene)
	self.scene:clear()
	
	self.particleBatches = {{}, {}}
	self.particles = {{}, {}}
	
	--keep track of reflections
	self.lastReflections = self.reflections or { }
	self.reflections = { }
	
	--reset stats
	self.stats.vertices = 0
	self.stats.shadersInUse = 0
	self.stats.materialsUsed = 0
	self.stats.draws = 0
end

--add an object to the default scene
function lib:draw(object, x, y, z, sx, sy, sz)
	--prepare transform matrix
	local transform
	local dynamic = false
	if x then
		--simple transform with arguments, ignores object transformation matrix
		transform = mat4({
			sx or 1, 0, 0, x,
			0, sy or sx or 1, 0, y,
			0, 0, sz or sx or 1, z,
			0, 0, 0, 1
		}) 
		dynamic = true
	end
	
	--add to scene
	self.delton:start("draw")
	self.scene:addObject(object, transform, dynamic)
	self.delton:stop()
end

--will render this scene
function lib:drawScene(scene)
	self.scenes[scene] = true
end

--will render this batch
function lib:drawParticleBatch(batch)
	local ID = (batch.emissionTexture and 2 or 1) + (batch.distortionTexture and 2 or 0)
	local bt = self.particleBatches[batch.alpha and 2 or 1]
	bt[ID] = bt[ID] or { }
	bt[ID][batch] = true
end

--draw a particle
function lib:drawParticle(particle, quad, x, y, z, ...)
	assert(particle.class == "particle", "create a particle object and pass it here")
	local particle = particle:clone()
	
	if type(quad) == "userdata" then
		particle.quad = quad
		particle.position = {x or 0, y or 0, z or 0}
		particle.transform = {...}
	else
		particle.quad = nil
		particle.position = {quad or 0, x or 0, y or 0}
		particle.transform = {z, ...}
	end
	particle.color = {love.graphics.getColor()}
	
	local p = self.particles[particle.alpha and 2 or 1]
	local id = particle:getID()
	p[id] = p[id] or { }
	table.insert(p[id], particle)
end

return lib