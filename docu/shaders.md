# Shaders
Every material or subObject can have a pixel shader, vertex shader and world shader.
A pixel shader handles materials related stuff, a vertex shader the vertex position and the world shader combines everything and outputs to the screen.


## create shader
Create a new shader object to be used later.
```lua
shader dream:newShader(path)
```

Check out "3DreamEngine/shaders/inbuilt" for examples.
A shader is a .lua file containing at least following functions:
```lua
local sh = { }

--the type of the shader (vertex, pixel, world)
sh.type = "vertex"

--a integer id in case this shader has different variants
function sh:getId(dream, mat, shadow)
	return 0
end

function sh:initObject(dream, obj)
	if obj.mesh then
		--any additional initializion you may need, called once after load and for each shader assignment on an object
	end
end

function sh:buildDefines(dream, mat)
	return [[
		// any additional externs, attributes or defines you need
		// use isdefine PIXEL/VERTEX if necessary
		
		// the world shader has to implemented, called for each light
		vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 fragmentNormal, vec3 albedo, float roughness, float metallic)
	]]
end

function sh:buildPixel(dream, mat)
	return [[
		--you have access to those base values
		vec3 viewVec;        // camera-to-fragment vector
		vec3 fragmentNormal; // a normalized per fragment normal
		vec3 vertexPos;      // the vertex position
		float depth;         // the view depth
		
		mat4 transformProj;   // projective transformation
		mat4 transform;       // model transformation
		vec3 viewPos;         // camera position
		
		//if you defined TANGENT you will get access to a tangent-to-world transformation
		#ifdef TANGENT
		varying mat3 TBN;
		#endif
		
		//for solid, non direct passes you have access to the depth texture
		#ifdef DEPTH_AVAILABLE
		extern Image tex_depth;
		#endif
		
		// if this shader is a pixel shader:
		// write to those (already defined!) outputs, you may not use them and use the default value instead
		vec3 normal;
		vec3 albedo = vec3(0.5);
		float alpha = 1.0;
		float roughness = 0.5;
		float metallic = 0.0;
		float ao = 1.0;
		vec3 emission = vec3(0.0);
		vec3 caustics = vec3(0.0);
		
		//if this is a world shader, write to
		vec2 distortion = vec2(0.0);
		vec3 color = vec3(0.0);
		
		//and use light for the light input
		vec3 light = vec3(0.0);
	]]
end

function sh:buildVertex(dream, mat)
	return [[
		// you have access to
		mat4 transformProj;   // projective transformation
		mat4 transform;       // model transformation
		vec3 viewPos;         // camera position
		
		// this is the default transformation, only modify VertexPos in the vertex shader
		VertexPos = (transform * vec4(VertexPos, 1.0)).xyz;
		
		// optional you can transform the normal transform
		mat3 normalTransform;
	]]
end

function sh:perShader(dream, shaderObject)
	--use perShader, perMaterial and perTask to pass data
	local shader = shaderObject.shader
	shader:send("yourData", data)
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)

end

return sh
```

## register shader
Once a shader is registered, you can use the string for setting shaders.
You need this if you want to set the shader in the .mat file.

```lua
dream:registerShader(path [, name])
```

## set default shader module
If not overwritten by the material or subObject, the default shader is used.

```lua
dream:setDefaultPixelShader(shader)
dream:setDefaultVertexShader(shader)
dream:setDefaultWorldShader(shader)

shader = dream:getDefaultPixelShader()
shader = dream:getDefaultVertexShader()
shader = dream:getDefaultWorldShader()
```
`dream` shader object or string for registered shader name 


## built-in shader modules
There are a few shader already built in:



### textured, material, simple
Those three shader either accept fully textured materials, a lookup table for the material shader or simple per vertex materials for the simple shader.


### water
A water material shader. Uses the normal texture for the wave animation.


### vertex
A vertex shader doing nothing.


### PBR
The default world shader is a PBR shader.


### wind and foliage
Wind lets the vertices wave. Foliage also uses a better fade out at the edge of the LoD draw range

local shader = dream:resolveShaderName("wind")
shader.speed = 0.05      -- the time multiplier
shader.strength = 1.0    -- the multiplier of animation
shader.scale = 0.25      -- the scale of wind waves

local shader = dream:resolveShaderName("foliage")
shader.fadeWidth = 1

```lua
--example material file for grass
return {
	cullMode = "none",
	
	vertexShader = "wind",
	
	shaderWindStrength = 1.0, -- additional wave strength factor
	shaderWindGrass = false,  -- behave like grass, lower part wont move
	shaderWindHeight = 1.0,   -- how height the plant is, determines the strength of animation on the upper part
}
```



### bones
3Dream supports animations with a few conditions:
1. it requires a skeleton and skin information, therefore export your object as a COLLADA file (.dae)
2. apply the bone vertex shader to the subObject in order to properly trigger its initialision
3. update animations as in the skeletal animations chapter specified



### multiTexture
Uses a second material, a blend texture and a optional second UV map to blend two materials together, for example to blend between road and grass. 
The blend texture gives the blend more detail. 
```
--the second material to use
subObj.material.material_2 = Material

subObj.material.tex_blend = "path" or Drawable

--scale of the blend texture
subObj.material.multiTextureBlendScale

--scale of second material UV
subObj.multiTextureUV2Scale = 1.0

--channel of the color buffer to be used as the blend factor
subObj.multiTextureColorChannel = 1

subObj:setVertexShader("multiTexture")
```