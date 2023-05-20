--[[
#3DreamEngine - 3D library by Luke100000
#Copyright 2020 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

---The main class
---@class Dream
local lib = { }

if love.filesystem.read("debugEnabled") == "true" then
	_DEBUGMODE = true
end

_3DreamEngine = lib
lib.root = (...):gsub("%.", "/")
if lib.root:sub(-4) == "init" then
	lib.root = lib.root:sub(1, -6)
end

--supported canvas formats
lib.canvasFormats = love.graphics and love.graphics.getCanvasFormats() or { }

--mobile mode sets lower graphics settings by default
lib.IS_MOBILE = false

if love.system.getOS() == "Android" or not lib.canvasFormats["rgba16f"] or not lib.canvasFormats["rg16f"] then
	print("System not fully supported, HDR and post effects disabled by default.")
	lib.IS_MOBILE = true
end

--load libraries
---@type DreamMat2
lib.mat2 = require(lib.root .. "/libs/luaMatrices/mat2")
---@type DreamMat3
lib.mat3 = require(lib.root .. "/libs/luaMatrices/mat3")
---@type DreamMat4
lib.mat4 = require(lib.root .. "/libs/luaMatrices/mat4")
require(lib.root .. "/libs/luaMatrices/mat4Extended")(lib.mat4)

---@type DreamVec2
lib.vec2 = require(lib.root .. "/libs/luaVectors/vec2")
---@type DreamVec3
lib.vec3 = require(lib.root .. "/libs/luaVectors/vec3")
---@type DreamVec4
lib.vec4 = require(lib.root .. "/libs/luaVectors/vec4")

---@type DreamQuat
lib.quat = require(lib.root .. "/libs/quat")

--provide access to other libs
for _, v1 in ipairs({ "mat2", "mat3", "mat4", "vec2", "vec3", "vec4", "quat" }) do
	for _, v2 in ipairs({ "mat2", "mat3", "mat4", "vec2", "vec3", "vec4", "quat" }) do
		lib[v1][v2] = lib[v2]
	end
end

lib.utils = require(lib.root .. "/libs/utils")
lib.cimg = require(lib.root .. "/libs/cimg")
lib.packTable = require(lib.root .. "/libs/packTable")
lib.xml2lua = require(lib.root .. "/libs/xml2lua/xml2lua")
lib.xmlTreeHandler = require(lib.root .. "/libs/xml2lua/tree")
lib.json = require(lib.root .. "/libs/json")
lib.inspect = require(lib.root .. "/libs/inspect")
lib.base64 = require(lib.root .. "/libs/base64")
lib.cache = require(lib.root .. "/libs/cache")
lib.packer = require(lib.root .. "/libs/packer")

table.unpack = table.unpack or unpack

--delton, disabled when not in debug mode
lib.delton = require(lib.root .. "/libs/delton"):new(512)
lib.deltonLoad = require(lib.root .. "/libs/delton"):new(1)
lib.deltonLoad.maxAge = 999999

if not _DEBUGMODE then
	lib.delton.start = function() end
	lib.delton.stop = lib.delton.start
	lib.delton.step = lib.delton.start
	lib.deltonLoad.start = function() end
	lib.deltonLoad.stop = lib.delton.start
	lib.deltonLoad.step = lib.delton.start
end

--load sub modules
require(lib.root .. "/functions")
require(lib.root .. "/settings")
require(lib.root .. "/classes")
require(lib.root .. "/shader")
require(lib.root .. "/loader")
require(lib.root .. "/materials")
require(lib.root .. "/resources")
require(lib.root .. "/render")
require(lib.root .. "/renderLight")
require(lib.root .. "/renderGodrays")
require(lib.root .. "/renderSky")
require(lib.root .. "/jobs")
require(lib.root .. "/particleSystem")

--file loader
lib.loader = { }
for _, s in pairs(love.filesystem.getDirectoryItems(lib.root .. "/loader")) do
	lib.loader[s:sub(1, #s - 4)] = require(lib.root .. "/loader/" .. s:sub(1, #s - 4))
end

--default material library
lib.materialLibrary = { }
lib.objectLibrary = { }

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
lib.canvases:setMode(lib.IS_MOBILE and "direct" or "normal")

lib.reflectionCanvases = lib:newCanvases()
lib.reflectionCanvases:setMode("direct")

--lib.mirrorCanvases = lib:newCanvases()
--lib.mirrorCanvases:setMode("lite")

--default camera
lib.camera = lib:newCamera()

--hardcoded mipmap count, do not change
lib.reflectionsLevels = 6

lib.version_3DO = 6

--default meshFormats
lib.meshFormats = { }
lib:registerMeshFormat(require(lib.root .. "/meshFormats/textured"), "textured")
lib:registerMeshFormat(require(lib.root .. "/meshFormats/simple"), "simple")
lib:registerMeshFormat(require(lib.root .. "/meshFormats/material"), "material")
lib:registerMeshFormat(require(lib.root .. "/meshFormats/font"), "font")

--some functions require temporary canvases
lib.canvasCache = { }

lib.renderTasks = { }

if love.graphics then
	--default objects
	lib.skyObject = lib:loadObject(lib.root .. "/objects/sky", { ignoreMissingMaterials = true })
	lib.cubeObject = lib:loadObject(lib.root .. "/objects/cube", { ignoreMissingMaterials = true })
	lib.planeObject = lib:loadObject(lib.root .. "/objects/plane", { ignoreMissingMaterials = true })
	
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
	
	--reset shader
	self:loadShaders()
	
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
	self.renderTasks = { }
	
	--keep track of reflections
	self.lastReflections = self.reflections or { }
	self.reflections = { }
	
	--reset stats
	self.stats.vertices = 0
	self.stats.shaderSwitches = 0
	self.stats.materialSwitches = 0
	self.stats.draws = 0
end

---draw
---@param object DreamObject | DreamMesh
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
	if type(x) == "table" then
		transform = x
	elseif x then
		--simple transform with arguments, ignores object transformation matrix
		transform = self.mat4({
			sx or 1, 0, 0, x,
			0, sy or sx or 1, 0, y,
			0, 0, sz or sx or 1, z,
			0, 0, 0, 1
		})
	end
	
	--add to scene
	table.insert(self.renderTasks, { object, transform })
end

---Add a light
---@param light DreamLight
function lib:addLight(light)
	table.insert(self.lighting, light)
end

---Add a new simple light
---@param typ string
---@param position DreamVec3
---@param color DreamVec3
---@param brightness number
function lib:addNewLight(typ, position, color, brightness)
	self:addLight(self:newLight(typ, position, color, brightness))
end

return lib