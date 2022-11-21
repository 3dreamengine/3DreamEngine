local lib = _3DreamEngine

local shapeModes = {
	height = true,
	simple = true,
	complex = true,
	wall = true
}

---A new collision mesh, containing only relevant data for a collider
---@param mesh DreamCollisionMesh
---@param shapeMode string
function lib:newCollisionMesh(mesh, shapeMode)
	shapeMode = shapeMode or "simple"
	assert(shapeModes[shapeMode], "Unknown collider shape mode " .. tostring(shapeMode))
	
	local c = {
		name = mesh.name,
		shapeMode = shapeMode,
		faces = mesh.faces,
		vertices = mesh.vertices,
		normals = mesh.normals,
	}
	
	return setmetatable(c, self.meta.collisionMesh)
end

---@class DreamCollisionMesh
local class = {
	links = { "collisionMesh" },
}

return class