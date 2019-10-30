![3DreamEngine](https://owo.whats-th.is/9ceoazf.png)
<a href="https://discord.gg/hpmZxNQ"><img src="https://discordapp.com/api/guilds/561664262481641482/embed.png" alt="Discord server" /></a>

# Features
* loading and rendering .obj files, supports materials and textures included in .mtl files
* fast rendering with z-buffer and vertex shaders
* screen space ambient occlusion (ssao)
* distance fog
* pseudo-volumetric clouds
* sky sphere
* static particle emitter (grass, leaves, random rocks, smaller details)
* specular map
* normal map
* pseudo-reflections
* wind animation (leaves, grass, ...)
* point-source lighting
* threaded object loading using 3DreamEngine specific object files, boosted with luaJITs FFI, converter included
* threaded texture loading
* anaglyph 3D

![screenshots](https://raw.githubusercontent.com/3dreamengine/3DreamEngine/master/screenshots.jpg)


# How to use?
```lua
--load 3DreamEngine
dream = require("3DreamEngine")

--inits (applies settings)
dream:init()

--loads a object
yourObject = dream:loadObject("examples/monkey/object")

function love.draw()
  --reset lighting
  dream:resetLight()
  
  --prepare for rendering
  dream:prepare()

  --rotate and draw
  yourObject:rotateY(love.timer.getDelta())
  dream:draw(yourObject, 0, 0, -5)

  --done
  dream:present()
end
```

# documentation

## settings
```lua
dream.objectDir = "objects"      --root directory of objects
dream.fov = 90                   --field of view (10 < fov < 180)

dream.AO_enabled = true          --ambient occlusion?
dream.AO_strength = 0.5          --blend strength
dream.AO_quality = 24            --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 1      --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.5        --resolution factor

lib.bloom_enabled = true         --enable bloom (simulate brightness exceeding the 1.0 screen limit)
lib.bloom_size = 12.0            --the size of the bloom effect
lib.bloom_quality = 4            --the steps of blurring
lib.bloom_resolution = 0.5       --the resolution while blurring
lib.bloom_strength = 2.0         --the blend strength

lib.anaglyph3D = false           --enable anaglyph 3D (red - cyan)
lib.anaglyph3D_eyeDistance = 0.05--distance between eyes

dream.lighting_max = 16          --max light sources, depends on GPU, has no performance impact if sources are unused

dream.abstractionDistance = 30   --if simple files are provided (check chapter simple files) every 30 units of distance one more level of abstraction is used

dream.nameDecoder = "blender"    --blender/none automatically renames objects, blender exports them as ObjectName_meshType.ID, but only ObjectName is relevant

dream.startWithMissing = false   --use the gray missing texture, then load the textures threaded

--use the inbuilt sky sphere and clouds
dream.cloudDensity = 0.6
dream.clouds = love.graphics.newImage("clouds.jpg")  --a noise texture, see firstpersongame for examples
dream.sky = love.graphics.newImage("sky.jpg")        --2:1 background
dream.night = love.graphics.newImage("night.jpg")    --can be nil to only have daytime
```

## functions
```lua
--inits (applies settings, reload canvases, ...)
dream:init()

--loads an object
yourObject = dream:loadObject("objectName", args)

	--where args is a table with additional settings
	splitMaterials       -- if a single mesh has different textured materials, it has to be split into single meshes. splitMaterials does this automatically.
	raster               -- load the object as 3D raster of different meshes (must be split). Instead of an 1D table, obj.objects[x][y][z] will be created.
	forceTextured        -- if the mesh gets created, it will determine texture mode or simple mode based on tetxures. forceTextured always loads as (non set) texture.
	noMesh               -- load vertex information but do not create a final mesh - template objects etc
	noParticleSystem     -- prevent the particle system from bein generated, used by template objects, ... If noMesh is true and noParticleSystem nil, it assume noParticleSystem should be true too.
	cleanup              -- release vertex, ... information once done - prefer using 3do files if cleanup is nil or true, since then it would not even load this information into RAM
	export3do            -- loads the object as usual, then export the entire object, including simple versions and particle system, as a single, high speed 3do file

--the name of the object (set by "o" inside .obj, in blender it is the name of the vertex data inside an object) can contain information:
--  if it contains REMOVE, it will not be used. Their use can be frames, particle emitters, helper objects, ...)
--  if it contains LAMP_name where name is a custom name, it will not be loaded, but instead an entry in object.lights will be made {name, x, y, z}, it can be used to set static lights more easy.
--    prefixes, for example Icosphere_LAMP_myName are valid and will be ignored.

--if 3do files or thumbnail textures are used, the resource loader requires to be updated. It controls the loader threads and texture loading.
dream.resourceLoader:update()

--transform the object
yourObject:reset()
yourObject:translate(x, y, z)
yourObject:scale(x, y, z)
yourObject:rotateX(angle)
yourObject:rotateY(angle)
yourObject:rotateZ(angle)

--update camera postion (transformations as yourObject)
dream.cam:reset()
dream.cam:translate(x, y, z)

--if you want an own camera use
yourCam = dream:newCam()
--and pass it to dream:prepare()

--update time (0-1, %1 applied automatically), where 0 is midnight
dream.dayTime = love.timer.getTime() * 0.05

--update sun position/vector, for example based on the dayTime var
dream.sun = {0.3, math.cos(dream.dayTime*math.pi*2), math.sin(dream.dayTime*math.pi*2)}

--update sun color, where color is a vec4, alpha is a multiplier, getDayLight() return colors based on dayTime.
dream.color_sun, dream.color_ambient = dream:getDayLight()

--resets light sources (if noDayLight is set to true, the sun light will not be added automatically)
dream:resetLight(noDayLight)

--add light, note that in case of exceeding the max light sources it only uses the most relevant sources, based on distance and brightness
dream:addLight(posX, posY, posZ, red, green, blue, brightness)

--prepare for rendering
--if cam is nil, it uses the default cam (dream.cam)
dream:prepare(cam)

--draw
--obj can be either the entire object, or an object inside the file (obj.objects.yourObject)
dream:draw(obj, x, y, z, sx, sy, sz)

--finish render session, it is possible to render several times per frame
--noDepth disables the depth buffer, useful for gui or background elements
--if noDepth is enabled, noSky will be true too by default
dream:present(noDepth, noSky)
```

## textures
To add textures to the model either...
* set the texture path (without extension!) in the mtl file (map_Kd, map_Ks, map_Kn, map_Ke for diffuse, specular, normal and emission)
* set the texture path (without extension!) or the loaded texture (not recommended) in the 3de file (tex_diffuse, tex_specular, tex_normal, tex_emission)
* name the textures exactly like a) the object or b) like the material and put it next to the object. It will find it automatically.

