# Reflection
A reflection globe, updated when visible. Dynamic globes are slow and should be used with care. In many cases, static globes are sufficient.
## Constructors
### `Reflection:newReflection()`

#### Returns
([Reflection](https://3dreamengine.github.io/3DreamEngine/docu/classes/reflection)) 


_________________

## Methods
### `Reflection:refresh()`
Request a rerender, especially relevant if the globe is static

_________________

### `Reflection:setLocal(center, first, second)`
Set the bounds of the globe. A local globe is more accurate for objects close to the bounds.
#### Arguments
`center` (Vec3) 

`first` (Vec3) 

`second` (Vec3) 


_________________

### `Reflection:getLocal()`


_________________

### `Reflection:setLazy(lazy)`
Lazy reflections spread the load over several frames and are therefore much faster at the cost of a bit of flickering
#### Arguments
`lazy` (boolean) 


_________________

### `Reflection:getLazy()`


_________________
