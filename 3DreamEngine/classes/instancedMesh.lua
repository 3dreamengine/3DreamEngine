---@type Dream
local lib = _3DreamEngine

---newMesh
---@param mesh DreamMesh
---@return DreamInstancedMesh | DreamMesh | DreamClonable | DreamHasShaders
function lib:newInstancedMesh(mesh)
	mesh.instancesCount = 0
	
	return setmetatable(mesh, self.meta.instancedMesh)
end

---@class DreamInstancedMesh : DreamMesh
local class = {
	links = { "clone", "shader", "mesh", "instancedMesh" },
}

function class:getInstancesCount()
	return self.instancesCount
end

function class:updateBoundingSphere()
	lib.classes.mesh.updateBoundingSphere(self)
	
	self.originalBoundingSphere = self.boundingSphere
	
	--todo similar algo like updateBoundingSphere for objects
end

function class:resize(count)
	self.originalBoundingSphere = self.boundingSphere:clone()
	
	--create mesh containing the transforms
	local new = love.graphics.newMesh({
		{ "InstanceRotation0", "float", 3 },
		{ "InstanceRotation1", "float", 3 },
		{ "InstanceRotation2", "float", 3 },
		{ "InstancePosition", "float", 3 },
	}, count)
	
	--copy existing buffer
	if self.instanceMesh then
		for i = 1, self.instanceMesh:getVertexCount() do
			new:setVertex(i, self.instanceMesh:getVertex(i))
		end
	end
	
	self.instanceMesh = new
	self.instancesCount = 0
end

---addInstance
---@param rotation "mat3"
---@param position "vec3"
---@param index number @ Optional index, else it will append
function class:addInstance(rotation, position, index)
	if not index then
		self.instancesCount = self.instancesCount + 1
		index = self.instancesCount
		assert(index <= self.instanceMesh:getVertexCount(), "Instance mesh too small!")
	end
	
	local instance = {
		rotation[1], rotation[2], rotation[3],
		rotation[4], rotation[5], rotation[6],
		rotation[7], rotation[8], rotation[9],
		position[1], position[2], position[3]
	}
	
	self.instanceMesh:setVertex(index, instance)
end

local function getLossySize(mat3)
	return math.sqrt(math.max(
			(mat3[1] ^ 2 + mat3[4] ^ 2 + mat3[7] ^ 2),
			(mat3[2] ^ 2 + mat3[5] ^ 2 + mat3[8] ^ 2),
			(mat3[3] ^ 2 + mat3[6] ^ 2 + mat3[9] ^ 2)
	))
end

---Place instances from an array of mat4x3 transformations, represented as a flat array (mat3 rotation, vec3 position)
---@param instances number[][]
function class:setInstances(instances)
	self:resize(#instances)
	self.instanceMesh:setVertices(instances)
	self.instancesCount = #instances
	self:updateBoundingSphere()
end

return class