# InstancedMesh
Extends [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)

Uses a mesh to create instances from it. Especially helpful when rendering many small instances
## Constructors
### `InstancedMesh:newInstancedMesh(mesh)`

#### Arguments
`mesh` ([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh))  The source mesh to create instances from

#### Returns
([InstancedMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/instancedmesh)) 


_________________

## Methods
### `InstancedMesh:getInstancesCount()`


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
