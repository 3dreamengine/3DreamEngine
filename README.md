![3DreamEngine](https://owo.whats-th.is/9ceoazf.png)
<a href="https://discord.gg/hpmZxNQ"><img src="https://discordapp.com/api/guilds/561664262481641482/embed.png" alt="Discord server" /></a>

# Features
* fast rendering with z-buffer and shaders
* PBR rendering (albedo, normal, roughness, metallic, ao, emission)
* Phong shading (color, normal, glossiness, specular, ao, emission)
* HDR with bloom
* screen space ambient occlusion (ssao)
* cubemap reflections
* proper blurred reflections on rough surfaces
* particle batches
* modular and extendable shaders
* dynamic clouds, sun, moon and stars
* rain with rain splashes, wetness and reflections
* eye adaption effect
* cascade shadow mapping
* cubemap shadow mapping
* smooth shadows
* distance fog
* static particle emitter (grass, leaves, random rocks, smaller details)
* wind animation (leaves, grass, ...)
* loading and rendering .obj files, supports materials and textures included in .mtl files
* threaded texture loading with automatic thumbnail generation
* threaded object loading using 3DreamEngine specific object files (converter included)
* included optimized vec2, vec3, vec4, mat2, mat3 and mat4 library
* 3D transformation-tree-based collision extension, supports closed meshes collision

![screenshots](https://raw.githubusercontent.com/3dreamengine/3DreamEngine/master/screenshots.jpg)


# How to use?
```lua
--load 3DreamEngine
dream = require("3DreamEngine")

--optionally set settings
dream.bloom_enabled = false

--inits (applies settings)
dream:init()

--loads a object
yourObject = dream:loadObject("examples/monkey/object")

function love.draw()
  --reset lighting to default sun
  dream:resetLight()
  
  --prepare for rendering
  dream:prepare()

  --rotate and draw and offset
  yourObject:rotateY(love.timer.getDelta())
  dream:draw(yourObject, 0, 0, -5)

  --render
  dream:present()
end
```

# documentation
[Documentation hosted on GitHub](https://github.com/3dreamengine/3DreamEngine/index.md)

# Examples
We have examples in the examples folder. The provided main.lua contains a demo selection.

# Credits
- [Lamborghini model](https://www.turbosquid.com/FullPreview/Index.cfm/ID/1117798)
- cc0textures.com
- texturehaven.com
- hdrihaven.com.com
- cgbookcase.com
- [Stars and Moon by Solar Textures](https://www.solarsystemscope.com/textures/)

# License (MIT/EXPAT LICENSE)
Copyright 2020 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
