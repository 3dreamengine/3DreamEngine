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
mat2 = require((...) .. "/libs/luaMatrices/mat2")
mat3 = require((...) .. "/libs/luaMatrices/mat3")
mat4 = require((...) .. "/libs/luaMatrices/mat4")

vec2 = require((...) .. "/libs/luaVectors/vec2")
vec3 = require((...) .. "/libs/luaVectors/vec3")
vec4 = require((...) .. "/libs/luaVectors/vec4")

cimg = require((...) .. "/libs/cimg")
require((...) .. "/libs/saveTable")
lib.ffi = require("ffi")

--load sub modules
_3DreamEngine = lib
lib.root = (...)
require((...) .. "/functions")
require((...) .. "/shader")
require((...) .. "/loader")
require((...) .. "/materials")
require((...) .. "/resources")
require((...) .. "/render")
require((...) .. "/renderLight")
require((...) .. "/renderSky")
require((...) .. "/jobs")
require((...) .. "/particlesystem")
require((...) .. "/particles")

--loader
lib.loader = { }
for d,s in pairs(love.filesystem.getDirectoryItems((...) .. "/loader")) do
	lib.loader[s:sub(1, #s-4)] = require((...) .. "/loader/" .. s:sub(1, #s-4))
end

--supported canvas formats
lib.canvasFormats = love.graphics and love.graphics.getCanvasFormats() or { }

--default material library
lib.materialLibrary = { }

lib.sun_offset = 0.25
lib.sun = vec3(-0.3, 0.6, 0.5)
lib.sun_color = vec3(0.63529411764706, 0.69411764705882, 0.71764705882353)
lib.sun_ambient = vec3(1.0, 1.0, 1.0)
lib.sun_shadow = true

lib.fog_enabled = false
lib.fog_distance = 20.0
lib.fog_density = 0.75
lib.fog_color = {0.5, 0.5, 0.5}

lib.AO_enabled = true
lib.AO_quality = 16
lib.AO_resolution = 0.75

lib.bloom_enabled = true
lib.bloom_size = 1.5
lib.bloom_resolution = 0.5
lib.bloom_strength = 1.0

--currently unavailable
lib.SSR_enabled = false
lib.SSR_resolution = 1.0
lib.SSR_format = "normal"

lib.refraction_enabled = true
lib.refraction_disableCulling = false

lib.textures_fastLoading = true
lib.textures_fastLoadingProgress = false
lib.textures_mipmaps = true
lib.textures_filter = "linear"
lib.textures_generateThumbnails = true

lib.colorFormat = "rgba16f"
lib.msaa = 4
lib.fxaa = false
lib.alphaBlendMode = "alpha"
lib.max_lights = 16
lib.nameDecoder = "blender"
lib.frustumCheck = true
lib.LoDDistance = 100

lib.shadow_resolution = 1024
lib.shadow_cube_resolution = 512
lib.shadow_distance = 8
lib.shadow_factor = 4
lib.shadow_smooth = true

lib.reflections_resolution = 512
lib.reflections_format = "rgba16f"
lib.reflections_alphaBlendMode = "dither"
lib.reflections_msaa = 4
lib.reflections_levels = 5
lib.reflection_downsample = 2

lib.gamma = 1.0
lib.exposure = 1.0

lib.autoExposure_enabled = false
lib.autoExposure_resolution = 128
lib.autoExposure_targetBrightness = 0.25
lib.autoExposure_interval = 1 / 15
lib.autoExposure_adaptionSpeed = 0.4

lib.sky_as_reflection = true
lib.sky_refreshRate = 1/15
lib.sky_refreshRateTexture = 0
lib.sky_cube = false
lib.sky_hdri = false
lib.sky_hdri_exposure = 1.0
lib.sky_resolution = 512
lib.sky_format = "rgba16f"
lib.sky_time = 0.3
lib.sky_day = 0.0
lib.sky_color = vec3(1.0, 1.0, 1.0)

lib.stars_enabled = true
lib.sunMoon_enabled = true

lib.clouds_enabled = true
lib.clouds_scale = 4.0
lib.clouds_threshold = 0.5
lib.clouds_thresholdPackets = 0.3
lib.clouds_sharpness = 0.15
lib.clouds_detail = 0.0
lib.clouds_packets = 0.25
lib.clouds_weight = 1.25
lib.clouds_thickness = 0.2

lib.weather_rain = 0.0
lib.weather_temperature = 0.0

--default camera
lib.cam = lib:newCam()

lib.delton = require((...) .. "/libs/delton"):new(512)

if not _DEBUGMODE then
	lib.delton.start = function() end
	lib.delton.stop = lib.delton.start
	lib.delton.step = lib.delton.start
end

--default textures
if love.graphics then
	lib.object_sky = lib:loadObject(lib.root .. "/objects/sky", {meshType = "textured", shaderType = "Phong"})
	lib.object_cube = lib:loadObject(lib.root .. "/objects/cube", {meshType = "simple", shaderType = "simple"})
	lib.object_plane = lib:loadObject(lib.root .. "/objects/plane", {meshType = "textured", shaderType = "Phong"})
	
	local pix = love.image.newImageData(2, 2)
	lib.textures = {
		default = love.graphics.newImage(lib.root .. "/res/default.png"),
		default_normal = love.graphics.newImage(lib.root .. "/res/default_normal.png"),
		
		brdfLUT = lib.root .. "/res/brdfLut.png",
		
		sky_fallback = love.graphics.newCubeImage({pix, pix, pix, pix, pix, pix}),
		
		sky = lib.root .. "/res/sky.png",
		stars_hdri = lib.root .. "/res/stars_hdri.png",
		moon = lib.root .. "/res/moon.png",
		moon_normal = lib.root .. "/res/moon_normal.png",
		sun = lib.root .. "/res/sun.png",
		
		clouds_rough = love.graphics.newImage(lib.root .. "/res/clouds/rough.png", {mipmaps = true}),
		clouds_packets = love.graphics.newImage(lib.root .. "/res/clouds/packets.png", {mipmaps = true}),
	}
	
	lib.textures.get = function(self, path)
		if type(self[path]) == "string" then
			self[path] = love.graphics.newImage(self[path])
		end
		return self[path]
	end
	
	--get color of sun based on sunrise sky texture
	lib.sunlight = require(lib.root .. "/res/sunlight")
end

--a canvas set is used to render a scene to
function lib.newCanvasSet(self, w, h, msaa, alphaBlendMode, postEffects_enabled)
	local set = { }
	
	set.width = w
	set.height = h
	set.msaa = msaa
	set.alphaBlendMode = alphaBlendMode
	set.postEffects_enabled = postEffects_enabled
	
	--depth
	set.depth_buffer = love.graphics.newCanvas(w, h, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = false, msaa = msaa})
	
	--temporary HDR color
	set.color = love.graphics.newCanvas(w, h, {format = self.colorFormat, readable = true, msaa = msaa})
	
	--depth
	set.depth = love.graphics.newCanvas(w, h, {format = "r16f", readable = true, msaa = msaa})
	
	--layer count and seperate color canvas for average alpha blending
	if alphaBlendMode == "average" then
		set.color_pass2 = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})       --r, g, b
		set.data_pass2 = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})        --steps, alpha, ior
		if self.refraction_enabled then
			set.normal_pass2 = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})  --xyz normal
		end
	end
	
	--screen space ambient occlusion blurring canvases
	if self.AO_enabled then
		set.AO_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		set.AO_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
	end
	
	--post effects
	if postEffects_enabled then
		--bloom blurring canvases
		if self.bloom_enabled then
			set.canvas_bloom_1 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = self.colorFormat, readable = true, msaa = 0})
			set.canvas_bloom_2 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = self.colorFormat, readable = true, msaa = 0})
		end
	end
	
	--screen space reflections
	if self.SSR_enabled then
		set.canvas_SSR_1 = love.graphics.newCanvas(w*self.SSR_resolution, h*self.SSR_resolution, {format = self.SSR_format, readable = true, msaa = 0})
		set.canvas_SSR_2 = love.graphics.newCanvas(w*self.SSR_resolution, h*self.SSR_resolution, {format = self.SSR_format, readable = true, msaa = 0})
	end
	
	return set
