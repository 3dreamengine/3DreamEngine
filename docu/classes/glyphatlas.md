# GlyphAtlas
A glyph atlas to be used in text rendering
## Constructors
### `GlyphAtlas:newGlyphAtlas(margin)`
Creates new glyph atlas
#### Arguments
`margin` (number)  Size of margin around each character. You need at least 2^mipmapping levels of margin for no bleeding artifacts.

#### Returns
([GlyphAtlas](https://3dreamengine.github.io/3DreamEngine/docu/classes/glyphatlas)) 


_________________

## Methods
### `GlyphAtlas:renderCharacters(characters)`
Render the characters to the atlas
#### Arguments
`characters` (string[]) 


_________________

### `GlyphAtlas:getAllCharacters()`
Get all characters contained in the font

_________________

### `GlyphAtlas:splitCharacters(str)`
Split the utf-8 string into characters
#### Arguments
`str` (string) 


_________________

### `GlyphAtlas:getGlyph(character)`
Renders that glyph if not already rendered and returns it
#### Arguments
`character` (string) 

#### Returns
(Glyph) 


_________________

### `GlyphAtlas:getDimensions()`
Returns the current atlas dimensions in pixels
#### Returns
(number, number) 


_________________

### `GlyphAtlas:getTexture()`
Gets the texture, updates it if the atlas was dirty
#### Returns
(Texture) 


_________________

### `GlyphAtlas:getCachedSpacing(glyph)`

#### Arguments
`glyph` (any) 


_________________

### `GlyphAtlas:getCachedKerning(prevGlyph, glyph)`

#### Arguments
`prevGlyph` (any) 

`glyph` (any) 


_________________

### `GlyphAtlas:getNewCodePoints()`

#### Returns
(MaterializedCodepoints) 


_________________

### `GlyphAtlas:getWrap(text, wrapLimit)`
Wraps a materialized text into lines
#### Arguments
`text` (MaterializedText) 

`wrapLimit` (number) 


_________________

### `GlyphAtlas:getCodepointWrap(codepoints, wrapLimit)`
Wraps the given materialized code points and returns a list of line widths and a list of materialized code points.
#### Arguments
`codepoints` (MaterializedCodepoints) 

`wrapLimit` (number) 

#### Returns
(number[], MaterializedCodepoints[]) 


_________________
