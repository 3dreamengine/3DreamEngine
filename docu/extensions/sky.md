# Sky
The sky module provides a few helpful tools to generate semi-dynamic sky spheres.

```lua
--require extension
local sky = require("extensions/sky")

--set sky renderer
dream:setSky(sky.render)
```

## Clouds
Clouds are rotating cubemaps, simulating moving cloud layers.
```lua
sky:setClouds(clouds)
clouds = sky:getClouds()
```
`clouds` is an array of tables
```lua
{
    texture = Cubemap, --texture
    rotation = 0, --initial rotation
    rotationDelta = -0.001, --rotation
    color = {1.0, 1.0, 1.0}, --base color
}
```


## Sky Color
```lua
sky:setSkyColor(rain)
sky:setSkyColor(color)
color = sky:getSkyColor()
```
`rain` from 0 to 1 to generate an estimated bluish tone  
`color` RGB color  


## Day Time
```
sky:setDaytime(sun, time)
```
`sun` a light object to set the direction  
`time`  time of day between 0 and 1 (starting at sunrise)

<br />

```lua
sky:setSunOffset(offset, rotation)
offset, rotation = sky:getSunOffset()
```
`offset` offset where 0 is the equator and 1 the north pole when using 'sky:setDaytime()'  
`rotation` the rotation on the Y axis  


## Rainbow
Renders a rainbow on the sky dome.

```lua
sky:setRainbow(strength, size, thickness)
sky:setRainbow(strength)
strength, size, thickness = sky:getRainbow()
```
`strength` the strength, usually between 0 and 1  
`size (~42°)` angle from viewer  
`thickness (0.2)` rainbow width  

<br />

```lua
sky:setRainbowDir(dir)
dir = sky:getRainbowDir()
```
`dir` vec3 of rainbow. Physically this is always -sunVector, but can be set for artistic reasons manually.  


## Moons
WIP