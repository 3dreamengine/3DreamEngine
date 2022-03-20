# settings
Most settings require `dream:init()` to be called afterwards.

- [Frustum](#frustum)
- [LOD Distance](#lod-distance)
- [Exposure](#exposure)
- [Auto Exposure](#auto-exposure)
- [Gamma](#gamma)
- [SSAO](#ssao)
- [Bloom](#bloom)
- [Fog](#fog)
- [Shadows](#shadows)
- [Sky](#sky)
- [Default Reflection](#default-reflection)
- [Resource Loader](#resource-loader)
- [Godrays](#godrays)
- [Disortion Margin](#disortion-margin)



## Frustum
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
dream:setAutoExposure(target, speed)
enabled, target, speed = dream:getAutoExposure()
```
`target` 0.25 is default.  
`speed` is the adaption speed, 1.0 is default.  
A single bool can either disabled or enable with default values.



## Gamma
Gamma correction is already applied, therefore default is 1.0. Disabled by default.

```lua
dream:setGamma(gamma)
gamma = dream:getGamma()
```
`gamma` can be a number or false.  



## SSAO
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

<br />

```lua
dream:setFogHeight()
dream:setFogHeight(min, max)
min, max = dream:getFogHeight()
```
`min (1)` lower, full-fog plane height. Nil/false sets fog constant.  
`max (-1)` higher, no-fog plane height. When smaller than min, fog is constant.  


## Shadows
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




## Sky
The sky renders behind all objects and if used on the default reflection cubemap.

```lua
dream:setSky(texture)
dream:setSky(texture, exposure)
texture, exposure = dream:getSky()
```
`texture (true)`  
Texture can be:
* true to use sky dome
* false to no clear at all
* a color
* cubemap (will set `dream:setReflection(cubemap) too as this is faster and the same result`)
* HDRI image (in combination with `setReflection(true)` bad because of unnesessary HDRI to cubemap render)
* a function with signature `(dream, transformProj, camTransform)` rendering to the already set canvas



## Default Reflection
Diffuse lighting and reflections fall back to this value if not specified otherwise.

```lua
dream:setDefaultReflection(texture)
texture = dream:getDefaultReflection()
```
`texture (true)`  
Texture can be:
* `true` to use sky dome as base reflection
* `false` to use ambient color only
* a reflection object
* a cubemap (requires custom mipmaps as specified in the reflections chapter)

The cubemap needs prepared mipmaps when using glossy reflections. Therefore, create the cube map with mipmaps set to `manual` and run following code to generate proper mipmaps (`dream:take3DScreenshot()` does that automatically):
```lua
for level = 2, yourCubeMap:getMipmapCount() do
	self:blurCubeMap(yourCubeMap, level)
end
```



### Sky Reflection
If the base reflection is true following settings affects how the sky dome is rendered.
```lua
dream:setSkyReflectionFormat(resolution, format, lazy)
resolution, format = dream:getSkyReflectionFormat()
```
`resolution (512)` cubemap resolution 
`format ("rgba16f")` cubemap format, HDR by default  
`lazy (false)` spread work over several frames  



## Resource Loader
The resource loader can load textures threaded to avoid loading times or lags.

```lua
dream:setResourceLoader(threaded)
threaded = dream:getResourceLoader()
```
`threaded (true)` use several cores to load images in the background  

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

## Godrays
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

<br />

## Disortion Margin
Alpha pass distortion is a post effect and relys on what is on screen.
A distortion margin smoothly fades out on the borders.

```lua
dream:setDistortionMargin(fade)
fade = dream:getDistortionMargin()
```
`fade (2.0)` 1.0 is over the full screen, 4.0 a quarter, ... 