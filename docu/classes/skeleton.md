# Skeleton
Contains a hierarchical bone structure and the final transformation matrices for skinning when a pose has been applied
## Constructors
### `Skeleton:newSkeleton(root)`
New skeleton from a hierarchical bone structure
#### Arguments
`root` ([Bone](https://3dreamengine.github.io/3DreamEngine/docu/classes/bone)) 

#### Returns
([Skeleton](https://3dreamengine.github.io/3DreamEngine/docu/classes/skeleton)) 


_________________

## Methods
### `Skeleton:applyPose(pose)`
Apply the pose to the skeleton
#### Arguments
`pose` ([Pose](https://3dreamengine.github.io/3DreamEngine/docu/classes/pose)) 


_________________

### `Skeleton:getTransform(name)`
Get the transformation matrix for a given joint name
#### Arguments
`name` (string) 

#### Returns
(Mat4) 


_________________
