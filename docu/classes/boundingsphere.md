# BoundingSphere
A bounding sphere is a sphere enclosing e.g. mesh data and may be used for frustum culling
## Constructors
### `BoundingSphere:newBoundingSphere(center, size)`
Creates a new bounding sphere
#### Arguments
`center` (Vec3)  optional

`size` (number)  optional


_________________

## Fields
`center` (Vec3) 

`size` (number) 

## Methods
### `BoundingSphere:merge(other)`
Merge with a second bounding sphere
#### Arguments
`other` ([BoundingSphere](https://3dreamengine.github.io/3DreamEngine/docu/classes/boundingsphere)) 

#### Returns
([BoundingSphere](https://3dreamengine.github.io/3DreamEngine/docu/classes/boundingsphere)) 


_________________

### `BoundingSphere:extend(margin)`
Extend bounding sphere
#### Arguments
`margin` (number) 

#### Returns
([BoundingSphere](https://3dreamengine.github.io/3DreamEngine/docu/classes/boundingsphere)) 


_________________

### `BoundingSphere:intersect(other)`
Test if two bounding spheres intersect
#### Arguments
`other` ([BoundingSphere](https://3dreamengine.github.io/3DreamEngine/docu/classes/boundingsphere)) 

#### Returns
(boolean) 


_________________

### `BoundingSphere:isInitialized()`

#### Returns
(boolean) 


_________________

### `BoundingSphere:getCenter()`

#### Returns
(Vec3) 


_________________

### `BoundingSphere:getSize()`

#### Returns
(number) 


_________________
