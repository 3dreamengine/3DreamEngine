![3DreamEngine](https://owo.whats-th.is/3AGtVNV.png)
<a href="https://discord.gg/hpmZxNQ"><img src="https://discordapp.com/api/guilds/561664262481641482/embed.png" alt="Discord server" /></a>

# Note
The 3d engine is working (check out the examples) however the documentation is being worked on be patient!

# Features
* loading and rendering .obj files
* very fast rendering with z-buffer and vertex shaders
* inbuilt screen space ambient occlusion (ssao)
* inbuilt distance fog
* diffuse and specular map
* point-source lightning (up to around 32 sources)
* per pixel lighting for better results at close light sources
* object merging to draw several objects at once
* load and render custom vertex lists
* load one big .obj as atlas and automatically split it up into sub objects

# In progress
* particle systems
* custom shaders (water waves, leaves, waving grass)
* 3D polygons

# How to use?
```lua
--load 3DreamEngine
l3d = require("3DreamEngine")

--update settings if required
l3d.fov = 90
l3d.AO_enabled = false

--inits (applies settings)
l3d:init()

--loads a object
yourObject = l3d:loadObject("objectName")

function love.draw()
  --prepare for rendering
  l3d:prepare()

  --draw
  l3d:draw(model, x, y, z, sx, sy, sz, rotX, rotY, rotZ)

  --done
  l3d:present()
end
```

# Examples
We have examples in the examples folder. To run them, require the main.lua within the example. E.g. require("examples/monkey/main").

# Credits
- The LuaMatrix team at http://lua-users.org/wiki/LuaMatrix
- The Lamborghini .obj and textures from https://www.turbosquid.com/FullPreview/Index.cfm/ID/1117798

# License (MIT/EXPAT LICENSE)
Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
