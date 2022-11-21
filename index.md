# Content

Most functions are annotated using EmmyLua doc strings.

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

* Extensions
    - [Sky](https://3dreamengine.github.io/3DreamEngine/docu/extensions/sky)
      Tips and tricks to double the FPS!

    - [Raytrace](https://3dreamengine.github.io/3DreamEngine/docu/extensions/raytrace)
      Fast ray-mesh intersection extension, designed for object selection, bullet calculations, ...

    - [Physics](https://3dreamengine.github.io/3DreamEngine/docu/extensions/physics)
      Y-axis extension to box2d. Quite fast, works perfectly on prims, works mostly on more complex shapes.

    - [Sounds](https://3dreamengine.github.io/3DreamEngine/docu/extensions/sounds)
      3D sound + sound resource manager. WIP.

There are a few libraries included you can use. Check their files for supported functions

* vec2, vec3, vec4 with common functions and metatables
* mat2, mat3, mat4
* quaternions
* a XML parser by Paul Chakravarti (`dream.xml2lua` and `dream.xmlTreeHandler`)
* a JSON parser by rxi (`dream.json`)
* utils.lua which expands luas table, string and math libraries by common functions (`dream.utils`)
* inspect by Enrique García Cota (`dream.inspect`)