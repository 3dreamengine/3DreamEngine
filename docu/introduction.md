# Engine

3Dreams idea is to be easy to use with a small but complete set of features.
If the features provided are not enough, or too slow, you are probably looking for a more advanced 3D engine.

Now, let's explain the basic components:

# Classes

3Dream uses classes and instances to represent most data objects.
For More information about specific classes, check out `3DreamEngine/classes/*`.

# Materials

Since object loading depends on having the correct materials and shader, it is recommended to start with defining the materials.

Importing materials from the respective file formats technically work (especially gltf), materials tend to be broken or misconfigured depending on the exporter.

Therefore, let's focus on two ways of adding materials to the `material library`:

````lua
-- Create an empty material
local material = dream:newMaterial()

-- Configure it
material:setAlbedoTexture("some/image.png")
material:setMetallic(1.0)
material:setRoughness(1.0)

-- And register it under the same name as used in your 3D model
dream:registerMaterial(material, "yourMaterial")
````

Now, since materials are quite common things there is a recommended shortcut:

````lua
-- Load all materials in a directory
dream:loadMaterialLibrary("materials")
````

Where the structure of that directory can be recursive, and can contain three possible material types:

* a directory with a `albedo.extension` texture
* a directory with a `material.lua` material description file
* a material description file `materialName.lua`

The first two variants should contain following textures:

* albedo (rgb)
* normal (xyz)
* roughness (r)
* metallic (r)
* emission (rgb)
* ao (r)
* material (xyz) (optional, would replace roughness, metallic and ao)

The material description file is a lua file returning a table defining the values as in `3DreamEngine/classes/material.lua`

Check out the `examples/Tavern/materials/` demo for an example.

# Objects

An object is a container for all kind of data, including other objects. It may store your scene graph, a character, animations, collision data, basically everything.

```lua
-- Create a new object
yourObject = dream:loadObject(path)

-- Print that object to get an better overview on what it contains.
yourObject:print()

-- Transform that object
yourObject:resetTransform()
yourObject:translate(1, 2, 3)

-- Create an identical object, which can have a different transform
yourSecondObject = yourObject:newInstance()

-- Clones an object, which can be modified (material, skeleton, ...) without affecting the original
yourSecondObject = yourObject:clone()
```

# Render loop

Your draw/update code should look something like that:

```lua
function love.draw()
	--clear render queue, lights, ...
	dream:prepare()
	
	--setup lights
	dream:addLight(...)
	
	--draw your stuff
	dream:draw(yourObject)
	dream:draw(yourSecondObject)
	
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

## Resource Loader

3Dream uses a resource manager to simplify texture loading.

[`dream:getImage(path, force)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#getImage) returns the image or false, if the image is not yet loaded. If not loaded, a request is made. Force enforces an immediate load.

[`dream:getImagePath(path)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#getImagePath) returns the path to the best image, e.g. `test` may return `test.png` if such image is given.
It is therefore not necessary to provide extension in the material description files, `getImage()` function or any other `setTexture()` function you may encounter.

## Pipeline

3Dream uses a forward renderer and optional hard coded post effects. All draw calls are batched and rendered for all required reflections and shadows after calling `dream:present()`.