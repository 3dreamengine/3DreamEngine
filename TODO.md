# TODO

A list of upcoming changes and features.

# Remove dynamic shadows

The idea (splitting static and dynamic shadows) performs surprisingly well but

* It's a lot of code to keep track of dynamic objects, and it's not even accurate for vertex shaders applying transforms
* It requires 2x shadow shaders
* It requires a lot of branching in the shadow rendering, which caused typos in the past already
* It's over optimization. The CPU bottleneck is the main issue, masking this with selective rendering is not really a fix

# Fix 3DO

Each class is serializable, which can be used for the internal file format but also to shader objects between threads efficiently (since the buffers are not copied).

But currently I broke it again...

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