# Shadow

## Constructors
### `Shadow:newShadow(typ, resolution)`
Creates a new shadow
#### Arguments
`typ` (string)  "sun" or "point"

`resolution` (number) 

#### Returns
([Shadow](https://3dreamengine.github.io/3DreamEngine/docu/classes/shadow)) 


_________________

## Methods
### `Shadow:setRefreshStepSize(refreshStepSize)`
The step size defines at what difference in position a shadow should be recalculated
#### Arguments
`refreshStepSize` (number) 


_________________

### `Shadow:getRefreshStepSize()`

#### Returns
(number) 


_________________

### `Shadow:setCascadeDistance(cascadeDistance)`
The cascade distance is the range of the sun shadow, higher range allows a higher shadow range, but decreases resolution
#### Arguments
`cascadeDistance` (number) 


_________________

### `Shadow:getCascadeDistance()`

#### Returns
(number) 


_________________

### `Shadow:setCascadeFactor(cascadeFactor)`
The cascade factor defines the factor at which each cascade is larger than the one before
#### Arguments
`cascadeFactor` (number) 


_________________

### `Shadow:getCascadeFactor()`

#### Returns
(number) 


_________________

### `Shadow:refresh()`
Refresh (static) shadows

_________________

### `Shadow:clear()`
Forces textures to be regenerated

_________________

### `Shadow:setResolution(resolution)`

#### Arguments
`resolution` (any) 


_________________

### `Shadow:getResolution()`

#### Returns
(number) 


_________________

### `Shadow:setStatic(static)`
Static lights wont capture moving objects
#### Arguments
`static` (boolean) 


_________________

### `Shadow:isStatic()`

#### Returns
(boolean) 


_________________

### `Shadow:setSmooth(smooth)`
Smoothing is slow and is therefore only available for static shadows
#### Arguments
`smooth` (boolean) 


_________________

### `Shadow:isSmooth()`

#### Returns
(boolean) 


_________________

### `Shadow:setLazy(lazy)`
Lazy rendering spreads the load on several frames at the cost of visible artifacts
#### Arguments
`lazy` (boolean) 


_________________

### `Shadow:isLazy()`

#### Returns
(boolean) 


_________________
