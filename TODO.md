# TODO

A list of upcoming changes and features.

# GLTF

COLLADA is a mess. The current import does its job half of the time and I will probably leave it there, but GLTF might be more suitable and stable.

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
* Custom reflection shader

# Text

* `dream:drawText()` as a wrapper to `love.graphics.print` and `printf`

# Physics extension

* Finish and simplify
    * 3Dream is not designed for full 3D games, but a basic physics lib can be helpful

# Performance

* Final Scene creation should make use of hierarchical information for frustum culling
* Finish LODs
* Simplify Vertical particles
    * Prevents optimizations for very little effect