---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---Creates a new mesh builder
---@param material DreamMaterial
---@return DreamMeshBuilder
function lib:newMeshBuilder(material)
	assert(material, "Required material")
	local mesh = lib:newMesh(material)
	
	--min level of integrity before defragmentation starts
	mesh.minIntegrity = 0.9
	
	--last used index in the buffers
	mesh.vertexIndex = 0
	mesh.indexIndex = 0
	
	--maximum size of the buffers
	mesh.vertexCapacity = 1
	mesh.indexCapacity = 1
	
	--maximum used index of buffers
	mesh.vertexTotal = 0
	mesh.indexTotal = 0
	
	--use chunks to keep track of used areas
	mesh.lastChunkId = 0
	mesh.chunks = { }
	mesh.vertexCache = lib:cache()
	mesh.indexCache = lib:cache()
	
	mesh.meshFormat = mesh:getMeshFormat()
	mesh.vertexIdentifier = mesh.meshFormat:getCStruct()
	
	return setmetatable(mesh, self.meta.meshBuilder)
end

---Mesh builder are buffers populated with primitives or objects on the CPU, then rendered altogether. They outperform individual draw calls and can be multi threaded and/or cached.
---@class DreamMeshBuilder : DreamMesh
local class = {
	links = { "mesh", "meshBuilder" },
}

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
	
	--defragment
	if self:getVertexIntegrity() < self.minIntegrity or self:getIndexIntegrity() < self.minIntegrity then
		self:defragment()
	end
	
	--resize
	while self.vertexIndex + vertexCount > self.vertexCapacity do
		self:resizeVertex()
	end
	while self.indexIndex + vertexMapLength > self.indexCapacity do
		self:resizeIndices()
	end
	
	--try to use cache
	local vertexIndex = self.vertexCache:pop(vertexCount)
	if not vertexIndex then
		vertexIndex = self.vertexIndex
		self.vertexIndex = self.vertexIndex + vertexCount
	end
	
	local indexIndex = self.indexCache:pop(vertexMapLength)
	if not indexIndex then
		indexIndex = self.indexIndex
		self.indexIndex = self.indexIndex + vertexMapLength
	end
	
	--place vertices
	ffi.copy(self.vertices + vertexIndex, mesh.verticesAccessor, ffi.sizeof(self.vertexIdentifier) * vertexCount)
	
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
			v.VertexNormalX = (transform[1] * nx + transform[2] * ny + transform[3] * nz) * 127 + 127
			v.VertexNormalY = (transform[5] * nx + transform[6] * ny + transform[7] * nz) * 127 + 127
			v.VertexNormalZ = (transform[9] * nx + transform[10] * ny + transform[11] * nz) * 127 + 127
		end
		
		if self.meshFormat.attributes["VertexTangent"] then
			local tx = v.VertexTangentX / 127 - 1.0
			local ty = v.VertexTangentY / 127 - 1.0
			local tz = v.VertexTangentZ / 127 - 1.0
			v.VertexTangentX = (transform[1] * tx + transform[2] * ty + transform[3] * tz) * 127 + 127
			v.VertexTangentY = (transform[5] * tx + transform[6] * ty + transform[7] * tz) * 127 + 127
			v.VertexTangentZ = (transform[9] * tx + transform[10] * ty + transform[11] * tz) * 127 + 127
		end
	end
	
	--place indices
	for i = 0, vertexMapLength - 1 do
		self.indices[i + indexIndex] = mesh.indicesAccessor[i] + vertexIndex
	end
	
	--remember the chunk
	self.lastChunkId = self.lastChunkId + 1
	self.chunks[self.lastChunkId] = {
		vertexIndex, vertexCount,
		indexIndex, vertexMapLength
	}
	
	--advance
	self.vertexTotal = self.vertexTotal + vertexCount
	self.indexTotal = self.indexTotal + vertexMapLength
	
	--mark dirty to make sure the mesh gets updated
	self.dirty = true
	
	return self.lastChunkId
end

---remove a chunk previously added
---@param id number
function class:remove(id)
	local chunk = self.chunks[id]
	assert(chunk, "Chunk does not exist")
	self.chunks[id] = nil
	
	--clear indices
	for i = chunk[3], chunk[3] + chunk[4] - 1 do
		self.indices[i] = 0
	end
	
	self.vertexTotal = self.vertexTotal - chunk[2]
	self.indexTotal = self.indexTotal - chunk[4]
	
	self.vertexCache:push(chunk[2], chunk[1])
	self.indexCache:push(chunk[4], chunk[3])
	
	self.dirty = true
end

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

---Returns the fraction of data in use
function class:getVertexIntegrity()
	return self.vertexTotal / self.vertexIndex
end

---Returns the fraction of data in use for the index buffer
function class:getIndexIntegrity()
	return self.indexTotal / self.indexIndex
end

function class:defragment()
	local oldByteData = self.byteData
	local oldVertices = self.vertices
	local oldVertexMapByteData = self.vertexMapByteData
	local oldIndices = self.indices
	
	--create
	self.byteData = love.data.newByteData(ffi.sizeof(self.vertexIdentifier) * self.vertexCapacity)
	self.vertices = ffi.cast(self.vertexIdentifier .. "*", self.byteData:getFFIPointer())
	self.vertexMapByteData = love.data.newByteData(ffi.sizeof("uint32_t") * self.indexCapacity)
	self.indices = ffi.cast("uint32_t*", self.vertexMapByteData:getFFIPointer())
	
	--copy old part
	self.vertexIndex = 0
	self.indexIndex = 0
	if oldByteData and oldVertexMapByteData then
		for id, chunk in pairs(self.chunks) do
			ffi.copy(self.vertices + self.vertexIndex, oldVertices + chunk[1], ffi.sizeof(self.vertexIdentifier) * chunk[2])
			
			--move indices
			for i = 0, chunk[4] - 1 do
				self.indices[self.indexIndex + i] = oldIndices[i + chunk[3]] - chunk[1] + self.vertexIndex
			end
			
			self.chunks[id] = { self.vertexIndex, chunk[2], self.indexIndex, chunk[4] }
			self.vertexIndex = self.vertexIndex + chunk[2]
			self.indexIndex = self.indexIndex + chunk[4]
		end
	end
	
	self.vertexTotal = self.vertexIndex
	self.indexTotal = self.indexIndex
	
	self.vertexCache = lib:cache()
	self.indexCache = lib:cache()
end

function class:resizeVertex(size)
	local oldSize =  self.vertexCapacity
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
	self.mesh = love.graphics.newMesh(self.meshFormat.vertexFormat, self.byteData, "triangles", "static")
end

function class:resizeIndices(size)
	local oldSize =  self.indexCapacity
	self.indexCapacity = size or (self.indexCapacity * 2)
	
	local oldVertexMapByteData = self.vertexMapByteData
	local oldIndices = self.indices
	
	--create
	self.vertexMapByteData = love.data.newByteData(ffi.sizeof("uint32_t") * self.indexCapacity)
	self.indices = ffi.cast("uint32_t*", self.vertexMapByteData:getFFIPointer())
	
	--copy old part
	if oldVertexMapByteData then
		ffi.copy(self.indices, oldIndices, ffi.sizeof("uint32_t") *  math.min(oldSize, self.indexCapacity))
	end
end

return class