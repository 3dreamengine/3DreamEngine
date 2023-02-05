# TODO

A list of upcoming changes and features.

# Fix 3DO

Each class is serializable, which can be used for the internal file format but also to shader objects between threads efficiently (since the buffers are not copied).

But currently I broke it again...

# Improve Doc

Light sources and a lot of other classes completely missing

# Improve godrays

The current light disk approach performs barely acceptable, but can be further enhanced:

* Tweak the disk, make rays texture less sharp
* Instead of calculating pixels on the entire screen, convert the disks border into a radian stripe and only calculate that
* Then use this 2D stripe for the rest of the screen, lookup using atan
* The lookup table has small y resolution for everything within the disk
* This lookup table is generated for each light source, and THEN is a common godray step performed

# Performance

* Finish LODs + example
* Simplify Vertical particles
  * Prevents optimizations for very little effect

# Buffer builder

* Create Meshes from several meshes
    * Supports adding full objects, but also primitives
        * Supports removing elements (see lovelyMeshBake)
    * Allows tiled worlds etc. with high performance
    * Maybe let all other things, like particle fields, particle batch, ... extend from that idea
    * Even a text object is effectively a buffer builder but with "addChar()"

# Particle field

* Similar to particle batch but static
    * Can be used for dust, rain or similar particle fields
    * Can then be animating with vertex shaders

# Reflections

* Non axis aligned box reflections
* Easier to use reflection globes
* Globe blending and proper multi globe