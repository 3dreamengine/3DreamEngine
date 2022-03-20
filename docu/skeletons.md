
## skeletal animations
WIP but should work fine. The COLLADA loader is often confused and needs further tweeking for some exports but should work most of the time.
A vertex can be assigned to multiple joints/bones, but 3Dream only considers the 4 most important ones.
The bone module has to be enabled on the object in order to use GPU acceleration.

Make sure the object has the inbuilt bone vertex shader applied.
```lua
object:setVertexShader("bones")
```

Returns a pose at a specific time stamp for the given animation.
As long as the joints share the same name, the object containing the animations do not need to be the one containing the skeleton/mesh.
```lua
pose = object.animations.animationName:getPose(time)
```
`time` time in seconds  

<br />

Apply this pose to the skeleton. First line is a shortcut to the second one.
```lua
object:applyPose(pose)
object.skeleton:applyPose(pose)
```

<br />

Apply the skeleton to the mesh directly on the CPU and therefore slow.
```lua
dream:applyBones()
```