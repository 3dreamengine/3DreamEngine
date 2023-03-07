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
`fov` (number)  horizontal field of view in degrees


_________________

### `Camera:getFov()`


_________________

### `Camera:setNear(near)`
Set near plane
#### Arguments
`near` (number) 


_________________

### `Camera:getNear()`


_________________

### `Camera:setFar(far)`
Set far plane
#### Arguments
`far` (number) 


_________________

### `Camera:getFar()`


_________________

### `Camera:setSize(size)`
Sets the horizontal orthographic viewport size
#### Arguments
`size` (number) 


_________________

### `Camera:getSize()`


_________________

### `Camera:setOrthographic(orthographic)`
Sets projection transform to orthographic, does not work with sky-boxes
#### Arguments
`orthographic` (boolean) 


_________________

### `Camera:isOrthographic()`


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
