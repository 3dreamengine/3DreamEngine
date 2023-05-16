# MeshFormat
Mesh formats contain the code required to populate the final render-able mesh and should overwrite the `create` methods. Use cases for custom mesh formats are additional attributes. Special shaders are required to make use of custom mesh formats. See https://github.com/3dreamengine/3DreamEngine/tree/master/3DreamEngine/meshFormats for inbuilt formats.
## Constructors
### `MeshFormat:newMeshFormat(vertexFormat)`
Creates a new mesh format
#### Arguments
`vertexFormat` (table)  A vertex format as specified in https://love2d.org/wiki/love.graphics.newMesh

#### Returns
([MeshFormat](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshformat)) 


_________________

## Methods
### `MeshFormat:create(mesh)`
Converts the intermediate buffer representation into drawable love2d meshes
#### Arguments
`mesh` ([Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)) 


_________________

### `MeshFormat:getCStruct()`


_________________
