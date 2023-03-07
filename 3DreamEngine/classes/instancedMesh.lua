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
	links = { "mesh", "instancedMesh" },
}

function class:getInstancesCount()
	return self.instancesCount
end

function class:updateBoundingSphere()
	lib.classes.mesh.updateBoundingSphere(self)
	
	self.originalBoundingSphere = self.boundingSphere
	
	self.boundingSphere = lib:newEmptyBoundingSphere()
	
	if self.instanceMesh then
		for i = 1, self.instanceMesh:getVertexCount() do
			self:extendBoundingSphere({ self.instanceMesh:getVertex(i) })
		end
	end
end

local function getLossySize(mat3)
	return math.sqrt(math.max(
			(mat3[1] ^ 2 + mat3[4] ^ 2 + mat3[7] ^ 2),
			(mat3[2] ^ 2 + mat3[5] ^ 2 + mat3[8] ^ 2),
			(mat3[3] ^ 2 + mat3[6] ^ 2 + mat3[9] ^ 2)
	))
end

function class:extendBoundingSphere(instance)
	local rotation = mat3(instance)
	local position = vec3(instance[10], instance[11], instance[12])
	local bs = lib:newBoundingSphere(
			rotation * self.originalBoundingSphere.center + position,
			self.originalBoundingSphere.size * getLossySize(rotation)
	
	)
	self.boundingSphere = self.boundingSphere:merge(bs)
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
---@param transform "mat4" @ a mat3x4 matrix, instances do not support shearing, e.g. the last row
---@param index number @ Optional index, else it will append
function class:addInstance(transform, index)
	if not index then
		self.instancesCount = self.instancesCount + 1
		index = self.instancesCount
		--todo just increase size?
		assert(index <= self.instanceMesh:getVertexCount(), "Instance mesh too small!")
	end
	
	local instance = {
		transform[1], transform[5], transform[9],
		transform[2], transform[6], transform[10],
		transform[3], transform[7], transform[11],
		transform[4], transform[8], transform[12]
	}
	
	self.instanceMesh:setVertex(index, instance)
	self:extendBoundingSphere(instance)
end

---Place instances from an array of mat3x4 transformations, represented as a flat array (mat3 rotation, vec3 position)
---@param instances number[][][]
function class:setInstances(instances)
	self:resize(#instances)
	self.instanceMesh:setVertices(instances)
	self.instancesCount = #instances
	self:updateBoundingSphere()
end

return class