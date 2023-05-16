---@type Dream
local lib = _3DreamEngine
local vec3, mat3 = lib.vec3, lib.mat3

---@param mesh DreamMesh @ The source mesh to create instances from
---@return DreamInstancedMesh
function lib:newInstancedMesh(mesh)
	mesh = setmetatable(mesh:clone(), self.meta.instancedMesh)
	
	mesh.instancesCount = 0
	
	mesh:resize(16)
	
	return mesh
end

---Uses a mesh to create instances from it. Especially helpful when rendering many small instances
---@class DreamInstancedMesh : DreamMesh
local class = {
	links = { "mesh", "instancedMesh" },
}

---Returns the current amount of instances
---@return number
function class:getInstancesCount()
	return self.instancesCount
end

---@private
function class:getMesh(name)
	name = name or "mesh"
	
	local mesh = lib.classes.mesh.getMesh(self, name)
	
	if name == "mesh" then
		mesh:attachAttribute("InstanceRotation0", self.instanceMesh, "perinstance")
		mesh:attachAttribute("InstanceRotation1", self.instanceMesh, "perinstance")
		mesh:attachAttribute("InstanceRotation2", self.instanceMesh, "perinstance")
		mesh:attachAttribute("InstancePosition", self.instanceMesh, "perinstance")
		return mesh, self.instancesCount
	end
	
	return mesh
end

---Clear all instances
function class:clear()
	self.instancesCount = 0
end

---Resize the instanced mesh, preserving previous entries
---@param count number
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
		for i = 1, math.min(self.instanceMesh:getVertexCount(), count) do
			new:setVertex(i, self.instanceMesh:getVertex(i))
		end
	end
	
	self.instanceMesh = new
	self.instancesCount = math.min(count, self.instancesCount)
end

---Add another instance
---@param transform DreamMat4 @ a mat3x4 matrix, instances do not support shearing, e.g. the last row
---@param index number @ Optional index, else it will append
function class:addInstance(transform, index)
	if not index then
		self.instancesCount = self.instancesCount + 1
		index = self.instancesCount
		if index > self.instanceMesh:getVertexCount() then
			self:resize(self.instanceMesh:getVertexCount() * 2)
		end
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

---Place instances from an array of mat3x4 transformations, represented as a flat array (mat3 rotation, vec3 position, basically a transposed DreamMat4 with missing last row)
---@param instances number[][][]
function class:setInstances(instances)
	self:resize(#instances)
	self.instanceMesh:setVertices(instances)
	self.instancesCount = #instances
	self:updateBoundingSphere()
end

---Updates the bounding sphere from scratch, called internally when needed
function class:updateBoundingSphere()
	lib.classes.mesh.updateBoundingSphere(self)
	
	self.originalBoundingSphere = self.boundingSphere
	
	self.boundingSphere = lib:newBoundingSphere()
	
	if self.instanceMesh then
		for i = 1, self.instanceMesh:getVertexCount() do
			self:extendBoundingSphere({ self.instanceMesh:getVertex(i) })
		end
	end
end

local function getLossySize(mat)
	return math.sqrt(math.max(
			(mat[1] ^ 2 + mat[4] ^ 2 + mat[7] ^ 2),
			(mat[2] ^ 2 + mat[5] ^ 2 + mat[8] ^ 2),
			(mat[3] ^ 2 + mat[6] ^ 2 + mat[9] ^ 2)
	))
end

---Extend the bounding sphere by another instance, called internally
---@param instance DreamMat4
function class:extendBoundingSphere(instance)
	local rotation = mat3(instance)
	local position = vec3(instance[10], instance[11], instance[12])
	local bs = lib:newBoundingSphere(
			rotation * self.originalBoundingSphere.center + position,
			self.originalBoundingSphere.size * getLossySize(rotation)
	
	)
	self.boundingSphere = self.boundingSphere:merge(bs)
end

return class