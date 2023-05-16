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
### `MeshBuilder:clear()`
Resets the buffer

_________________

### `MeshBuilder:updateBoundingSphere()`


_________________

### `MeshBuilder:addMesh(mesh, transform)`
Adds a mesh with given transform to the builder
#### Arguments
`mesh` ([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)) 

`transform` (Mat4) 


_________________

### `MeshBuilder:addVertices(vertexCount, vertexMapLength)`
Returns the pointer to vertices, pointer to vertex map and the index offset. Make sure to fill all requested vertices and build the vertex map accordingly.
#### Arguments
`vertexCount` (number) 

`vertexMapLength` (number) 


_________________

### `MeshBuilder:addTriangle()`
Allocates an triangle and returns the pointer to the first vertex

_________________

### `MeshBuilder:addQuad()`
Allocates an quad and returns the pointer to the first vertex

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
