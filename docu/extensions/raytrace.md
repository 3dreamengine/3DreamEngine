# Raytrace

The raytrace extensions allows for fast ray vs mesh collision checks.

Check out the Tavern example for basic use case.

````lua
-- Load extension
local raytrace = require("extensions/raytrace")

-- Cast a ray from origin towards the direction, objects farther away than the directions are not taken in account
local result = raytrace:cast(object, origin, direction)
if result then
	local mesh = result:getMesh()
	local position = result:getPosition()
	local normal = result:getNormal()
end
````

## Optimize

While fast, it is generally a faste to test collisions against the full mesh. Instead you usually would like an abstract representation of the world, often the same as used in collisions.

Naming an object `RAYTRACE_yourObject` puts it into the `object.raytraceMeshes` table.

Supplying `true` as the fourth parameter switches to using only those meshes instead:

```lua
local result = raytrace:cast(object, origin, direction, true)
```