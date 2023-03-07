# Canvases
Canvases are target frame buffers storing intermediate and final rendering steps as well as graphics settings
## Constructors
### `Canvases:newCanvases()`
Creates a new set of canvas outputs
#### Returns
([Canvases](https://3dreamengine.github.io/3DreamEngine/docu/classes/canvases)) 


_________________

## Methods
### `Canvases:setMode(mode)`
Set the output mode, normal contains all features, direct do not use a canvas at all and directly renders and lite uses a canvas but on a faster feature set
#### Arguments
`mode` (CanvasMode) 


_________________

### `Canvases:getMode()`


_________________

### `Canvases:setFormat(format)`
Sets the pixel format manually
#### Arguments
`format` (PixelFormat) 


_________________

### `Canvases:getFormat()`


_________________

### `Canvases:setAlphaPass(alphaPass)`
Toggle the alpha pass
#### Arguments
`alphaPass` (boolean) 


_________________

### `Canvases:getAlphaPass()`


_________________

### `Canvases:setRefractions(refractions)`
Toggle refractions
#### Arguments
`refractions` (boolean) 


_________________

### `Canvases:getRefractions()`


_________________

### `Canvases:setFXAA(fxaa)`
Toggle Fast approximate anti aliasing
#### Arguments
`fxaa` (boolean) 


_________________

### `Canvases:getFXAA()`


_________________

### `Canvases:setMSAA(msaa)`
Set Multi Sample Anti Aliasing sample count
#### Arguments
`msaa` (number) 


_________________

### `Canvases:getMSAA()`


_________________

### `Canvases:setResolution(px)`
Sets the resolution, requires a reinit
#### Arguments
`px` (number) 


_________________

### `Canvases:getResolution()`


_________________

### `Canvases:init(w, h)`
Initialize that canvas set
#### Arguments
`w` (number)  optional

`h` (number)  optional


_________________
