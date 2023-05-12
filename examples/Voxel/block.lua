---@class Block
local block = { }

function block:new(red, green, blue)
	local b = { }
	
	b.id = -1
	b.red = red
	b.green = green
	b.blue = blue
	
	return setmetatable(b, block)
end

function block:getId()
	return self.id
end

function block:getColor()
	return self.red, self.green, self.blue
end

local directions = {
	top = 1,
	bottom = 2,
	right = 3,
	left = 4,
	front = 5,
	back = 6
}

local faces = {
	{ 8, 7, 6, 5 },
	{ 1, 2, 3, 4 },
	{ 3, 2, 6, 7 },
	{ 8, 5, 1, 4 },
	{ 4, 3, 7, 8 },
	{ 2, 1, 5, 6 }
}

local vertices = {
	{ 0, 0, 0 },
	{ 1, 0, 0 },
	{ 1, 0, 1 },
	{ 0, 0, 1 },
	{ 0, 1, 0 },
	{ 1, 1, 0 },
	{ 1, 1, 1 },
	{ 0, 1, 1 },
}

local normals = {
	{ 0, 1, 0 },
	{ 0, -1, 0 },
	{ 1, 0, 0 },
	{ -1, 0, 0 },
	{ 0, 0, 1 },
	{ 0, 0, -1 },
}

---Render
---@param chunk Chunk
---@param x number
---@param y number
---@param z number
function block:render(chunk, x, y, z)
	if self:getId() > 0 then
		for _, direction in pairs(directions) do
			local normal = normals[direction]
			local b = chunk:getNeighbour(x + normal[1], y + normal[2], z + normal[3])
			if b:getId() == 0 then
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
			end
		end
	end
end

block.__index = block

return block