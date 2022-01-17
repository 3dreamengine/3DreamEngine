local lib = _3DreamEngine

function lib:newCollider(mesh)
	local c = {
		faces = mesh.faces,
		vertices = mesh.vertices,
		normals = mesh.normals,
		name = mesh.name
	}
	
	return setmetatable(c, self.meta.collider)
end

local class = {
	link = {"collider"},
	
	setterGetter = {
		
	},
}

return class