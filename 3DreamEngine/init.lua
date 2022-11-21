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
require((...) .. "/libs/luaMatrices/mat4Extended")

_G.vec2 = require((...) .. "/libs/luaVectors/vec2")
_G.vec3 = require((...) .. "/libs/luaVectors/vec3")
_G.vec4 = require((...) .. "/libs/luaVectors/vec4")

_G.quat = require((...) .. "/libs/quat")

lib.utils = require((...) .. "/libs/utils")
lib.cimg = require((...) .. "/libs/cimg")
lib.packTable = require((...) .. "/libs/packTable")
lib.xml2lua = require((...) .. "/libs/xml2lua/xml2lua")
lib.xmlTreeHandler = require((...) .. "/libs/xml2lua/tree")
lib.json = require((...) .. "/libs/json")
lib.inspect = require((...) .. "/libs/inspect")
lib.base64 = require((...) .. "/libs/base64")

table.unpack = table.unpack or unpack

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
if lib.root:find(".", 0, true) then
	error("Ambiguous dots in require('" .. lib.root .. "'). Use slashes and avoid dots in file paths!")
end

--load sub modules
require((...) .. "/functions")
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

--file loader
lib.loader = { }
for _, s in pairs(love.filesystem.getDirectoryItems((...) .. "/loader")) do
	lib.loader[s:sub(1, #s - 4)] = require((...) .. "/loader/" .. s:sub(1, #s - 4))
end

--supported canvas formats
lib.canvasFormats = love.graphics and love.graphics.getCanvasFormats() or { }

--default material library
lib.materialLibrary = { }
lib.objectLibrary = { }

lib:registerMaterial(lib:newMaterial(), "None")
lib:registerMaterial(lib:newMaterial(), "Material")

--default settings
lib:setAO(32, 0.75, false)
lib:setBloom(-1)
lib:setFog()
lib:setFogHeight()
lib:setExposure(false)
lib:setGamma(true)
lib:setMaxLights(16)
lib:setFrustumCheck(true)
lib:setLODDistance(10)
lib:setGodrays(false)
lib:setDistortionMargin(true)

--loader settings
lib:setResourceLoader(true)
lib:setSmoothLoading(false)
lib:setSmoothLoadingBufferSize(128)
lib:setMipmaps(true)

--sky
lib:setDefaultReflection("sky")
lib:setSky({ 0.5, 0.5, 0.5 })
lib:setSkyReflectionFormat(256, "rgba16f", false)

--auto exposure
lib:setAutoExposure(false)

--canvas set settings
lib.canvases = lib:newCanvases()
lib.canvases:setRefractions(true)
lib.canvases:setMode("normal")

lib.reflectionCanvases = lib:newCanvases()
lib.reflectionCanvases:setMode("direct")

--lib.mirrorCanvases = lib:newCanvases()
--lib.mirrorCanvases:setMode("lite")

--default camera
lib.camera = lib:newCamera()

--default scene
lib.scene = lib:newScene()

--hardcoded mipmap count, do not change
lib.reflectionsLevels = 6

lib.version_3DO = 6

--default meshFormats
lib.meshFormats = { }
lib:registerMeshFormat("textured", require(lib.root .. "/meshFormats/textured"))
lib:registerMeshFormat("simple", require(lib.root .. "/meshFormats/simple"))
lib:registerMeshFormat("material", require(lib.root .. "/meshFormats/material"))

--some functions require temporary canvases
lib.canvasCache = { }

if love.graphics then
	--default objects
	lib.skyObject = lib:loadObject(lib.root .. "/objects/sky")
	lib.cubeObject = lib:loadObject(lib.root .. "/objects/cube")
	lib.planeObject = lib:loadObject(lib.root .. "/objects/plane")
	
	--default textures
	local pix = love.image.newImageData(2, 2)
	lib.textures = {
		default = love.graphics.newImage(lib.root .. "/res/default.png"),
		godray = love.graphics.newImage(lib.root .. "/res/godray.png"),
		defaultNormal = love.graphics.newImage(lib.root .. "/res/defaultNormal.png"),
		skyFallback = love.graphics.newCubeImage({ pix, pix, pix, pix, pix, pix }),
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
end

---Reload canvases
---@param w number
---@param h number
function lib:resize(w, h)
	w = w or love.graphics.getWidth()
	h = h or love.graphics.getHeight()
	
	--canvases sets
	self.canvases:init(w, h)
	self.reflectionCanvases:init()
	--self.mirrorCanvases:init(w, h)
end

---Applies settings and load canvases
---@param w number
---@param h number
function lib:init(w, h)
	if self.canvases.mode == "direct" then
		local width, height, flags = love.window.getMode()
		if flags.depth == 0 then
			print("Direct render is enabled, but there is no depth buffer! Using 16-bit depth from now on.")
			love.window.updateMode(width, height, { depth = 16 })
		end
	end
	
	if self.autoExposure_enabled and self.canvases.mode == "direct" then
		print("Autoexposure does not work with direct render! Autoexposure has been disabled.")
		self:setAutoExposure(false)
	end
	
	self:resize(w, h)
	
	self.canvasCache = { }
	
	self:clearLoadedCanvases()
	
	--reset shader
	self:loadShader()
	
	--reset lighting
	for _, l in pairs(self.lighting or { }) do
		if l.shadow then
			l.shadow:clear()
		end
	end
	self.lighting = { }
	
	--sky box
	if self.defaultReflection == "sky" then
		self.defaultReflectionCanvas = love.graphics.newCanvas(self.sky_resolution, self.sky_resolution, { format = self.sky_format, readable = true, msaa = 0, type = "cube", mipmaps = "manual" })
	else
		self.defaultReflectionCanvas = false
	end
	
	self:initJobs()
end

---Clears the current scene
function lib:prepare()
	self.lighting = { }
	
	self.scenes = { }
	
	lib:drawScene(self.scene)
	self.scene:clear()
	
	self.particleBatches = { {}, {} }
	self.particles = { {}, {} }
	
	--keep track of reflections
	self.lastReflections = self.reflections or { }
	self.reflections = { }
	
	--reset stats
	self.stats.vertices = 0
	self.stats.shadersInUse = 0
	self.stats.materialsUsed = 0
	self.stats.draws = 0
end

---draw
---@param object DreamObject
---@param x number
---@param y number
---@param z number
---@param sx number
---@param sy number
---@param sz number
---@overload fun(object: DreamObject)
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

---Add a light
---@param light DreamLight
function lib:addLight(light)
	table.insert(self.lighting, light)
end

---Add a new simple light
---@param typ string
---@param position "vec3"
---@param color "vec3"
---@param brightness number
function lib:addNewLight(typ, position, color, brightness)
	self:addLight(self:newLight(typ, position, color, brightness))
end

---Will render this scene
---@param scene DreamScene
function lib:drawScene(scene)
	self.scenes[scene] = true
end

---Will render this batch
---@param batch DreamParticleBatch
function lib:drawParticleBatch(batch)
	local ID = (batch.emissionTexture and 2 or 1) + (batch.distortionTexture and 2 or 0)
	local bt = self.particleBatches[batch.alpha and 2 or 1]
	bt[ID] = bt[ID] or { }
	bt[ID][batch] = true
end

---Draw a single particle
---@param particle DreamParticle
---@param quad Quad
---@param x number
---@param y number
---@param z number
function lib:drawParticle(particle, quad, x, y, z, ...)
	assert(particle.class == "particle", "create a particle object and pass it here")
	particle = particle:clone()
	
	if type(quad) == "userdata" then
		particle.quad = quad
		particle.position = { x or 0, y or 0, z or 0 }
		particle.transform = { ... }
	else
		particle.quad = nil
		particle.position = { quad or 0, x or 0, y or 0 }
		particle.transform = { z, ... }
	end
	particle.color = { love.graphics.getColor() }
	
	local p = self.particles[particle.alpha and 2 or 1]
	local id = particle:getID()
	p[id] = p[id] or { }
	table.insert(p[id], particle)
end

return lib