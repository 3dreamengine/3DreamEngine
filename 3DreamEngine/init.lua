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

function math.mix(a, b, f)
	return a * (1.0 - f) + b * f 
end

function math.clamp(v, a, b)
	return math.max(math.min(v, b or 1.0), a or 0.0)
end

mat2 = require((...) .. "/libs/luaMatrices/mat2")
mat3 = require((...) .. "/libs/luaMatrices/mat3")
mat4 = require((...) .. "/libs/luaMatrices/mat4")

vec2 = require((...) .. "/libs/luaVectors/vec2")
vec3 = require((...) .. "/libs/luaVectors/vec3")
vec4 = require((...) .. "/libs/luaVectors/vec4")

mimg = require((...) .. "/libs/mimg")
lib.ffi = require("ffi")

_3DreamEngine = lib
lib.root = (...)
require((...) .. "/functions")
require((...) .. "/shader")
require((...) .. "/loader")
require((...) .. "/render")
require((...) .. "/jobs")
require((...) .. "/particlesystem")
require((...) .. "/libs/saveTable")
_3DreamEngine = nil

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
lib.fog_baseline = 0.0
lib.fog_height = 5.0
lib.fog_density = 0.05
lib.fog_color = {0.5, 0.5, 0.5}

lib.AO_enabled = true
lib.AO_quality = 16
lib.AO_resolution = 0.75

lib.bloom_enabled = true
lib.bloom_size = 1.5
lib.bloom_resolution = 0.5
lib.bloom_strength = 1.0

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

lib.msaa = 4
lib.fxaa = false
lib.deferred_lighting = false
lib.lighting_engine = "PBR"
lib.secondPass = true
lib.renderToFinalCanvas = false
lib.max_lights = 16
lib.nameDecoder = "blender"

lib.shadow_resolution = 1024
lib.shadow_cube_resolution = 512
lib.shadow_distance = 8
lib.shadow_factor = 4
lib.shadow_smooth = true
lib.shadow_smoother = true
lib.shadow_smooth_downScale = 0.5
lib.shadow_quality = "low"

lib.reflections_resolution = 512
lib.reflections_format = "rgba16f"
lib.reflections_deferred_lighting = false
lib.reflections_secondPass = true
lib.reflections_msaa = 4
lib.reflections_levels = 5
lib.reflection_downsample = 2

lib.gamma = 1.0
lib.exposure = 1.0

lib.rain_enabled = true
lib.rain_resolution = 512
lib.rain_isRaining = false
lib.rain_strength = 3
lib.rain_adaptRain = 0.1
lib.rain_wetness_increase = 0.02
lib.rain_wetness_decrease = 0.01
lib.rain_rain = 0.0
lib.rain_wetness = 0.0

lib.autoExposure_enabled = false
lib.autoExposure_resolution = 128
lib.autoExposureTargetBrightness = 0.333
lib.autoExposureAdaptionFactor = 1.0
lib.autoExposure_interval = 1 / 15
lib.autoExposure_adaptionSpeed = 0.1

lib.sky_enabled = true
lib.sky_hdri = false
lib.sky_hdri_exposure = 1.0
lib.sky_resolution = 1024
lib.sky_format = "rgba16f"
lib.sky_time = 0.3
lib.sky_day = 0.0
lib.sky_color = vec3(1.0, 1.0, 1.0)
lib.sky_ambient = 0.5

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

