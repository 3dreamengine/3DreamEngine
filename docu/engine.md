# Engine
3Dreams idea is to be easy to use, without any fancy stuff or modularity. If the features provided are not enough, you are probably looking for a larger 3D engine.

- [Recommended Usage](#recommended-usage)
- [Materials](#materials)
- [Resource Loader](#resource-loader)
- [Pipeline](#pipeline)
- [3DO - 3Dream Object File](#3do---3dream-object-file)



## Recommended Usage
While it's possible to create an own object loader, the recommended way to use 3Dream consists of following steps to help the default loader optimize things:
* [Register optional shaders](https://3dreamengine.github.io/3DreamEngine/docu/shaders)
* [Register materials](#materials)
* [Create Objects Library](https://3dreamengine.github.io/3DreamEngine/docu/functions#object-library)
* [Load Objects](https://3dreamengine.github.io/3DreamEngine/docu/functions#load-object)

In other words, avoid setting materials or shaders after loading. In most cases it works fine, but some shaders do not work on final (cleaned up) objects.

Your draw/update code should look something like that:

```lua
function love.draw()
  --clear render queue, lights, ...
  dream:prepare()

  --setup lights
  dream:addLight(...)

  --draw your stuff
  dream:draw(...)

  --render
  dream:present()
end

function love.update(dt)
  --update resource loader
  dream:update()
end

function love.resize()
  --handle resizing
  dream:resize()
end
```



## Materials
[`dream:newMaterial()`](https://3dreamengine.github.io/3DreamEngine/docu/classes#material) and [`lib:registerMaterial(material, name)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#registerMaterial) can be used to register custom materials.

It makes sense to use a material loader instead, e.g. the inbuilt [`lib:loadMaterialLibrary(path, prefix)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#loadMaterialLibrary). It loads all materials recursively in a given directory, where a material is defined as either
* a directory with a `albedo.extension` texture
* a directory with the `material.mat` material description file
* a material description file `materialName.mat`

The first two directories should contain following textures (they have to contain the type in their file name)
* albedo (rgb)
* normal (xyz)
* roughness (r)
* metallic (r)
* emission (rgb)
* ao (r)
* material (xyz) (optional, would replace roughness, metallic and ao)

A material description file is a lua file with [specific fields](https://3dreamengine.github.io/3DreamEngine/docu/classes#data-structure).



## Resource Loader
3Dream uses a resource manager to simplify texture loading.
[`dream:getImage(path, force)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#getImage) returns the image or false, if the image is not yet loaded. If not loaded, a request is made. Force enforces an immediate load.

[`dream:getImagePath(path)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#getImagePath) returns the path to the best image, e.g. `test` may return `test.png` if such image is given. It is therefore not necessary to provide extension in the material description files, `getImage()` function or any other `setTexture()` function you may encounter.



## Pipeline
3Dream uses a forward renderer and optional hard coded post effects. All draw calls are batched and rendered for all required reflections and shadows after calling `dream:present()`.



## 3DO - 3Dream Object File
It is recommended to export your objects as 3do files, these files have only ~10-20% loading time compared to .obj or .dae and are better compressed. It supports all features as every class is serializable.
To export, just set the argument 'export3do' to true when loading the object. This saves it with the same relative path into the LÖVE save directory. Next time loading the game will use the new file instead. The original files are no longer required. If the original files are modified, the current 3DO file is rebuild automatically.