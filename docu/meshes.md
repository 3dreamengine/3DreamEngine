# Meshes

This page comes with a dedicated example, showcasing following concepts in action:
[/examples/MeshBuilders/main.lua](https://github.com/3dreamengine/3DreamEngine/blob/master/examples/MeshBuilders/main.lua)

A mesh is a drawable object with a shape and material. It's usually encapsulated into an object to have an position. Meshes can be shared across multiple objects.

````lua
--Access and modify a meshes material
mesh:getMaterial()
````

## Mesh

See [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/mesh)

The parent class of all following classes is the plain mesh. It is usually used within the object loaders.

```lua
--Create an empty mesh
local mesh = dream:newMesh(material)

--Request a vertex (position), texture coordinates and normals buffer
--Depending on the shader you may need more 
local meshVertices = mesh:getOrCreateBuffer("vertices")
local meshTexCoords = mesh:getOrCreateBuffer("texCoords")
local meshNormals = mesh:getOrCreateBuffer("normals")

--As well as the faces (triangles)
local meshFaces = mesh:getOrCreateBuffer("faces")

--Fill it
meshVertices:append({ 1, 0, 0 })
meshVertices:append({ 0, 1, 0 })
meshVertices:append({ 1, 1, 0 })

meshTexCoords:append({ 1, 0 })
meshTexCoords:append({ 0, 1 })
meshTexCoords:append({ 1, 1 })

meshNormals:append({ 0, 0, 1 })
meshNormals:append({ 0, 0, 1 })
meshNormals:append({ 0, 0, 1 })

meshFaces:append({ 1, 1, 1 })

--Explicitly creates the underlying mesh, is called automatically otherwise
mesh:create()

--If you know that the buffers are no used for anything else, free them
mesh:cleanup()
```

# MeshBuilder

See [MeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshbuilder), [MeshFormat](https://3dreamengine.github.io/3DreamEngine/docu/classes/meshformat)

Building Meshes the manual way is quite tedious and slow, so lets use the preferred mesh builder, which wraps a lot of stuff.

```lua
--Create a material, we use the simple pixel shader, which uses a simple, colored but non textures meshFormat.
--The vertex members are defined in the mesh format.
local material = dream:newMaterial()
material:setPixelShader("simple")

--Create the mesh builder. Whenever possible, reuse an old one and use clear.
local meshBuilder = dream:newMeshBuilder(material)


--The simplest way to populate a buffer is by adding entire meshes at given transformations
--Those meshes need to share the same mesh format, and should share the same material
meshBuilder:addMesh(someMesh, dream.mat4.getTranslate(1, 2, 3))


--Requests a quad
local pointer = meshBuilder:addQuad()

--Set the X position of the first vertex
--All data for the specified mesh format should be set and is 0 otherwise (tangent data is auto generated if not provided)
pointer[0].VertexPositionX = 7


--If a quad or triangle is still too high level, request a raw memory segment
--VertexOffset points to your first vertex and is required to be used in setting the index buffer accordingly
--Refer to the example linked for an implementation
local vertexPointer, indexPointer, vertexOffset = meshBuilder:addVertices(4, 6)
```

## MutableMeshBuilder

See [MutableMeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/mutablemeshbuilder)

Sometimes one would like to modify a buffer without rebuilding it completely.

```lua
--Create a mutable version
local meshBuilder = dream:newMutableMeshBuilder(material)

--Add as previously
meshBuilder:addMesh(someMesh, dream.mat4.getTranslate(1, 2, 3))

--But store the id to find that memory segment again
local id = meshBuilder:getLastChunkId()

--And remove
meshBuilder:remove(id)
```

The mutable mesh builders have a higher memory overhead and will perform defragmentation from time to time.

# TextMeshBuilder

See [TextMeshBuilder](https://3dreamengine.github.io/3DreamEngine/docu/classes/textmeshbuilder), [GlyphAtlas](https://3dreamengine.github.io/3DreamEngine/docu/classes/glyphatlas)

A special variant of mesh builders is used for text.

```lua
--Create a new glyph atlas using LÖVEs default font and size 64
local glyphAtlas = dream:newGlyphAtlas(nil, 64)

--Create a text builder, which internally uses the glyph atlas
local text = dream:newTextMeshBuilder(glyphAtlas)

--Formatted, aligned (here we use originCenter, which uses the origin X as center), line wrapped text
text:printf("This text should be perfectly centered", 400, "originCenter")
```

# InstancedMesh

See [InstancedMesh](https://3dreamengine.github.io/3DreamEngine/docu/classes/instancedmesh)

Another approach are instances, where the same (usually small mesh) is placed at multiple locations.
It tends to be faster than a mesh builder and requires less memory, but is restricted to a single template mesh.

```lua
local instancedMesh = dream:newInstancedMesh(templateMesh)

--Appends a new instance
instancedMesh:addInstance(dream.mat4.getTranslate(1, 2, 3))

--Replace an existing instance
instancedMesh:addInstance(dream.mat4.getTranslate(1, 2, 3), 1)
```

# Sprite

See [Sprite](https://3dreamengine.github.io/3DreamEngine/docu/classes/sprite)

A sprite is used to draw a single quad.

```lua
local sprite = dream:newSprite(texture)

--Draw it somewhere facing the camera
dream:draw(sprite, sprite:getSpriteTransform(x, y, z, rot, sx, sy))
```

# SpriteBatch

See [SpriteBatch](https://3dreamengine.github.io/3DreamEngine/docu/classes/spritebatch)

If you have multiple sprites you may want to use a spritebatch. Sprites are rendered always camera-normal aligned (not camera facing, there is a small deviation). The math is done on the GPU, thus much faster than manually transforming and setting vertices. Spritebatches also have a bit smaller memory usage.

```lua
local spriteBatch = dream:newSpriteBatch(texture)
spriteBatch:add(x, y, z, rot, sx, sy)
spriteBatch:addQuad(quad, x, y, z, rot, sx, sy)
spriteBatch:set(index, x, y, z, rot, sx, sy)
spriteBatch:setQuad(index, quad, x, y, z, rot, sx, sy)
```