--default textures
if love.graphics then
	lib.object_sky = lib:loadObject(lib.root .. "/objects/sky", {meshType = "textured"})
	lib.object_cube = lib:loadObject(lib.root .. "/objects/cube", {meshType = "color"})
	lib.object_warning = lib:loadObject(lib.root .. "/objects/warning", {meshType = "color_extended"})
	lib.object_plane = lib:loadObject(lib.root .. "/objects/plane", {meshType = "textured"})
	lib.object_rain = lib:loadObject(lib.root .. "/objects/rain", {meshType = "textured"})
	
	lib.textures = {
		default = love.graphics.newImage(lib.root .. "/res/default.png"),
		default_normal = love.graphics.newImage(lib.root .. "/res/default_normal.png"),
		
		brdfLUT = love.graphics.newImage(lib.root .. "/res/brdfLut.png"),
		
		rain_1 = love.graphics.newImage(lib.root .. "/res/rain_1.png"),
		rain_2 = love.graphics.newImage(lib.root .. "/res/rain_2.png"),
		rain_3 = love.graphics.newImage(lib.root .. "/res/rain_3.png"),
		rain_4 = love.graphics.newImage(lib.root .. "/res/rain_4.png"),
		rain_5 = love.graphics.newImage(lib.root .. "/res/rain_5.png"),
		
		splash = love.graphics.newImage(lib.root .. "/res/splash.png"),
		wetness = love.graphics.newImage(lib.root .. "/res/wetness.png"),
		
		sky = love.graphics.newImage(lib.root .. "/res/sky.png"),
		stars_hdri = lib.root .. "/res/stars_hdri.png",
		moon = lib.root .. "/res/moon.png",
		moon_normal = lib.root .. "/res/moon_normal.png",
		sun = lib.root .. "/res/sun.png",
		
		clouds_rough = love.graphics.newImage(lib.root .. "/res/clouds/rough.png", {mipmaps = true}),
		clouds_packets = love.graphics.newImage(lib.root .. "/res/clouds/packets.png", {mipmaps = true}),
	}
	
	--get color of sun based on sunrise sky texture
	lib.sunlight = require(lib.root .. "/res/sunlight")
	
--	local img = love.image.newImageData(lib.root .. "/res/sky_color.png")
--	for x = 1, img:getWidth() do
--		local r, g, b = img:getPixel(x-1, 0)
--		print("	vec3(" .. r .. ", " .. g .. ", " .. b .. "),")
--	end
	
	if love.graphics.getTextureTypes()["array"] then
		lib.textures_array = {
			default = love.graphics.newArrayImage({lib.root .. "/res/default.png"}),
			default_normal = love.graphics.newArrayImage({lib.root .. "/res/default_normal.png"}),
		}
	end
end

--a canvas set is used to render a scene to
function lib.newCanvasSet(self, w, h, msaa, deferred_lighting, secondPass, postEffects_enabled)
	local set = { }
	
	set.width = w
	set.height = h
	set.msaa = msaa
	set.deferred_lighting = deferred_lighting
	set.secondPass = secondPass
	set.postEffects_enabled = postEffects_enabled
	
	--temporary HDR color
	set.color = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})
	
	--normal
	if deferred_lighting or secondPass then
		set.normal = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa}) -- normal + depth
	end
	
	--layer count and seperate color canvas for second pass
	if secondPass then
		set.color_pass2 = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})
		set.data_pass2 = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})
		if self.refraction_enabled then
			set.normal_pass2 = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})
		end
	end
	
	--depth
	set.depth = love.graphics.newCanvas(w, h, {format = "r16f", readable = true, msaa = msaa})
	
	--depth
	set.depth_buffer = love.graphics.newCanvas(w, h, {format = self.canvasFormats["depth32f"] and "depth32f" or self.canvasFormats["depth24"] and "depth24" or "depth16", readable = false, msaa = msaa})
	
	--data, albedo and position only for deferred lighting
	if deferred_lighting then
		set.albedo = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})    -- albedo color
		set.position = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})  -- xyz position
		set.material = love.graphics.newCanvas(w, h, {format = "rgba16f", readable = true, msaa = msaa})  -- roughness, metallic, depth
	end
	
	--screen space ambient occlusion blurring canvases
	if self.AO_enabled then
		set.AO_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		set.AO_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
	end
	
	--rain
	if self.rain_enabled then
		self.canvas_rain = love.graphics.newCanvas(self.rain_resolution, self.rain_resolution, {format = "rgba16f"})
		self.canvas_rain:setWrap("repeat")
		
		love.graphics.setCanvas(self.canvas_rain)
		love.graphics.clear(0.0, 0.0, 1.0)
		love.graphics.setCanvas()
	end
	
	--final
	if postEffects_enabled and (self.renderToFinalCanvas or self.autoExposure_enabled) then
		set.final = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = 0})
	end
	
	return set
