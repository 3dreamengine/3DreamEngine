# Physics Extension

Physics is based on Box2D and has been extended to support basic 3D functionality.
It is not a replacement for a proper 3D collision/physics library.
It can also be used solely for 2D, to simplify shape generation of meshes etc.

Theoretically, all functions like joints, motors, chains etc. works. in 2D. Whether they make sense in a 3D environment is another question.

# World

A world is a wrapper of the Box2D world, contains the resolver for the third dimension and provides a few additional methods for adding and removing shapes.

# Shape

A Shape contains the Love2D shape, but also additional height information to simulate the 3rd axis.

## Mesh Shape

A mesh shape is internally a list of polygon shapes and is the only shape with complex height information ([See collisions](#collisions)).

* 1

## Cylinder/Capsule

Both are cylindrical colliders, but the cylinder is more accurate on meshes.

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