# functions
- [init](#init)
- [load object](#load-object)
- [update](#update)
- [prepare](#prepare)
- [draw](#draw)
- [draw particle](#draw-particle)
- [present](#present)
- [utils](#utils)
- [skeletal animations](#skeletal-animations)

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
* `noMesh` load vertex information but do not create a final mesh - template objects etc
* `noParticleSystem` prevent the particle system from being generated
* `cleanup` the level of cleanup after the objects have been loaded. false deloads * `nothing. nil (default) deloads all buffers except faces and vertex positions. true deloads * `everything.
* `export3do`loads the object as usual, then export the entire object inclusive * `animations, collisions, positions and similar as a 3DO file. See 3DO chapter for use cases
* `export3doVertices`vertices are not included by default, since they are bulky and unecessary unless converting an object to a collision. While not recommended, you can force vertices and edge data to be included.
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



## skeletal animations
WIP but should work fine. The COLLADA loader is often confused and needs further tweeking for some exports but should work most of the time.
A vertex can be assigned to multiple joints/bones, but 3Dream only considers the 4 most important ones.
The bone module has to be enabled on the object in order to use GPU acceleration.

Returns a pose at a specific time stamp.
```lua
pose = dream:getPose(object, time)
pose = dream:getPose(object, time, name)
```
`object` object containing skeleton and animation  
`time` time in seconds  
`name ("default")` animation name if split  
`pose` a table containg transformation instructions for each joint  

<br />

Apply this pose (results in object.boneTransforms).
```lua
dream:applyPose(object, pose)
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