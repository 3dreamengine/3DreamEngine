local lib = _3DreamEngine

---A new raytrace collision mesh, containing only relevant data
---@param mesh RaytraceMesh
function lib:newRaytraceMesh(mesh)
	local c = {
		name = mesh.name,
		faces = mesh.faces,
		vertices = mesh.vertices,
		normals = mesh.normals,
	}
	
	return setmetatable(c, self.meta.raytraceMesh)
end

---@class RaytraceMesh
local class = {
	links = { "raytraceMesh" },
}

return class