# Material
Extends Clonable, HasShaders, IsNamed

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
### `Material:setSolid()`
Makes the material solid

_________________

### `Material:setAlpha()`
Materials with set alpha are rendered on the alpha pass, which is slower but fully supports transparency and blending

_________________

### `Material:isAlpha()`

#### Returns
(boolean) 


_________________

### `Material:setCutout()`
Enabled cutout only renders when alpha is over a threshold, faster than alpha since on the main pass but slower than solid

_________________

### `Material:isCutout()`

#### Returns
(boolean) 


_________________

### `Material:setDither()`
Dither internally uses discarding and simulates alpha by dithering, may be used for fading objects

_________________

### `Material:isDither()`

#### Returns
(boolean) 


_________________

### `Material:setCullMode(cullMode)`
Sets the culling mode
#### Arguments
`cullMode` (CullMode) 


_________________

### `Material:getCullMode()`

#### Returns
(CullMode) 


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
Sets the base color, multiplicative to the texture if present
#### Arguments
`r` (number) 

`g` (number) 

`b` (number) 

`a` (number) 


_________________

### `Material:setAlbedoTexture(tex)`
Sets the albedo texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setEmission(r, g, b)`
Sets the emission color. If an emission texture is used, the emission color is additive. If no texture is present, emission color is multiplicative.
#### Arguments
`r` (number) 

`g` (number) 

`b` (number) 


_________________

### `Material:setEmissionFactor(r, g, b)`
Sets the emission factor. If the material has a emission texture, it is multiplied by this factor.
#### Arguments
`r` (number) 

`g` (number) 

`b` (number) 


_________________

### `Material:setEmissionTexture(tex)`
Sets the emission texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setAoTexture(tex)`
Sets the ambient occlusion texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setNormalTexture(tex)`
Sets the normal map texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setRoughness(r)`
Sets the base roughness, multiplicative to the texture if present
#### Arguments
`r` (number) 


_________________

### `Material:setMetallic(m)`
Sets the base metallic value, multiplicative to the texture if present
#### Arguments
`m` (number) 


_________________

### `Material:setRoughnessTexture(tex)`
Sets the roughness texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setMetallicTexture(tex)`
Sets the metallic texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setMaterialTexture(tex)`
Sets the combined roughness-metallic-ao texture
#### Arguments
`tex` (Texture) 


_________________

### `Material:setAlphaCutoff(alphaCutoff)`
The alpha cutoff decides at which alpha value the cutout mode will jump into action. A value of 1 makes the object fully transparent.
#### Arguments
`alphaCutoff` (number) 


_________________

### `Material:getAlphaCutoff()`

#### Returns
(number) 


_________________

### `Material:setParticle(particle)`
Setting the material in particle mode removes some normal math in the lighting functions, which looks better on 2D sprites and very small objects
#### Arguments
`particle` (boolean) 


_________________

### `Material:isParticle()`
Checks if this material is rendered as a particle
#### Returns
(boolean) 


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

### `Material:lookForTextures(directory, filter)`
Looks for and assigns textures in a specific directory using an optional filter
#### Arguments
`directory` (string) 

`filter` (string) 


_________________

### `Clonable:clone()`
Slow and deep clone

_________________

### `Clonable:instance()`
Creates an fast instance

_________________

### `HasShaders:setPixelShader(shader)`

#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `HasShaders:setVertexShader(shader)`

#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


_________________

### `HasShaders:setWorldShader(shader)`

#### Arguments
`shader` ([Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)) 


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
