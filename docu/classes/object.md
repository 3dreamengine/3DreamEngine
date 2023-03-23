# Object
Extends Clonable, Transformable, HasShaders


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

### `Object:setName(name)`

#### Arguments
`name` (string) 


_________________

### `Object:getName()`


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


_________________

### `Transformable:setTransform(t)`

#### Arguments
`t` (any) 


_________________

### `Transformable:getTransform()`


_________________

### `Transformable:translate(x, y, z)`

#### Arguments
`x` (any) 

`y` (any) 

`z` (any) 


_________________

### `Transformable:scale(x, y, z)`

#### Arguments
`x` (any) 

`y` (any) 

`z` (any) 


_________________

### `Transformable:rotateX(rx)`

#### Arguments
`rx` (any) 


_________________

### `Transformable:rotateY(ry)`

#### Arguments
`ry` (any) 


_________________

### `Transformable:rotateZ(rz)`

#### Arguments
`rz` (any) 


_________________

### `Transformable:translateWorld(x, y, z)`

#### Arguments
`x` (any) 

`y` (any) 

`z` (any) 


_________________

### `Transformable:scaleWorld(x, y, z)`

#### Arguments
`x` (any) 

`y` (any) 

`z` (any) 


_________________

### `Transformable:rotateXWorld(rx)`

#### Arguments
`rx` (any) 


_________________

### `Transformable:rotateYWorld(ry)`

#### Arguments
`ry` (any) 


_________________

### `Transformable:rotateZWorld(rz)`

#### Arguments
`rz` (any) 


_________________

### `Transformable:getPosition()`


_________________

### `Transformable:lookAt(position, up)`

#### Arguments
`position` (any) 

`up` (any) 


_________________

### `Transformable:setDirty()`


_________________

### `Transformable:getGlobalTransform()`
getGlobalTransform
#### Returns
(Mat4)  returns the last global transform. Needs to be rendered once, and if rendered multiple times, the result is undefined


_________________

### `Transformable:lookTowards(direction, up)`

#### Arguments
`direction` (any) 

`up` (any) 


_________________

### `Transformable:getInvertedTransform()`


_________________

### `Transformable:setDynamic(dynamic)`

#### Arguments
`dynamic` (any) 


_________________

### `Transformable:isDynamic()`


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
