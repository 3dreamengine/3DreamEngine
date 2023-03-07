---@type Dream
local lib = _3DreamEngine

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

---A new raytrace collision mesh, containing only relevant data, created automatically when the object has the `RAYTRACE` tag
---@class DreamRaytraceMesh
local class = {
	links = { "raytraceMesh" },
}

return class