local f = { }

f.meshLayout = {
	{"VertexPosition", "float", 4},     -- x, y, z
	{"VertexNormal", "byte", 4},        -- normal
	{"VertexMaterial", "float", 1},     -- material
}

local empty = {1, 0, 1, 1}
function f:create(mesh)
	for i = 1, #mesh.vertices do
		local vertex = mesh.vertices[i] or empty
		local normal = mesh.normals[i] or empty
		local texCoord = mesh.texCoords[i] or empty
		
		obj.mesh:setVertex(i,
			vertex[1], vertex[2], vertex[3], 1,
			normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
			texCoord[1]
		)
	end
end

return f