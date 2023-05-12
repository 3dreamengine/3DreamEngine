# Meshes

A mesh is a drawable object with a shape and material. It's usually encapsulated into an object to have an position. Meshes can be shared across multiple objects.

## Mesh

See [Mesh](https://3dreamengine.github.io/3DreamEngine/docu/skeletons)

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

Building Meshes the manual way is quite tedious and slow, so lets use the preferred mesh builder, which wraps a lot of stuff.

```lua
--Create a material, we use the simple pixel shader, which uses a simple, colored but non textures meshFormat.
local material = dream:newMaterial()
material:setPixelShader("simple")

local meshBuilder = dream:newMeshBuilder(material, "triangles")

local pointer = chunk.mesh:addQuad()
for i = 1, 4 do
    local v = pointer[i - 1]
    v.VertexPositionX = x + vertices[faces[direction][i]][1]
    v.VertexPositionY = y + vertices[faces[direction][i]][2]
    v.VertexPositionZ = z + vertices[faces[direction][i]][3]
    v.VertexNormalX = normal[1] * 127.5 + 127.5
    v.VertexNormalY = normal[2] * 127.5 + 127.5
    v.VertexNormalZ = normal[3] * 127.5 + 127.5
    v.VertexMaterialX = 127
    v.VertexMaterialY = 0
    v.VertexMaterialZ = 0
    v.VertexColorX = self.red
    v.VertexColorY = self.green
    v.VertexColorZ = self.blue
    v.VertexColorW = 255
end
```

# ParticleMesh

```lua

```

# FontMesh

```lua

```

# InstancedMesh

Another approach are instances, where the same (usually small mesh) is placed at multiple locations.
It tends to be faster than a mesh builder and requires less memory, but is restricted to a single template mesh.

```lua

```
