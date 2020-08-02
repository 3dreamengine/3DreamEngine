--[[
#part of the 3DreamEngine by Luke100000
particles.lua - particle spritebatches
--]]

local lib = _3DreamEngine

local minIncreaseStep = 16
local maxCount = 1024 * 32

--instancemesh
local instanceFormat = {
	{"InstanceCenter", "float", 3},    -- x, y, z
	{"InstanceSize", "float", 2},      -- size
	{"InstanceTexOffset", "float", 2}, -- uv offset
	{"InstanceTexScale", "float", 2},  -- uv scale
	{"InstanceEmission", "float", 1},  -- emission
	{"InstanceColor", "byte", 4},      -- color
}

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


--sorter
local sortingCamPos
local sortFunction = function(a, b)
	local distA = (a[1] - sortingCamPos[1])^2 + (a[2] - sortingCamPos[2])^2 + (a[3] - sortingCamPos[3])^2
	local distB = (b[1] - sortingCamPos[1])^2 + (b[2] - sortingCamPos[2])^2 + (b[3] - sortingCamPos[3])^2
	return distA > distB
end

local meta = {
	--clear the batch
	clear = function(self)
		self.instances = { }
	end,
	
	--add a new particle to this batch
	add = function(self, px, py, pz, size, emission, quad)
		local n = #self.instances
		if n < maxCount then
			local r, g, b, a = love.graphics.getColor()
			if quad then
				local x, y, w, h = quad:getViewport()
				local sw, sh = quad:getTextureDimensions()
				local ratio = h / w
				self.instances[n+1] = {px, py, pz, size, size * ratio, x / sw, y / sh, w / sw, h / sh, emission or 0, r, g, b, a}
			else
				self.instances[n+1] = {px, py, pz, size, size, 0, 0, 1, 1, emission or 0, r, g, b, a}
			end
		end
	end,
	
	--present the batch
	present = function(self, camPos)
		if #self.instances == 0 then
			return
		end
		
		if self.sort then
			sortingCamPos = camPos
			table.sort(self.instances, sortFunction)
		end
		
		--increase mesh data if required
		if not instanceMesh or instanceMesh:getVertexCount() < #self.instances then
			instanceMesh = love.graphics.newMesh(instanceFormat, math.ceil(#self.instances / minIncreaseStep) * minIncreaseStep, "triangles", "dynamic")
			
			--attach instance mesh
			for d,s in pairs({"InstanceCenter", "InstanceSize", "InstanceTexScale", "InstanceTexOffset", "InstanceEmission", "InstanceColor"}) do
				mesh:detachAttribute(s)
				mesh:attachAttribute(s, instanceMesh, "perinstance")
			end
		end
		
		--fill instance buffer
		instanceMesh:setVertices(self.instances)
		
		mesh:setTexture(self.texture)
		
		--draw
		love.graphics.drawInstanced(mesh, #self.instances)
	end,
}

function lib:newParticleBatch(texture, pass)
	local p = { }
	
	p.texture = texture or 2
	p.pass = pass or 2
	p.sort = p.pass == 2
	
	p.instances = { }
	
	return setmetatable(p, {__index = meta})
end