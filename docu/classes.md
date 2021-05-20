# objects
3Dream uses objects to represent its data structure. Each object may extend a number of classes. Classes can not have instances.

* classes
	- [transform class](#transform)
	- [visibility class](#visibility)
	- [clone class](#clone)
	- [shader class](#shader)
* objects
	- [object](#object)
	- [subObject](#subobject)
	- [camera](#camera)
	- [light](#light)
	- [shadow](#shadow)
	- [reflection](#reflection)
	- [scene](#scene)
	- [setSettings](#setsettings)
	- [materials](#materials)
	- [tasks](#tasks)

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

```lua
self:setDynamic(dynamic)
dynamic = self:isDynamic(dynamic)
```
`dynamic` is set when calling any transformation automatically and affects how often it gets refreshed when using dynamic shadows.



## visibility class
Sets LODs and pass visibility.

```lua
self:setLOD(map)
map = self:getLOD()
```
`map` subject to change

<br />

```lua
self:setRenderVisibility(enable)
enable = self:getRenderVisibility()
```
`enable` enabled in default render pass  

<br />

```lua
self:setShadowVisibility(enable)
enable = self:getShadowVisibility()
```
`enable` enabled in default shadow pass  

<br />

```lua
self:setFarVisibility(enable)
enable = self:getFarVisibility()
```
`enable` draw in cascade level > 1. Disable for small objects to achieve higher sun shadow performance.



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
loaded = self:isLoaded()
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
light = dream:newLight(typ, pos, color, brightness)
```
`light` a new light object, without shadow  
`typ ("point")` a light type  
`pos (vec3(0, 0, 0))` initial position  
`color (vec3(1, 1, 1))` initial color  
`brightness (1)` initial brightness  

<br />

change light data. If you want to modify the sun, update `dream.sunObject` after `resetLight`, since `resetLight` overwrites the sun object with data. 
```lua
light:setBrightness(b)
b = light:getBrightness()

light:setColor(r, g, b)
light:setColor(vec3)
vec3 = light:getColor()

light:setPosition(x, y, z)
light:setPosition(vec3)
vec3 = light:getPosition()

light:setDirection(x, y, z)
light:setDirection(vec3)
vec3 = light:getDirection()
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

<br />

To control the godray on that specific source.
```lua
dream:setGodrays(enabled)
dream:setGodrayLength(length)
dream:setGodraySize(size)
```
`enabled (nil)` enable this light for the godray pass, nil uses the default set by the global setting. 



## shadow
A shadow can be attached to a lightsource.

```lua
dream:newShadow(typ, static, res)
```
`typ` "point" or "sun"
`static` 
- 'false' render realtime (slow, not recommended) 
- 'true' render once, sun will updates on position (with respective step size) or direction changes 
- 'dynamic' (default) render once, then render all dynamics realtime. Much faster than no static with minor memory impact. 
`res` resolution

<br />

Refresh the shadow as soon as possible (relevant for static shadows)
```lua
shadow:refresh()
```

<br />

Sets the max distance the sun light can move without re-rendering the static part. Change if artefacts occur, especially when changing the distance of shadow cascades.
```lua
shadow:setRefreshStepSize(step)
step = shadow:getRefreshStepSize()
```
`step (1)` distance in units to update first cascade. Second cascade at 2.3 * step and third cascade at 2.3^2 * step. This wierd scales ensure that the distribution of re renders are more even.



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
set:setMode(renderMode)
set:setResolution(res)
set:setFormat(format)
set:setPostEffects(enabled)
set:setMsaa(msaa)
set:setFxaa(enabled)
set:setRefractions(enabled)
set:setAlphaPass(enabled)
```
`renderMode` String
* `direct` fastest, very reduced features, requires set depth canvas via conf.lua. If missing it will add it, causing a short flicker, sets format to rgb8
* `lite` fast, reduced features, does not output, but stores result on `canvases.color`, sets format to rgb8
* `normal` full features, default, sets to rgba16f HDR canvas.

`res (512)` resolution if not specified in `dream:newCanvasSet()`.  
`format ("rgba16f")` LÖVE pixel format.  

`enabled` features:
* post effects are effects like exposure, bloom, ... which are unwanted for temporary results (e.g. reflections)
* msaa is slower but more beatiful (consider hardware limit), fxaa is faster but blurry. Dont use both.
* refractions simulate refractions for objects in the alpha pass and ior ~= 1.0
* alpha pass can be disabled entirely, increasing performance a bit. Disable if no object use the second pass anyways.




## materials
Materials can be either per object by providing a .mtl or .mat file with the same name as the object file or they can be in a global material library, in which case they got chosen first.

extends `clone`, `shader`

Load materials into the library. If an objects now requires a material, it will first look into the library.

A material library looks for material files (.mat) or for directory containing material.mat or at least one texture, linking them automatically. See for example the Tavern demo.

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

material:setColor(r, g, b, a)
material:setAlbedoTex(tex)

material:setEmission(r, g, b)
material:setEmissionTex(tex)

material:setGlossiness(value)
material:setGlossinessTex(tex)

material:setSpecular(value)
material:setSpecularTex(tex)

material:setRoughness(value)
material:setRoughnessTex(tex)

material:setMetallic(value)
material:setMetallicTex(tex)
```
`enabled` enable feature
`tex` LÖVE drawable
`r g b a` color


### data structure
```lua
{
	color = {0.5, 0.5, 0.5, 1.0},
	glossiness = 0.1,
	specular = 0.5,
	emission = {0.0, 0.0, 0.0},
	roughness = 0.5,
	metallic = 0.0,
	alpha = false,
	discard = false,
	name = "None",         --name, used for texture linking
	dir = dir,             --directory, used for texture linking
	ior = 1.0,
	translucent = 0.0,
	onFinsh = function(mat, obj)
		//calls itself once after loading the object, or after adding to the material library, in which case obj is nil
	end
}
```


### transparent materials
You have to tell the engine how to render this material.  
`Alpha` enabled will use the Z-sorted second pass.
`Translucent` puts light on the backside. Settings translucent via the functions also sets the cullmode to none.  
`Discard` is required if the texture contains an alpha channel, but should not use the alpha pass. Discard is slow on some, usually weaker, systems.
```lua
material:setAlpha(enabled)
material:setSolid(enabled)
material:setDiscard(enabled)
material:setTranslucent(value)
material:cullMode(cullmode)
```
`cullmode` LÖVE cullmode ("none", "back")  



## tasks
A task is a small class containing a scene entry ready to draw. It's not intended to be used directly so I skip further documentation here.