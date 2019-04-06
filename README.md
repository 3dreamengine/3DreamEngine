![3DreamEngine](https://owo.whats-th.is/9ceoazf.png)
<a href="https://discord.gg/hpmZxNQ"><img src="https://discordapp.com/api/guilds/561664262481641482/embed.png" alt="Discord server" /></a>

# Features
* loading and rendering .obj files, supports materials and textures included in .mtl files
* very fast rendering with z-buffer and vertex shaders
* inbuilt screen space ambient occlusion (ssao)
* inbuilt distance fog
* inbuilt "volumetric" clouds
* inbuilt sky sphere
* particle emitter (grass, leaves, random rocks, smaller details)
* diffuse and specular map
* point-source lightning (up to around 32 sources)
* per pixel lighting for better results at close light sources
* object merging to draw several objects at once
* load one big .obj as atlas and automatically split it up into sub objects

# In progress
* 3D polygons
* screen space reflections
* normal maps
* simple 3d collision

# How to use?
```lua
--load 3DreamEngine
dream = require("3DreamEngine")

--update settings if required
dream.fov = 90
dream.AO_enabled = false

--inits (applies settings)
dream:init()

--loads a object
yourObject = dream:loadObject("objectName")

function love.draw()
  --prepare for rendering
  dream:prepare()

  --draw
  dream:draw(yourObject, x, y, z, sx, sy, sz, rotX, rotY, rotZ)

  --done
  dream:present()
end
```

documentation in 3DreamEngine/init.lua

# Examples
We have examples in the examples folder. To run them, require the main.lua within the example. E.g. require("examples/monkey/main").

# Credits
- The LuaMatrix team at http://lua-users.org/wiki/LuaMatrix
- The Lamborghini .obj and textures from https://www.turbosquid.com/FullPreview/Index.cfm/ID/1117798
- Textures.com at https://www.textures.com/

# License (MIT/EXPAT LICENSE)
Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