The diffuse texture is a RGB non alpha texture with the color.
The specular texture is either the sharpness of specular lighting, or more importantly the amount of reflection if enabled.
The normal texture contains local normal coordinates.
The emission texture contains RGBA, where A is just a multiplier, and will be multiplied by the materials emission value. Check out the Lamborghini example for an example. Only makes sense if bloom is enabled.

## simple files
Simple files decrease loading time and increase performance by using simplified objects.
* Only supported in 3do files: load only the layer of abstraction actually needed, based on distance. Also, load simpler version first, then complex ones to faster provide results.
* Supported on obj files too: display abstraction based on distance.
Simple files (only .obj, .mtl will be ignored) have to contain the same materials, the same objects (or less) and should look similar enough to avoid ugly transitions.

Textures can also be simple: yourTexture_simple_1.png, ...

If startWithMissing is disabled, it will load the lowest quality file first. Simpler textures do not have to has the same file format. Mixing png and jpg works too.
Texture loading then is threaded and will load nessesary textures automatically, based on distance.
(dream.resourceLoader:update() required)

## reflections
To enable reflections on materials either ...
* set material.reflections_day / material.reflections_night to a path (without extension, uses resource loader) or to an texture.
* set object.reflections_day / object.reflections_night to a path (without extension, uses resource loader) or to an texture.
* set material.reflections to true ("reflections true" in mtl files, "reflections = true" in 3de files). This will use the sky/night sphere texture if provided.

(in order, if the material already has an texture defined, it will use it instead of the objects texture)

## 3de - 3Dream material file
The .mtl file usually exported with .obj will be loaded automatically.
To use more 3DreamEngine specific features (reflections, particle system, wind animation ...) a .3de file is required. A .3de file can replace the .mtl file entirely, else it will extend it.
If you do not edit the variables it is recommended to remove the line, it then uses the default values.
(dream.resourceLoader:update() required)

