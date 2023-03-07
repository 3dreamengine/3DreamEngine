# MeshBuilder
Extends [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)

Mesh builder are buffers populated with primitives or objects on the CPU, then rendered altogether. They outperform individual draw calls and can be multi threaded and/or cached.
## Constructors
### `MeshBuilder:newMeshBuilder(material)`
Creates a new mesh builder
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 

#### Returns
([MeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshbuilder)) 


_________________

## Methods
### `MeshBuilder:updateBoundingSphere()`


_________________

### `MeshBuilder:addMesh(mesh, transform)`
Adds a mesh with given transform to the builder
#### Arguments
`mesh` ([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)) 

`transform` (Mat4) 


_________________

### `MeshBuilder:remove(id)`
remove a chunk previously added
#### Arguments
`id` (number) 


_________________

### `MeshBuilder:getMesh(name)`

#### Arguments
`name` (any) 


_________________

### `MeshBuilder:getVertexIntegrity()`
Returns the fraction of data in use

_________________

### `MeshBuilder:getIndexIntegrity()`
Returns the fraction of data in use for the index buffer

_________________

### `MeshBuilder:defragment()`


_________________

### `MeshBuilder:resizeVertex(size)`

#### Arguments
`size` (any) 


_________________

### `MeshBuilder:resizeIndices(size)`

#### Arguments
`size` (any) 


_________________

### `Mesh:setMaterial(material)`
Sets the meshes material
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 


_________________

### `Mesh:getMaterial()`


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

### `Mesh:setFarShadowVisibility(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Mesh:getFarShadowVisibility()`


_________________

### `Mesh:setName(name)`

#### Arguments
`name` (string) 


_________________

### `Mesh:getName()`


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

### `Mesh:getOrCreateBuffer(name)`
Gets or creates an dynamic, typeless buffer
#### Arguments
`name` (string)  name of buffer


_________________

### `Mesh:decode(meshData)`

#### Arguments
`meshData` (any) 


_________________

### `Clonable:clone()`
Slow and deep clone

_________________

### `Clonable:instance()`
Creates an fast instance

_________________

### `HasShaders:setPixelShader(shader)`

#### Arguments
`shader` (any) 


_________________

### `HasShaders:setVertexShader(shader)`

#### Arguments
`shader` (any) 


_________________

### `HasShaders:setWorldShader(shader)`

#### Arguments
`shader` (any) 


_________________
