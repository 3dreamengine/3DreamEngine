local lib = _3DreamEngine

local function inner(physics, obj, transform, colliders, shapeMode)
	assert(obj.class == "object", "Object Expected")
	
	if obj.transform then
		transform = transform and transform * obj.transform or obj.transform
	end
	
	if shapeMode then
		for _, mesh in pairs(obj.meshes) do
			table.insert(colliders, { lib:newCollider(mesh, shapeMode), transform })
		end
	else
		for _, phy in pairs(obj.physics) do
			table.insert(colliders, { phy, transform })
		end
	end
	
	for _, s in pairs(obj.objects) do
		inner(physics, s, transform, colliders, shapeMode)
	end
end

---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

---create a new shape from an object, using all meshes
function physicsExtension:newObject(object, shapeMode)
	---@type Collider
	local colliders = { }
	inner(self, object, false, colliders, shapeMode or "simple") --todo type check
	return self:newMultiMesh(colliders)
end

---create a new shape from an object, using only pre-defined physics objects
function physicsExtension:newPhysicsObject(object)
	---@type Collider
	local colliders = { }
	inner(self, object, false, colliders)
	return self:newMultiMesh(colliders)
end