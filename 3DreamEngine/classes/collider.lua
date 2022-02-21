local lib = _3DreamEngine

local shapeModes = {
	height = true,
	simple = true,
	complex = true
}

function lib:newCollider(mesh)
	local c = {
		faces = mesh.faces,
		vertices = mesh.vertices,
		normals = mesh.normals,
		name = mesh.name,
		shapeMode = type(mesh.tags.physics) == "string" and shapeModes[mesh.tags.physics] and mesh.tags.physics or "complex",
	}
	
	return setmetatable(c, self.meta.collider)
end

local class = {
	link = {"collider"},
	
	setterGetter = {
		
	},
}

function class:decode()
	self.transform = mat4(self.transform)
	for i,v in ipairs(self.vertices) do
		self.vertices[i] = vec3(v)
	end
	for i,v in ipairs(self.normals) do
		self.normals[i] = vec3(v)
	end
end

return class