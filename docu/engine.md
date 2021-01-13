# engine
- [transparency](#transparency)
- [textures](#textures)
  * [thumbnails](#thumbnails)
- [level of detail](#level-of-detail)
- [3DO - 3Dream object file](#3do---3dream-object-file)  

## transparency
To make transparency possible, a few features have to be enabled. Enabling them by default would be slow, so this has to be done manually.  
There are two render passes. The first, with depth writing, only render fully solid materials. The second pass render transparent materials.    

* Does the material contain no alpha? -> `material:setAlpha(false)` (default)
* Does the material contain smooth alpha (values between 0 and 1)? -> `material:setAlpha(true)` (by default disabled, requires enabled backface culling and should be used on convex meshes only)
* Does the material contain alpha, but no visible gradient is required? -> `material:setDiscard(true)` (by default disabled)

Additionally, if your scene contains a lot of transparent materials and the rather limited sorting of the alpha pass fails, enable average alpha mode. This is an approximation of correct alpha blending and may look better.  
`dream.renderSet:setAverageAlpha(true)`


See their respective chapters for detailed information.
* [transparent materials](#transparent-materials)
* [setSettings](#setsettings)



## level of detail
Will change, dont use yet.

I'm working on automatic LOD generation, material merge, LOD billboard generation and similar.




## textures
To add textures to the model ...
* name the textures albedo, normal, roughness, metallic, glossiness, specular, emission and put it next to the material (for material library entries) or suffix them with either the material name "material_" or the object name "object_"
* set the texture path in the mtl file, if exported by another software it should work fine
* set the texture path in the mat file (tex_diffuse, tex_normal, tex_emission, ...)
* set the texture manually after loading
* by default 3Dream looks for textures relative to the object path, if not overwritten by the `textures` arg in the model loader
* it does automatically choose the best format and load it threaded when needed. Setting a texture manually prevents this.

* The diffuse texture is a RGB non alpha texture with the color. Alpha channel needs material `setAlpha(true)`.
* The normal texture contains tangential normal coordinates.
* The emission texture contains RGB color.
* Roughness and metallic or specular and glossiness as well as ambient occlusion are single channel textures, however the engine works with combined RMA textures for performance reasons. If not present, 3Dream will generate them and caches them in the love save directory. It is recommended to use them in the final build to avoid heavy (but at least threaded) CPU merge operations, or provide RMA textures in the first place.
* DDS files are supported, but can not generate mipmaps automatically. Also love2ds DDS loader seems to hate mipmaps in DDS files.



### thumbnails
Subject to change. Texture loader will receive together with the final LOD update more features which may change thumbnails.

Name a (smaller) file "yourImage_thumb.ext" to let the texture loader automatically load it first, then load the full textures at the end.

If the automatic thumbnail generator is enabled (true by default), this will be done automatically, but the first load will be without thumbnail.



## 3DO - 3Dream object file
It is recommended to export your objects as 3do files, these files can be loaded on multiple cores, have only ~10-20% loading time compared to .obj, are better compressed and do not need additional files like mtl. They (should) support all features other files have.
To export, just set the argument 'export3do' to true when loading the object. This saves it with the same relative path into the LÖVE save directory. Next time loading the game will use the new file instead. The original files are no longer required.

But note that...
* The exported file needs to be packed into the final game at some point.
* You can not modify 3do files, they contain binary mesh data. Therefore keep the original files!
* The exported 3do is shader dependend, you can not change the used based shader later.