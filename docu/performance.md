# Performance

Here will be a collection of performance tips.

## 3DO - 3Dream Object File

UNDER CONSTRUCTION

It is recommended to export your objects as 3do files, these files have only ~10-20% loading time compared to .obj or .dae and are better compressed. It supports all features as every class is serializable.
To export, just set the argument 'export3do' to true when loading the object. This saves it with the same relative path into the LÖVE save directory. Next time loading the game will use the new file instead. The original files are no longer required. If the original files are modified, the current 3DO file is rebuild automatically.