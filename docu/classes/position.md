# Position
Extends Clonable, IsNamed

New position, mostly used internally for objects marked with the `POS` tag.
## Constructors
### `Position:newPosition(position, size, value)`

#### Arguments
`position` (Vec3) 

`size` (number) 

`value` (string) 

#### Returns
([Position](https://3dreamengine.github.io/3DreamEngine/docu/classes/position)) 


_________________

## Methods
### `Position:setPosition(position)`

#### Arguments
`position` (Vec3) 


_________________

### `Position:getPosition()`

#### Returns
(Vec3) 


_________________

### `Position:setValue(value)`

#### Arguments
`value` (string) 


_________________

### `Position:getValue()`

#### Returns
(string)  the value passed with the tag while loading


_________________

### `Position:setSize(size)`

#### Arguments
`size` (number) 


_________________

### `Position:getSize()`

#### Returns
(number) 


_________________

### `Clonable:clone()`
Slow and deep clone

_________________

### `Clonable:instance()`
Creates an fast instance

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
