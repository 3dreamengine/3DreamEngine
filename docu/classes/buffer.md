# Buffer
A buffer is a continues collection of primitives (vectors, scalars or matrices) used to store vertex information and co.
## Constructors
### `Buffer:newBuffer(type, dataType, length)`
New compact data buffer
#### Arguments
`type` (string)  "vec2", "vec3", "vec4", or "mat4"

`dataType` (string)  C type, e.g. "float"

`length` (number) 

#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

### `Buffer:newDynamicBuffer()`
A dynamic buffer is a slower, more dynamic lua array implementation
#### Returns
([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 


_________________

## Methods
### `Buffer:getType()`


_________________

### `Buffer:getDataType()`


_________________

### `Buffer:append(data)`
Append a value to the buffer
#### Arguments
`data` (number) 


_________________

### `Buffer:set(index, data)`
Set a value in the buffer
#### Arguments
`index` (number) 

`data` (number) 


_________________

### `Buffer:get(index)`
Get a raw value from the buffer
#### Arguments
`index` (number) 

#### Returns
(number) 


_________________

### `Buffer:getOrDefault(index)`
Get a raw value from the buffer without risking a out of bounds
#### Arguments
`index` (number) 

#### Returns
(number) 


_________________

### `Buffer:getVector(index)`
Get a casted value from the buffer
#### Arguments
`index` (number) 

#### Returns
(number) 


_________________

### `Buffer:copyFrom(source, dstOffset, srcOffset, srcLength)`
Copy data from one buffer into another, offsets given in indices
#### Arguments
`source` ([Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)) 

`dstOffset` (number) 

`srcOffset` (number) 

`srcLength` (number) 


_________________

### `Buffer:getSize()`
Get the size of this buffer

_________________

### `Buffer:ipairs()`
Iterate over every raw value

_________________

### `Buffer:toArray()`
Convert buffer to a Lua array

_________________
