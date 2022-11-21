local lib = _3DreamEngine

local function newObjectInner(physics, obj, transform, colliders, shapeMode)
	assert(obj.class == "object", "Object Expected")
	
	if obj.transform then
		transform = transform and transform * obj.transform or obj.transform
	end
	
	if shapeMode then
		for _, mesh in pairs(obj.meshes) do
			table.insert(colliders, { lib:newCollisionMesh(mesh, shapeMode), transform })
		end
	else
		for _, phy in pairs(obj.collisionMeshes) do
			table.insert(colliders, { phy, transform })
		end
	end
	
	for _, s in pairs(obj.objects) do
		newObjectInner(physics, s, transform, colliders, shapeMode)
	end
end

---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

---Create a new shape from an object, using all meshes
---@param object DreamObject
---@param shapeMode string
---@return DreamCollider
function physicsExtension:newObject(object, shapeMode)
	---@type DreamCollider
	local colliders = { }
	newObjectInner(self, object, false, colliders, shapeMode or "simple")
	return self:newMultiMesh(colliders)
end

---Create a new shape from an object, using only pre-defined physics objects
---@param object DreamObject
---@return DreamCollider
function physicsExtension:newPhysicsObject(object)
	local colliders = { }
	newObjectInner(self, object, false, colliders)
	return self:newMultiMesh(colliders)
end