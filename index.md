# content

* **[settings](#settings)** (global settings)
* **[functions](#functions)** (main functions)
* **[utils](#utils)** (helpful utils)
* **[scene](#scene)** (scenes)
* **[object](#object)** (main container)
* **[subObjects](#subObjects)** (renderable object)
* **[visibility](#visibility)** (LODs and render pass visibility)
* **[shader](#shader)**
* **[materials](#materials)**
* **[camera](#camera)**
* **[lights](#lights)**
* **[shadows](#shadows)**
* **[reflections](#reflections)**
* **[setSettings](#setSettings)** (graphics settings)  
* **[collisions](#collisions)**


# settings
Most settings require `dream:init()` to be called afterwards.


## Default shader
Sets the default shader, false to choose between textured Phong and simple Phong.

```lua
dream:setDefaultShaderType(typ)
typ = dream:getDefaultShaderType()
```
`typ (false)` valid shader type or false  


## Deferred shader
Deferred shading, unlike forward, can only have one lighting function at the same time.

```lua
dream:setDeferredShaderType(typ)
typ = dream:getDeferredShaderType()
```
`typ (false)` valid shader type to take light function from or false  


## Max Lights
The maximal number per light typ. This is just a hardlimit.

```lua
dream:setMaxLights(limit)
limit = dream:getMaxLights()
```
`limit (16)` number  


## Name Decoder
Some exporter add some pre and postfixes, with this regex string you can fix the names. False to disable.

```lua
dream:setNameDecoder(decoder)
decoder = dream:setNameDecoder()
```
`decoder ("^(.+)_([^_]+)$")` regex string  


## Frustum
To improve performance you can enable frustum checks to only render visible objects.

```lua
dream:setFrustumCheck(enabled)
enabled = dream:getFrustumCheck()
```
`enabled (true)`


## LOD Distance
The distance at which the highest LOD level will be used

```lua
dream:setLODDistance(distance)
distance = dream:getLODDistance()
```
`distance (100)` distance in meter  


## Dither
Depth testing and dither do not like each other. You can choose between dithering or fixed 0.5 threshold.

```lua
dream:setDither(enabled)
enabled = dream:setDither()
```
`enabled (true)`  


## Exposure
Sets the exposure for HDR, making it possible to represent colors over 1. 1.0 is default. False disables it.
```lua
dream:setExposure(enabled)
enabled = dream:getExposure(enabled)
```


## Auto Exposure
Sets the target average screen brightness for automatic adaption. Disabled by default.  

```lua
dream:setAutoExposure(enabled)
dream:setAutoExposure(target, speed, skip)
enabled, target, speed, skip = dream:getAutoExposure(target, speed, skip)
```
`target` 0.25 is default.  
`speed` is the adaption speed, 1.0 is default.  
`skip` is the amount of frames skipped for the job engine, higher values results in better performance but possible stutter. Default is 4.  
A single bool can either disabled or enable with default values.


## Gamma
Gamma correction is already applied, therefore default is 1.0. Disabled by default.

```lua
dream:setGamma(gamma)
gamma = dream:getGamma()
```
`gamma` can be a number or false.  


## Screen Space Ambient Occlusion
To simulate shadows between close surfaces a lightweight screen space occlusion methode can be used. Enabled by default.

```lua
dream:setAO(samples, resolution, blur)
enabled, samples, resolution, blur = dream:getAO()
```
`samples (32)` Higher samples increase quality.  
`resolution (0.75)` Subsampling factor.  
`blur` (false) Additional two-pass Gaussian blur.  


## Bloom
To simulate bright surfaces bloom can be applied. Enabled by default.

```lua
dream:setBloom(quality)
dream:setBloom(quality, resolution, size, strength)
enabled, quality, resolution, size, strength = dream:getBloom()
```
`quality (-1)` Blurring steps. Depends on resolution, subsampling and bloom spread. Low values cause grid effects, high values are useless. -1 tries to detect the quality automatically (~2 on 1080p, ~3 on 4k)  
`resolution (0.5)` Subsampling factor. Since subsampling is a natural blur this should be smaller than 1.0.  
`strength (1.0)` Blend strength.  
`size (10.0)` Spread size, approximately in pixels.  


## Fog
Allows the simulation of fog, smoke or visible gasses and sunlight scatter between two defined density layers.

```lua
dream:setFog(density, color, scatter)
enabled, density, color, scatter = dream:getFog()
```
`density` density  
`color` vec3 color  
`scatter` 0 or more multiplier for sun scatter  

```lua
dream:setFogHeight()
dream:setFogHeight(min, max)
min, max = dream:getFogHeight()
```
`min (1)` lower, full-fog plane height. Nil/false sets fog constant.  
`max (-1)` higher, no-fog plane height. When smaller than min, fog is constant.  


## Rainbow
Renders a rainbow on the sky dome.

```lua
dream:setRainbow(strength, size, thickness)
dream:setRainbow(strength)
strength, size, thickness = dream:getRainbow()
```
`strength` the strength, usually between 0 and 1  
`size (~42°)` angle from viewer  
`thickness (0.2)` rainbow width  

```lua
dream:setRainbowDir(dir)
dir = dream:getRainbowDir()
```
`dir` vec3 of rainbow. Physically this is always -sunVector, but can be set for artistic reasons manually.  


## Shadows
Shadows can use per light/shadow settings, else they will use default values set here.  
Higher resolution may increase quality, but usually smoothing hides lower resolutions anyways.  

```lua
dream:setShadowResolution(sun, point)
sun, point = dream:getShadowResolution()
```
`sun (1024)` sun cascade resolution (3x canvases)  
`point (512)` point source cubemap shadows  

```lua
dream:setShadowSmoothing(enabled)
enabled = dream:getShadowSmoothing()
```
`enabled (false)` slow, but fancy shadow smoothing.  

```lua
dream:setShadowCascade(distance, factor)
distance, factor = dream:getShadowCascade()
```
`distance (8)` shadow range in metres.  
`factor (4)` factor of range of next shadow map, distance * factor^2 therefore is the total range.  


```lua
dream:setSunShadow(enabled)
enabled = dream:getSunShadow()
```
`enabled (true)` If the sun light object should receive a shadow.


## Sun
Sets the position of the sun (done automatically by 'dream:setDaytime()'

```lua
dream:setSunDir(direction)
direction = dream:getSunDir()
```
`direction` vec3 direction of the sun  

```lua
dream:setSunOffset(offset)
offset = dream:getSunOffset()
```
`offset` offset where 0 is the equator and 1 the north pole when using 'dream:setDaytime()'.  


## Daytime
Automatically fetches sky and sun color, sets sun position based on offset and controls moon cycle.

```lua
dream:setDaytime(time)
time = dream:getDaytime()
```
`time` Time between 0 and 1, where 0.0 is sunrise and 0.5 sunset.  


## Weather
The weather controlls sky color, clouds and if enabled the rain module.
Those functions has to be called after `setDaytime()`.

```lua
dream:setWeather(rain)
dream:setWeather(rain, temp)
dream:setWeather(rain, temp, raining)
rain, temp, raining = dream:getWeather()
```
`rain` thicker clouds, darker sky, ...  
`temp (1.0 - rain)` temperature, mainly controls clouds  
`raining (rain > 0.5)` wether its actually raining  

An extended version which performs a smooth transition, generated mist and a rainbow after rain:
```lua
dream:updateWeather(rain, temp, dt)
```
`rain` thicker clouds, darker sky, ...  
`temp (1.0 - rain)` temperature, mainly controls clouds  
`dt` delta time, can be used to control speed of weather change


## Base Reflection
Diffuse lighting and reflections fall back to this value if not specified otherwise.

```lua
dream:setReflection(texture)
texture = dream:getReflection()
```
`texture (true)`
* true to use sky dome as base reflection
* false to use ambient color only
* reflection object
* cubemap (requires custom mipmaps as specified in the reflections chapter)

## Sky Reflection
If the base reflection is true following settings affects how the sky dome is rendered.
```lua
dream:setSkyReflectionFormat(resolution, format, skip)
resolution, format, skip = dream:getSkyReflectionFormat()
```
`resolution (512)` cubemap resolution 
`format ("rgba16f")` cubemap format, HDR by default  
`skip (4)` frame skip, see jobs chapter  


## Sky
The sky renders behind all objects and if used on the default reflection cubemap.

```lua
dream:setSky(texture)
dream:setSky(texture, exposure)
texture, exposure = dream:getSky()
```
`texture (true)`
* true to use sky dome
* false to use transparent background
* cubemap (will set `dream:setReflection(cubemap) too as this is faster and the same result`)
* HDRI image (in combination with `setReflection(true)` bad because of unnesessary HDRI to cubemap render)   


## Clouds
If the sky dome is used weather based random clouds can be rendered.

```lua
dream:setClouds(enabled)
dream:setClouds(enabled, resolution, scale)
enabled, resolution, scale = dream:getClouds()
```
`enabled (true)`  
`resolution (1024)` random cloud buffer canvas size  
`scale (2.0)` scale of clouds  

```lua
dream:setWind(x, y)
x, y = dream:getWind()
```
`x, y` cloud movement direction  

```lua
dream:setCloudsStretch(stretch, stretch_wind, angle)
stretch, stretch_wind, angle = dream:getCloudsStretch()
```
`stretch` stretch strength  
`stretch_wind` stretch strength based on wind  
`angle` angle offset  


## Resource loader
The resource loader can load textures threaded to avoid loading times or lags.

```lua
dream:setResourceLoader(threaded, thumbnails)
threaded, thumbnails = dream:getResourceLoader()
```
`threaded (true)` use several cores to load images in the background  
`thumbnails (true)` generate thumbnails, which will be loaded first next time to deliver results faster  

large images cause a lag when pushing to the GPU, by using 3Dreams smooth loader this can be avoided.
However images will then be canvases instead, which should not make a different.

```lua
dream:setSmoothLoading()
dream:setSmoothLoading(time)
time = dream:getSmoothLoading()
```
`time (1 / 1000)` how many seconds per cycle

```lua
dream:setSmoothLoadingBufferSize(size)
size = dream:getSmoothLoadingBufferSize()
```
`size (128)` chunk size, the bigger the better, but increase time required and therefore may cause lags.


```lua
dream:setMipmaps(enabled)
enabled = dream:getMipmaps()
```
`enabled` if the loader should generate mipmaps  


# functions
```lua
--inits (applies settings, reload canvases, ...)
dream:init()

--loads an object
yourObject = dream:loadObject("objectName", shaderType, args)
	
	--where shaderType determines the base shader required, e.g. PBR, Phong or simple. Leave blank to 

	--where args is a table with additional settings
	textures             -- location for textures, use "dir/" to specify diretcory, "file" to specify "file_albedo", "file_roughness", ...
	splitMaterials       -- if a single mesh has different textured materials, it has to be split into single meshes. splitMaterials does this automatically.
	grid                 -- grid moves all vertices in a way that 0, 0, 0 is the floored origin with an maximal overhang of 0.25 units.
	noMesh               -- load vertex information but do not create a final mesh - template objects etc
	noParticleSystem     -- prevent the particle system from being generated
	cleanup              -- the level of cleanup after the objects have been loaded. false deloads nothing. nil (default) deloads all buffers except faces and vertex positions. true deloads everything.
	export3do            -- loads the object as usual, then export the entire object inclusive animations, collisions, positions and similar as a 3DO file. See 3DO chapter for use cases
	export3doVertices    -- vertices are not included by default, since they are bulky and unecessary unless converting an object to a collision. While not recommended, you can force vertices and edge data to be included.
	centerMass           -- normalize the center of mass (vertice mass) to its origin
	mergeObjects         -- merge all object into one
	animations           -- when using COLLADA format, split the animation into {key = {from, to}}, where from and to are timestamps in seconds

--if the name of an subObject contains:
-- ... "POS_" it puts it into the positions table for manual use and skips loading. Positions contain the position (x, y, z), its averge radius from its origin as size and the name
-- ... "COLLISION_" it loads it as a collision and puts it into the collisions table. If used as a collider it only uses those instead.

--required for loading textures, 3do files, ...
dream:update()

--update time and weather
dream:setDaytime(time)
dream:setWeather(rain, temp)

--prepare for rendering
--if cam is nil, it uses the default cam (dream.cam)
dream:prepare(cam)

--draw
--obj can be either the entire object, or an object inside the file (yourOject.objects.yourSubObject)
dream:draw(obj, x, y, z, sx, sy, sz)

--finish render session, it is possible to render several times per frame but then use presentLite() since present() also renders sub tasks
--noSky disables the sky
--cam specifies its own camera
--canvases its own canvas set, default is dream.canvases
dream:present(noSky, cam, canvases)
dream:presentLite(noSky, cam, canvases)
```

### transform functions
Supports Objects and Cameras
```lua
--transform the object
object:reset()
object:translate(x, y, z)
object:scale(x, y, z)
object:rotateX(angle)
object:rotateY(angle)
object:rotateZ(angle)
object:setDirection(normal, [up]) --rotate the object to face into the given direction, up is default vec3(0, 1, 0)
```

### camera
```lua
--default camera (with functions as defined in chapter above)
dream.cam:reset()

--if you want an own camera use
yourCam = dream:newCam()
--and pass it to dream:prepare()
```

### light
```lua
--resets light sources (if noDayLight is set to true, the sun light (dream.sunObject) will not be added)
dream:resetLight(noDayLight)

--creates a new light
--typ is the light type, "point" and "sun" is inbuild, further types can be added via the shader library
local light = dream:newLight(x, y, z, red, green, blue, brightness, typ)

--add a shadow to the light
--typ is either point or sun
--static only renders one and is therefore faster
--res can set a custom resolution
light.shadow = dream:newShadow(typ, static, res)

--change light data
light:setBrightness(b)
light:setColor(r, g, b)
light:setPosition(x, y, z)

--add light to scene, note that in case of exceeding the max light sources it only uses the most relevant sources, based on distance to camera and brightness
dream:addLight(light)

--or create a new light source and add it at once
dream:addNewLight(x, y, z, red, green, blue, brightness, typ)
```


## utils
This is a collection of helpful utils.
```lua
local m = dream:lookAt(eye, at, up)               --returns a transformation matrix at point 'eye' looking at 'at' with upwards vector 'up' (default vec3(0, 1, 0))
dream:pointToPixel(point, cam, canvases)          --converts a 3D point with given camera (default dream.cam) and canvas set (default dream.canvases) to a vec3 2D screen coord + depth
dream:pixelToPoint(point, cam, canvases)          --converts a 2D screen coord + depth to a 3D point

local r, g, b = dream:HSVtoRGB(h, s, v)           --converts hsv to rgb
local h, s, v = dream:RGBtoHSV(r, g, b)           --converts rgb to hsv

dream:inFrustum(cam, pos, radius)                 --checks if the position with given radius is visible with the current (projection matrix) camera
dream:getCollisionData(object)                    --returns a raw collision object used in the collision extensions newMesh function from an subObject

dream:take3DScreenshot(pos, resolution, path)     --takes a rgba16f screenshot and saves it using the (custom) CIMG lib. Can be used to capture a static reflection cubemap. Performs blurring automatically. See Tavern demo for usage example.
```

There are a few libraries included you can use. Check their files for supported functions
* vec2, vec3, vec4 with common functions and metatables
* mat2, mat3, mat4
* quaternions
* a XML parser
* utils.lua which expands luas table, string and math libraries by common functions


## sky
The sky will be rendered when the `noSky` arg in dream:present() is not true and contains a sky color, sun, moon, stars and clouds.
`dream:setWeather(rain, temperature)` and `dream:setDaytime(time)` are helper functions to control those.
The sky dome is WIP and will receive further upgrades.

### hdri
Alternatively you can use a sphere hdri image.
Set `dream.sky_hdri` to an Drawable. Optionally set `dream.sky_hdri_exposure` to adjust exposure.

### cubemap
Or you can use a cubemap.
Set `dream.sky_cube` to an CubeImage.


## particle batches
Particles are batched and rendered all together.
```lua
--create a particle batch
--pass a texture and the alphaPass. alphaPass true uses z-sorting and is slower.
local particleBatch = dream:newParticleBatch(texture, alphaPass)

--set additional settings
particleBatch.vertical = true  --vertical does only rotate the particle on the Y-axis, used for flames, ...
particleBatch.sort = false     --sorting is required for transparent particles with a pattern. For example dust with only one color does not require it. Pass 1 does not require it at all.

--clear batch
particleBatch:clear()

--add particles
particleBatch:add(x, y, z, size, emission, quad)

--queue for drawing
dream:drawParticleBatch(particleBatch)
```


## materials
Materials can be either per model by providing a .mtl or .mat file with the same name as the object file or they can be in a global material library.
```lua
--load materials into the library, if a object now requires a material, and it is not defined in a local material file, it will take the global one
dream:loadMaterialLibrary("path")
```
A material library looks for material files (.mat) or for directory containing material.mat or at least one texture, linking them automatically.

For the internal format see chapter .mat.


### transparent materials
With alpha, you have to tell the engine how the material has to be rendered. Set the `alpha` tag accordingly:
```lua
mat.alpha = true  -- this material needs Z-sorting and alpha blending, optionally causes refractions and transmission colors if using deferred rendering
mat.alpha = false -- this material is solid, alpha will be dithered
```


## level of detail
To define the level of detail, add a boolean array with size 9 to the object or subobject, index 1 is nearest. False prevents this object from rendering.
```
--set reference distance (max render distance if 9th index is false)
dream.LoDDistance = 100

--set objects LoD
yourObject.LoD = {true, true, true, false, false, false, false, false, false} --allow rendering 1/3 of the max LoD distance

--overwrite the LoD of one sub object
yourObject.objects.subObject.LoD = {true, true, true, true, true, true, false, false, false} --allow rendering 2/3 of the max LoD distance
```
Support for custom LoD maps for reflections and shadows are WIP.


## textures
To add textures to the model ...
* name the textures albedo, normal, roughness, metallic, glossiness, specular, emission and put it next to the material (for material library entries) or suffix them with either the material name "material_" or the object name "object_"
* set the texture path in the mtl file, if exported by another software it should work fine
* set the texture in the mat file (tex_diffuse, tex_normal, tex_emission, ...)
* by default 3Dream looks for textures relative to the object path, if not overwritten by the `textures` arg in the model loader
* it does automatically choose the best format and load it threaded when needed. Setting a texture manually prevents this.

* The diffuse texture is a RGB non alpha texture with the color. Alpha channel needs material `alpha` tag set accordingly and a valid alpha blend mode.
* The normal texture contains tangential normal coordinates.
* The emission texture contains RGB color, in contrast to all other textures it will be multiplied by material.emission (RGB color) instead of using it as fallback. Use this as a multiplier if required.
* Roughness, metallic or specular and glossiness as well as ambient occlusion are single channel textures, however the engine works with combined RMA textures for performance reasons. If not present, 3Dream will generate them and caches them in the love save directory. It is recommended to use them in the final build to avoid heavy (but at least threaded) CPU merge operations, or provide RMA textures in the first place.
* DDS files are supported, but can not generate mipmaps automatically. Also love2ds DDS loader seems to hate some mipmaps.


### thumbnails
Name a (smaller) file "yourImage_thumb.ext" to let the texture loader automatically load it first, then load the full textures at the end.

If the automatic thumbnail generator is enabled (true by default), this will be done automatically, but the first load will be without thumbnail.


## mat - 3Dream material file (lua syntax)
The .mtl file usually exported with .obj will be loaded automatically.
To use more 3DreamEngine specific features (particle system, wind animation ...) a .mat file is required. A .mat file can replace the .mtl file entirely, else it will extend it.

### example mat file:
```lua 
--3DreamEngine material properties file
return {
	{
		name = "grass",      --extend material Grass
		
		alpha = false,       --the alpha pass required as explained in alpah blending chapter
		cullMode = "back",   --the cullmode to render the mesh with
		shadow = nil,        --false would disable this object in the shadow pass
		
		--Shared for all shading
		color = {1.0, 1.0, 1.0, 1.0},  -- color
		emission = {1.0, 1.0, 1.0},    -- emission color, or the multiplier if a texture is present
		
		--Phong
		specular = 0.5,                -- specular component (note that specular component has the same color as the albedo texture / color)
		glossiness = 0.1,              -- exponent, 0-1 (where 1 represent around exponent 1000)
		
		--PBR
		roughness = 0.5,               -- roughness if no texture is set
		metallic = 0.5,                -- metallic if no texture is set
		
		extra = 1.0,                   -- the value in the shader extra slot, primary used for animations, e.g. in the wind shader. Particle system generate them automatically.
		
		--textures (loaded automatically and should, but dont have to, be strings)
		--Textured Phong
		tex_albedo = "path/name",
		tex_normal = "path/name",
		tex_specular = "path/name",
		tex_glossiness = "path/name",
		tex_emission = "path/name",
		tex_ao = "path/name",
		tex_combined = "path/name", --replaced glossiness, specular and ao
		
		--PBR
		tex_albedo = "path/name",
		tex_normal = "path/name",
		tex_roughness = "path/name",
		tex_metallic = "path/name",
		tex_emission = "path/name",
		tex_ao = "path/name",
		tex_combined = "path/name", --replaced roughness, metallic and ao
		
		--a callback once the material has been fully finished
		--obj is nil in case on an public material
		--this callback is commonly used to apply shader modules or change values based on dynamic data
		onFinish = function(mat, obj)
			
		end,
		
		--add particleSystems
		particleSystems = {
			{ --first system
				objects = { --add objects, pathes have to be global, objects are merged and therefore has to share a material. If not, use two particle systems instead.
					["path/grass"] = 20,
				},
				randomSize = {0.75, 1.25},    --randomize the particle size
				randomRotation = true,        --randomize the rotation
				normal = 0.9,                 --align to 90% with its emitters surface normal
				
				shader = "wind",              --instruction on how to set the extra buffer, currently only wind exists, see wind module on how to use
				shaderValue = "grass",        --tell the wind shader to behave like grass, the amount of waving depends on its Y-value
				shaderValue = 0.2,            --or use a constant float
			},
		}
	},
}
```


## Reflections
Reflections are dynamic or static cubemaps, automatically updated if in use and can be assigned to one or several objects.

Dynamic Reflections are heavy resources and should be used carefully. Use static tag and set priority to achieve best performance.

```lua
--add reflections to the object
--use static if the scene does not change or the reflection should not reflect changes
--priority is used to priorisize the sub task render queue, trying to keep up with the screen refreh rate.
--pos is an alternative position, else taken from the boundary center of the object connected with. Carefull with multiple assignments.

local r = dream:newReflection(static, priority, pos) -- dynamic
local r = dream:newReflection(cubemap)               -- static cubemap

dream.defaultReflection = r     -- use as default reflection, read chapter 'default reflection'
yourObject.reflection = r       -- assign to object including subObject
yourObject.objects.yourSubObject.reflection = r -- assign to subObject only
```

### Local cubemaps
By default cubemaps are treated as infinite cubemaps, working perfect for distant objects. If all objects are on the same AABB bounding box (e.g. a room, hallway, ...) local correction can be applied.
```
local r = dream:newReflection()
r.pos = vec3()    -- center of cubemap
r.first = vec3()  -- smaller point of the AABB
r.second = vec3() -- bigger point of the AABB
```

### Planar reflections
WIP

### default reflection
If a object has no reflection assigned it falls back the default reflection cubemap or a single color (dream.sun_ambient) of not set either.

To use the sky dome set `dream.sky_as_reflection` to true.
Note that this will also use the hdri or cube map set. Match the format and resolution to the given texture to avoid loss in quality.

To set the map manually, set `dream.sky_as_reflection` to false and 'dream.defaultReflection' to a reflection object.
The cubemap should (but don't necessary have to if not using glossy reflections) mipmaps, each heavily blurred. Therefore, create the cube map with mipmaps set to `manual` and run following code to generate proper mipmaps:
```lua
for level = 2, yourCubeMap:getMipmapCount() do
	self:blurCubeMap(yourCubeMap, level)
end
```
If you change the cubemaps content, you need to recreate mipmaps too.
If the cubemap is static you can also use advanced software to create those mipmaps.


## Shaders
The shader is constructed based on its base shader, the vertex module and additional, optional shader modules.
There are basic default shaders present, so this chapter is advanced usage.

### register own shader
A more tidy docu will be written soon, for now look up the syntax in shaders/base, shaders/vertex, shaders/shading, shaders/light and shaders/modules.
For a better understanding in the final shader, look into shaders/base.glsl. This is the skeleton where the modules are imported.
```lua
--register a component to the library
dream:registerShader(pathToLuaFile)
```

### base shader
This shader does most of the work. It is responsible for fetching data, calculating reflections, emission, ...
It's chosen by the objects `shaderType` tag, provided at the object loader.
If not set, it will fall back to `dream.defaultShaderType`.
If `dream.defaultShaderType` is not set either, it will be `simple` or `Phong`, depending on wether its material has textures.
The base shader can also set its own light function (the actual thing calculating the effect of light sources), if not, it uses Phong shading.

### shader modules
Those modules can extend the shader to add certain effects. For example a rain effect as the one implemeted, or a burning animation, or a disolving effect, ...
```lua
--activate/deactive a module to all objects
dream:activateShaderModule(name)
dream:deactivateShaderModule(name)

--get the shader module, for example to change its settings
dream:getShaderModule(name)

--check if this module is globally active
dream:isShaderModuleActive(name)
```

To apply a module on a single object, subObject or material only, use following functions:
```lua
obj:activateShaderModule(name)
obj:deactivateShaderModule(name)
obj:isShaderModuleActive(name)
```

Or modify the `obj.modules` table manually. This way you can also specify modules on a subObject only:
```lua
obj.modules = {
	["effect"] = true,
}
```

### built-in shader modules
There are a few modules already built in, ready to enable:

#### rain
The rain modules renders rain, wetness and splash animations on surfaces.
The render part requires the module to be activated globally.
```lua
dream:activateShaderModule("rain")
dream:getShaderModule("rain").isRaining = true
dream:getShaderModule("rain").strength = 3 -- 1 to 5
```

#### wind
Wind lets the vertices wave. It requires the extra buffer as an factor of animation, either set `material.extra` to an appropiate constant or let the particle system generator do it. See mat chapter for this. To enable the wind shader, enable it on the affected material, optional adjust the shader modules settings.
```lua
material:activateShaderModule("wind")
```
Since .mat files supports `onFinish()` callbacks you can put the above line here too.
```lua
--example material file for grass
return {
	shadow = false,
	extra = 0.02,
	cullMode = "none",
	
	onFinish = function(mat, obj)
		mat:activateShaderModule("wind")
	end,
}
```

#### bones
3Dream supports animations with a few conditions:
1. it requires a skeleton and skin information, therefore export your object as a COLLADA file (.dae)
2. the bone module needs to be activated: `object:activateShaderModule("bones")` in order to use GPU powered transformations. Theoretical optional but cause heavy CPU usage and GPU bandwidth.
3. update animations as in the skeletal animations specified

## skeletal animations
WIP but should work fine. The COLLADA loader is often confused and needs further tweeking for some exports but should work most of the time.
A vertex can be assigned to multiple joints/bones, but 3Dream only considers the 4 most important.

```lua
--returns a pose at a specific time stamp
pose = self:getPose(object, time)

--apply this pose (results in object.boneTransforms)
self:applyPose(object, pose)

--alternative create and apply in one
dream:setPose(object, time)

--apply joints to mesh, heavy operation, shader module instead recommended
dream:applyJoints(object)
```


## 3do - 3Dream object file
WIP - currently receiving improvements and might not work as expected
It is strongly recommended to export your objects as 3do files, these files can be loaded on multiple cores, have only ~10-20% loading time compared to .obj and are better compressed.
To export, just set the argument 'export3do' to true when loading the object. This then combines the .obj, .mtl, .mat file and particle systems into one .3do files and saves it with the same relative path into the LÖVE save directory. Next time loading the game will use the new file instead. The original files are no longer required.

But note that...
* The exported file needs to be packed into the final game at some point.
* You can not modify 3do files, they contain binary mesh data. Therefore keep the original files!
* The exported 3do is shader dependend, you can not change the used shading engine later. You can not change any args to be precice.
* Particle systems are packed too, it is not possible to e.g. change the particle system based on user settings. Instead, disable particle system objects manually (yourObject.objects.particleSystemName.disabled = true).


## Object format
dream:loadObject() returns an object using this format:
```lua
object = {
	--a table of local materials
	materials = {
		None = {
			--None is the default, empty fallback material
			--material data as described in chapter 'materials' and 'mat - 3Dream material file'
		},
	},
	
	--a table of sub objects, each representing a drawable mesh, vertice buffers, render instructions and optional data
	objects = {
		yourSubObject = {
			faces = {
				{1, 2, 3}, --final ids
			},
			
			--buffers, each a vector or a skalar
			--following buffers are must have (might be empty to use default values)
			--additional buffers (e.g. joints, vertex weights, additional uv maps) require custom base shaders or modules
			vertices = { },
			normals = { },
			texCoords = { },
			colors = { },
			materials = { },
			extras = { },
			faces = { },
			
			material = material,              --material. Per mesh only one material is possible. Therefore consider splitMaterials, or per vertex color only
			
			name = "yourSubObjectBaseName",   --the name, without material postfixes in case of splitMaterials
			
			shaderType = "PBR",               --the used shader (PBR, Phong, simple or a custom one)
			meshType = "textured",            --simple, textured, material - if not overwritten by the arg in the object loader it will be chosen based on shaderType
			mesh = love.graphics.newMesh(),   --a static, triangles-mesh, may be nil when using 3do, loads automatically if not disabled by arg
			
			transform = mat4(),               --default is nil, overwrites global object transformation
		}
	},
	
	--array of positions as explained earlier
	positions = { },
	
	--the provided args in the loader
	args = { },
	
	path = path, --absolute path to object
	name = name, --name of object
	dir = dir,   --dir containing the object
	
	--the object transformation
	transform = mat4(),
}
```


## deferred rendering
REMOVED
After thinking about pro and cons I came to the conclusion that deferred rendering was a nice experiment, but exceeds the use cases for this 3D engine.
The currently implemented forward-shading technique supports nearly the same amount of features and is in most cases faster.

## collisions
The collision extension supports exact collision detection between a collider and another collider or (nested) group.

The second collider/group therefore creates an tree, allowing automatic optimisation and recursive transformations.

A transformation is either a mat4 or a vec3 offset. Transformations with different scales per axis might not work on certain types due to optimisations (e.g. mesh works, spheres do not).

The collision extension is rather slow and relies on proper optimisation of the scene (usage of groups, collision meshes with decreased vertex count, ...).

There will not be a physics engine.

```lua
--load the extension
collision = require("3DreamEngine/collision")

--functions
normal, position = collision:collide(a, b, fast)   --checks for collisions between a and b, where a can not be a group. Fast skips deep scan and only returns true or false. Normal and positions are averaged.
collision:getCollisions()                          --returns an array containing all collisions in the format {normal, position, collider} a has collided with
collision:print(collider)                          --recursively print the collider and a few relevant stats

--a helper function, returning the resulting velocity final, its approximate impact speed and the finals raw components reflect and slide based on its current velocity, normal vector of impact, elastiness from 0 to 1 and friction from 0 to 1
final, impact, reflect, slide = collision:calculateImpact(velocity, normal, elastic, friction)

--colliders
collision:newGroup(transform)          --create a group
collision:newSphere(size, transform)   --create a sphere with radius
collision:newBox(size, transform)      --create a box with vec3 size
collision:newPoint(transform)          --create a point
collision:newSegment(a, b)             --create a segment between a and b
collision:newMesh(object, transform)   --create a mesh from an object (creating a sub group automatically), a subobject or a collision (see next sub chapter)


--collider functions
collider:clone()                  --create a copy from it, only linking mesh data if present
collider:moveTo(vec3 offset)      --moves to a position (e.g. offset this collider)
collider:moveTo(mat4 transform)   --transforms this object
collider:moveTo(x, y, z)          --same as first but with numbers

--additional functions for groups
collider:add(o)                   --add an object to its children
collider:remove(o)                --remove an object from its children
```

### collisions in objects
Naming a subobject "COLLISION..." will load it as a collision mesh and removes it from the regular meshes.
Use them to define an abstract representation of your object to save CPU power.
Those collisions are stored in 'object.collisions[name]' similar as regular subObjects.
When loading the entire object, it will only use those special collision meshes.
Theoretically one can pass a specific collision directly.

## 3D sounds
3D sounds with related features like effects (echo, muffled, ...), environmental sounds (birds, river, ...) and similar is a WIP.
