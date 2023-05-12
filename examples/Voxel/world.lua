local chunkClass = require("examples.Voxel.chunk")

---@class World
local world = { }

local chunkSize = 16

---@param game Game
---@return World
function world:new(game)
	---@type World
	local w = setmetatable({ }, world)
	
	w.game = game
	w.chunkSize = chunkSize
	
	---@type table<number, table<number, table<number, Chunk>>>
	w.chunks = { }
	
	return w
end

function world:getChunkCoords(x, y, z)
	return math.floor(x / chunkSize), math.floor(y / chunkSize), math.floor(z / chunkSize)
end

function world:getBlockCoords(cx, cy, cz, x, y, z)
	return cx * chunkSize + x, cy * chunkSize + y, cz * chunkSize + z
end

function world:setBlock(x, y, z, name)
	local block = self.game.registry:get(name)
	local cx, cy, cz = self:getChunkCoords(x, y, z)
	local chunk = self:getChunk(cx, cy, cz)
	chunk:setBlock(x - cx * chunkSize, y - cy * chunkSize, z - cz * chunkSize, block)
end

function world:getBlock(x, y, z)
	local cx, cy, cz = self:getChunkCoords(x, y, z)
	local chunk = self:getChunk(cx, cy, cz)
	return chunk:getBlock(x - cx * chunkSize, y - cy * chunkSize, z - cz * chunkSize)
end

function world:getChunk(cx, cy, cz, optional)
	local id = string.format("%d %d %d", cx, cy, cz)
	if not optional and not self.chunks[id] then
		local c = chunkClass:new(self, cx, cy, cz, chunkSize)
		self.chunks[id] = c
		return c, true
	end
	return self.chunks[id], false
end

world.__index = world

return world