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

function class:updateBoundingBox()
	lib.meta.mesh.updateBoundingBox(self)
	
	self.originalBoundingBox = self.boundingBox
	
	--todo
end

function class:resize(count)
	self.originalBoundingBox = self.boundingBox:clone()
	
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

---@private
function class:extendBoundingBoxByVertex(instance)
	--todo
	self.boundingBox = self.boundingBox:merge(lib:newBoundingBox(
			rotation * self.originalBoundingBox.first + position,
			rotation * self.originalBoundingBox.second + position
	))
end

---Place instances from an array of mat4x3 transformations, represented as a flat array (mat3 rotation, vec3 position)
---@param instances number[][]
function class:setInstances(instances)
	self:resize(#instances)
	self.instanceMesh:setVertices(instances)
	self.instancesCount = #instances
end

return class