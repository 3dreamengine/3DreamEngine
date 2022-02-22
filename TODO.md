# TODO
A list of upcoming changes and features.

# Bufferbuilder
* Create Meshes from several meshes
    * Allows tiled worlds etc with high performance

# Particlefield
* Similar to particlebatch but static
    * Can be used for dust, rain or similar particle fields
    * Are way faster than particlebatches since Vertex-shader based

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
* Final Scene creation should make use of hierachical information for frustum culling
* Finish LODs