![3DreamEngine](https://owo.whats-th.is/9ceoazf.png)
<a href="https://discord.gg/hpmZxNQ"><img src="https://discordapp.com/api/guilds/561664262481641482/embed.png" alt="Discord server" /></a>

# Features
* fast rendering with z-buffer and shaders
* PBR rendering (albedo, normal, roughness, metallic, ao, emission)
* Phong shading (color, normal, glossiness, specular, ao, emission)
* HDR with bloom
* average alpha blending with approximated refraction
* screen space ambient occlusion (ssao)
* cubemap reflections
* proper blurred reflections on rough surfaces
* particle batches
* modular and extendable shaders
* dynamic clouds, sun, moon and stars
* rain with rain splashes, wetness and reflections
* eye adaption effect
* cascade shadow mapping
* cubemap shadow mapping
* smooth shadows
* distance fog
* static particle emitter (grass, leaves, random rocks, smaller details)
* wind animation (leaves, grass, ...)
* loading and rendering .obj files, supports materials and textures included in .mtl files
* threaded texture loading with automatic thumbnail generation
* threaded object loading using 3DreamEngine specific object files (converter included)
* included optimized vec2, vec3, vec4, mat2, mat3 and mat4 library
* 3D transformation-tree-based collision extension, supports closed meshes collision

![screenshots](https://raw.githubusercontent.com/3dreamengine/3DreamEngine/master/screenshots.jpg)


# How to use?
```lua
--load 3DreamEngine
dream = require("3DreamEngine")

--optionally set settings
dream.bloom_enabled = false

--inits (applies settings)
dream:init()

--loads a object (optional with args)
yourObject = dream:loadObject("examples/monkey/object", {splitMaterials = true})

function love.draw()
  --reset lighting to default sun
  dream:resetLight()
  
  --prepare for rendering
  dream:prepare()

  --rotate and draw and offset
  yourObject:rotateY(love.timer.getDelta())
  dream:draw(yourObject, 0, 0, -5)

  --render
  dream:present()
end
```

# documentation

## settings
```lua
-- all settings marked with a star can and should be managed with a dream function as listed in chapter "functions"

dream.sun_offset = 0.25                   -- the distance from the equator
dream.sun = vec3(-0.3, 0.6, 0.5)          -- the sun vector *
dream.sun_color = vec3(10.0, 10.0, 10.0)  -- sun color *
dream.sun_ambient = vec3(1.0, 1.0, 1.0)   -- ambient light color used when no sky is specified *
dream.sun_shadow = true                   -- if the default sun should use a shadow

dream.fog_enabled = false                 -- enables fog
dream.fog_distance = 20.0                 -- caps density at this distance
dream.fog_density = 0.75                  -- density at max distance
dream.fog_color = {0.5, 0.5, 0.5}         -- the color of the fog

dream.AO_enabled = true                   -- enable screen space ambient occlusion
dream.AO_quality = 16                     -- samples
dream.AO_resolution = 0.75                -- downscale AO canvas

dream.bloom_enabled = true                -- simulate bright spots
dream.bloom_size = 1.5                    -- bloom effect size
dream.bloom_resolution = 0.5              -- downscale bloom canvas
dream.bloom_strength = 1.0                -- strength of appliance

dream.refraction_enabled = true           -- if second pass is enabled, this will enable refractions
dream.refraction_disableCulling = false   -- technically the backside of an object is visible too, however it is false by default because it visually looks better

dream.textures_fastLoading = true         -- enables the fast texture loader which loads the textures slow to avoid lags. It does NOT toggle threaded loading!
dream.textures_fastLoadingProgress = false-- during the loading process a temporary result could be displayed, chunks withing the texture are visible if enabled
dream.textures_mipmaps = true             -- if mipmaps should be generated for textures, should be true for best results
dream.textures_filter = "linear"          -- the filter mode for the textures
dream.textures_generateThumbnails = true  -- thumbnails are described in its own section below. Those thumbnails can be generated automatically, although they are visible after the second start

dream.msaa = 4                            -- multi sample anti aliasing, slightly more expensive but good results
dream.fxaa = false                        -- fast approximated anti aliasing, fast but less good results
dream.defaultShaderType = nil             -- if not specifally set, use this shader. Nil uses simple or phong, depending on wether the material has textures.
dream.alphaBlendMode = "alpha"            -- average is slowest with order independent blending and optional refraction, "alpha" uses alpha blending with possible order-artefacts,
                                          -- "dither" dithers between full and zero based on alpha and "disabled" only renders 100% alpha. "dither" and "disabled" only require one pass.
dream.max_lights = 16                     -- max lights. The actual limit is light types and hardware dependend, this value just caps the light count.
dream.nameDecoder = "blender"             -- imported objects often contain mesh data names appended to the actual name,, blender decoder removes them
dream.frustumCheck = true                 -- enable automatic frustum check
dream.LoDDistance = 100                   -- LoD reference distance

dream.shadow_resolution = 1024            -- cascade shadow resolution
dream.shadow_cube_resolution = 512        -- cube map shadow resolution
dream.shadow_distance = 8                 -- distance from player for the cascade shadow
dream.shadow_factor = 4                   -- cascade shadow has 3 layers, each with size factor times bigger
dream.shadow_smooth = true                -- enables smooth shadows, required 20 instad of 1 points Texels and 17 instad of 4 sun Texels. Point shadows also blur out based on distance.

dream.reflections_resolution = 512        -- cubemap reflection resolution
dream.reflections_format = "rgba16f"      -- reflection format, normal or rgba16f, where rgba16f preserves more detail in brightness
dream.reflections_alphaBlendMode = "average" --//--
dream.reflections_msaa = 4                -- multi sample antialiasing for reflections, else use fxaa if enabled
dream.reflections_levels = 5              -- the count of mipmaps used, lower values cause incorrect blending between roughnesses, high values cause low quality on high roughnesses
dream.reflection_downsample = 2           -- the factor of downsampling when bluring the cubemap. Should not be changed since the blur is calibrated.

dream.gamma = 1.0                         -- gamma, 1.0 has no effect
dream.exposure = 1.0                      -- final exposure

dream.rain_enabled = true                 -- enable rain engine, does not actually toggle rain
dream.rain_resolution = 512               -- splash texture resolution
dream.rain_isRaining = false              -- enables rain
dream.rain_strength = 3                   -- set rain strength
dream.rain_adaptRain = 0.1                -- speed of rain strength change
dream.rain_wetness_increase = 0.02        -- speed of wetness increase
dream.rain_wetness_decrease = 0.01        -- speed of wetness decrease

dream.autoExposure_enabled = false        -- enables auto exposure which adapts the exposure to the current view
dream.autoExposure_resolution = 128       -- temporary canvas resolution
dream.autoExposure_targetBrightness = 0.25-- target screen brightness to normalize to
dream.autoExposure_interval = 1 / 15      -- samples per second
dream.autoExposure_adaptionSpeed = 0.4    -- speed of adaption

dream.sky_as_reflection = true            -- use the sky dome (or cube map / hdri image) as the default reflection cube map
dream.sky_refreshRate = 1/15              -- refreshes per second when using sky dome
dream.sky_refreshRateTexture = 0          -- refreshes per second when using a cube map or hdri, 0 means static: only when reference changes
dream.sky_cube = false                    -- use a cubemap instead
dream.sky_hdri = false                    -- use an hdri sphere image instead. Should be a hdr format for optimal results.
dream.sky_hdri_exposure = 1.0             -- set image exposure
dream.sky_resolution = 512                -- resolution of sky cubemap, should match the wrapped hdri image size
dream.sky_format = "rgba16f"              -- format of sky, should be rgba16f, especially when using hdr formats for the hdri
dream.sky_time = 0.45                     -- time of day between 0 and 1, uses automatically the fract *
dream.sky_day = 0.0                       -- determines the moon phase *
dream.sky_color = vec3(1.0, 1.0, 1.0)     -- sets the base color of the sky *

dream.stars_enabled = true                -- enables stars at night
dream.sunMoon_enabled = true              -- enables sun and moon

dream.clouds_enabled = true               -- enables dynamic clouds, all of the following parameters can be controlled using the two last ones
dream.clouds_scale = 4.0                  -- the scale/distance of the clouds
dream.clouds_threshold = 0.5              -- the base threshold, higher values decrease clouds
dream.clouds_thresholdPackets = 0.3       -- make them more packy
dream.clouds_sharpness = 0.15             -- sharpen the sun side
dream.clouds_detail = 0.0                 -- sets the mipmap level and threrefore blurs the clouds
dream.clouds_packets = 0.25               -- multiplier for the packets texture
dream.clouds_weight = 1.5                 -- make them look thicker and more dense
dream.clouds_thickness = 0.1              -- reduce light coming through

--use dream:setWeather(rain, temp) instead of modifying directly
dream.weather_rain = 0.0                  -- between sunny (0) and thunderstorm (1)
dream.weather_temperature = 0.0           -- between cold (0) and hot (1)
```

## functions
```lua
--inits (applies settings, reload canvases, ...)
dream:init()

--loads an object
yourObject = dream:loadObject("objectName", args)

	--where args is a table with additional settings
	textures             -- location for textures, use "dir/" to specify diretcory, "file" to specify "file_albedo", "file_roughness", ...
	splitMaterials       -- if a single mesh has different textured materials, it has to be split into single meshes. splitMaterials does this automatically.
	grid                 -- grid moves all vertices in a way that 0, 0, 0 is the floored origin with an maximal overhang of 0.25 units.
	forceTextured        -- if the mesh gets created, it will determine texture mode or simple mode based on tetxures. forceTextured always loads as (non set) texture.
	noMesh               -- load vertex information but do not create a final mesh - template objects etc
	noParticleSystem     -- prevent the particle system from bein generated, used by template objects, ... If noMesh is true and noParticleSystem nil, it assume noParticleSystem should be true too.
	cleanup              -- release vertex, ... information once done - prefer using 3do files if cleanup is nil or true, since then it would not even load this information into RAM
	export3do            -- loads the object as usual, then export the entire object, including simple versions and particle system, as a single, high speed 3do file
	centerMass           -- normalize the center of mass (vertice mass) to its origin
	mergeObjects         -- merge all object into one

--the name of the object (set by "o" inside .obj, in blender it is the name of the vertex data inside an object) can contain information:
--  if it contains REMOVE, it will not be used. Their use can be frames, particle emitters, helper objects, ...)
--  if it contains POS it puts it into the positions table for manual use and skips loading. Positions contain the position (x, y, z), its averge radius from its origin as size and the name (everything behind POS+1, but stops at a dot to exlude numberings)

--required for loading textures, 3do files, ...
dream:update()

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

### Object/Camera functions
```lua
--transform the object
yourObject:reset()
yourObject:translate(x, y, z)
yourObject:scale(x, y, z)
yourObject:rotateX(angle)
yourObject:rotateY(angle)
yourObject:rotateZ(angle)
yourObject:setDirection(normal, [up]) --rotate the object to face into the given direction, up is default vec3(0, 1, 0)
```

### Camera
```lua
--default camera (with functions as defined in chapter above)
dream.cam:reset()

--if you want an own camera use
yourCam = dream:newCam()
--and pass it to dream:prepare()
```

### Light
```lua
--update time and weather
dream:setDaytime(time)
dream:setWeather(rain, temp)

--resets light sources (if noDayLight is set to true, the sun light (dream.sunObject) will not be added)
dream:resetLight(noDayLight)

--creates a new light
--typ is the light type, "point" and "sun" is inbuild, further types can be added via the shader library
local light = dream:newLight(posX, posY, posZ, red, green, blue, brightness, typ)

--add a shadow to the light
--typ is either point or sun
--static only renders one and is therefore faster
--res can set a custom resolution
light.shadow = dream:newShadow(typ, static, res)

--change light data
light:setBrightness(b)
light:setColor(r, g, b)
light:setPosition(x, y, z)

--add light to scene, note that in case of exceeding the max light sources it only uses the most relevant sources, based on distance and brightness
dream:addLight(light)

--or create a new light source and add it at once
dream:addNewLight(posX, posY, posZ, red, green, blue, brightness, typ)
```

### Reflections
Reflections are updated automatically if in use and can be assigned to several objects without issues. Note that reflections are cubemap based and are physically incorrect the more far away the pixel from the reflection center is.
```lua
--add reflections to the object
--reflections are rather slow, use static if the scene does not change or the reflection should not reflect changes
--priority is used to priorisize the sub task render queue
--pos is an alternative position, else taken from the boundary center
yourObject.reflection = dream:newReflection(static, priority, pos)
yourObject.objects.yourSubObject.reflection = dream:newReflection(static, priority, pos)
```

### Utils
This is a collection of helpful utils.
```lua
local m = dream:lookAt(eye, at, up)               --returns a transformation matrix at point 'eye' looking at 'at' with upwards vector 'up' (default vec3(0, 1, 0))
dream:pointToPixel(point, cam, canvases)          --converts a 3D point with given camera (default dream.cam) and canvas set (default dream.canvases) to a vec3 2D screen coord + depth
dream:pixelToPoint(point, cam, canvases)          --converts a 2D screen coord + depth to a 3D point

local r, g, b = dream:HSVtoRGB(h, s, v)           --converts hsv to rgb
local h, s, v = dream:RGBtoHSV(r, g, b)           --converts rgb to hsv

dream:inFrustum(cam, pos, radius)                 --checks if the position with given radius is visible with the current (projection matrix) camera
dream:getCollisionData(object)                    --returns a raw collision object used in the collision extensions newMesh function from an subObject
```

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

### vertex shader
The vertex shader transforms the vertices, e.g. the wind shader. It can be set using the `shader` tag, default is 'default'.
This shader has to create a 'vec3 pos'.

### shader modules
Those modules can extend the shader to add certain effects. For example a rain effect as the one implemted, or a burning animation, or a disolving effect, ...
```lua
--activate/deactive a module to all objects
dream:activateShaderModule(name)
dream:deactivateShaderModule(name)

--get the shader module, for example to change its settings
dream:getShaderModule(name)

--check if this module is globally active
dream:isShaderModuleActive(name)
```

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

## default reflection
If a object has no reflection assigned (see chapter functions - reflections) it falls back the default reflection cubemap, or a single color of not set either.

### use sky dome
To use the sky dome set `dream.sky_as_reflection` to true.
Note that this will also use the hdri or cube map set. Match the format and resolution to the given texture to avoid loss in quality.

### use a custom cubemap
To set the map manually, set `dream.sky_as_reflection` to false to avoid automatic overriding it and 'dream.defaultReflection' to the cube map.
The cubemap should (but dont necessary have to if not using glossy reflections) mipmaps, each heavyly blurred. Therefore, create the cube map with mipmaps set to `manual` and run following code to generate proper mipmaps:
```lua
for level = 2, yourCubeMap:getMipmapCount() do
	self:blurCubeMap(yourCubeMap, level)
end
```
If you change the cubemaps content, you need to recreate mipmaps too.

Make sure `dream.sky_as_reflection` is false, else it will override your reflection.
Then overwrite `dream.defaultReflection` with a volume Drawable (before `dream:prepare()`)
This will NOT affect the sky visible to the camera. 
If you want to use this cubemap instead of an HDRI or the sky dome, set `dream.reflection_as_sky` to true.

### particle batches
Particles are batched and rendered all together.
```lua
--create a particle batch
--pass a texture and the target pass. 1 means the texture is opaque and depth buffer can be used, 2 means its transparent. 2 is default and slower. Average alpha mode is currently not fully supported and might cause wrong ordering.
local particleBatch = dream:newParticleBatch(texture, pass)

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
dream:loadMaterialLibrary("materialsDirectory")
```
A material library looks for material files (.mat) or for directory containing material.mat or at least an image.

## alpha blend mode
Alpha blending can be quite tricky, therefore 3Dream offers 4 different approaches, depending on your scene.
There is a AlphaBlending demo to see those modes in action.
Currently its only possible to use one method at a time.
Dream.init() has to be called after changing.
```
--uses a second render step and a set of canvases to perform an order independent average alpha
--note that this blend mode is by far more slow than the other modes
--if you do not have alpha components, use dither or disabled
--this also allows refractions, if enabled
dream.alphaBlendMode = "average"

--sort the objects and render in a second step using alpha blending
--works mostly, but can screw up render order, especially within the same object
dream.alphaBlendMode = "alpha"

--does not require a second step, but perform dithering based on alpha
dream.alphaBlendMode = "dither"

--uses a threshold and avoid alpha at all
--known issues are linear interpolated mipmaps and alpha, since the interpolated parts are cut away.
dream.alphaBlendMode = "disabled"
```

## Level of Detail
To define the level of detail, add a boolean array with size 9 to the object or subobject, index 1 is nearest. False prevents this object from rendering.
```
--set reference distance (max render distance if 9th index is false)
dream.LoDDistance = 100

--set objects LoD
yourObject.LoD = {true, true, true, false, false, false, false, false, false} --allow rendering 1/3 of the max LoD distance

--overwrite the LoD of one sub object
yourObject.objects.subObject.LoD = {true, true, true, true, true, true, false, false, false} --allow rendering 2/3 of the max LoD distance
```

## textures
To add textures to the model ...
* name the textures albedo, normal, roughness, metallic, glossiness, specular, emission and put it next to the material (for material library entries) or suffix them with either the material name "material_" or the object name "object_"
* set the texture path in the mtl file. See (3DreamEngine/loader/mtl.lua) for up to date parser information (no prefix)
* set the texture in the mat file (tex_diffuse, tex_normal, tex_emission, ...) (no prefix)
* the relative path it uses to look for textures is the same as the object itself, if not overwritten by the "textures" arg in the model loader
* it does automatically choose the best format and load it threaded when needed.

The diffuse texture is a RGB non alpha texture with the color.
The normal texture contains tangential normal coordinates.
The emission texture contains RGB color, in contrast to all other textures it will be multiplied by material.emission (RGB color) instead of using it as fallback. Use this as a multiplier if required.
Roughness, metallic, specular and glossiness are single channel textures.

Please note that the rendering pipeline only accepts combined RMA textures (roughness, metallic, ao, or its Phong counterpart glossiness, specular, ao).
If not present, it will generate it and put it in the love save directory. It is recommended to use them to avoid heavy (but at least threaded) CPU merge operations.
DDS files are supported, but can not generate mipmaps automatically.

## thumbnails
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
		name = "grass", --extend material Grass
		
		--Shared for all shading
		color = {1.0, 1.0, 1.0, 1.0},  -- color
		emission = {1.0, 1.0, 1.0},    -- emission color, or the multiplier if a texture is present
		
		--Phong
		specular = 0.5,                -- specular component (note that specular component has the same color as the albedo texture / color)
		glossiness = 0.1,              -- exponent, 0-1 (where 1 represent around exponent 1000)
		
		--PBR
		roughness = 0.5,               -- roughness if no texture is set
		metallic = 0.5,                -- metallic if no texture is set
		
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
		
		--vertex shader information
		shader = "wind",                -- vertex shader affecting the entire object
		shaderValue = 1.0,              -- animation multiplier
		
		--some shaders have additional values, like the wind shader (currently the only one)
		shader_wind_speed = 0.5,       -- the time multiplier
		shader_wind_strength = 1.0,    -- the multiplier of animation
		shader_wind_scale = 3.0,       -- the scale of wind waves
		
		--add particleSystems
		particleSystems = {
			{ --first system
				objects = { --add objects, pathes have to be global, objects are merged and therefore has to share a material. If not, use two particle systems instead.
					["path/grass"] = 20,
				},
				randomSize = {0.75, 1.25},    --randomize the particle size
				randomRotation = true,        --randomize the rotation
				normal = 0.9,                 --align to 90% with its emitters surface normal
				shader = "wind",              --use the wind shader
				shaderValue = "grass",        --tell the wind shader to behave like grass, the amount of waving depends on its Y-value
				shaderValue = 0.2,            --or use a constant float
			},
		}
	},
}
```

## 3do - 3Dream object file
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
	materials = {
		None = {
			--None is the default, empty fallback material
			--material data as described in chapter 'materials' and 'mat - 3Dream material file'
		},
	},
	
	objects = {
		yourSubObject = {
			faces = {
				{1, 2, 3}, --final ids
			},
			final = {
				{x, y, z, shaderData, nx, ny, nz, material, u, v, tx, ty, tz, btx, bty, btz}, -- position, shader extra value e.g. for animation, normal, material (used for flat shading only), uv coords (may be nil for flat shading), tangent and bitangent (calculated automatically)
			},
			-- when using 3do or when args.noCleanup is disabled (default is false) faces and final will be deleted once the mesh is created to free memory.
			
			material = material,              --mesh material. If several materials are used (and splitMaterials is disabled), it can only use the last, unlinking your other materials.
			
			name = "yourSubObjectBaseName",   --the name, without material postfixes
			
			shaderType = "PBR",               --the used shader (PBR, Phong, simple or a custom one)
			meshType = "textured",            --simple, textured, textured_array - determines the data the mesh contains, if nil it will be guessed based on the shaderType
			mesh = love.graphics.newMesh(),   --a static, triangles-mesh, may be nil when using 3do, loads automatically
			
			transform = mat4(),               --default is nil, overwrites global object transformation
		}
	},
	
	--array of positions as explained earlier
	positions = { },

	path = path, --absolute path to object
	name = name, --name of object
	dir = dir,   --dir containing the object

	--args as provided in loadObject
	--some nil args will be automatically set to default values based on shading engine
	splitMaterials = args.splitMaterials,
	--...
	--...
	--...

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

# Examples
We have examples in the examples folder. The provided main.lua contains a demo selection.

# Credits
- The Lamborghini .obj and textures from https://www.turbosquid.com/FullPreview/Index.cfm/ID/1117798
- cc0textures.com
- texturehaven.com
- hdrihaven.com.com
- cgbookcase.com
- Stars and Moon by Solar Textures at https://www.solarsystemscope.com/textures/ (CC BY 4.0)

# License (MIT/EXPAT LICENSE)
Copyright 2020 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
