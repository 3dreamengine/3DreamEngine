# Camera
Extends Transformable

Contains transformation and lens information used to render the scene
## Constructors
### `Camera:newCamera(transform, transformProj, position, normal)`
Creates a new camera
#### Arguments
`transform` (Mat4) 

`transformProj` (Mat4) 

`position` (Vec3) 

`normal` (Vec3) 

#### Returns
([Camera](https://3dreamengine.github.io/3DreamEngine/docu/classes/camera)) 


_________________

## Methods
### `Camera:setFov(fov)`
Set FOV
#### Arguments
`fov` (number)  vertical field of view in degrees


_________________

### `Camera:getFov()`

#### Returns
(number) 


_________________

### `Camera:setNear(near)`
Set near plane
#### Arguments
`near` (number) 


_________________

### `Camera:getNear()`

#### Returns
(number) 


_________________

### `Camera:setFar(far)`
Set far plane
#### Arguments
`far` (number) 


_________________

### `Camera:getFar()`

#### Returns
(number) 


_________________

### `Camera:setSize(size)`
Sets the horizontal orthographic viewport size
#### Arguments
`size` (number) 


_________________

### `Camera:getSize()`

#### Returns
(number) 


_________________

### `Camera:setOrthographic(orthographic)`
Sets projection transform to orthographic, does not work with sky-boxes
#### Arguments
`orthographic` (boolean) 


_________________

### `Camera:isOrthographic()`

#### Returns
(boolean) 


_________________

### `Camera:getNormal()`

#### Returns
(Vec3) 


_________________

### `Camera:getPosition()`

#### Returns
(Vec3) 


_________________

### `Camera:inFrustum(pos, radius, id)`
Checks if the giving sphere is in the cameras frustum
#### Arguments
`pos` (Vec3) 

`radius` (number) 

`id` (any) 


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
