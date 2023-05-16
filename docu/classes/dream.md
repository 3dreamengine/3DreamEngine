# Dream
The main class
## Methods
### `Dream:newAnimation(frameTable)`
Creates a new, empty animation from a dictionary of joint names and animation frames
#### Arguments
`frameTable` (<string, [AnimationFrame](https://3dreamengine.github.io/3DreamEngine/docu/classes/animationframe)[]>) 

#### Returns
([Animation](https://3dreamengine.github.io/3DreamEngine/docu/classes/animation)) 


_________________

### `Dream:newAnimationFrame(time, position, rotation, scale)`
Creates a new frame in an animation
#### Arguments
`time` (number) 

`position` (Vec3) 

`rotation` (Quat) 

`scale` (number) 


_________________

### `Dream:newBone(id, transform)`
Creates a new bone with given initial transform
#### Arguments
`id` (string) 

`transform` (Mat4) 

#### Returns
([Bone](https://3dreamengine.github.io/3DreamEngine/docu/classes/bone)) 


_________________

### `Dream:newBoundingSphere(center, size)`
Creates a new bounding sphere
#### Arguments
`center` (Vec3)  optional

`size` (number)  optional


_________________

### `Dream:newBufferFromArray(array)`
Converts given float array into a buffer
#### Arguments
`array` (number[]) 

#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

### `Dream:newBufferLike(buffer)`
New empty buffer with the same memory layout as the existing buffer
#### Arguments
`buffer` ([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 

#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

### `Dream:bufferFromString(type, dataType, str)`
New Buffer from string
#### Arguments
`type` (string)  "vec2", "vec3", "vec4", or "mat4"

`dataType` (string)  C type, e.g. "float"

`str` (string) 

#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

### `Dream:newBuffer(type, dataType, length)`
New compact data buffer
#### Arguments
`type` (string)  "vec2", "vec3", "vec4", or "mat4"

`dataType` (string)  C type, e.g. "float"

`length` (number) 

#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

### `Dream:newCamera(transform, transformProj, position, normal)`
Creates a new camera
#### Arguments
`transform` (Mat4) 

`transformProj` (Mat4) 

`position` (Vec3) 

`normal` (Vec3) 

#### Returns
([Camera](https://3dreamengine.github.io/3DreamEngine/docu/classes/camera)) 


_________________

### `Dream:newCanvases()`
Creates a new set of canvas outputs
#### Returns
([Canvases](https://3dreamengine.github.io/3DreamEngine/docu/classes/canvases)) 


_________________

### `Dream:newCollisionMesh(mesh, shapeMode)`
A new collision mesh, containing only relevant data for a collider
#### Arguments
`mesh` ([CollisionMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/collisionmesh)) 

`shapeMode` (string) 


_________________

### `Dream:newDynamicBuffer()`
A dynamic buffer is a slower, more dynamic lua array implementation
#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

### `Dream:newGlyphAtlas(margin)`
Creates new glyph atlas
#### Arguments
`margin` (number)  Size of margin around each character. You need at least 2^mipmapping levels of margin for no bleeding artifacts.

#### Returns
([GlyphAtlas](https://3dreamengine.github.io/3DreamEngine/docu/classes/glyphatlas)) 


_________________

### `Dream:newInstancedMesh(mesh)`

#### Arguments
`mesh` ([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh))  The source mesh to create instances from

#### Returns
([InstancedMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/instancedmesh)) 


_________________

### `Dream:newLight(typ, position, color, brightness)`
Creates new light source
#### Arguments
`typ` (string)  "point" or "sun"

`position` (Vec3) 

`color` (number[]) 

`brightness` (number) 

#### Returns
([Light](https://3dreamengine.github.io/3DreamEngine/docu/classes/light)) 


_________________

### `Dream:newMaterial(name)`
Creates an empty material
#### Arguments
`name` (string) 

#### Returns
([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 


_________________

### `Dream:newMesh(material)`
Creates a new empty mesh
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 

#### Returns
([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)) 


_________________

### `Dream:newMeshBuilder(material)`
Creates a new mesh builder
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 

#### Returns
([MeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshbuilder)) 


_________________

### `Dream:newMeshFormat(vertexFormat)`
Creates a new mesh format
#### Arguments
`vertexFormat` (table)  A vertex format as specified in https://love2d.org/wiki/love.graphics.newMesh

#### Returns
([MeshFormat](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshformat)) 


_________________

### `Dream:newMutableMeshBuilder(material)`
Creates a new mutable mesh builder
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 

#### Returns
([MutableMeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/mutablemeshbuilder)) 


_________________

### `Dream:newLinkedObject()`
`deprecated`  

#### Returns
([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)) 


_________________

### `Dream:newObject()`
Create an empty object
#### Returns
([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)) 


_________________

### `Dream:newPosition(position, size, value)`

#### Arguments
`position` (Vec3) 

`size` (number) 

`value` (string) 

#### Returns
([Position](https://3dreamengine.github.io/3DreamEngine/docu/classes/position)) 


_________________

### `Dream:newRaytraceMesh(mesh)`

#### Arguments
`mesh` ([RaytraceMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/raytracemesh)) 


_________________

### `Dream:newReflection()`

#### Returns
([Reflection](https://3dreamengine.github.io/3DreamEngine/docu/classes/reflection)) 


_________________

### `Dream:newShader(path)`

#### Arguments
`path` (string) 

#### Returns
([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `Dream:newShadow(typ, resolution)`
Creates a new shadow
#### Arguments
`typ` (string)  "sun" or "point"

`resolution` (number) 

#### Returns
([Shadow](https://3dreamengine.github.io/3DreamEngine/docu/classes/shadow)) 


_________________

### `Dream:newSkeleton(root)`
New skeleton from a hierarchical bone structure
#### Arguments
`root` ([Bone](https://3dreamengine.github.io/3DreamEngine/docu/classes/bone)) 

#### Returns
([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton)) 


_________________

### `Dream:newSprite(texture, emissionTexture, normalTexture, quad)`
Creates a new sprite, that is, a textured quad mesh
#### Arguments
`texture` (Texture)  optional

`emissionTexture` (Texture)  optional

`normalTexture` (Texture)  optional

`quad` (Quad)  optional

#### Returns
([Sprite](https://3dreamengine.github.io/3DreamEngine/docu/classes/sprite)) 


_________________

### `Dream:newSpriteBatch(texture, emissionTexture, normalTexture)`
Creates a new sprite batch
#### Arguments
`texture` (Texture)  optional

`emissionTexture` (Texture)  optional

`normalTexture` (Texture)  optional


_________________

### `Dream:newTextMeshBuilder(glyphAtlas)`
Creates a text mesh builder
#### Arguments
`glyphAtlas` ([GlyphAtlas](https://3dreamengine.github.io/3DreamEngine/docu/classes/glyphatlas)) 

#### Returns
([TextMeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/textmeshbuilder)) 


_________________

### `Dream:lookAt(eye, at, up)`
Returns the look-at transformation matrix
#### Arguments
`eye` (Vec3) 

`at` (Vec3) 

`up` (Vec3)  default vec3(0.0, 1.0, 0.0)


_________________

### `Dream:HSVtoRGB(h, s, v)`
HSV to RGB
#### Arguments
`h` (number) 

`s` (number) 

`v` (number) 


_________________

### `Dream:RGBtoHSV(r, g, b)`
RGB to HSV
#### Arguments
`r` (number) 

`g` (number) 

`b` (number) 


_________________

### `Dream:pointToPixel(point, camera, canvases)`
Convert a 3D point to 2D screen coordinates
#### Arguments
`point` (Vec3) 

`camera` ([Camera](https://3dreamengine.github.io/3DreamEngine/docu/classes/camera)) 

`canvases` ([Canvases](https://3dreamengine.github.io/3DreamEngine/docu/classes/canvases)) 


_________________

### `Dream:pixelToPoint(point, camera, canvases)`
Convert 3D screen coordinates to 3D point, if the depth is unknown pass 1
#### Arguments
`point` (Vec3) 

`camera` ([Camera](https://3dreamengine.github.io/3DreamEngine/docu/classes/camera)) 

`canvases` ([Canvases](https://3dreamengine.github.io/3DreamEngine/docu/classes/canvases)) 


_________________

### `Dream:getBarycentric(x, y, x1, y1, x2, y2, x3, y3)`
Gets the barycentric coordinates of a point given the three vertices of a triangle
#### Arguments
`x` (number) 

`y` (number) 

`x1` (number) 

`y1` (number) 

`x2` (number) 

`y2` (number) 

`x3` (number) 

`y3` (number) 


_________________

### `Dream:blurCanvas(canvas, strength, iterations, mask)`
Two-pass Gaussian blur
#### Arguments
`canvas` (Canvas) 

`strength` (number) 

`iterations` (number) 

`mask` (table)  optional


_________________

### `Dream:blurCubeMap(cube, layers, strength, mask, blurFirst)`
Blur a cubemap close to realtime
#### Arguments
`cube` (Canvas) 

`layers` (number) 

`strength` (number) 

`mask` (table)  optional

`blurFirst` (boolean) already blur the first layer, as usually used for ambient lighting maps


_________________

### `Dream:takeScreenshot()`
Takes a threaded screenshot and saves it into the screenshot directory in the saves directories

_________________

### `Dream:take3DScreenshot(pos, resolution, path)`
Takes a 3D screenshot and saves it as a custom CIMG cubemap image with pre blurred reflection mipmaps, may be used for static reflection globes
#### Arguments
`pos` (Vec3) 

`resolution` (number) 

`path` (string) 


_________________

### `Dream:HDRItoCubemap(hdri, resolution)`
Converts a 2:1 HDRI to a 1:6 flattened cubemap
#### Arguments
`hdri` (Drawable) 

`resolution` (number) 

#### Returns
(Canvas) 


_________________

### `Dream:resize(w, h)`
Reload canvases
#### Arguments
`w` (number) 

`h` (number) 


_________________

### `Dream:init(w, h)`
Applies settings and load canvases
#### Arguments
`w` (number) 

`h` (number) 


_________________

### `Dream:prepare()`
Clears the current scene

_________________

### `Dream:draw(object, x, y, z, sx, sy, sz)`
draw
#### Arguments
`object` ([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object), [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)) 

`x` (number) 

`y` (number) 

`z` (number) 

`sx` (number) 

`sy` (number) 

`sz` (number) 


_________________

### `Dream:draw(object)`
draw
#### Arguments
`object` ([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object), [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)) 


_________________

### `Dream:addLight(light)`
Add a light
#### Arguments
`light` ([Light](https://3dreamengine.github.io/3DreamEngine/docu/classes/light)) 


_________________

### `Dream:addNewLight(typ, position, color, brightness)`
Add a new simple light
#### Arguments
`typ` (string) 

`position` (Vec3) 

`color` (Vec3) 

`brightness` (number) 


_________________

### `Dream:loadLibrary(path, args, prefix)`
Loads and adds that object as a library, see https://3dreamengine.github.io/3DreamEngine/docu/introduction
#### Arguments
`path` (any) 

`args` (any) 

`prefix` (any) 


_________________

### `Dream:registerObject(object, name)`
Register object in the object library. Objects loaded with the `LINK` tag are then replaced with the entry from the library
#### Arguments
`object` ([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)) 

`name` (string) 


_________________

### `Dream:loadScene(path, args)`
Loads an scene, see https://3dreamengine.github.io/3DreamEngine/docu/introduction
#### Arguments
`path` (any) 

`args` (any) 


_________________

### `Dream:loadObject(path, args)`
Load an object
#### Arguments
`path` (string)  Path to object without extension

`args` (table) 


_________________

### `Dream:registerMaterial(material, name)`
Registers a material to the material library. Materials in loaded objects with the same name then use this one. Multiple registered aliases are valid.
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 

`name` (string)  optional


_________________

### `Dream:loadMaterialLibrary(path, prefix)`
Looks for mat files or directories with an albedo texture
#### Arguments
`path` (any) 

`prefix` (any) 


_________________

### `Dream:present(camera, canvases, lite)`
Render or present the scene, depending on the canvas settings
#### Arguments
`camera` ([Camera](https://3dreamengine.github.io/3DreamEngine/docu/classes/camera))  defaults to internal camera `dream.camera`

`canvases` ([Canvases](https://3dreamengine.github.io/3DreamEngine/docu/classes/canvases))  defaults to internal canvases `dream.canvases`

`lite` (boolean)  when lite is enabled, no side tasks like shadow or reflection generations are executed


_________________

### `Dream:getLoaderThreadUsage()`
Returns statistics of the loader threads
#### Returns
(number, number, number)  todo, in progress, awaiting upload to GPU


_________________

### `Dream:update()`
Updates active resource tasks (mesh loading, texture loading, ...)

_________________

### `Dream:clearLoadedTextures()`
Clear all loaded textures, releasing VRAM but forcing a reload when used

_________________

### `Dream:getImagePath(path)`
Get image path if present
#### Arguments
`path` (string)  Slash separated path without extension to image

#### Returns
(string) 


_________________

### `Dream:getImagePaths()`
Returns a dictionary, mapping every image without extension to its best file with extension
#### Returns
(<string, string>) 


_________________

### `Dream:getImage(path, force)`
Get a texture, load it threaded if enabled and therefore may return nil first
#### Arguments
`path` (any) 

`force` (any) 


_________________

### `Dream:combineTextures(metallic, roughness, AO)`
Lazily combine 3 textures to use only one texture
#### Arguments
`metallic` (string)  path

`roughness` (string)  path

`AO` (string)  path


_________________

### `Dream:setMaxLights(count)`
Sets the max count of simple light sources
#### Arguments
`count` (number) 


_________________

### `Dream:getMaxLights()`


_________________

### `Dream:setFrustumCheck(enable)`
Set frustum check
#### Arguments
`enable` (boolean) 


_________________

### `Dream:getFrustumCheck()`


_________________

### `Dream:setLODDistance(distance)`
Sets the distance of the lowest LOD level
#### Arguments
`distance` (number) 


_________________

### `Dream:getLODDistance()`


_________________

### `Dream:setExposure(enable)`
`deprecated`  
Sets whether tone-mapping should be applied, deprecated
#### Arguments
`enable` (boolean) 


_________________

### `Dream:getExposure()`
`deprecated`  


_________________

### `Dream:setAutoExposure(target, speed)`
Toggle auto exposure
#### Arguments
`target` (number)  target average screen brightness, default 0.3 when `true`

`speed` (number)  speed of adaption, default 1.0


_________________

### `Dream:setAutoExposure(target)`
Toggle auto exposure
#### Arguments
`target` (number)  target average screen brightness, default 0.3 when `true`


_________________

### `Dream:getAutoExposure()`


_________________

### `Dream:setGamma(gamma)`
Sets the screen gamma
#### Arguments
`gamma` (number) 


_________________

### `Dream:getGamma()`


_________________

### `Dream:setAO(samples, resolution, blur)`
Sets the Screen Space Ambient Occlusion settings
#### Arguments
`samples` (number)  more samples result in less visible patterns/artifacts

`resolution` (number)  resolution factor of temporary canvas

`blur` (number)  strength of blur and size of occlusion


_________________

### `Dream:getAO()`
Get the state of ambient occlusion
#### Returns
(boolean, number, number)  enabled, quality, resolution


_________________

### `Dream:setBloom(quality, resolution, size, strength)`
Bloom effect settings
#### Arguments
`quality` (number)  blurring iterations

`resolution` (number)  default 0.5

`size` (number)  default 0.1

`strength` (number)  default 1.0


_________________

### `Dream:getBloom()`
Get the state of bloom
#### Returns
(boolean, number, number, number, number)  enabled, quality, resolution, size, strength


_________________

### `Dream:setFog(density, color, scatter)`
Depth based fog
#### Arguments
`density` (number) 

`color` (Vec3) 

`scatter` (number)  Light scatter effect on sun light


_________________

### `Dream:getFog()`
Get the state of fog
#### Returns
(boolean, number, Vec3, number)  enabled, density, color, scatter


_________________

### `Dream:setFogHeight(min, max)`
Fog height, where min is full density and max zero density, Y-aligned
#### Arguments
`min` (number) 

`max` (number) 


_________________

### `Dream:getFogHeight()`
Get the height, or (1, -1) if disabled
#### Returns
(number, number)  min and max


_________________

### `Dream:setDefaultReflection(texture)`
Sets the reflection type used for reflections, "sky" uses the Sky dome and only makes sense when using an animated, custom dome. Texture can be a 2D HDRi or a CubeImage, or an 3Dream Reflection object
#### Arguments
`texture` (Texture, [Reflection](https://3dreamengine.github.io/3DreamEngine/docu/classes/reflection), boolean, string) 


_________________

### `Dream:getDefaultReflection()`


_________________

### `Dream:setSkyReflectionFormat(resolution, format, lazy)`
Set settings for sky reflection, if "sky" is used
#### Arguments
`resolution` (number) 

`format` (number) 

`lazy` (boolean)  Update texture over several frames to spread the load


_________________

### `Dream:getSkyReflectionFormat()`


_________________

### `Dream:setSky(sky, exposure)`
Sets the sky HDRI, cubemap or just sky dome
#### Arguments
`sky` (table)  rgb color

`sky` (boolean)  false to disable sky, use in enclosed areas

`sky` (Texture)  2D HDRI or Cubemap

`sky` (callable)  a custom function

`exposure` (table)  only for HDRI skies, default 1.0


_________________

### `Dream:getSky()`


_________________

### `Dream:setResourceLoader(threaded)`
Set resource loader settings
#### Arguments
`threaded` (boolean)  load textures lazily using multithreading


_________________

### `Dream:getResourceLoader()`


_________________

### `Dream:setMipmaps(mode)`
Toggle mipmap generations for loaded images
#### Arguments
`mode` (boolean) 


_________________

### `Dream:getMipmaps()`


_________________

### `Dream:setGodrays()`
`deprecated`  


_________________

### `Dream:getGodrays()`
`deprecated`  


_________________

### `Dream:setDistortionMargin(value)`
Distortion is a post processing effect and will fail for everything outside the screen, therefore a margin is required, higher values produce a sharper margin towards the edges, default 2.0
#### Arguments
`value` (number) 


_________________

### `Dream:getDistortionMargin()`


_________________

### `Dream:setDefaultPixelShader(shader)`
Default Pixel shader, if not overwritten by the material or mesh
#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `Dream:getDefaultPixelShader()`


_________________

### `Dream:setDefaultVertexShader(shader)`
Default Vertex shader, if not overwritten by the material or mesh
#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `Dream:getDefaultVertexShader()`


_________________

### `Dream:setDefaultWorldShader(shader)`
Default World shader, if not overwritten by the material or mesh
#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `Dream:getDefaultWorldShader()`


_________________

### `Dream:registerMeshFormat(format, name)`
Register a new format, see `3DreamEngine/meshFormats/*` for examples
#### Arguments
`format` ([MeshFormat](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshformat)) 

`name` (string) 


_________________

### `Dream:registerShader(shader, name)`
Register a shader to the shader registry, materials files can then reference them
#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 

`name` (string) 


_________________

### `Dream:getShader(name)`
Gets a shader from the library
#### Arguments
`name` (string) 


_________________
