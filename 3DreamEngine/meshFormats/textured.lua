local f = { }

f.meshLayout = {
	{"VertexPosition", "float", 4},     -- x, y, z
	{"VertexTexCoord", "float", 2},     -- UV
	{"VertexNormal", "byte", 4},        -- normal
	{"VertexTangent", "byte", 4},       -- normal tangent
}

local empty = {1, 0, 1, 1}
function f:create(mesh)
	mesh:calcTangents()
	
	for i = 1, #mesh.vertices do
		local vertex = mesh.vertices[i] or empty
		local normal = mesh.normals[i] or empty
		local texCoord = mesh.texCoords[i] or empty
		local tangent = mesh.tangents[i] or empty
		
		mesh.mesh:setVertex(i,
			vertex[1], vertex[2], vertex[3], 1,
			texCoord[1], texCoord[2],
			normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
			tangent[1]*0.5+0.5, tangent[2]*0.5+0.5, tangent[3]*0.5+0.5, tangent[4] or 0.0
		)
	end
end

return f