# functions
- [Init](#init)
- [Load Object](#load-object)
- [Load Scene](#load-scene)
- [Object Library](#object-library)
- [Update](#update)
- [Prepare](#prepare)
- [Draw](#draw)
- [Draw Particle](#draw-particle)
- [Present](#present)
- [Utils](#utils)



## Init
Applies settings, reload canvases, ...  
Needs to be called after changing settings or resizing the screen.  

```lua
dream:init()
```


<br />

## Load Object
Loads an object containing renderable meshes, positions, bone data and similar.  

```lua
yourObject = dream:loadObject(path)
yourObject = dream:loadObject(path, args)
```

`path` The path of the object without extension. Supported are currently .obj, .dae, .vox and the custom .3do  
`args` a table of additional settings on how to load the object.  


* `mesh (true)` create a mesh after loading
* `particlesystems (true)` generate particlesystems as defined in the material
* `cleanup (true)` deloads raw buffers (positions, normals, ...) after finishing loading
* `export3do (false)`loads the object as usual, then export the entire object as a 3DO file
* `animations (nil)` when using COLLADA format, split the animation into `{key = {from, to}}`, where `from` and `to` are timestamps in seconds
* `decodeBlenderNames (true)` remove the vertex objects postfix added on export, e.g. `name` instead of `name_Cube`

### Tags
The mesh name may contain additional tags, denoted as `TAG:VALUE_` or `TAG_`

* `POS:name` treats it as position
* `PHYSICS:type` treats it as a collider
* `LOD:level` set lod, starting at 0
* `LINK:name` replace this object with an library entry
* `RAYTRACE` treat as raytrace, puts it into 
* `REFLECTION` treat as reflection (WIP)
* `REMOVE` removes, may be used for placeholder or reference objects
* `SHADOW:FALSE` disabled shadow


<br />

## Load Scene
Loads an object but creates sub objects, grouping together objects with the same name. This is usually the way to go, especially since several materials need to be different meshes (done by COLLADA automatically), but they should be treated as one object.

```lua
yourScene = dream:loadScene(path)
yourScene = dream:loadScene(path, args)
```

For example, exporting a blender project with 3 objects `tree`, `tree.002` and `rock.43`, the sub objects are `tree` and `rock`, with the respective meshes inside.


<br />

## Update
Required for loading threaded textures, 3do files, ...
```lua
work = dream:update()
```
`work` if something has been loaded this call.  


<br />

## Object Library
To reuse data efficiently, objects can be linked by using the `LINK:libraryEntry` tag. Before that, the object needs to be registered.

Common use case is a world file (e.g. in blender), using simplified models (e.g. trees) to mark their positions. The actual model, maybe with LODs, scripts or similar are then inserted while loading, saving memory and loading time.

```lua
dream:registerObject(object, name)
```

Load a scene and register it.
```lua
dream:loadLibrary(path, args, prefix)
```


<br />

## Prepare
Prepare for rendering by clearing all batches and queues.
```lua
dream:prepare()
```


<br />

## Draw
Adds an object or sub object to the default scene to render.
```lua
dream:draw(obj)
dream:draw(obj, x, y, z)
dream:draw(obj, x, y, z, sx, sy, sz)
```
`obj` object or subobject  
`x y z` position  
`sx sy sz` scale  


<br />

## Draw Particle
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



## Present
Finish render session, it is possible to render several times per frame but then use presentLite() since present() also renders sub tasks
```lua
dream:present(cam, canvases, lite)
```
`cam (dream.cam)` custom cam  
`canvases (dream.canvases)` custom canvas set  
`lite (false)` do not perform job updating, set this to true when using present several times per frame  


## Utils
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