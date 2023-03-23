# Content

Most functions are annotated using EmmyLua doc.

## Usage

- [Introduction](https://3dreamengine.github.io/3DreamEngine/docu/introduction)
  Main components and design choices of the engine. You should read that.

- [Particles](https://3dreamengine.github.io/3DreamEngine/docu/particles)
  The 3D-version of loves spritebatches, designed to draw 2D Images with high performance

- [Skeletons](https://3dreamengine.github.io/3DreamEngine/docu/skeletons)
  Skeletal Animations

- [Shaders](https://3dreamengine.github.io/3DreamEngine/docu/particles)
  More advanced shader modifications, from wind shader to skeletal animations

- [Performance](https://3dreamengine.github.io/3DreamEngine/docu/performance)
  Tips and tricks to double the FPS!

## Documentation
[Dream](https://3dreamengine.github.io/3DreamEngine/docu/classes/dream)


* [Animation](https://3dreamengine.github.io/3DreamEngine/docu/classes/animation)  
* [AnimationFrame](https://3dreamengine.github.io/3DreamEngine/docu/classes/animationframe)  
* [Bone](https://3dreamengine.github.io/3DreamEngine/docu/classes/bone)  
* [BoundingSphere](https://3dreamengine.github.io/3DreamEngine/docu/classes/boundingsphere)  
* [Buffer](https://3dreamengine.github.io/3DreamEngine/docu/classes/buffer)  
* [Camera](https://3dreamengine.github.io/3DreamEngine/docu/classes/camera)  
* [Canvases](https://3dreamengine.github.io/3DreamEngine/docu/classes/canvases)  
* [CollisionMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/collisionmesh)  
* [InstancedMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/instancedmesh)  
* [Light](https://3dreamengine.github.io/3DreamEngine/docu/classes/light)  
* [Material](https://3dreamengine.github.io/3DreamEngine/docu/classes/material)  
* [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)  
* [MeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshbuilder)  
* [MeshFormat](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshformat)  
* [Object](https://3dreamengine.github.io/3DreamEngine/docu/classes/object)  
* [Particle](https://3dreamengine.github.io/3DreamEngine/docu/classes/particle)  
* [Pose](https://3dreamengine.github.io/3DreamEngine/docu/classes/pose)  
* [Position](https://3dreamengine.github.io/3DreamEngine/docu/classes/position)  
* [RaytraceMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/raytracemesh)  
* [Reflection](https://3dreamengine.github.io/3DreamEngine/docu/classes/reflection)  
* [Shader](https://3dreamengine.github.io/3DreamEngine/docu/classes/shader)  
* [Shadow](https://3dreamengine.github.io/3DreamEngine/docu/classes/shadow)  
* [Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton)

## Extensions

- [Sky](https://3dreamengine.github.io/3DreamEngine/docu/extensions/sky)
  Dynamic Sky

- [Raytrace](https://3dreamengine.github.io/3DreamEngine/docu/extensions/raytrace)
  Fast ray-mesh intersection extension, designed for object selection, bullet calculations, ...

- [Physics](https://3dreamengine.github.io/3DreamEngine/docu/extensions/physics)
  Y-axis extension to Box2D. Works fine on primitives, not recommended for complex shapes.

- [Sounds](https://3dreamengine.github.io/3DreamEngine/docu/extensions/sounds)
  3D sound + sound resource manager. WIP.

## Libraries

There are a few libraries included you can use. Check their files for supported functions

* Vec2, vec3, vec4 with common functions and metatables (`dream.vecn`)
* Mat2, mat3, mat4 (`dream.matn`)
* Quaternions (`dream.quat`)
* A XML parser by Paul Chakravarti (`dream.xml2lua` and `dream.xmlTreeHandler`)
* A JSON parser by rxi (`dream.json`)
* Utils.lua which expands luas table, string and math libraries by common functions (`dream.utils`)
* Inspect by Enrique García Cota (`dream.inspect`)

