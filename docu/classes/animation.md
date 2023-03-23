# Animation
Extends Clonable

A animation contains transformation tracks for a set of joints
## Constructors
### `Animation:newAnimation(frameTable)`
Creates a new, empty animation from a dictionary of joint names and animation frames
#### Arguments
`frameTable` (<string, [AnimationFrame](https://3dreamengine.github.io/3DreamEngine/docu/classes/animationframe)[]>) 

#### Returns
([Animation](https://3dreamengine.github.io/3DreamEngine/docu/classes/animation)) 


_________________

## Fields
`frames` (<string, [AnimationFrame](https://3dreamengine.github.io/3DreamEngine/docu/classes/animationframe)[]>) 

## Methods
### `Animation.interpolateFrames(first, second, blend)`
`static`  
Linear interpolation between two frames
#### Arguments
`first` ([AnimationFrame](https://3dreamengine.github.io/3DreamEngine/docu/classes/animationframe)) 

`second` ([AnimationFrame](https://3dreamengine.github.io/3DreamEngine/docu/classes/animationframe)) 

`blend` (number) 


_________________

### `Animation:getPose(time)`
Returns a new animated pose at a specific time stamp
#### Arguments
`time` (number) 

#### Returns
([Pose](https://3dreamengine.github.io/3DreamEngine/docu/classes/pose)) 


_________________

### `Animation:getLength()`
Returns the length in seconds

_________________

### `Clonable:clone()`
Slow and deep clone

_________________

### `Clonable:instance()`
Creates an fast instance

_________________
