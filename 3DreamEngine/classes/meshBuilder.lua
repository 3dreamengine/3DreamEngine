---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---Creates a new mesh builder
---@param material DreamMaterial
---@return DreamMeshBuilder
function lib:newMeshBuilder(material)
	assert(material, "Required material")
	local mesh = lib:newMesh(material)
	setmetatable(mesh, self.meta.meshBuilder)
	
	--maximum size of the buffers
	mesh.vertexCapacity = 1
	mesh.indexCapacity = 1
	
	--clear pointers
	mesh:clear()
	
	mesh.meshFormat = mesh:getMeshFormat()
	mesh.vertexIdentifier = mesh.meshFormat:getCStruct()
	
	return mesh
end

---Mesh builder are buffers populated with primitives or objects on the CPU, then rendered altogether. They outperform individual draw calls and can be multi threaded and/or cached.
---@class DreamMeshBuilder : DreamMesh
local class = {
	links = { "mesh", "meshBuilder" },
}

---Resets the buffer
function class:clear()
	self.vertexIndex = 0
	self.indexIndex = 0
end

function class:updateBoundingSphere()
	--nop, mesh builders are too dynamic and performance orientated to use bounding spheres for now
end

---Adds a mesh with given transform to the builder
---@param mesh DreamMesh
---@param transform DreamMat4
function class:addMesh(mesh, transform)
	--create the vertexByteData
	if not mesh.vertexByteData then
		assert(mesh.material.meshFormat == self.material.meshFormat, "Mesh format of builder and added mesh mismatch!")
		
		mesh.vertexByteData = mesh:getMeshFormat():create(mesh)
		mesh.vertexMapByteData = mesh:createVertexMap()
		
		mesh.verticesAccessor = ffi.cast(self.vertexIdentifier .. "*", mesh.vertexByteData:getFFIPointer())
		mesh.indicesAccessor = ffi.cast("uint32_t*", mesh.vertexMapByteData:getFFIPointer())
	end
	
	local vertexCount = mesh.vertices:getSize()
	local vertexMapLength = mesh.faces:getSize() * 3
	
	local vertices, indices, vertexIndex = self:addVertices(vertexCount, vertexMapLength)
	
	--place vertices
	ffi.copy(vertices, mesh.verticesAccessor, ffi.sizeof(self.vertexIdentifier) * vertexCount)
	
	--transform vertices
	for i = vertexIndex, vertexCount - 1 + vertexIndex do
		local v = self.vertices[i]
		
		local x = v.VertexPositionX
		local y = v.VertexPositionY
		local z = v.VertexPositionZ
		v.VertexPositionX = transform[1] * x + transform[2] * y + transform[3] * z + transform[4]
		v.VertexPositionY = transform[5] * x + transform[6] * y + transform[7] * z + transform[8]
		v.VertexPositionZ = transform[9] * x + transform[10] * y + transform[11] * z + transform[12]
		
		if self.meshFormat.attributes["VertexNormal"] then
			local nx = v.VertexNormalX / 127 - 1.0
			local ny = v.VertexNormalY / 127 - 1.0
			local nz = v.VertexNormalZ / 127 - 1.0
			v.VertexNormalX = (transform[1] * nx + transform[2] * ny + transform[3] * nz) * 127.5 + 127.5
			v.VertexNormalY = (transform[5] * nx + transform[6] * ny + transform[7] * nz) * 127.5 + 127.5
			v.VertexNormalZ = (transform[9] * nx + transform[10] * ny + transform[11] * nz) * 127.5 + 127.5
		end
		
		if self.meshFormat.attributes["VertexTangent"] then
			local tx = v.VertexTangentX / 127 - 1.0
			local ty = v.VertexTangentY / 127 - 1.0
			local tz = v.VertexTangentZ / 127 - 1.0
			v.VertexTangentX = (transform[1] * tx + transform[2] * ty + transform[3] * tz) * 127.5 + 127.5
			v.VertexTangentY = (transform[5] * tx + transform[6] * ty + transform[7] * tz) * 127.5 + 127.5
			v.VertexTangentZ = (transform[9] * tx + transform[10] * ty + transform[11] * tz) * 127.5 + 127.5
		end
	end
	
	--place indices
	for i = 0, vertexMapLength - 1 do
		indices[i] = mesh.indicesAccessor[i] + vertexIndex
	end
	
	return self.lastChunkId
