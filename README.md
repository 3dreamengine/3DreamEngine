![3DreamEngine](https://owo.whats-th.is/9ceoazf.png)
<a href="https://discord.gg/hpmZxNQ"><img src="https://discordapp.com/api/guilds/561664262481641482/embed.png" alt="Discord server" /></a>

# Features
* easy to use yet powerful 3D extension to LÖVE
* fast forward rendering with alpha pass
* metallness workflow (albedo, normal, roughness, metallic, ao, emission)
* HDR with bloom
* refractions
* screen space ambient occlusion (ssao)
* cubemap reflections
* proper blurred reflections on rough surfaces
* particle batches and single sprites
* particle/foliage systems
* simple custom shaders
* eye adaption effect
* cascade shadow mapping
* cubemap shadow mapping
* smooth shadows
* distance fog
* godrays
* included shaders for wind animation, water, ...
* supports .obj, .mtl, .dae and .vox
* threaded texture loading
* optional high performance file format to accelerate loading times
* included optimized vec2, vec3, vec4, mat2, mat3 and mat4 library
* Box2D extension to support basic 3D collisions
* dynamic clouds, sun, moon, stars and rainbows

![screenshots](https://raw.githubusercontent.com/3dreamengine/3DreamEngine/master/screenshots.jpg)


# development
Due to rapid changes to 3Dream I am working on a seperate branch ("beta"). While this branch is faster and offers more and improved features, I am experimenting with it and may change how things work.


# documentation
Undocumented features are subject to change. They will receive proper documentation once finished.

[Documentation hosted on GitHub](https://3dreamengine.github.io/3DreamEngine/)


# How to use?
```lua
--load 3DreamEngine
dream = require("3DreamEngine")

--optionally set settings
dream:setBloom(3)

--init (applies settings)
dream:init()

--loads a object
yourObject = dream:loadObject("examples/monkey/object")

--creates a light
light = dream:newLight("point", vec3(3, 2, 1), vec3(1.0, 0.75, 0.2), 50.0)

--add shadow to light source
light:addShadow()

function love.draw()
	--prepare for rendering
	dream:prepare()

	--add light
	dream:addLight(light) 

	--rotate, offset and draw
	yourObject:resetTransform() 
	yourObject:rotateY(love.timer.getTime())
	yourObject:translate(0, 0, -3)
	dream:draw(yourObject)

	--render
	dream:present()
end

function love.update()
	--update resource loader
	dream:update()
end
```

# Examples
We have examples in the examples folder. The provided main.lua contains a demo selection screen.

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