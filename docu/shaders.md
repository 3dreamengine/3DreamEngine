# Shaders
The shader is constructed based on its base shader and additional/optional shader modules.
There are basic default shaders and modules present, so this chapter is advanced usage.

- [rain](#rain)
- [wind](#wind)
- [bones](#bones)
- [fade](#fade)
- [multiTexture](#multiTexture)

## enable shader module globally
You can enable shaders per object, per subObject and per material. In addition, some shader can (somethimes has to) be global.

```lua
dream:activateShaderModule(name)
dream:deactivateShaderModule(name)
module = dream:getShaderModule(name)
active = dream:isShaderModuleActive(name)
```
`name` shader module name  
`module` shader module  
`active` currently active  



## register own shader
A more tidy docu will be written soon.
For a better understanding in the final shader, look into shaders/base.glsl. This is the skeleton where the modules are imported.
```lua
dream:registerShader(pathToLuaFile)
```



## base shader
This shader does most of the work. Except a few addons (fog, reflections) it works alone.
It's chosen by the objects `shaderType` tag, provided at the object loader and stored in the sub object.

## shader modules
Those modules can extend the shader to add certain effects. For example a rain effect as the one implemeted, the bone modules as one of the more heavy ones, or a burning animation, or a disolving effect, ...



## built-in shader modules
There are a few modules already built in, ready to enable:

### rain
The rain modules renders rain, wetness and splash animations on surfaces.
The render part requires the module to be activated globally.
```lua
dream:activateShaderModule("rain")
dream:getShaderModule("rain").isRaining = true
dream:getShaderModule("rain").strength = 3 -- 1 to 5
```



### wind
Wind lets the vertices wave. It requires the extra buffer as an factor of animation, either set `material.extra` to an appropiate constant or let the particle system generator do it. See mat chapter for this. To enable the wind shader, enable it on the affected material, optional adjust the shader modules settings.
```lua
material:activateShaderModule("wind")
```
Since .mat files supports `onFinish()` callbacks you can put the above line here too.
```lua
--example material file for grass
return {
	extra = 0.02,
	cullMode = "none",
	vertexShader = "wind",
}
```



### bones
3Dream supports animations with a few conditions:
1. it requires a skeleton and skin information, therefore export your object as a COLLADA file (.dae)
2. the bone module needs to be activated: `object:activateShaderModule("bones")` in order to use GPU powered transformations. Theoretical optional but cause heavy CPU usage and GPU bandwidth.
3. update animations as in the skeletal animations specified



### fade
Uses the alpha channel to fade out right before its LOD. Used for example for grass to smoothly let it appear.
```
-- width of fading ring.
dream:getShaderModule("fade").fadeWidth = 1.0
```



### multiTexture
Uses a second material, a blend mask and a blend texture and a second UV map to blend two materials together, for example to blend between road and grass. 
The mask texture, red channel, blends betweens the two materials. 
The blend texture is a (for now) constant 64 times the mask uv and gives the usually quite low res mask more detail.
Custom second UV map WIP. 
Per object and per material settings WIP, currently only per subObject. 
```
subObj.material_2 = Material

subObj.tex_mask = "path" or Drawable
subObj.tex_blend = "path" or Drawable

-- scale of second material UV
subObj.multiTexture_uv2Scale = 1.0
```