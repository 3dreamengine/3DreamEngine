# Shadow

## Constructors
### `Shadow:newShadow()`

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


_________________

### `Shadow:setCascadeDistance(cascadeDistance)`
The cascade distance is the range of the sun shadow, higher range allows a higher shadow range, but decreases resolution
#### Arguments
`cascadeDistance` (number) 


_________________

### `Shadow:getCascadeDistance()`


_________________

### `Shadow:setCascadeFactor(cascadeFactor)`
The cascade factor defines the factor at which each cascade is larger than the one before
#### Arguments
`cascadeFactor` (number) 


_________________

### `Shadow:getCascadeFactor()`


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


_________________

### `Shadow:setStatic(static)`
Static lights wont capture moving objects, no effect when dynamic mode active
#### Arguments
`static` (boolean) 


_________________

### `Shadow:isStatic()`


_________________

### `Shadow:setDynamic(dynamic)`
Dynamic mode only re-renders dynamic objects and is much faster than a full render, but slower than fully static
#### Arguments
`dynamic` (boolean) 


_________________

### `Shadow:isDynamic()`


_________________

### `Shadow:setSmooth(smooth)`
Smoothing is slow and is therefore only available for static shadows
#### Arguments
`smooth` (boolean) 


_________________

### `Shadow:isSmooth()`


_________________

### `Shadow:setLazy(lazy)`
Lazy rendering spreads the load on several frames at the cost of visible artifacts
#### Arguments
`lazy` (boolean) 


_________________

### `Shadow:isLazy()`


_________________
