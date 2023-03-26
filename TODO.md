# TODO

A list of upcoming changes and features.

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