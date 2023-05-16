# Object
Extends Clonable, Transformable, HasShaders, IsNamed


## Constructors
### `Object:newObject()`
Create an empty object
#### Returns
([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)) 


_________________

### `Object:loadLibrary(path, args, prefix)`
Loads and adds that object as a library, see https://3dreamengine.github.io/3DreamEngine/docu/introduction
#### Arguments
`path` (any) 

`args` (any) 

`prefix` (any) 


_________________

### `Object:loadObject(path, args)`
Load an object
#### Arguments
`path` (string)  Path to object without extension

`args` (table) 


_________________

## Fields
`objects` ([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)[]) 

`meshes` ([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)[]) 

`positions` ([Position](https://3dreamengine.github.io/3DreamEngine/docu/classes/position)[]) 

`lights` ([Light](https://3dreamengine.github.io/3DreamEngine/docu/classes/light)[]) 

`collisionMeshes` ([CollisionMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/collisionmesh)[]) 

`raytraceMeshes` ([RaytraceMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/raytracemesh)[]) 

`reflections` ([Reflection](https://3dreamengine.github.io/3DreamEngine/docu/classes/reflection)[]) 

`animations` ([Animation](https://3dreamengine.github.io/3DreamEngine/docu/classes/animation)[]) 

## Methods
### `Object:newInstance()`


_________________

### `Object:clone()`


_________________

### `Object:instance()`
Creates an recursive instance, objects can now be transformed individually, all other changes remain synced
#### Returns
([Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)) 


_________________

### `Object:getMainSkeleton()`
The main skeleton is usually the one used by all meshes, but may be nil or unused
#### Returns
([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton)) 


_________________

### `Object:setLOD(min, max)`
Range in which this object should be rendered
#### Arguments
`min` (number) 

`max` (number) 


_________________

### `Object:getLOD()`


_________________

### `Object:updateBoundingSphere()`


_________________

### `Object:clearMeshes()`


_________________

### `Object:cleanup()`


_________________

### `Object:preload(force)`

#### Arguments
`force` (any) 


_________________

### `Object:meshesToCollisionMeshes()`
Converts all meshes to physics meshes

_________________

### `Object:getAllMeshes()`
Get all pairs of (DreamMesh, mat4 transform), recursively, as a flat array

_________________

### `Object:merge()`
Merge all meshes, recursively, of an object

_________________

### `Object:applyTransform()`
Apply the current transformation to the meshes

_________________

### `Object:applyBones(skeleton)`
Apply joints to mesh data directly
#### Arguments
`skeleton` ([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton))  optional


_________________

### `Object:createMeshes()`
Create all render-able meshes

_________________

### `Object:setVisible(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Object:setRenderVisibility(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Object:setShadowVisibility(visibility)`

#### Arguments
`visibility` (boolean) 


_________________

### `Object:setFarVisibility(visibility)`
Set whether the outer layers of the sun cascade shadow should render this object
#### Arguments
`visibility` (boolean) 


_________________

### `Object:setMaterial(material)`
A object has no material, therefore this call will forward this to all Meshes
#### Arguments
`material` ([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 


_________________

### `Object:print()`
Print a detailed summary of this object

_________________

### `Object:export3do()`
`deprecated`  
Exports this object in the custom, compact and fast 3DO format

_________________

### `Clonable:clone()`
Slow and deep clone

_________________

### `Clonable:instance()`
Creates an fast instance

_________________

### `Transformable:resetTransform()`
Resets the transform to the identify matrix
#### Returns
(Transformable) 


_________________

### `Transformable:setTransform(transform)`

#### Arguments
`transform` (Mat4) 

#### Returns
(Transformable) 


_________________

### `Transformable:getTransform()`
Gets the current, local transformation matrix
#### Returns
(Mat4) 


_________________

### `Transformable:translate(x, y, z)`
Translate in local coordinates
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:scale(x, y, z)`
Scale in local coordinates
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:rotateX(rx)`
Euler rotation around the X axis in local coordinates
#### Arguments
`rx` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:rotateY(ry)`
Euler rotation around the Y axis in local coordinates
#### Arguments
`ry` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:rotateZ(rz)`
Euler rotation around the Z axis in local coordinates
#### Arguments
`rz` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:translateWorld(x, y, z)`
Translate in world coordinates
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:scaleWorld(x, y, z)`
Scale in world coordinates
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:rotateXWorld(rx)`
Euler rotation around the X axis in world coordinates
#### Arguments
`rx` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:rotateYWorld(ry)`
Euler rotation around the Y axis in world coordinates
#### Arguments
`ry` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:rotateZWorld(rz)`
Euler rotation around the Z axis in world coordinates
#### Arguments
`rz` (number) 

#### Returns
(Transformable) 


_________________

### `Transformable:getPosition()`
Gets the current world position
#### Returns
(Vec3) 


_________________

### `Transformable:lookAt()`
Makes the object look at the target position with given up vector
#### Returns
(Transformable) 


_________________

### `Transformable:setDirty()`
Marks as modified

_________________

### `Transformable:getGlobalTransform()`
Gets the last global transform. Needs to be rendered once, and if rendered multiple times, the result is undefined
#### Returns
(Mat4) 


_________________

### `Transformable:lookTowards(direction, up)`
Look towards the global direction and upwards vector
#### Arguments
`direction` (Vec3) 

`up` (Vec3) 


_________________

### `Transformable:getInvertedTransform()`
Returns the cached inverse of the local transformation
#### Returns
(Mat4) 


_________________

### `Transformable:setDynamic(dynamic)`
Dynamic objects are excluded from static shadows and reflections. Applying a transforms sets this flag automatically.
#### Arguments
`dynamic` (boolean) 


_________________

### `Transformable:isDynamic()`
Returns weather this object is excluded from statis shadows and reflections
#### Returns
(boolean) 


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
