# content

- [functions](#functions)  
   * [init](#init) -
   [load object](#load-object) -
   [update](#update) -
   [prepare](#prepare) -
   [draw](#draw) -
   [draw particle](#draw-particle) -
   [present](#present)
- [settings](#settings)
  * [Default shader](#default-shader) -
  [deferred shader](#deferred-shader) -
  [max Lights](#max-lights) -
  [name Decoder](#name-decoder) -
  [frustum](#frustum) -
  [LOD Distance](#lod-distance) -
  [dither](#dither) -
  [exposure](#exposure) -
  [auto Exposure](#auto-exposure) -
  [gamma](#gamma) -
  [screen space ambient occlusion](#screen-space-ambient-occlusion) -
  [bloom](#bloom) -
  [fog](#fog) -
  [rainbow](#rainbow) -
  [shadows](#shadows) -
  [sun](#sun) -
  [daytime](#daytime) -
  [weather](#weather) -
  [sky](#sky) -
  [clouds](#clouds) -
  [base reflection](#base-reflection) -
  [resource loader](#resource-loader)
- [objects](#objects)
  * [transform class](#transform-class) -
  [visibility class](#visibility-class) -
  [clone class](#clone-class) -
  [shader class](#shader-class)
  * [object](#object) -
  [subObject](#subobject) -
  [camera](#camera) -
  [light](#light) -
  [shadow](#shadow) -
  [reflection](#reflection) -
  [scene](#scene) -
  [setSettings](#setsettings) -
  [materials](#materials)
- [utils](#utils)  
- [particle batches](#particle-batches)
- [level of detail](#level-of-detail)
- [textures](#textures)
  * [thumbnails](#thumbnails)
- [data structures](#data-structures)
  * [object](#object-1) -
  [subobject](#subobject) -
  [material](#material)
- [Shaders](#shaders)
  * [built-in shader modules](#built-in-shader-modules)
    + [rain](#rain) -
    [wind](#wind) -
    [bones](#bones)
- [skeletal animations](#skeletal-animations)
- [3DO - 3Dream object file](#3do---3dream-object-file)
- [collisions](#collisions)
- [3D sounds](#3d-sounds)



# functions

## init
Applies settings, reload canvases, ...  
Needs to be called after changing settings or resizing the screen.  

```lua
dream:init()
```



## load object
Loads an object containing renderable sub objects, positions, bone data and similar.  
This is the most important type.  

```lua
yourObject = dream:loadObject(path)
yourObject = dream:loadObject(path, shaderType)
yourObject = dream:loadObject(path, args)
yourObject = dream:loadObject(path, shaderType, args)
```

`path` The path of the object without extension. Supported are currently .obj, .dae, .vox and the custom .3do  
`shaderType` the shader to use (e.g. Phong, simple, PBR, ...)  
`args` a table of additional settings on how to load the object.  


* `textures` location for textures, use "dir/" to specify diretcory, "file" to specify "file_albedo", "file_roughness", ...  
* `splitMaterials` if a single mesh has different textured materials, it has to be split into single meshes. splitMaterials does this automatically.
* `grid` grid moves all vertices in a way that 0, 0, 0 is the floored origin with an maximal overhang of 0.25 units.
* `noMesh` load vertex information but do not create a final mesh - template objects etc
* `noParticleSystem` prevent the particle system from being generated
* `cleanup`the level of cleanup after the objects have been loaded. false deloads * `nothing. nil (default) deloads all buffers except faces and vertex positions. true deloads * `everything.
* `export3do`loads the object as usual, then export the entire object inclusive * `animations, collisions, positions and similar as a 3DO file. See 3DO chapter for use cases
* `export3doVertices`vertices are not included by default, since they are bulky and unecessary unless converting an object to a collision. While not recommended, you can force vertices and edge data to be included.
centerMass` normalize the center of mass (vertice mass) to its origin
* `mergeObjects` merge all object into one
* `animations` when using COLLADA format, split the animation into {key = {from, to}}, where from and to are timestamps in seconds

if the name of an subObject contains:
* "POS_" it puts it into the positions table for manual use and skips loading. Positions contain the position (x, y, z), its averge radius from its origin as size and the name
* "COLLISION_" it loads it as a collision and puts it into the collisions table. If used as a collider it only uses those instead.



## update
Required for loading threaded textures, 3do files, ...
```lua
work = dream:update()
```
`work` if something has been loaded this call.  



## prepare
Prepare for rendering by clearing all batches and queues.
```lua
dream:prepare()
```



## draw
Adds an object or sub object to the default scene to render.
```lua
dream:draw(obj)
dream:draw(obj, x, y, z)
dream:draw(obj, x, y, z, sx, sy, sz)
```
`obj` object or subobject  
`x y z` position  
`sx sy sz` scale  



## draw particle
A particle is the port of `love.graphics.draw` to 3D and is far slower than particle batches or meshes. Use with care.  
If only the emission should be visible, set the emission to a value > 0 and use `love.graphics.setColor(0, 0, 0)` to make the diffuse term black.

```lua
dream:drawParticle(drawable, quad, ...)
dream:drawEmissionParticle(drawable, emissionDrawable, ...)
```
`drawable` a LÖVE drawable  
`emissionDrawable` a LÖVE drawable for the emission texture  
`...` same signature as LÖVEs draw  

<br />

Additional settings are set before the draw call.
```lua
dream:setParticleVertical(vertical)
vertical = dream:getParticleVertical()
```
`vertical (0)` 0 faces you, 1 keeps pointing towards sky. Useful for candles, distant LoD, ...

<br />

```lua
dream:setParticleEmission()
dream:setParticleEmission(emisison)
emisison = dream:getParticleEmission()
```
`emisison (false)` emission multiplier, or false to use 0 or 1, depending on emission texture.



## present
Finish render session, it is possible to render several times per frame but then use presentLite() since present() also renders sub tasks
```lua
dream:present(cam, canvases, lite)
```
`cam (dream.cam)` custom cam  
`canvases (dream.canvases)` custom canvas set  
`lite (false)` do not perform job updating, set this to true when using present several times per frame  



# settings
Most settings require `dream:init()` to be called afterwards.


## default shader
Sets the default shader, false to choose between textured Phong and simple Phong.

```lua
dream:setDefaultShaderType(typ)
typ = dream:getDefaultShaderType()
```
`typ (false)` valid shader type or false  



## deferred shader
Deferred shading, unlike forward, can only have one lighting function at the same time.

```lua
dream:setDeferredShaderType(typ)
typ = dream:getDeferredShaderType()
```
`typ (false)` valid shader type to take light function from or false  


## max Lights
The maximal number per light typ. This is just a hardlimit.

```lua
dream:setMaxLights(limit)
limit = dream:getMaxLights()
```
`limit (16)` number  



## name Decoder
Some exporter add some pre and postfixes, with this regex string you can fix the names. False to disable.

```lua
dream:setNameDecoder(decoder)
decoder = dream:setNameDecoder()
```
`decoder ("^(.+)_([^_]+)$")` regex string  



## frustum
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



## dither
Depth testing and dither do not like each other. You can choose between dithering or fixed 0.5 threshold.

```lua
dream:setDither(enabled)
enabled = dream:setDither()
```
`enabled (true)`  



## exposure
Sets the exposure for HDR, making it possible to represent colors over 1. 1.0 is default. False disables it.
```lua
dream:setExposure(enabled)
enabled = dream:getExposure(enabled)
```



## auto Exposure
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



## gamma
Gamma correction is already applied, therefore default is 1.0. Disabled by default.

```lua
dream:setGamma(gamma)
gamma = dream:getGamma()
```
`gamma` can be a number or false.  



## screen space ambient occlusion
To simulate shadows between close surfaces a lightweight screen space occlusion methode can be used. Enabled by default.

```lua
dream:setAO(samples, resolution, blur)
enabled, samples, resolution, blur = dream:getAO()
```
`samples (32)` Higher samples increase quality.  
`resolution (0.75)` Subsampling factor.  
`blur` (false) Additional two-pass Gaussian blur.  



## bloom
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



## fog
Allows the simulation of fog, smoke or visible gasses and sunlight scatter between two defined density layers.

```lua
dream:setFog(density, color, scatter)
enabled, density, color, scatter = dream:getFog()
```
`density` density  
`color` vec3 color  
`scatter` 0 or more multiplier for sun scatter  

<br />

```lua
dream:setFogHeight()
dream:setFogHeight(min, max)
min, max = dream:getFogHeight()
```
`min (1)` lower, full-fog plane height. Nil/false sets fog constant.  
`max (-1)` higher, no-fog plane height. When smaller than min, fog is constant.  


## rainbow
Renders a rainbow on the sky dome.

```lua
dream:setRainbow(strength, size, thickness)
dream:setRainbow(strength)
strength, size, thickness = dream:getRainbow()
```
`strength` the strength, usually between 0 and 1  
`size (~42°)` angle from viewer  
`thickness (0.2)` rainbow width  

<br />

```lua
dream:setRainbowDir(dir)
dir = dream:getRainbowDir()
```
`dir` vec3 of rainbow. Physically this is always -sunVector, but can be set for artistic reasons manually.  


## shadows
Shadows can use per light/shadow settings, else they will use default values set here.  
Higher resolution may increase quality, but usually smoothing hides lower resolutions anyways.  

```lua
dream:setShadowResolution(sun, point)
sun, point = dream:getShadowResolution()
```
`sun (1024)` sun cascade resolution (3x canvases)  
`point (512)` point source cubemap shadows  

<br />

```lua
dream:setShadowSmoothing(enabled)
enabled = dream:getShadowSmoothing()
```
`enabled (false)` slow, but fancy shadow smoothing.  

<br />

```lua
dream:setShadowCascade(distance, factor)
distance, factor = dream:getShadowCascade()
```
`distance (8)` shadow range in metres.  
`factor (4)` factor of range of next shadow map, distance * factor^2 therefore is the total range.  

<br />

```lua
dream:setSunShadow(enabled)
enabled = dream:getSunShadow()
```
`enabled (true)` If the sun light object should receive a shadow.



## sun
Sets the position of the sun (done automatically by 'dream:setDaytime()'

```lua
dream:setSunDir(direction)
direction = dream:getSunDir()
```
`direction` vec3 direction of the sun  

<br />

```lua
dream:setSunOffset(offset)
offset = dream:getSunOffset()
```
`offset` offset where 0 is the equator and 1 the north pole when using 'dream:setDaytime()'.  



## daytime
Automatically fetches sky and sun color, sets sun position based on offset and controls moon cycle.

```lua
dream:setDaytime(time)
time = dream:getDaytime()
```
`time` Time between 0 and 1, where 0.0 is sunrise and 0.5 sunset.  



## weather
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

<br />

An extended version which performs a smooth transition, generated mist and a rainbow after rain:
```lua
dream:updateWeather(rain, temp, dt)
```
`rain` thicker clouds, darker sky, ...  
`temp (1.0 - rain)` temperature, mainly controls clouds  
`dt` delta time, can be used to control speed of weather change



## sky
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



## clouds
If the sky dome is used weather based random clouds can be rendered.

```lua
dream:setClouds(enabled)
dream:setClouds(enabled, resolution, scale, amount, rotations)
enabled, resolution, scale = dream:getClouds()
```
`enabled (true)`  
`resolution (1024)` random cloud buffer canvas size  
`scale (2.0)` scale of clouds  
`amount (32)` amount of clouds per sector  
`rotations (true)` if rotation should be used  

<br />

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

<br />

```lua
dream:setCloudsAnim(size, position)
size, position = dream:setCloudsAnim()
```
`size (0.01)` randomize size speed  
`position (0.25)` randomize position speed  

```lua
dream:setCloudsStretch(stretch, stretch_wind, angle)
stretch, stretch_wind, angle = dream:getCloudsStretch()
```
`stretch` stretch strength  
`stretch_wind` stretch strength based on wind  
`angle` angle offset  



## base reflection
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

The cubemap needs prepared mipmaps when using glossy reflections. Therefore, create the cube map with mipmaps set to `manual` and run following code to generate proper mipmaps (`dream:take3DScreenshot()` does that automatically):
```lua
for level = 2, yourCubeMap:getMipmapCount() do
	self:blurCubeMap(yourCubeMap, level)
end
```



### sky reflection
If the base reflection is true following settings affects how the sky dome is rendered.
```lua
dream:setSkyReflectionFormat(resolution, format, skip)
resolution, format, skip = dream:getSkyReflectionFormat()
```
`resolution (512)` cubemap resolution 
`format ("rgba16f")` cubemap format, HDR by default  
`skip (4)` frame skip, see jobs chapter  



## resource loader
The resource loader can load textures threaded to avoid loading times or lags.

```lua
dream:setResourceLoader(threaded, thumbnails)
threaded, thumbnails = dream:getResourceLoader()
```
`threaded (true)` use several cores to load images in the background  
`thumbnails (true)` generate thumbnails, which will be loaded first next time to deliver results faster  

large images cause a lag when pushing to the GPU, by using 3Dreams smooth loader this can be avoided.
However images will then be canvases instead, which should not make a different.

<br />

```lua
dream:setSmoothLoading()
dream:setSmoothLoading(time)
time = dream:getSmoothLoading()
```
`time (1 / 1000)` how many seconds per cycle

<br />

```lua
dream:setSmoothLoadingBufferSize(size)
size = dream:getSmoothLoadingBufferSize()
```
`size (128)` chunk size, the bigger the better, but increase time required and therefore may cause lags.

<br />

```lua
dream:setMipmaps(enabled)
enabled = dream:getMipmaps()
```
`enabled` if the loader should generate mipmaps  




# objects
3Dream uses objects to represent its data structure. Each object may extend a number of classes. Classes can not have instances.

## transform class
Sets the transform matrix using helper functions.

```lua
self:reset()
self:transform(mat4)
self:translate(x, y, z)
self:scale(x, y, z)
self:rotateX(angle)
self:rotateY(angle)
self:rotateZ(angle)
self:setDirection(normal)
self:setDirection(normal, up)
```



## visibility class
Sets LODs and pass visibility.

```lua
self:setLOD(map)
map = self:getLOD()
```
`map` subject to change

<br />

```lua
self:setVisibility()
self:setVisibility(render, shadow, reflections)
render, shadow, reflections = self:setVisibility()
```
`render` enabled in efault render pass  
`shadow` enabled in shadow render pass  
`reflections` enabled in reflections render pass 



## clone class
The clone class allows to create a clone with shared data but individual transforms, ...  
Therefore do not modify data directly.

```lua
c = self:clone()
```
`c` new object  



## shader class
The shader class allows managing additional shader modules assigned to certain objects/materials.

```lua
self:activateShaderModule(name)
self:deactivateShaderModule(name)
enabled = self:isShaderModuleActive(name)
```
`name` name of shadermodule
`enabled` 



## object
Returned by `dream:loadObject()`

Extends `clone`, 'transform', 'visibility', 'shader'

Subobjects from 3DO files are loaded threaded and may not be loaded yet when using. They will not cause troubles, just wont render. Requesting an object happens automatically if not disabled in `dream:loadObject()` or via `request()`. If tried to render it also requests automatically. You can yield with `wait()` until everything has been loaded.
```lua
laoded = self:isLoaded()
self:request()
self:wait()
```



## subObject
A subobject is an renderable mesh inside an object and is usually not directly controlled.

Extends `clone`, 'transform', 'visibility', 'shader'

Similar as a object individual subObjects might be requested manually. Usually not required.
```lua
laoded = self:isLoaded()
self:request()
self:wait()
```




## camera
A custom camera can be used in `dream:present()` if necessary, but usually the default camera in `dream.cam` is sufficiant.

extends `transform`  

```lua
cam = dream:newCam()
```

<br />

```lua
dream:setFov(fov)
fov = dream:setFov()

dream:setNear(near)
near = dream:setNear()

dream:setFar(far)
far = dream:setFar()
```
`fov` field of view between 0 and 180  
`near` the nearest object  
`far` the furthest object. The depth precision decreases with increasing far-near distance.  



## light
Lights are stored in an active light queue and will be chosen per scene as it fits best.

```lua
light = dream:newLight()
light = dream:newLight(typ, x, y, z, r, g, b, brightness)
```
`light` a new light object, without shadow  
`typ ("point")` a light type  
`x y z (0)` initial position  
`r, g, b (1)` initial color  
`brightness (1)` initial brightness  

<br />

change light data
```lua
light:setBrightness(b)
b = light:getBrightness()

light:setColor(r, g, b)
r, g, b = light:getColor()

light:setPosition(x, y, z)
x, y, z = light:getPosition()
```

<br />

Adds a new shadow to the light.
```lua
light:addShadow(static, res)
```
`static` only render once, faster but does not reflect changes  
`res` resolution of shadow map, either cubemap or cascade depending on light typ.  

<br />

Sets/gets the shadow. Theoretically you can share a shadow between lights.
```lua
light:setShadow(shadow)
shadow = light:getShadow()
```
`shadow` valid shadow object  

<br />

Enable shadow smoothing for this source. Slow, but beatiful.
```lua
light:setSmoothing(smooth)
smooth = light:setSmoothing()
```
`smooth (false)` boolean

<br />

Set the frameskip to slow down shadow rendering on unimportant sources.
```lua
light:setFrameSkip(skip)
skip = light:getFrameSkip()
```
`skip (0)` frames to skip for each rendered

<br />

To reset the light (optional without the default sun object), add a light and add a unshadowed new light (same signature as creating a light):
```lua
dream:resetLight(noDayLight)
dream:addLight(light)
dream:addNewLight(...)
```



## shadow
A shadow can be attached to a lightsource.

```lua
dream:newShadow(typ, static, res)
```
`typ` "point" or "sun"
`static` render only once
`res` resolution

<br />

Refresh the shadow as soon as possible (relevant for static shadows)
```lua
shadow:refresh()
```



## reflection
A reflection uses a cubemap to render its environment to simulate local reflections.

```lua
dream:newReflection(static, res, noRoughness)
```
`static` only render once  
`res` resolution, only works with direct render enabled  
`noRoughness` roughness can be simulated using blurring. If not required, disable it!  

<br />

```lua
reflection:setFrameSkip(skip)
skip = reflection:getFrameSkip()
```
`skip (0)` number of frame  

<br />

```lua
reflection:setRoughness(roughness)
roughness = reflection:getRoughness()
```
`roughness (true)` simulate roughness  

<br />

Rerender it as soon as possible.
```lua
reflection:refresh()
```


### local cubemaps
By default cubemaps are treated as infinite cubemaps, working perfect for distant objects. If all objects are close the same AABB bounding box (e.g. a room, hallway, ...) local correction can be applied.

```lua
reflection:setLocal(pos, first, second)
```
`pos` vec3 center  
`first` vec3 first, smaller corner of AABB  
`second` vec3 second, larger corner of AABB  

### Planar reflections
WIP, they would make mirrors and water surfaces possible and are way faster than cubemap reflections, but cant be static.



## scene
A scene contains a list of objects to render. They are currently subject to change and will receive a demo project.
The default scene is saved in `dream.scene`.

extends `visibility`

Create an activate scene:
```lua
scene = dream:newScene()
dream:drawScene(scene)
```

<br />

```lua
scene:clear()
scene:add(obj)
scene:add(obj, transform)
scene:add(obj, transform, col)
```
`obj` object or subobject
`transform (I)` mat4
`col (white)` vec3 color



## setSettings
A canvas set contains the target framebuffers and most of the graphics settings. Default sets are saved in `dream.renderSet`, `dream.reflectionsSet` and `dream.mirrorSet`.

```lua
set = dream:newSetSettings()

canvases = newCanvasSet(set)
canvases = newCanvasSet(set, w, h)
```
`set` settings, no actual data yet  
`canvases` ready to use canvases  

<br />

All of the following functions have a getter too.
```lua
set:setResolution(res)
set:setFormat(format)
set:setDeferred(enabled)
set:setPostEffects(enabled)
set:setDirect(enabled)
set:setMsaa(msaa)
set:setFxaa(enabled)
set:setRefractions(enabled)
set:setAverageAlpha(enabled)
set:setAlphaPass(enabled)
```
`res (512)` resolution if not specified in `dream:newCanvasSet()`.
`format ("rgba16f")` LÖVE pixel format.
`enabled` features
* deferred uses a G-Buffer and draws light as a posteffect. Large overhead, small light-performance. Future unclear.
* post effects are effects like exposure, bloom, ... which are unwanted for temporary results (e.g. reflections)
* direct rendering is fast and do not use any canvases. It also lacks most features (no AO, no bloom, no refractions, ...)
* msaa is slower but more beatiful (consider hardware limit), fxaa is faster but blurry. Dont use both.
* refractions simulate refractions for objects in the alpha pass and ior ~= 1.0
* average alpha is slightly more heavy and simulates several objects in a row better. Depends on your scene if this makes sense.
* alpha pass can be disabled entirely, increasing performance a bit. Disable if no object use the second pass anyways.




## materials
Materials can be either per model by providing a .mtl or .mat file with the same name as the object file or they can be in a global material library, in which case they got chosen first.

extends `clone`, `shader`

Load materials into the library. If an objects now requires a material, it will first look into the library.

A material library looks for material files (.mat) or for directory containing material.mat or at least one texture, linking them automatically. See for examplke Tavern demo.

```lua
dream:loadMaterialLibrary(path)
dream:loadMaterialLibrary(path, prefix)
```
`path` path to directory  
`prefix` prefix to add before name  

<br />

All functions also have getters too. Colors are multiplied with textures. If a texture is set it clears the color to white EXCEPT if set via a .mat file.
```lua
material:setIOR(ior)
material:setDither(enabled)

material:color(r, g, b, a)
material:albedoTex(tex)

material:emission(r, g, b)
material:emissionTex(tex)

material:glossiness(value)
material:glossinessTex(tex)

material:specular(value)
material:specularTex(tex)

material:roughness(value)
material:roughnessTex(tex)

material:metallic(value)
material:metallicTex(tex)
```
`enabled` custom dithering mode for this material instead of using the global one.
`tex` LÖVE drawable
`r g b a` color


### transparent materials
You have to tell the engine how to render this material. Alpha enabled will use the second pass. Solid enabloed the first pass. Both can be enabled and makes sense for materials containing both full alpha parts and semi transparent parts. Translucent puts light on the backside. Settings translucent via the functions also sets the cullmode to none.
```lua
material:setAlpha(enabled)
material:setSolid(enabled)
material:setTranslucent(value)
material:cullMode(cullmode)
```
`cullmode` LÖVE cullmode ("none", "back")  



# utils
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

--CIMG (Complex Image) can export and load canvases, cubemaps, volume images and array images with any format and including mipmaps. Fast.
cimg:load(path)
cimg:export(drawable, path)
```

There are a few libraries included you can use. Check their files for supported functions
* vec2, vec3, vec4 with common functions and metatables
* mat2, mat3, mat4
* quaternions
* a XML parser
* utils.lua which expands luas table, string and math libraries by common functions



# particle batches
Particles are batched and rendered all together.
```lua
batch = dream:newParticleBatch(texture)
batch = dream:newParticleBatch(texture, emissionTexture)
```
`texture` LÖVE drawable  
`emissionTexture` LÖVE drawable for emission  

<br />

Enqueue for drawing.
```lua
dream:drawParticleBatch(batch)
```

<br />

Adds particles.
```lua
batch:add(x, y, z, sx, sy, emission)
batch:addQuad(quad, x, y, z, sx, sy, emission)
```
`quad` LÖVE quad to use
`x, y, z` position  
`sx, sy, sz` scale, where, unlike single particles, 1 unit is exactly 1 meter  
`emission (0.0 or 1.0 with emission texture)` emission multiplier

<br />

```lua
batch:clear()
count = batch:getCount()
```
`count` amount of currently inserted particles  

<br />

Set additional settings (all functions have getters too)
```lua
batch:setTexture(tex)
batch:setEmissionTexture(tex)
batch:setSorting(enabled)
batch:setVertical(vertical)
```
`tex` LÖVE drawable  
`enabled` sort particles, only required for textured particles in the alpha pass  
`vertical` 1.0 points to the sky, useful for candles, ...  



# level of detail
Will change, dont use yet.

I'm working on automatic LOD generation, material merge, LOD billboard generation and similar.




# textures
To add textures to the model ...
* name the textures albedo, normal, roughness, metallic, glossiness, specular, emission and put it next to the material (for material library entries) or suffix them with either the material name "material_" or the object name "object_"
* set the texture path in the mtl file, if exported by another software it should work fine
* set the texture path in the mat file (tex_diffuse, tex_normal, tex_emission, ...)
* set the texture manually after loading
* by default 3Dream looks for textures relative to the object path, if not overwritten by the `textures` arg in the model loader
* it does automatically choose the best format and load it threaded when needed. Setting a texture manually prevents this.

* The diffuse texture is a RGB non alpha texture with the color. Alpha channel needs material `setAlpha(true)`.
* The normal texture contains tangential normal coordinates.
* The emission texture contains RGB color.
* Roughness and metallic or specular and glossiness as well as ambient occlusion are single channel textures, however the engine works with combined RMA textures for performance reasons. If not present, 3Dream will generate them and caches them in the love save directory. It is recommended to use them in the final build to avoid heavy (but at least threaded) CPU merge operations, or provide RMA textures in the first place.
* DDS files are supported, but can not generate mipmaps automatically. Also love2ds DDS loader seems to hate mipmaps in DDS files.



## thumbnails
Subject to change. Texture loader will receive together with the final LOD update more features which may change thumbnails.

Name a (smaller) file "yourImage_thumb.ext" to let the texture loader automatically load it first, then load the full textures at the end.

If the automatic thumbnail generator is enabled (true by default), this will be done automatically, but the first load will be without thumbnail.



# data structures
Here is a list of internat data structures. The `.mat` files for example use the same structure of materials.

## object

## subobject

## material



# Shaders
The shader is constructed based on its base shader and additional/optional shader modules.
There are basic default shaders and modules present, so this chapter is advanced usage.

## enable shader module globally
You can enable shaders per object, per subObject and per material. In addition, some shader can (somethimes has to) be global.

```lua
dream:activateShaderModule(name)
dream:deactivateShaderModule(name)
module = dream:getShaderModule(name)
active = dream:isShaderModuleActive(name)
```
`name` shader module name  
`module` shader module  
`active` currently active  



## register own shader
A more tidy docu will be written soon.
For a better understanding in the final shader, look into shaders/base.glsl. This is the skeleton where the modules are imported.
```lua
dream:registerShader(pathToLuaFile)
```



## base shader
This shader does most of the work. Except a few addons (fog, reflections) it works alone.
It's chosen by the objects `shaderType` tag, provided at the object loader and stored in the sub object.

## shader modules
Those modules can extend the shader to add certain effects. For example a rain effect as the one implemeted, the bone modules as one of the more heavy ones, or a burning animation, or a disolving effect, ...



## built-in shader modules
There are a few modules already built in, ready to enable:

### rain
The rain modules renders rain, wetness and splash animations on surfaces.
The render part requires the module to be activated globally.
```lua
dream:activateShaderModule("rain")
dream:getShaderModule("rain").isRaining = true
dream:getShaderModule("rain").strength = 3 -- 1 to 5
```

### wind
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

### bones
3Dream supports animations with a few conditions:
1. it requires a skeleton and skin information, therefore export your object as a COLLADA file (.dae)
2. the bone module needs to be activated: `object:activateShaderModule("bones")` in order to use GPU powered transformations. Theoretical optional but cause heavy CPU usage and GPU bandwidth.
3. update animations as in the skeletal animations specified



# skeletal animations
WIP but should work fine. The COLLADA loader is often confused and needs further tweeking for some exports but should work most of the time.
A vertex can be assigned to multiple joints/bones, but 3Dream only considers the 4 most important ones. The bone module has to be enabled on the object in order to use GPU acceleration.

Returns a pose at a specific time stamp.
```lua
pose = self:getPose(object, time)
pose = self:getPose(object, time, name)
```
`object` object containing skeleton and animation  
`time` time in seconds  
`name ("default")` animation name if split  
`pose` a table containg transformation instructions for each joint  

<br />

Apply this pose (results in object.boneTransforms).
```lua
self:applyPose(object, pose)
```

<br />

Alternative create and apply in one.
```lua
dream:setPose(object, time)
dream:setPose(object, time, name)
```

<br />

Apply joints to mesh, heavy operation, shader module instead recommended.
```lua
dream:applyJoints(object)
```



# 3DO - 3Dream object file
It is recommended to export your objects as 3do files, these files can be loaded on multiple cores, have only ~10-20% loading time compared to .obj, are better compressed and do not need additional files like mtl. They (should) support all features other files have.
To export, just set the argument 'export3do' to true when loading the object. This saves it with the same relative path into the LÖVE save directory. Next time loading the game will use the new file instead. The original files are no longer required.

But note that...
* The exported file needs to be packed into the final game at some point.
* You can not modify 3do files, they contain binary mesh data. Therefore keep the original files!
* The exported 3do is shader dependend, you can not change the used based shader later.



# collisions
The collision extension supports exact collision detection between a collider and another collider or (nested) group.

The second collider/group therefore creates an tree, allowing optimisation and recursive transformations.

A transformation is either a mat4 or a vec3 offset. Transformations with different scales per axis might not work on certain types due to optimisations (e.g. mesh works, spheres do not).

The collision extension is rather slow and relies on proper optimisation of the scene (usage of groups, collision meshes with decreased vertex count, ...). I am working on threaded and C-implementations to increase performance, but do not expect more than a 4x improvement. Just don't overuse them or use a proper library.

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



## collisions in objects
Naming a subobject "COLLISION..." will load it as a collision mesh and removes it from the regular meshes.
Use them to define an abstract representation of your object to save CPU power.
Those collisions are stored in 'object.collisions[name]' similar as regular subObjects.
When loading the entire object, it will only use those special collision meshes.
Theoretically one can pass a specific collision directly.



# 3D sounds
3D sounds with related features like effects (echo, muffled, ...), environmental sounds (birds, river, ...) and similar is a WIP.