end

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
	self.canvases = self:newCanvasSet(w, h, self.msaa, self.alphaBlendMode, true)
	self.canvases_reflections = self:newCanvasSet(self.reflections_resolution, self.reflections_resolution, self.reflections_msaa, self.reflections_alphaBlendMode, false)
	
	--auto exposure scaling canvas
	if self.autoExposure_enabled then
		self.canvas_exposure = love.graphics.newCanvas(self.autoExposure_resolution, self.autoExposure_resolution, {format = "r16f", readable = true, msaa = 0, mipmaps = "auto"})
		self.canvas_exposure_fetch = love.graphics.newCanvas(1, 1, {format = "r16f", readable = true, msaa = 0, mipmaps = "none"})
		
		self.canvas_exposure:setFilter("linear")
		self.canvas_exposure:setMipmapFilter("linear")
		
		love.graphics.setCanvas(self.canvas_exposure_fetch)
		love.graphics.clear(1, 1, 1)
		love.graphics.setCanvas()
	end
	
	--sky box
	if self.sky_as_reflection then
		self.defaultReflection = love.graphics.newCanvas(self.sky_resolution, self.sky_resolution, {format = self.sky_format, readable = true, msaa = 0, type = "cube", mipmaps = "manual"})
	end
	
	self.lastSkyTexID = nil
	
	self:loadShader()
