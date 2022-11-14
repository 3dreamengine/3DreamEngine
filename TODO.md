# TODO

A list of upcoming changes and features.

# Fix 3DO

Each class is serializable, which can be used for the internal file format but also to shader objects between threads efficiently (since the buffers are not copied).

But currently I broke it again...

# Improve godrays

The current light disk approach performs barely acceptable, but can be further enhanced:

* Tweak the disk, make rays texture less sharp
* Instead of calculating pixels on the entire screen, convert the disks border into a radian stripe and only calculate that
* Then use this 2D stripe for the rest of the screen, lookup using atan
* The lookup table has small y resolution for everything within the disk
* This lookup table is generated for each light source, and THEN is a common godray step performed

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