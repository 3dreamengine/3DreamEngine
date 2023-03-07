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

* Vec2, vec3, vec4 with common functions and metatables
* Mat2, mat3, mat4
* Quaternions
* A XML parser by Paul Chakravarti (`dream.xml2lua` and `dream.xmlTreeHandler`)
* A JSON parser by rxi (`dream.json`)
* Utils.lua which expands luas table, string and math libraries by common functions (`dream.utils`)
* Inspect by Enrique García Cota (`dream.inspect`)