end

--applies settings and load canvases
function lib.init(self, w, h)
	assert(not self.SSR_enabled, "screen space reflections are currently unavailable and have to be disabled!")
	
	self:resize(w or love.graphics.getWidth(), h or love.graphics.getHeight())
	
	--reset shader
	self:loadShader()
	
	--reset lighting
	self.lighting = { }
	
	--create sun shadow if requested
	self.sunObject = lib:newLight(1, 1, 1, 1, 1, 1, 5, "sun")
	if self.sun_shadow then
		self.sunObject.shadow = lib:newShadow("sun")
	else
		self.sunObject.shadow = nil
	end
end

--clears the current scene
function lib.prepare(self)
	--clear draw table
	self.drawTable = { }
	self.particles = { }
	self.particlePresence = { }
	self.reflections_last = self.reflections or { }
	self.reflections = { }
	self.allActiveShaderModules = { }
end

--add an object to the scene
local identityMatrix = mat4:getIdentity()
function lib:draw(obj, x, y, z, sx, sy, sz)
	self.delton:start("draw")
	
	self.delton:start("transform")
	local transform
	if x then
		--simple transform with arguments, ignores object transformation matrix
		transform = mat4(
			sx or 1, 0, 0, x,
			0, sy or sx or 1, 0, y,
			0, 0, sz or sx or 1, z,
			0, 0, 0, 1
		)
		
		--also applies objects own transformation
		if obj.transform then
			transform = transform * obj.transform
		end
	else
		--pre defined transform
		transform = obj.transform or identityMatrix
	end
	self.delton:stop()
	
	local col = vec4(love.graphics.getColor())
	
	--add to scene
	self.delton:start("add")
	for d,s in pairs(obj.objects or {obj}) do
		if s.mesh and not s.disabled then
			--get required shader
			s.shader = self:getShaderInfo(s, obj)
			
			local pos
			local bb = s.boundingBox
			if bb then
				--mat4 * vec3 multiplication, for performance reasons hardcoded
				local a = bb.center
				pos = vec3(transform[1] * a[1] + transform[2] * a[2] + transform[3] * a[3] + transform[4],
					transform[5] * a[1] + transform[6] * a[2] + transform[7] * a[3] + transform[8],
					transform[9] * a[1] + transform[10] * a[2] + transform[11] * a[3] + transform[12])
			else
				pos = vec3(transform[4], transform[8], transform[12])
			end
			
			--add
			table.insert(lib.drawTable, {
				transform = transform, --transformation matrix, can be nil
				pos = pos,             --bounding box center position of object
				s = s,                 --drawable object
				color = col,           --color, will affect color/albedo input
				obj = obj,             --the object container used to store general informations (reflections, ...)
			})
		end
	end
	self.delton:stop()
	self.delton:stop()
end

function lib:drawParticleBatch(batch)
	--register as to-draw
	self.particles[batch] = true
	
	--enable particle rendering
	self.particlePresence[batch.pass] = true
end

return lib