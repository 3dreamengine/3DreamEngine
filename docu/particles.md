# Particle Batches

Particles are batched and rendered all together.

```lua
batch = dream:newParticleBatch(texture)
batch = dream:newParticleBatch(texture, emissionTexture)
```

`texture` LÖVE drawable  
`emissionTexture` LÖVE drawable for emission

<br />

Enqueue for drawing.

```lua
dream:drawParticleBatch(batch)
```

<br />

Adds particles.

```lua
batch:add(x, y, z, sx, sy, emission)
batch:addQuad(quad, x, y, z, sx, sy, emission)
```

`quad` LÖVE quad to use
`x, y, z` position  
`sx, sy, sz` scale, where, unlike single particles, 1 unit is exactly 1 meter  
`emission (0.0 or 1.0 with emission texture)` emission multiplier

<br />

```lua
batch:clear()
count = batch:getCount()
```

`count` amount of currently inserted particles

<br />

Set additional settings (all functions have getters too)

```lua
batch:setTexture(tex)
batch:setEmissionTexture(tex)
batch:setSorting(enabled)
batch:setVertical(vertical)
```

`tex` LÖVE drawable  
`enabled` sort particles, only required for textured particles in the alpha pass  
`vertical` 1.0 points to the sky, useful for candles, ...  