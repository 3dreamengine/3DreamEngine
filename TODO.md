# TODO

A list of upcoming changes and features.

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
* One more attempt on transformation caching
    * If we had a scene tree, transformations could be cached
    * This only works if all objects are unique, which instantiate ensures
    * Cache transform, position and scale for objects and meshes by using a weak parent table .cache
    * All operations on objects now need to use the adder and remover functions to ensure integrity
        * Protect objects and meshes with metatable just to make sure
* Add an experimental freezeShader function
    * The only way for the shader to change is...
        * Changes to the material, reflection, mesh, global shader and scene settings
        * A cache would add a subcache to the shader cache and is slightly faster at the expense of potential missed update errors
* Threaded scenes
    * A scene would need a perfect reconstruction of all transforms and bounding boxes on a thread
        * That would work with the assumption of uniqueness from before!
    * The sync happens via a shared memory segment
    * The thread traverses the tree, places the transforms, does frustum culling, lods and sorting, and provides an argsort list.
    * The main thread syncs back with the thread and uses the array
    * Only issue: the main thread needs to do other work in the meantime.
        * The smoothest way are coroutines, render just adds its 1 or 2 (with alpha) scenes to the queue, together with the args
        * Once the thread reports back, finish that coroutine, in order to maintain reflections
        * In best case scenario, with 2 shadowed light sources, 4 threads can be used

# Reflections

* Non axis aligned box reflections
* Easier to use reflection globes
* Globe blending and proper multi globe