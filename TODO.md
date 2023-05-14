# TODO

A list of upcoming changes and features.

# Critical

* Getter for material
* Doc for material
* Clazz for shader and light classes, maybe instead of current linking massacre

# Merge particles with default pipeline

A particle is just a object with a transform and a material with diffuse, emission and distortion texture as well as custom shader
particle uses internally a particle builder
Similar, a particles batch is just an instanceBuilder with custom material and shader
No overhead since fast drawMesh(mesh, transform) can be used too

# Fix 3DO

Each class is serializable, also expand that to vectors (e.g. save __class = "vec3")

# Improve Doc

Light sources and a lot of other classes completely missing

# Improve godrays

The current light disk approach performs barely acceptable, but can be further enhanced:

* Tweak the disk, make rays texture less sharp
* Instead of calculating pixels on the entire screen, convert the disks border into a radian stripe and only calculate that
* Then use this 1D stripe for the rest of the screen, lookup using atan, no godray within the disk
* This lookup table is generated for each light source (e.g.: 8px output), and then applied all at once, thus allowing easy multi source godrays if required

# Performance

* Finish LODs + example
* Simplify Vertical particles
    * Prevents optimizations for very little effect
* One more attempt on transformation caching
    * If we had a scene tree, transformations could be cached
    * This only works if all objects are unique, which instantiate ensures
    * To provide backwards compatibility
    * Cache transform, position and scale for objects and meshes by using a weak parent table .cache
    * All operations on objects now need to use the adder and remover functions to ensure integrity
        * Protect objects and meshes with metatable just to make sure
        * Protect instances from being linked to a shared memory block more than once
        * Use https://stackoverflow.com/questions/27426704/lua-5-1-workaround-for-gc-metamethod-for-tables to free space in the global shared memory
* Add an experimental freezeShader function
    * The only way for the shader to change is
        * Changes to the material, reflection, mesh, global shader and scene settings
        * A cache would add a subcache to the shader cache and is slightly faster at the expense of potential missed update errors
* Threaded scenes
    * A scene would need a perfect reconstruction of all transforms and bounding boxes on a thread
        * That would work with the assumption of uniqueness!
    * The sync happens via a shared memory segment
    * The thread traverses the tree, places the transforms (maybe its even save to directly use that memory segment in the shader), does frustum culling, lods and sorting, and provides an argsort list.
    * The main thread syncs back with the thread and uses the array
    * Only issue: the main thread needs to do other work in the meantime.
        * The smoothest way are coroutines, render just adds its 1 or 2 (with alpha) scenes to the queue, together with the args
        * Once the thread reports back, finish that coroutine, in order to maintain reflections
        * In best case scenario, with 2 shadowed light sources, 4 threads can be used

# Buffer builder

* Make a particle batch as a subclass of instanced builder
* Make an experimental particle batch as a subclass of mesh builder to compare performance, especially in static mode
* Add a text buffer, which basically extends a mesh builder by adding a custom material and

# Particle field

* Similar to particle batch but static
    * Can be used for dust, rain or similar particle fields
    * Can then be animating with vertex shaders

# Reflections

* Non axis aligned box reflections
* Easier to use reflection globes
* Globe blending and proper multi globe