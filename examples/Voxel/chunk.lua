local dream = _3DreamEngine

---@class Chunk
local chunk = { }

local ffi = require("ffi")
ffi.cdef [[
	typedef struct { uint16_t tile; } block;
]]

local material = dream:newMaterial()
material:setPixelShader("simple")

---Creates a new empty chunk
---@param world World
---@param cx number
---@param cy number
---@param cz number
---@param chunkSize number
---@return Chunk
function chunk:new(world, cx, cy, cz, chunkSize)
	---@type Chunk
	local c = setmetatable({ }, chunk)
	
	c.world = world
	c.cx = cx
	c.cy = cy
	c.cz = cz
	c.chunkSize = chunkSize
	
	--create a mesh builder based on a simple material
	c.mesh = dream:newMeshBuilder(material, "triangles")
	
	c.mesh.boundingSphere = dream:newBoundingSphere(dream.vec3(0, 0, 0), math.sqrt((chunkSize / 2) ^ 3))
	
	c.byteData = love.data.newByteData(ffi.sizeof("block") * (chunkSize ^ 3))
	c.blocks = ffi.cast("block*", c.byteData:getFFIPointer())
	
	c.dirty = false
	
	c:generate()
	
	return c
end

function chunk:generate()
	for x = 0, self.chunkSize - 1 do
		for z = 0, self.chunkSize - 1 do
			local n1 = love.math.noise((self.cx * self.chunkSize + x) / 600, (self.cz * self.chunkSize + z) / 800)
			local n2 = love.math.noise((self.cx * self.chunkSize + x) / 300, (self.cz * self.chunkSize + z) / 500)
			local n3 = love.math.noise((self.cx * self.chunkSize + x) / 100, (self.cz * self.chunkSize + z) / 100)
			local n4 = love.math.noise((self.cx * self.chunkSize + x) / 60, (self.cz * self.chunkSize + z) / 60)
			local n5 = love.math.noise((self.cx * self.chunkSize + x) / 30, (self.cz * self.chunkSize + z) / 30)
			for y = 0, self.chunkSize - 1 do
				local n6 = love.math.noise((self.cx * self.chunkSize + x) / 70, (self.cy * self.chunkSize + y) / 70, (self.cz * self.chunkSize + z) / 70)
				local n = (n3 + n4 + n5) * n2 * n1 * (n6 > 0.5 and 1.5 or 0.5)
				local ay = self.cy * self.chunkSize + y
				if ay < n * 10 then
					self:setBlock(x, y, z, self.world.game.registry:get("stone"))
				elseif ay < n * 10 + 1 then
					if ay <= 1 then
						self:setBlock(x, y, z, self.world.game.registry:get("water"))
					elseif ay <= 2 then
						self:setBlock(x, y, z, self.world.game.registry:get("sand"))
					else
						self:setBlock(x, y, z, self.world.game.registry:get("grass"))
					end
				end
			end
		end
	end
end

function chunk:surrounded()
	return self.world:getChunk(self.cx - 1, self.cy, self.cz, true)
			and self.world:getChunk(self.cx + 1, self.cy, self.cz, true)
			and self.world:getChunk(self.cx, self.cy - 1, self.cz, true)
			and self.world:getChunk(self.cx, self.cy + 1, self.cz, true)
			and self.world:getChunk(self.cx, self.cy, self.cz - 1, true)
			and self.world:getChunk(self.cx, self.cy, self.cz + 1, true)
end

---Render and get mesh
---@return DreamMesh
function chunk:getMesh()
	if self.dirty and self:surrounded() then
		self.dirty = false
		self.mesh:clear()
		for x = 0, self.chunkSize - 1 do
			for y = 0, self.chunkSize - 1 do
				for z = 0, self.chunkSize - 1 do
					self:getBlock(x, y, z):render(self, x, y, z)
				end
			end
		end
	end
	return self.mesh
end

function chunk:getId(x, y, z)
	return x * self.chunkSize * self.chunkSize + y * self.chunkSize + z
end

function chunk:getBlockCoords(x, y, z)
	return self.world:getBlockCoords(self.cx, self.cy, self.cz, x, y, z)
end

function chunk:getNeighbour(x, y, z)
	if x >= 0 and x <= 15 and y >= 0 and y <= 15 and z >= 0 and z <= 15 then
		return self:getBlock(x, y, z)
	else
		return self.world:getBlock(self:getBlockCoords(x, y, z))
	end
end

---Get a block
---@param x number
---@param y number
---@param z number
---@return Block
function chunk:getBlock(x, y, z)
	return self.world.game.registry:get(self.blocks[self:getId(x, y, z)].tile)
end

---Sets a block
---@param x number
---@param y number
---@param z number
---@param block Block
function chunk:setBlock(x, y, z, block)
	self.blocks[self:getId(x, y, z)].tile = block:getId()
	self:setDirty()
end

function chunk:setDirty()
	self.dirty = true
end

chunk.__index = chunk

return chunk