# Light
Extends Clonable, IsNamed

A light source.
## Constructors
### `Light:newLight(typ, position, color, brightness)`
Creates new light source
#### Arguments
`typ` (string)  "point" or "sun"

`position` (Vec3) 

`color` (number[]) 

`brightness` (number) 

#### Returns
([Light](https://3dreamengine.github.io/3DreamEngine/docu/classes/light)) 


_________________

## Methods
### `Light:setSize(size)`
The size mostly affects smooth lighting
#### Arguments
`size` (number) 


_________________

### `Light:getSize()`


_________________

### `Light:setAttenuation(attenuation)`
The attenuation exponent should be 2.0 for realism, but higher values produce a more cozy, artistic result
#### Arguments
`attenuation` (number) 


_________________

### `Light:getAttenuation()`


_________________

### `Light:setGodrays()`
`deprecated`  


_________________

### `Light:getGodrays()`
`deprecated`  


_________________

### `Light:setBrightness(brightness)`

#### Arguments
`brightness` (any) 


_________________

### `Light:getBrightness()`


_________________

### `Light:setColor(r, g, b)`
Sets the color, should roughly be a unit vector
#### Arguments
`r` (number) 

`g` (number) 

`b` (number) 


_________________

### `Light:getColor()`


_________________

### `Light:setPosition(x, y, z)`
Set the position for point sources
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 


_________________

### `Light:getPosition()`


_________________

### `Light:setDirection(x, y, z)`
Set the direction for sun light sources
#### Arguments
`x` (number) 

`y` (number) 

`z` (number) 


_________________

### `Light:getDirection()`


_________________

### `Light:addShadow(shadow)`
Assign a shadow to this light source, a shadow can be shared by light sources if close to each other
#### Arguments
`shadow` ([Shadow](https://3dreamengine.github.io/3DreamEngine/docu/classes/shadow)) 


_________________

### `Light:addNewShadow(resolution)`
Creates a new shadow with given resolution
#### Arguments
`resolution` (number) 


_________________

### `Light:getShadow()`

#### Returns
([Shadow](https://3dreamengine.github.io/3DreamEngine/docu/classes/shadow)) 


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
