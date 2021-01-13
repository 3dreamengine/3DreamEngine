# collisions
DEPRICATED
The collision extension supports exact collision detection between a collider and another collider or (nested) group.

The second collider/group therefore creates an tree, allowing optimisation and recursive transformations.

A transformation is either a mat4 or a vec3 offset. Transformations with different scales per axis might not work on certain types due to optimisations (e.g. mesh works, spheres do not).

The collision extension is rather slow and relies on proper optimisation of the scene (usage of groups, collision meshes with decreased vertex count, ...). I am working on threaded and C-implementations to increase performance, but do not expect more than a 4x improvement. Just don't overuse them or use a proper library.

There will not be a physics engine.

```lua
--load the extension
collision = require("3DreamEngine/collision")

--functions
normal, position = collision:collide(a, b, fast)   --checks for collisions between a and b, where a can not be a group. Fast skips deep scan and only returns true or false. Normal and positions are averaged.
collision:getCollisions()                          --returns an array containing all collisions in the format {normal, position, collider} a has collided with
collision:print(collider)                          --recursively print the collider and a few relevant stats

--a helper function, returning the resulting velocity final, its approximate impact speed and the finals raw components reflect and slide based on its current velocity, normal vector of impact, elastiness from 0 to 1 and friction from 0 to 1
final, impact, reflect, slide = collision:calculateImpact(velocity, normal, elastic, friction)

--colliders
collision:newGroup(transform)          --create a group
collision:newSphere(size, transform)   --create a sphere with radius
collision:newBox(size, transform)      --create a box with vec3 size
collision:newPoint(transform)          --create a point
collision:newSegment(a, b)             --create a segment between a and b
collision:newMesh(object, transform)   --create a mesh from an object (creating a sub group automatically), a subobject or a collision (see next sub chapter)


--collider functions
collider:clone()                  --create a copy from it, only linking mesh data if present
collider:moveTo(vec3 offset)      --moves to a position (e.g. offset this collider)
collider:moveTo(mat4 transform)   --transforms this object
collider:moveTo(x, y, z)          --same as first but with numbers

--additional functions for groups
collider:add(o)                   --add an object to its children
collider:remove(o)                --remove an object from its children
```



## collisions in objects
Naming a subobject "COLLISION..." will load it as a collision mesh and removes it from the regular meshes.
Use them to define an abstract representation of your object to save CPU power.
Those collisions are stored in 'object.collisions[name]' similar as regular subObjects.
When loading the entire object, it will only use those special collision meshes.
Theoretically one can pass a specific collision directly.