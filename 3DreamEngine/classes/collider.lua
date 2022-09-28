local lib = _3DreamEngine

local shapeModes = {
	height = true,
	simple = true,
	complex = true,
	wall = true
}

function lib:newCollider(mesh, shapeMode)
	shapeMode = shapeMode or "complex"
	assert(shapeModes[shapeMode], "Unknown collider shape mode " .. tostring(shapeMode))
	
	local c = {
		faces = mesh.faces,
		vertices = mesh.vertices,
		normals = mesh.normals,
		name = mesh.name,
		shapeMode = shapeMode,
	}
	
	return setmetatable(c, self.meta.collider)
end

local class = {
	link = { "collider" },
	
	setterGetter = {
		
	},
}

function class:decode()
	self.transform = mat4(self.transform)
	for i, v in ipairs(self.vertices) do
		self.vertices[i] = vec3(v)
	end
	for i, v in ipairs(self.normals) do
		self.normals[i] = vec3(v)
	end
end

return class