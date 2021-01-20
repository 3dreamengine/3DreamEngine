# settings
Most settings require `dream:init()` to be called afterwards.

- [Default shader](#default-shader)
- [max Lights](#max-lights)
- [name Decoder](#name-decoder)
- [frustum](#frustum)
- [LOD Distance](#lod-distance)
- [dither](#dither)
- [exposure](#exposure)
- [auto Exposure](#auto-exposure)
- [gamma](#gamma)
- [screen space ambient occlusion](#screen-space-ambient-occlusion)
- [bloom](#bloom)
- [fog](#fog)
- [rainbow](#rainbow)
- [shadows](#shadows)
- [sun](#sun)
- [daytime](#daytime)
- [weather](#weather)
- [sky](#sky)
- [clouds](#clouds)
- [base reflection](#base-reflection)
- [resource loader](#resource-loader)

## default shader
Sets the default shader, false to choose between textured Phong and simple Phong.

```lua
dream:setDefaultShaderType(typ)
typ = dream:getDefaultShaderType()
```
`typ (false)` valid shader type or false  



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
`enabled (true)` enable frusutm plane based checks



## LOD Distance
The distance at which the highest LOD level will be used

```lua
dream:setLODDistance(distance)
distance = dream:getLODDistance()
```
`distance (100)` distance in meter  



## dither
Depth testing and alpha gradients do not like each other. You can choose between dithering or a fixed 0.5 threshold. Heavily depends on your scene, and can be enabled per material for more control.

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
dream:setSunShadow(enabled, static)
enabled, static = dream:getSunShadow()
```
`enabled (true)` If the automatic generated sun light object should receive a shadow. 
`static ("dynamic")` The static level, look up the static description in the shadow class. 



## sun
Sets the position of the sun (done automatically by 'dream:setDaytime()'

```lua
dream:setSunDir(direction)
direction = dream:getSunDir()
```
`direction` vec3 direction of the sun  

<br />

```lua
dream:setSunOffset(offset, rotation)
offset, rotation = dream:getSunOffset()
```
`offset` offset where 0 is the equator and 1 the north pole when using 'dream:setDaytime()'  
`rotation` the rotation on the Y axis  



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

<br />

```lua
dream:setCloudsStretch(stretch, stretch_wind, angle)
stretch, stretch_wind, angle = dream:getCloudsStretch()
```
`stretch` stretch strength  
`stretch_wind` stretch strength based on wind  
`angle` angle offset  

<br />

```lua
dream:setUpperClouds(enabled, density, rotation)
enabled, density, rotation = dream:setUpperClouds()
```
`enabled (true)`   
`density (0.5)` density multiplier  
`rotation (0.01)` rotation effect  



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

<br />

Godrays simulate shadow shafts in (dusty) air. Other than volumetric rendering, this is a very fast, multi light source implementation.
Max source count is currently hardcoded to 8. Settings are hardcoded and will receive appropiate setters soon.

```lua
dream:setGodrays(false)
dream:setGodrays(quality, allSources)
enabled, quality, allSources = dream:getGodrays()
```
`enabled (true)` if the godray pass is active 
`quality (16)` the samples used to determine occlusion 
`allSources (false)` if not manually set per source, only sun objects receive godrays 