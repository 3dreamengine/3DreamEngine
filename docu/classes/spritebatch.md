# SpriteBatch
Extends [InstancedMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/instancedmesh)

A spritebatch allows for easy, performant, z sorted and camera facing sprites
## Constructors
### `SpriteBatch:newSpriteBatch(texture, emissionTexture, normalTexture)`
Creates a new sprite batch
#### Arguments
`texture` (Texture)  optional

`emissionTexture` (Texture)  optional

`normalTexture` (Texture)  optional


_________________

## Methods
### `SpriteBatch:clear()`
Clear the batch

_________________

### `SpriteBatch:add(x, y, z, rot, sx, sy, emission)`
Add a new sprite to this batch, uses current color state
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 

`rot` (number)  rotation at the Z axis, 0 by default

`sx` (number)  horizontal scale, default 1

`sy` (number)  vertical scale, or sx

`emission` (number)  optional emission factor, requires set emission texture


_________________

### `SpriteBatch:addQuad(quad, x, y, z, rot, sx, sy, emission)`
Add a new sprite with given quad to this batch, uses current color state
#### Arguments
`quad` (Quad) 

`x` (number) 

`y` (number) 

`z` (number) 

`rot` (number)  rotation at the Z axis, 0 by default

`sx` (number)  horizontal scale, default 1

`sy` (number)  vertical scale, or sx

`emission` (number)  optional emission factor, requires set emission texture


_________________

### `SpriteBatch:set(index, x, y, z, rot, sx, sy, emission)`
Sets an existing sprite
#### Arguments
`index` (any) 

`x` (any) 

`y` (any) 

`z` (any) 

`rot` (any) 

`sx` (any) 

`sy` (any) 

`emission` (any) 


_________________

### `SpriteBatch:setQuad(index, quad, x, y, z, rot, sx, sy, emission)`
Sets an existing sprite
#### Arguments
`index` (any) 

`quad` (any) 

`x` (any) 

`y` (any) 

`z` (any) 

`rot` (any) 

`sx` (any) 

`sy` (any) 

`emission` (any) 


_________________

### `SpriteBatch:resize(size)`
Resizes the spritebatch, usually called automatically
#### Arguments
`size` (number) 


_________________

### `SpriteBatch:setAlpha(enabled)`
A helper function to set whether alpha mode (true) or cutout (false) should be used. The later one will disable sorting as it is not required.
#### Arguments
`enabled` (boolean) 


_________________

### `SpriteBatch:setSorting(sorting)`
Sorting only makes sense when alpha mode is enabled, and the texture is not single colored
#### Arguments
`sorting` (boolean) 


_________________

### `SpriteBatch:getSorting()`

#### Returns
(boolean) 


_________________

### `SpriteBatch:setVertical(vertical)`
A verticalness of 1 draws the sprites aligned to the Y coordinate, a value of 0 fully faces the camera
#### Arguments
`vertical` (number) 


_________________

### `SpriteBatch:getVertical()`
Gets the verticalness
#### Returns
(number) 


_________________

### `InstancedMesh:getInstancesCount()`
Returns the current amount of instances
#### Returns
(number) 


_________________

### `InstancedMesh:clear()`
Clear all instances

_________________

### `InstancedMesh:resize(count)`
Resize the instanced mesh, preserving previous entries
#### Arguments
`count` (number) 


_________________

### `InstancedMesh:addInstance(transform, index)`
Add another instance
#### Arguments
`transform` (Mat4)  a mat3x4 matrix, instances do not support shearing, e.g. the last row

`index` (number)  Optional index, else it will append


_________________

### `InstancedMesh:setInstances(instances)`
Place instances from an array of mat3x4 transformations, represented as a flat array (mat3 rotation, vec3 position, basically a transposed DreamMat4 with missing last row)
#### Arguments
`instances` (number[]) [][]


_________________

### `InstancedMesh:updateBoundingSphere()`
Updates the bounding sphere from scratch, called internally when needed

_________________

### `InstancedMesh:extendBoundingSphere(instance)`
Extend the bounding sphere by another instance, called internally
#### Arguments
`instance` (Mat4) 


_________________

### `Mesh:setMaterial(material)`
Sets the meshes material
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 


_________________

### `Mesh:getMaterial()`

#### Returns
([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 


_________________

### `Mesh:setVisible(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Mesh:setRenderVisibility(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Mesh:getRenderVisibility()`


_________________

### `Mesh:setShadowVisibility(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Mesh:getShadowVisibility()`


_________________

### `Mesh:setSkeleton(skeleton)`

#### Arguments
`skeleton` ([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton)) 


_________________

### `Mesh:getSkeleton()`


_________________

### `Mesh:getPixelShader()`


_________________

### `Mesh:getVertexShader()`


_________________

### `Mesh:getWorldShader()`


_________________

### `Mesh:updateBoundingSphere()`
Updates the bounding sphere based on mesh data

_________________

### `Mesh:cleanup()`


_________________

### `Mesh:preload(force)`
Load textures and similar
#### Arguments
`force` (boolean)  Bypass threaded loading and immediately load things


_________________

### `Mesh:clearMesh()`
Deletes the mesh, will regenerate next time needed

_________________

### `Mesh:getMesh(name)`
Get a mesh, load automatically if required
#### Arguments
`name` (string)  optional, default "mesh"


_________________

### `Mesh:applyTransform(transform)`
Apply a transformation matrix to all vertices
#### Arguments
`transform` (Mat4) 


_________________

### `Mesh:applyBones(skeleton)`
Apply joints to mesh data directly
#### Arguments
`skeleton` ([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton))  optional


_________________

### `Mesh:getJointMatrix(skeleton, jointIndex)`
Returns the final joint transformation based on vertex weights
#### Arguments
`skeleton` ([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton)) 

`jointIndex` (number) 

#### Returns
(Mat4) 


_________________

### `Mesh:recalculateTangents()`


_________________

### `Mesh:createVertexMap()`


_________________

### `Mesh:getMeshFormat()`
Returns the required mesh format set by the current pixel shader
#### Returns
([MeshFormat](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshformat)) 


_________________

### `Mesh:create()`
Makes this mesh render-able

_________________

### `Mesh:separate()`
Separates by loose parts and returns a list of new meshes
#### Returns
([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)[]) 


_________________

### `Mesh:setMeshDrawMode(meshDrawMode)`
Sets the current meshDrawMode, rarely makes sense to set manually
#### Arguments
`meshDrawMode` (MeshDrawMode) 


_________________

### `Mesh:getMeshDrawMode()`
Gets the current meshDrawMode
#### Returns
(MeshDrawMode) 


_________________

### `Mesh:getOrCreateBuffer(name)`
Gets or creates an dynamic, typeless buffer
#### Arguments
`name` (string)  name of buffer


_________________

### `Clonable:clone()`
Slow and deep clone

_________________

### `Clonable:instance()`
Creates an fast instance

_________________

### `HasShaders:setPixelShader(shader)`

#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `HasShaders:setVertexShader(shader)`

#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `HasShaders:setWorldShader(shader)`

#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `IsNamed:setName(name)`
A name has no influence other than being able to print more nicely
#### Arguments
`name` (string) 


_________________

### `IsNamed:getName()`
Gets the name, or "unnamed"
#### Returns
(string) 


_________________
