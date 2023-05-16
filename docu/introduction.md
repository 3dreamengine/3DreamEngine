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

### Alpha

By default materials are solid, and the alpha channel is ignored. To render alpha three approaches are available:

* `material:setAlpha()` to render on the alpha pass. This is slower, but allows transparency, blending and refractions.
* `material:setCutout()` to discard pixels after a threshold in alpha. Slower than solid, faster than alpha as it's rendered on the main pass and makes use of the depth buffer. It will result in hard edges and is the more common method.
* `material:setDither()` to simulate alpha using discarding on a dither pattern. Intended for fading, solid objects.

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

# Camera

A camera is another class created using `dream:newCamera()`, but it is recommended to use the default one at `dream.camera`, if no multi-camera scene is required.

A first person camera could look something like this, which resets the camera, moves it to a player, rotates yaw and then pitch:

```lua
dream.camera:resetTransform()
dream.camera:translate(player.x, player.y, player.z)
dream.camera:rotateY(player.ry)
dream.camera:rotateX(player.rx)
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

## Advanced Object loading

For everything beyond loading and rendering a singular object, let's take a look at advanced features:

### Scenes

````lua
local yourScene = dream:loadScene(path) 
````

A scene is an object, but restructured to have similar named objects grouped.
Imagine this object, loaded with `loadObject()`:

```
└─test
  └─objects
    ├─Lamp
    │ └─meshes
    │   └─mesh (96 vertices)
    ├─Lamp
    │ └─meshes
    │   └─mesh (96 vertices)
    ├─Lamp
    │ └─physics
    │   └─mesh
    ├─Lamp
    │ └─meshes
    │   └─mesh (96 vertices)
    └─Crate
      └─meshes
        └─mesh (96 vertices)

```

It consists of two objects, a Lamp and a Crate. The Lamp has a collider, two LODs and a light source.
Now, since Blender flattens any hierarchy we have a bit of a mess. You can not transform the entire lamp, since it's mixed with the crate. Now take a look at the object loaded using `dream:loadScene()`:

```
└─test
  └─objects
    ├─Lamp
    │ └─objects
    │   ├─Lamp
    │   │ └─meshes
    │   │   └─mesh (96 vertices)
    │   ├─Lamp
    │   │ └─meshes
    │   │   └─mesh (96 vertices)
    │   ├─Lamp
    │   │ └─meshes
    │   │   └─mesh (96 vertices)
    │   └─Lamp
    │     └─physics
    │       └─mesh
    └─Crate
      └─objects
        └─Crate
          └─meshes
            └─mesh (96 vertices)

```

We now have two objects, one for Lamp and one for Crate. Objects are merged based on their name, excluding any tags (explained later) and postfixes (seperated using a dot).

### Tags

Sometimes it is required to tag certain objects, e.g. mark them to use a specific LOD, or to be colliders, or to represent reflection gloves etc. Names are therefore parsed for tags in the format `{TAG:VALUE_|TAG_}name{.postfix}`. E.g. an LOD, which is also used as a collider could be called `LOD:0_PHYSICS_yourObject.001`.

Refer to the function documentation for a list of tags: `3DreamEngine/loader.lua".

### Linked Objects

If you use an object in several scenes, you might want to consider creating an object library, then reuse that object in your respective scenes.

This can be especially useful if your object consists of LODs, collisions, maybe light sources etc and copying them around is tedious.

````lua
-- Load a scene and register all objects as library objects, with given prefix.
dream:loadLibrary(path, args, prefix)

-- Or register a specific objects under a name
dream:registerObject(object, name)
````

Now tag your reference object, e.g. `LINK:yourObject_yourReferenceObject`.
That will replace that object during `dream:loadObject()` with the full library entry.
Which is usually faster, requires less memory on disk and allows for easier reuse and updating.

## Resource Loader

3Dream uses a resource manager to simplify texture loading.

[`dream:getImage(path, force)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#getImage) returns the image or false, if the image is not yet loaded. If not loaded, a request is made. Force enforces an immediate load.

[`dream:getImagePath(path)`](https://3dreamengine.github.io/3DreamEngine/docu/functions#getImagePath) returns the path to the best image, e.g. `test` may return `test.png` if such image is given.
It is therefore not necessary to provide extension in the material description files, `getImage()` function or any other `setTexture()` function you may encounter.

## Pipeline

3Dream uses a forward renderer and optional hard coded post effects. All draw calls are batched and rendered for all required reflections and shadows after calling `dream:present()`.