end

---Returns the pointer to vertices, pointer to vertex map and the index offset. Make sure to fill all requested vertices and build the vertex map accordingly.
---@param vertexCount number
---@param vertexMapLength number
function class:addVertices(vertexCount, vertexMapLength)
	--resize
	while self.vertexIndex + vertexCount > self.vertexCapacity do
		self:resizeVertex()
	end
	while self.indexIndex + vertexMapLength > self.indexCapacity do
		self:resizeIndices()
	end
	
	--try to use cache
	local vertexIndex = self.vertexIndex
	self.vertexIndex = self.vertexIndex + vertexCount
	
	local indexIndex = self.indexIndex
	self.indexIndex = self.indexIndex + vertexMapLength
	
	--mark dirty to make sure the mesh gets updated
	--technically not dirty at this point but its expected to fill immediately after requesting space
	self.dirty = true
	
	return self.vertices + vertexIndex, self.indices + indexIndex, vertexIndex
end

---Allocates an triangle and returns the pointer to the first vertex
function class:addTriangle()
	local vertexPointer, indexPointer, vertexOffset = self:addVertices(3, 3)
	
	indexPointer[0] = vertexOffset
	indexPointer[1] = vertexOffset + 1
	indexPointer[2] = vertexOffset + 2
	
	return vertexPointer
end

---Allocates an quad and returns the pointer to the first vertex
function class:addQuad()
	local vertexPointer, indexPointer, vertexOffset = self:addVertices(4, 6)
	
	indexPointer[0] = vertexOffset
	indexPointer[1] = vertexOffset + 1
	indexPointer[2] = vertexOffset + 2
	indexPointer[3] = vertexOffset
	indexPointer[4] = vertexOffset + 2
	indexPointer[5] = vertexOffset + 3
	
	return vertexPointer
end

---@private
function class:getMesh(name)
	name = name or "mesh"
	
	if name == "mesh" then
		if self.indexIndex > 0 then
			if self.dirty then
				self.mesh:setVertices(self.byteData, 1, self.vertexIndex)
				self.mesh:setVertexMap(self.vertexMapByteData, "uint32")
				self.dirty = false
			end
			self.mesh:setDrawRange(1, self.indexIndex)
			
			return self.mesh
		else
			return false
		end
	end
	
	return lib.classes.mesh.getMesh(self, name)
end

---@private
function class:resizeVertex(size)
	local oldSize = self.vertexCapacity
	self.vertexCapacity = size or (self.vertexCapacity * 2)
	
	local oldByteData = self.byteData
	local oldVertices = self.vertices
	
	--create
	self.byteData = love.data.newByteData(ffi.sizeof(self.vertexIdentifier) * self.vertexCapacity)
	self.vertices = ffi.cast(self.vertexIdentifier .. "*", self.byteData:getFFIPointer())
	
	--copy old part
	if oldByteData then
		ffi.copy(self.vertices, oldVertices, ffi.sizeof(self.vertexIdentifier) * math.min(oldSize, self.vertexCapacity))
	end
	
	--new mesh
	self.mesh = love.graphics.newMesh(self.meshFormat.vertexFormat, self.byteData, self:getMeshDrawMode(), "static")
end

---@private
function class:resizeIndices(size)
	local oldSize = self.indexCapacity
	self.indexCapacity = size or (self.indexCapacity * 2)
	
	local oldVertexMapByteData = self.vertexMapByteData
	local oldIndices = self.indices
	
	--create
	self.vertexMapByteData = love.data.newByteData(ffi.sizeof("uint32_t") * self.indexCapacity)
	self.indices = ffi.cast("uint32_t*", self.vertexMapByteData:getFFIPointer())
	
	--copy old part
	if oldVertexMapByteData then
		ffi.copy(self.indices, oldIndices, ffi.sizeof("uint32_t") * math.min(oldSize, self.indexCapacity))
	end
end

return class