end

--load canvases
function lib.resize(self, w, h)
	--canvases sets
	self.canvases = self:newCanvasSet(w, h, self.msaa, self.deferred_lighting, self.secondPass, true)
	self.canvases_reflections = self:newCanvasSet(self.reflections_resolution, self.reflections_resolution, self.reflections_msaa, self.reflections_deferred_lighting, self.reflections_secondPass)
	
	--bloom blurring canvases
	if self.bloom_enabled then
		self.canvas_bloom_1 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = "rgba16f", readable = true, msaa = 0})
		self.canvas_bloom_2 = love.graphics.newCanvas(w*self.bloom_resolution, h*self.bloom_resolution, {format = "rgba16f", readable = true, msaa = 0})
	end
	
	--screen space reflections
	if self.SSR_enabled then
		self.canvas_SSR_1 = love.graphics.newCanvas(w*self.SSR_resolution, h*self.SSR_resolution, {format = self.SSR_format, readable = true, msaa = 0})
		self.canvas_SSR_2 = love.graphics.newCanvas(w*self.SSR_resolution, h*self.SSR_resolution, {format = self.SSR_format, readable = true, msaa = 0})
	end
	
	--auto exposure scaling canvas
	if self.autoExposure_enabled then
		self.canvas_exposure = love.graphics.newCanvas(self.autoExposure_resolution, self.autoExposure_resolution, {format = "rgba16f", readable = true, msaa = 0, mipmaps = "auto"})
		self.canvas_exposure_fetch = love.graphics.newCanvas(1, 1, {format = "r16f", readable = true, msaa = 0, mipmaps = "none"})
		
		self.canvas_exposure:setFilter("linear")
		self.canvas_exposure:setMipmapFilter("linear")
		
		love.graphics.setCanvas(self.canvas_exposure_fetch)
		love.graphics.clear(1, 1, 1)
		love.graphics.setCanvas()
	end
	
	--sky box
	if self.sky_enabled then
		self.canvas_sky = love.graphics.newCanvas(self.sky_resolution, self.sky_resolution, {format = self.sky_format, readable = true, msaa = 0, type = "cube", mipmaps = "manual"})
	end
	
	self:loadShader()
end

--applies settings and load canvases
function lib.init(self)
	if self.SSR_enabled and not self.deferred_lighting then
		self.SSR_enabled = false
		print("SSR can only be used with deferred lighting! SSR has been disabled.")
	end
	
	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
	
	--reset shader
	self:loadShader()
	
	--reset lighting
	self.lighting = { }
	
	--create sun shadow if requested
	self.sunObject = lib:newLight(1, 1, 1, 1, 1, 1, 5, 0)
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
	self.particleCounter = 0
end

--add an object to the scene
function lib.draw(self, obj, x, y, z, sx, sy, sz)
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
		transform = obj.transform
	end
	
	--add to scene
	for d,s in pairs(obj.objects or {obj}) do
		if not s.disabled and s.mesh then
			--get required shader
			s.shader = s.shader or self:getShaderInfo(s.material, s.shaderType, obj)
			
			--add
			table.insert(lib.drawTable, {
				transform = transform,                  --transformation matrix, can be nil
				pos = transform * vec3(0, 0, 0),        --bounding box center position of object
				s = s,                                  --drawable object
				color = vec4(love.graphics.getColor()), --color, will affect color/albedo input
				obj = obj,                              --the object container used to store general informations (reflections, ...)
			})
		end
	end
end

--add a particle to the scene
function lib.drawParticle(self, tex, quad, x, y, z, size, rot, emission, emissionTexture)
	if type(quads) == "number" then
		return self:drawParticle(tex, false, x, y, z, size, rot)
	end
	
	self.particleCounter = self.particleCounter + 1
	self.particles[self.particleCounter] = {tex, quad, x, y, z, (size or 1.0), rot or 0.0, emission or 0.0, emissionTexture}
end

return lib