# Material
A material holds textures, render settings, shader information and similar and is assigned to a mesh.
## Constructors
### `Material:newMaterial(name)`
Creates an empty material
#### Arguments
`name` (string) 

#### Returns
([Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)) 


_________________

## Methods
### `Material:setName(name)`

#### Arguments
`name` (string) 


_________________

### `Material:getName()`


_________________

### `Material:setAlpha(alpha)`

#### Arguments
`alpha` (any) 


_________________

### `Material:getAlpha()`


_________________

### `Material:setDiscard(discard)`

#### Arguments
`discard` (any) 


_________________

### `Material:getDiscard()`


_________________

### `Material:setDither(dither)`

#### Arguments
`dither` (any) 


_________________

### `Material:getDither()`


_________________

### `Material:setCullMode(cullMode)`
Sets the culling mode
#### Arguments
`cullMode` (CullMode) 


_________________

### `Material:getCullMode()`


_________________

### `Material:setTranslucency(translucency)`
Sets the object translucency (light coming through to the other side of a face), will disable mesh culling of translucency is larger than 0
#### Arguments
`translucency` (number) 


_________________

### `Material:setIOR(ior)`
Sets (not physically accurate) refraction index
#### Arguments
`ior` (number) 


_________________

### `Material:throwsShadow(shadow)`
Similar to shadowVisibility on meshes, this allows materials to only be visible in the render pass
#### Arguments
`shadow` (boolean) 


_________________

### `Material:setColor(r, g, b, a)`

#### Arguments
`r` (any) 

`g` (any) 

`b` (any) 

`a` (any) 


_________________

### `Material:setAlbedoTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setEmission(r, g, b)`

#### Arguments
`r` (any) 

`g` (any) 

`b` (any) 


_________________

### `Material:setEmissionTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setAoTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setNormalTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setRoughness(r)`

#### Arguments
`r` (any) 


_________________

### `Material:setMetallic(m)`

#### Arguments
`m` (any) 


_________________

### `Material:setRoughnessTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setMetallicTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setMaterialTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:getMaterialTexture(tex)`

#### Arguments
`tex` (any) 


_________________

### `Material:setAlphaCutoff(alphaCutoff)`

#### Arguments
`alphaCutoff` (any) 


_________________

### `Material:getAlphaCutoff()`


_________________

### `Material:setCullMode(cullMode)`

#### Arguments
`cullMode` (any) 


_________________

### `Material:getCullMode()`


_________________

### `Material:preload(force)`
Load textures and similar
#### Arguments
`force` (boolean)  Bypass threaded loading and immediately load things


_________________

### `Material:loadFromFile(file)`
Populate from a lua file returning a material
#### Arguments
`file` (string) 


_________________
