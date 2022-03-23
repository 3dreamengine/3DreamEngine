# Objects
3Dream uses classes and objects to represent its data structure. Each class may extend a number of classes.

* Classes
	- [Clone class](#clone)
	- [Shader class](#shader)
	- [Transform class](#transform)
* Objects
	- [Animation](#animation)
	- [Camera](#camera)
	- [Collider](#collider)
	- [Light](#light)
	- [Material](#material)
	- [Mesh](#mesh)
	- [Object](#object)
	- [Particle](#particle)
	- [Pose](#pose)
	- [Reflection](#reflection)
	- [Scene](#scene)
	- [SetSettings](#setsettings)
	- [Shadow](#shadow)
	- [Skeleton](#skeleton)
	- [Task](#task)



## Clone class
The clone class allows to create a clone with shared data but individual transforms or similar.

```lua
c = self:clone()
```
`c` new object  



## Shader class
Sets mesh shaders. Objects pass the calls recursively down to meshes. Mesh shaders override material shaders. See engine chapter for more details.
```lua
self:setPixelShader(shader)
self:setVertexShader(shader)
self:setWorldShader(shader)
```



## Transform class
Sets the transformation of an object.

```lua
self:resetTransform()
self:setTransform(mat4)
self:translate(x, y, z)
self:scale(x, y, z)
self:rotateX(angle)
self:rotateY(angle)
self:rotateZ(angle)
self:setDirection(normal)
self:setDirection(normal, up)
self:getInvertedTransform()
```

```lua
self:setDynamic(dynamic)
dynamic = self:isDynamic(dynamic)
```
`dynamic` flag is set when calling any transformation automatically and affects how often it gets refreshed when using dynamic shadows.



## Animation
An animation is a clip of transformations for each join for a skeleton.
Collada files may contain such animations.
`todo`



## Camera
A custom camera can be used in `dream:present()` if necessary, but usually the default camera in `dream.cam` is sufficiant.

extends `transform`  

```lua
cam = dream:newCamera()
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



## Collider
A collider contains required vertex and normal data to be used as a collision object in the physics extension.
`todo`



## Light
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

light:setAttenuation(a)
a = light:getAttenuation()

light:setSize(size)
size = light:getSize()

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
light:addShadow(res)
```
`res` resolution of shadow map, either cubemap or cascade depending on light typ.  

<br />

Sets/gets the shadow. Theoretically you can share a shadow between lights.
```lua
light:setShadow(shadow)
shadow = light:getShadow()
```
`shadow` valid shadow object  

<br />

To control the godray on that specific source.
```lua
dream:setGodrays(enabled)
dream:setGodrayLength(length)
dream:setGodraySize(size)
```
`enabled (false)` enable this light for the godray pass



## Material
Materials describe the appearance of meshes. For usage information take a look at the engines general documentation.

extends `clone`, `shader`

```lua
material = dream:newMaterial()
```

All functions also have getters too. Colors are multiplied with textures, if provided. If a texture is set it clears the color to white.
```lua
material:setIOR(ior)
material:setDither(enabled)

material:setColor(r, g, b, a)
material:setAlbedoTexture(tex)

material:setRoughness(value)
material:setRoughnessTexture(tex)

material:setMetallic(value)
material:setMetallicTexture(tex)

material:setEmission(r, g, b)
material:setEmissionTexture(tex)

material:setMaterialTexture(tex)

material:setAoTexture(tex)
```
`enabled` enable feature
`tex` LÖVE drawable
`r g b a` color

For performance reasons, roughness, metallic and ambient occlusion is merged into one material image. If avaiable, provide one directly to shorten loading times. Merging is cached.


### Data Structure
```lua
{
	color = {0.5, 0.5, 0.5, 1.0},
	emission = {0.0, 0.0, 0.0},
	roughness = 0.5,
	metallic = 0.0,
	alpha = false,
	discard = false,
	name = "None",
	ior = 1.0,
	translucent = 0.0,
}
```


### Transparent Materials
You have to tell the engine how to render transparent materials.  
`Alpha` enabled will use the Z-sorted second pass and correct blending, if no object intersections occur.
`Translucent` puts light on the backside. Settings translucent via the functions also sets the cullmode to none.  
`Discard` is required if the texture contains an alpha channel, but should not use the alpha pass. Discard is slow on some, usually integrated GPUs.

```lua
material:setAlpha(enabled)
material:setSolid(enabled)
material:setDiscard(enabled)
material:setTranslucent(value)
material:cullMode(cullmode)
```
`cullmode` LÖVE cullmode ("none", "back")  



## Mesh
A mesh is the actual renderable object containing buffers, material and render settings.

Extends `clone`, `shader`

```lua
mesh = dream:newMesh(name, material)
mesh = dream:newMesh(name, material, meshType)
```
`name` the objects name  
`material (Material)` material  
`meshType` the mesh type used to construct the final mesh data, default uses the materials pixel material  

<br />

Returns a mesh with given name, loads it in case it's a 3do object.
```lua
mesh:getMesh(name)
```

<br />

```lua
self:setLOD(min, max)
min, max = self:getLOD()
```
`min` distance before it gets rendered (or `false`)
`max` distance before it gets out of sight (or `false`)

<br />

```lua
self:setVisible(enable)
```
Shortcut for shadow and render pass visibility  
`enable` enabled in all passes  

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



## Object
A container with all meshes, lights, positions, etc.  

Extends `clone`, `transform`, `shader`

```lua
object = dream:newObject()
```

<br />

Pass visibilities down to sub objects and meshes, see Mesh for more details.
```lua
self:setVisible(enable)
self:setRenderVisibility(enable)
self:setShadowVisibility(enable)
self:setFarVisibility(enable)
```



## Particle
`todo`



## Pose
`todo`



## Reflection
A reflection uses a cubemap to render its environment to simulate local reflections.

```lua
reflection = dream:newReflection(static, resolution, roughness, lazy)
```
`static (false)` only render once  
`resolution` resolution, only works with direct render enabled  
`roughness (true)` roughness can be simulated using blurring. If not required, disable it!  
`lazy` lazy rendering spreads the work over several frames  

<br />

```lua
reflection:setLazy(lazy)
lazy = reflection:getLazy()
```

<br />

Rerender it as soon as possible.
```lua
reflection:refresh()
```


### Local Cubemaps
By default cubemaps are treated as infinite cubemaps, working perfect for distant objects. If all objects are close the same AABB bounding box (e.g. a room, hallway, ...) local correction can be applied.

```lua
reflection:setLocal(pos, first, second)
```
`pos` vec3 origin of reflection  
`first` vec3 first, smaller corner of AABB  
`second` vec3 second, larger corner of AABB  

### Planar reflections
WIP, they would make mirrors and water surfaces possible and are faster than cubemap reflections, but cant be static.



## Scene
A scene contains a list of objects to render. They are currently subject to change and will receive a demo project.
The default scene is stored in `dream.scene`.

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



## SetSettings
A canvas set contains the target framebuffers and most of the graphics settings. Default sets are saved in `dream.renderSet`, `dream.reflectionsSet` and `dream.mirrorSet`.

```lua
set = dream:newSetSettings()

canvases = dream:newCanvasSet(set)
canvases = dream:newCanvasSet(set, w, h)
```
`set` settings, no actual data yet  
`canvases` ready to use canvases  

<br />

All of the following functions have a getter too.
```lua
set:setMode(renderMode)
set:setResolution(res)
set:setFormat(format)
set:setMsaa(msaa)
set:setFxaa(enabled)
set:setRefractions(enabled)
set:setAlphaPass(enabled)
```
`renderMode` String
* `direct` fastest, very reduced features, requires set depth canvas via conf.lua. If missing dream will add it
* `lite` fast, reduced features, does not output, but stores result in `canvases.color`
* `normal (default)` full features, slowest

`res (512)` resolution if not specified in `dream:newCanvasSet()`.  
`format ("rgba16f")` LÖVE pixel format.  

`enabled` features:
* MSAA is slower but more beatiful, fxaa is faster but slightly blurry. Dont use both.
* refractions simulate refractions for objects in the alpha pass for `ior ~= 1.0`
* alpha pass can be disabled entirely, increasing performance a bit. Disable if no object use the second pass anyways.



## Shadow
A shadow can be attached to a lightsource.

```lua
dream:newShadow(typ, resolution)
```
`typ` "point" or "sun"
`resolution` resolution, optional

<br />

Static shadows are only rendered once, if not moved or refreshed manually.
```lua
shadow:setStatic(static)
static = shadow:isStatic()
```
<br />

Because static shadows limits shadow mapping to static objects, the alternative dynamic rendering (by default enabled) can be used. Both static and dynamic objects are rendered on seperate channels. This allows dynamic shadows while still making use of static performance. You can not set both dynamic and static flag. You can however set both to false to enforce classic shadowmapping without any fancy stuff.
```lua
shadow:setDynamic(dynamic)
smooth = dynamic:isDynamic()
```
<br />

Smoothing increases quality by performing a post-blur on the shadow map. While this produces beatiful results, it may also cause artifacts and slow performance if non-dynamic and non-static mode is chosen.
If dynamic mode is chosen, the dynamic shadows are not blurred.
The blurring can be controlled by the light objects size.
```lua
shadow:setSmooth(b)
smooth = shadow:isSmooth()
```
<br />

Controls the cascade shadow for sun shadows
```lua
shadow:setCascadeDistance(8)
shadow:setCascadeFactor(4)
```

<br />

Lazy mode spreads the work across several frames. May cause self-shadowing artifacts but tends to be a lot faster.
```lua
shadow:setLazy()
```

<br />

Sets the max distance the sun light can move without re-rendering the static part. Change if artefacts occur, especially when changing the distance of shadow cascades.
```lua
shadow:setRefreshStepSize(step)
step = shadow:getRefreshStepSize()
```
`step (1)` distance in units to update first cascade. Second cascade at 2.3 * step and third cascade at 2.3^2 * step. This wierd scales ensure that the distribution of re renders are more even.



## Skeleton
A skeleton contains joints and required mappings to transform an corresponding skin (mesh with joint buffers).



## Task
A task is a small class containing a scene entry ready to draw. It's an internal structure so I skip further documentation here.