# Skeletal animations

I noticed that DAE export/import in Blender is broken at some models, prefer GLTF.
A vertex can be assigned to multiple joints/bones, but 3Dream only considers the 4 most important ones.
The bone vertex shader has to be enabled on the object in order to use GPU acceleration.

```lua
object:setVertexShader("bones")
```

Now create a pose at a specific time stamp for the given animation.
As long as the joints share the same name, the object containing the animations do not need to be the one containing the skeleton/mesh.
That means, you can create separate animation libraries.

```lua
pose = object.animations.animationName:getPose(time)
```

`time` time in seconds

Now apply this pose to the skeleton, which will recursively create transformation matrices for each join.

```lua
object:getMainSkeleton():applyPose(pose)
```

You can now draw the object.

You can also apply the skeleton to the mesh (or all objects meshes) directly on the CPU.
That's of course slow, but might be required for certain applications.

```lua
mesh:applyBones()
object:applyBones()
```