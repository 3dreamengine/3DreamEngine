# Shaders

Every material or mesh can have a pixel shader, vertex shader and world shader.
A pixel shader handles materials related stuff, a vertex shader the vertex position and the world shader combines everything and outputs to the screen.

Usually, the world shader is set globally and not per mesh or material.

```lua
-- Create a shader from a file
local shader = dream:newShader(path)

-- And register it
dream:registerShader(path, name)

-- Then use it
dream:setDefaultPixelShader(shader)
dream:setDefaultVertexShader(shader)
dream:setDefaultWorldShader(shader)

--Or respectively on objects (passes down to meshes), meshes or materials
object:setPixelShader(shader)
object:setVertexShader(shader)
object:setWorldShader(shader)
```

Check out "3DreamEngine/shaders/inbuilt" for examples.

A shader is a .lua file containing at least following functions:

```lua
local sh = { }

--the type of the shader (vertex, pixel, world)
sh.type = "vertex"

--A integer id in case this shader has different variants
--It allows 3Dream to identify a shader
function sh:getId(material, shadow)
	return 0
end

function sh:initMesh(mesh)
	local primaryMesh = mesh:getMesh()
	--any additional initialization you may need
	--initMesh is called when the mesh is fully loaded
end

function sh:buildFlags(material)
	return [[
		// any additional flags or crucial defines which should be executed before everything else
		// for example, the tangent flag to enable access to the normal-to-world matrix should be here
		#define TANGENT
	]]
end

function sh:buildDefines(material)
	return [[
		// any additional externs, attributes, defines or functions you need
		// use ifdef PIXEL/VERTEX if necessary
		
		// the world shader has to implement
		vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float roughness, float metallic)
		// which is called for each light source
	]]
end

function sh:buildPixel(material)
	return [[
		--you have access to those base values
		vec3 viewVec;        // camera-to-fragment vector
		vec3 vertexPos;      // the vertex position
		float depth;         // the view depth
		
		mat4 transformProj;   // projective transformation
		mat4 transform;       // model transformation
		vec3 viewPos;         // camera position
		
		//if you defined TANGENT you will get access to a tangent-to-world transformation
		#ifdef TANGENT
		varying mat3 TBN;
		#endif
		
		//for solid, non direct render passes you have access to the depth texture
		#ifdef DEPTH_AVAILABLE
		uniform Image depthTexture;
		#endif
		
		// if this shader is a pixel shader:
		// optionally write to those (already defined!) outputs
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
		
		//and use light for the summed light input
		vec3 light = vec3(0.0);
	]]
end

function sh:buildVertex(material)
	return [[
		// you have access to
		mat4 transformProj;   // projective transformation
		mat4 transform;       // model transformation
		vec3 viewPos;         // camera position
		
		// this is the default transformation, feel free to extend or overwrite
		vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
		
		// optional you can transform the normal transform
		mat3 normalTransform;
	]]
end

--use perShader, perMaterial and perTask to pass data
function sh:perShader(shaderObject)
	local shader = shaderObject.shader
	shader:send("yourData", data)
end

function sh:perMaterial(shaderObject, material)

end

function sh:perTask(shaderObject, task)

end

return sh
```

# Built-in shaders

There are a few shader already built in:

### Textured

Default shader accepting color, metallic, roughness, AO and emission.

## Simple

Default shader only accepting color, metallic, roughnesses and (float) emission.

## Material

WIP

## Water

A water material shader.
Uses the normal texture for the wave animation.

WIP

## Vertex

A vertex shader doing nothing special.

## PBR

The default world shader is a PBR shader.

## Wind and foliage

Wind lets the vertices wave. Foliage also uses a better fade out at the edge of the LoD draw range. You can set global shader settings or pet-material settings.

local shader = dream:getShader("wind")
shader.speed = 0.05 -- the time multiplier
shader.strength = 1.0 -- the multiplier of animation
shader.scale = 0.25 -- the scale of wind waves

local shader = dream:getShader("foliage")
shader.fadeWidth = 1

```lua
--example material file for grass
return {
	-- double sided and translucency
	cullMode = "none",
	translucency = 1,
	
	-- registered (default) wind shader
	vertexShader = "wind",
	
	windShaderStrength = 1.0, -- additional wave strength factor
	windShaderGrass = false, -- behave like grass, lower part wont move
	windShaderHeight = 1.0, -- how height the plant is, determines the strength of animation on the upper part
}
```

## Bones

Check out the Skeleton documentation.

## MultiTexture

Uses a second material, a blend texture and a optional second UV map to blend two materials together, for example to blend between road and grass.
The blend texture gives the blend more detail.

```
--the second material to use
mesh.material.material2 = Material

mesh.material.blendTexture = "path" or Drawable

--scale of the blend texture
mesh.material.multiTextureBlendScale

--scale of second material UV
mesh.multiTextureUV2Scale = 1.0

--channel of the color buffer to be used as the blend factor
mesh.multiTextureColorChannel = 1

--apply shader
mesh:setVertexShader("multiTexture")
```