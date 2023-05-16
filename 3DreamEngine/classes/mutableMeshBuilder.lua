---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---Creates a new mutable mesh builder
---@param material DreamMaterial
---@return DreamMutableMeshBuilder
function lib:newMutableMeshBuilder(material)
	local mesh = lib:newMeshBuilder(material)
	setmetatable(mesh, self.meta.mutableMeshBuilder)
	
	--min level of integrity before defragmentation starts
	mesh.minIntegrity = 0.9
	
	return mesh
end

---A mutable mesh builder stored references to added objects and can remove them
---@class DreamMutableMeshBuilder : DreamMeshBuilder
local class = {
	links = { "meshBuilder", "mutableMeshBuilder" },
}

function class:clear()
	lib.classes.meshBuilder.clear(self)
	
	--maximum used index of buffers
	self.vertexTotal = 0
	self.indexTotal = 0
	
	--use chunks to keep track of used areas
	self.lastChunkId = 0
	self.chunks = { }
	self.vertexCache = lib:cache()
	self.indexCache = lib:cache()
end

---Returns the pointer to vertices, pointer to vertex map and the index offset. Make sure to fill all requested vertices and build the vertex map accordingly.
---@param vertexCount number
---@param vertexMapLength number
function class:addVertices(vertexCount, vertexMapLength)
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
	--technically not dirty at this point but its expected to fill immediately after requesting space
	self.dirty = true
	
	return self.vertices + vertexIndex, self.indices + indexIndex, vertexIndex
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

---Returns the fraction of data in use
---@return number
function class:getVertexIntegrity()
	return self.vertexTotal / self.vertexIndex
end

---Returns the fraction of data in use for the index buffer
---@return number
function class:getIndexIntegrity()
	return self.indexTotal / self.indexIndex
end

---The last added chunk id is required if you want to remove added content later on
---@return number
function class:getLastChunkId()
	return self.lastChunkId
end

---Defragment mesh now, shifting all data to the very left and updating the chunk pointers
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

return class