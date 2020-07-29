--[[
#part of the 3DreamEngine by Luke100000
particles.lua - particle spritebatches
--]]

local lib = _3DreamEngine

local maxCount = 512

--instancemesh
local f = {
	{"InstanceCenter", "float", 3},    -- x, y, z
	{"InstanceSize", "float", 2},      -- size
	{"InstanceTexOffset", "float", 2}, -- uv offset
	{"InstanceTexScale", "float", 2},  -- uv scale
	{"InstanceEmission", "float", 1},  -- emission
	{"InstanceColor", "byte", 4},      -- color
}
local instanceMesh = love.graphics.newMesh(f, maxCount, "triangles", "dynamic")


--quad
local f = {
	{"VertexPosition", "float", 3},    -- x, y, z
	{"VertexTexCoord", "float", 2},    -- uv
}
local mesh = love.graphics.newMesh(f, {
	{-0.5, -0.5, 0.0, 1.0, 1.0},
	{0.5, -0.5, 0.0, 0.0, 1.0},
	{0.5, 0.5, 0.0, 0.0, 0.0},
	{-0.5, 0.5, 0.0, 1.0, 0.0},
}, "triangles", "dynamic")
mesh:setVertexMap(1, 2, 3, 1, 3, 4)


--attach instance mesh
mesh:attachAttribute("InstanceCenter", instanceMesh, "perinstance")
mesh:attachAttribute("InstanceSize", instanceMesh, "perinstance")
mesh:attachAttribute("InstanceTexScale", instanceMesh, "perinstance")
mesh:attachAttribute("InstanceTexOffset", instanceMesh, "perinstance")
mesh:attachAttribute("InstanceEmission", instanceMesh, "perinstance")
mesh:attachAttribute("InstanceColor", instanceMesh, "perinstance")


--sorter
local sortingCamPos
local sortFunction = function(a, b)
	local distA = (a[1] - sortingCamPos[1])^2 + (a[2] - sortingCamPos[2])^2 + (a[3] - sortingCamPos[3])^2
	local distB = (b[1] - sortingCamPos[1])^2 + (b[2] - sortingCamPos[2])^2 + (b[3] - sortingCamPos[3])^2
	return distA > distB
end

local meta = {
	clear = function(self)
		self.instances = { }
	end,
	
	add = function(self, px, py, pz, size, emission, quad)
		local r, g, b, a = love.graphics.getColor()
		if quad then
			local x, y, w, h = quad:getViewport()
			local sw, sh = quad:getTextureDimensions()
			local ratio = h / w
			self.instances[#self.instances+1] = {px, py, pz, size, size * ratio, x / sw, y / sh, w / sw, h / sh, emission or 0, r, g, b, a}
		else
			self.instances[#self.instances+1] = {px, py, pz, size, size * ratio, 0, 0, 1, 1, emission or 0, r, g, b, a}
		end
	end,
	
	present = function(self, camPos)
		if self.pass == 2 then
			sortingCamPos = camPos
			table.sort(self.instances, sortFunction)
		end
		
		--fill instance buffer
		instanceMesh:setVertices(self.instances)
		
		mesh:setTexture(self.texture)
		
		--draw
		love.graphics.drawInstanced(mesh, #self.instances)
	end,
}

function lib:newParticleBatch(texture, count, pass)
	local p = { }
	
	p.texture = texture or 2
	p.pass = pass or 2
	
	p.instances = { }
	
	return setmetatable(p, {__index = meta})
end