### example 3de file:
```lua 
--3DreamEngine material properties file
return {
	Grass = { --extend material Grass
		reflections = true,            -- metalic reflections (using specular value)
		
		shader = "wind",               -- shader affecting the entire object
		shaderInfo = 1.0,              -- animation multiplier
		
		--some shaders have additional values, like the wind shader (currently the only one)
		shader_wind_speed = 0.5,       -- the time multiplier
		shader_wind_strength = 1.0,    -- the multiplier of animation
		shader_wind_scale = 3.0,       -- the scale of wind waves
		
		color = {1.0, 1.0, 1.0, 1.0},  -- color used for flat shading
		specular = 0.5,                -- specular or reflection used when no specular texture is provided
		emission = 0.0,                -- the brightness of the emission texture, the diffuse texture or the face color
		
		alphaThreshold = 0.0           -- since the depth buffer only supports alpha 0.0 or 1.0, a threshold will choose when to draw. For grass, ... a threshold of 0.75 works fine.
		
		--change textures
		tex_diffuse = "tex_diffuse",
		tex_normal = "tex_normal",
		tex_specular = "tex_specular",
		tex_emission = "tex_emission",
		
		--a function called every object before rendering
		--while you can change any values, do NOT remove values (like textures). Only switch them if necessary.
		--m is the material, o is either the object, or the subObject (rare case)
		update = function(m, o)
			o.torch_id = o.torch_id or math.random()
			m.emission = love.math.noise(love.timer.getTime() * 2.0 + o.torch_id) * 1.0 + 1.0
		end,
		
		--add particleSystems
		particleSystems = {
			{ --first system
				objects = { --add objects, they have to be in the same directory as the scene (sub directories like particles/grass work too)
					["grass"] = 20,
				},
				randomSize = {0.75, 1.25}, --randomize the particle size
				randomRotation = true, --randomize the rotation
				normal = 0.9, --align to 90% with its emitters surface normal
				shader = "wind", --use the wind shader
				shaderInfo = "grass", --tell the wind shader to behave like grass, the amount of waving depends on its Y-value
				--shaderInfo = 0.2, --or use a constant float
			},
		}
	},
}
```

## 3do - 3Dream object file
It is strongly recommended to export your objects as 3do files, these files can be loaded on multiple cores, have only ~10-20% loading time compared to .obj and are better compressed.
To export, just set the argument export3do to true when loading. This then combines the .obj, .mtl, .3de file and particle systems into one .3do files and saves it with the same relative path into the LÖVE save directory. Next time loading the game will use the new file instead. The original files are no longer required. (Except for modifying)

But note that...
* The file will not refresh if changes to the original files are made
* You can not modify 3do files, they contain binary mesh data. Therefore keep the original files!
* Particle systems and simple files are packed too, it is not possible to e.g. change the particle system based on user settings. Instead, disable particle system objects manually (yourObject.objects.particleSystemName.disabled = true).

## Object format
dream:loadObject() returns an object using this format:
```lua
object = {
	materials = {
		None = {
			color = {1.0, 1.0, 1.0, 1.0},
			specular = 0.5,
			--may contain more, see example file from 3do chapter
			name = "None",     --internal value, equal to material key (None)
			ID = 1,            --internal value
		},
	},
	materialsID = {"None"}, -- internal value, only used for flat shading to store a single ID
	
	objects = {
		yourSubObject = {
			faces = {
				{1, 2, 3}, --final ids
			},
			final = {
				{x, y, z, shaderData, nx, ny, nz, materialID, u, v, tx, ty, tz, btx, bty, btz}, -- position, shader extra value e.g. for animation, normal, materialID (used for flat shading), uv coords (may be nil for flat shading), tangent and bitangent (calculated automatically)
			},
			-- when using 3do or when args.cleanup is enabled (default is true!) faces and final will be deleted once the mesh is created
			
			material = material, --mesh material. If several materials are used (and splitMaterials is disabled), it can only use the last.
			
			name = "yourSubObjectBaseName", --the name, without material postfixes (if splitMaterials is used) and simple postfixes (simple_x)
			simple = simple, --the level of abstraction, or nil
			super = simple == 1 and nameBase or simple and (nameBase .. "_simple_" .. (simple-1)) or nil, --the next more detailed object
			simpler = simple and (nameBase .. "_simple_" .. (simple+1)) or nil, --the next more abstract object, object may not exist
			
			meshType = "textured", --flat, textured or textured_normal - determines the data the mesh contains
			mesh = love.graphics.newMesh(), --a static, triangles-mesh, may be nil when using 3do, loads automatically
		}
	},
	
	loaded = true, --true if fully loaded, always true by .obj, with .3do when all meshes are loaded (they only load when needed)

	--instead of loading LIGHT_ objects as meshes, put them into the lights table for manual use and skip them.
	lights = { },

	path = path, --absolute path to object
	name = name, --name of object
	dir = dir, --dir containing the object

	--args as provided in loadObject
	splitMaterials = args.splitMaterials,
	--...
	--...
	--...

	--the object transformation
	transform = matrix{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	},

	--project related functions
	reset = self.reset,
	--...
	--...
	--...

	self = self, --the 3DreamEngine itself
}
```


# Examples
We have examples in the examples folder. The provided main.lua contains a demo selection.

# Credits
- The LuaMatrix team at http://lua-users.org/wiki/LuaMatrix
- The Lamborghini .obj and textures from https://www.turbosquid.com/FullPreview/Index.cfm/ID/1117798
- Textures.com at https://www.textures.com/

# License (MIT/EXPAT LICENSE)
Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
