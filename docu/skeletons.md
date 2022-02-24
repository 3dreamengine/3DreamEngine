
## skeletal animations
WIP but should work fine. The COLLADA loader is often confused and needs further tweeking for some exports but should work most of the time.
A vertex can be assigned to multiple joints/bones, but 3Dream only considers the 4 most important ones.
The bone module has to be enabled on the object in order to use GPU acceleration.

Returns a pose at a specific time stamp.
```lua
pose = dream:getPose(object, time)
pose = dream:getPose(object, time, name)
```
`object` object containing skeleton and animation  
`time` time in seconds  
`name ("default")` animation name if split  
`pose` a table containg transformation instructions for each joint  

<br />

Apply this pose (results in object.boneTransforms).
```lua
dream:applyPose(object, pose)
```

<br />

Alternative create and apply in one.
```lua
dream:setPose(object, time)
dream:setPose(object, time, name)
```

<br />

Apply joints to mesh, heavy operation, shader module instead recommended.
```lua
dream:applyJoints(object)
```