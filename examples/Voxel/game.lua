---@class Game
local game = { }

local dream = _3DreamEngine

---New game
---@return Game
function game:new(player)
	---@type Game
	local g = setmetatable({ }, game)
	
	local block = require("examples.Voxel.block")
	
	g.player = player
	
	g.utils = require("examples.Voxel.utils")
	
	g.registry = require("examples.Voxel.registry"):new()
	
	g.registry:add("air", block:new(0, 0, 0))
	g.registry:add("stone", block:new(128, 128, 128))
	g.registry:add("grass", block:new(30, 200, 30))
	g.registry:add("sand", block:new(128, 255, 0))
	g.registry:add("water", block:new(32, 32, 255))
	g.registry:add("bricks", block:new(255, 64, 0))
	
	g.world = require("examples.Voxel.world"):new(g)
	
	return g
end

function game:draw()
	local t = love.timer.getTime()
	local view = 16
	local budget = 1 / 1000
	local px = math.floor(self.player.x / self.world.chunkSize)
	local py = math.floor(self.player.y / self.world.chunkSize)
	local pz = math.floor(self.player.z / self.world.chunkSize)
	
	for cx, cy, cz in self.utils:traverseSphere(px, py, pz, view) do
		local chunk = self.world:getChunk(cx, cy, cz, (love.timer.getTime() - t) > budget)
		if chunk then
			local mesh = chunk:getMesh()
			if mesh:getMesh() then
				dream:draw(mesh, cx * self.world.chunkSize, cy * self.world.chunkSize, cz * self.world.chunkSize)
			end
		end
	end
end

function game:mousepressed(x, y, button)
	local pos = dream.vec3(self.player.x, self.player.y, self.player.z)
	local lx, ly, lz
	self.utils:iterateCubesOnLine(pos, pos + dream.camera.normal * 20, function(x, y, z)
		local block = self.world:getBlock(x, y, z)
		if block:getId() > 0 then
			if button == 1 then
				self.world:setBlock(x, y, z, "air")
			elseif lx then
				self.world:setBlock(lx, ly, lz, "bricks")
			end
			return true
		end
		lx, ly, lz = x, y, z
	end)
end

game.__index = game

return game