# Physics Extension

Physics is based on Box2D and has been extended to support basic 3D functionality.
It is not a replacement for a proper 3D collision/physics library.
It can also be used solely for 2D, to simplify shape generation of meshes etc.

Theoretically, all functions like joints, motors, chains etc. works. in 2D. Whether they make sense in a 3D environment is another question.

# Example

```lua
--require extension
local physics = require("extensions/physics/init")

--create a new world
local world = physics:newWorld()

--load object
local object = dream:loadObject("object")

--create a shape from this object and it's current transformation
local shape = physics:newObject(object)

--add this shape to the world
local collider = world:add(shape, "dynamic", x, y, z)

function love.update(dt)
	--update the physics
	world:update(dt)
end
```

# World

A world is a wrapper of the Box2D world, contains the resolver for the third dimension and provides a few additional methods for adding and removing shapes.

# Shape

A Shape contains the Love2D shape, but also additional height information to simulate the 3rd axis.

## Mesh Shape

A mesh shape is internally a list of polygon shapes and is the only shape with complex height information ([See collisions](#collisions)).

* `wall` - no height information, extends to inf
* `height` - extend the height to inf
* `simple` (default) - allows every shape towards the top, e.g. vertices on the bottom side may not fully reflect the actual shape
* `complex` - supports all shapes, with much higher build time and potential higher runtime performance impact

## Object Shape

Objects combine all meshes from an entire object into one Mesh Shape.

## Primitives

All other primitives only use a height (or top and bottom Y).

## World Shape

WIP

That one is special, as it does not interact with Box2D. Instead, it recycles the mesh collision in a more efficient way to allow heightmap collisions faster than when misusing Box2d.

# Collisions

WIP

Collision resolving differentiates between 2 types of collisions: Complex height supports accurate height, while simple height only has a flat top and bottom.

## Simple Height vs Simple Height

Fast collision resolving, does not affect velocity, since no gradient is present. This collision usually happens between dynamic types, but may also be simple, static landscapes.

## Simple Height vs Complex Height

A much slower resolver, which considers the top and bottom surface of the complex collider. It is not perfectly accurate but is usually sufficient for landscape/environment collisions.

## Complex Height vs Complex Height

This collision is invalid.