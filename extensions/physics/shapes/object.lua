local function inner(physics, obj, transform, loveShapes)
	assert(obj.class == "object", "Object Expected")
	
	if obj.transform then
		transform = transform and transform * obj.transform or obj.transform
	end
	
	if obj.physics then
		for _, phy in pairs(obj.physics) do
			table.insert(loveShapes, physics:newMesh(phy, transform))
		end
	end
	
	for _, s in pairs(obj.objects) do
		inner(physics, s, transform, loveShapes)
	end
end

---@type PhysicsExtension
local physicsExtension = _G._PhysicsExtension

function physicsExtension:newObject(obj)
	---@type Collider[]
	local loveShapes = { }
	inner(self, obj, false, loveShapes)
	return loveShapes
end