local lib = _3DreamEngine

---A new raytrace collision mesh, containing only relevant data
---@param mesh DreamRaytraceMesh
function lib:newRaytraceMesh(mesh)
	local c = {
		name = mesh.name,
		faces = mesh.faces,
		vertices = mesh.vertices,
		normals = mesh.normals,
	}
	
	return setmetatable(c, self.meta.raytraceMesh)
end

---@class DreamRaytraceMesh
local class = {
	links = { "raytraceMesh" },
}

return class