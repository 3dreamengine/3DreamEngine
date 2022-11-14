# TODO

A list of upcoming changes and features.

# Fix 3DO

Each class is serializable, which can be used for the internal file format but also to shader objects between threads efficiently (since the buffers are not copied).

But currently I broke it again...

# Scene Graph

Currently, the graph (scene) is loosely connected.
This has no real benefits, but a few downsides instead.
Instead, a full scene graph may be used (which also replaces the current scenes system)

* If each object (instance) is unique, the local transformation and everything around it can be cached.
* The local transformation is known before/independent on the last scene render

# Buffer builder

* Create Meshes from several meshes
    * Allows tiled worlds etc. with high performance

# Particle field

* Similar to particle batch but static
    * Can be used for dust, rain or similar particle fields
    * Can then be animating with vertex shaders

# Reflections

* Non axis aligned box reflections
* Easier to use reflection globes
* Globe blending and proper multi globe

# Text

* `dream:drawText()` as a wrapper to `love.graphics.print` and `printf`

# Performance

* Final Scene creation should make use of hierarchical information for frustum culling
* Finish LODs
* Simplify Vertical particles
    * Prevents optimizations for very little effect