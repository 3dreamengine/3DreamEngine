local f = { }

f.meshLayout = {
	{"VertexPosition", "float", 4},     -- x, y, z
	{"VertexNormal", "byte", 4},        -- normal
	{"VertexMaterial", "float", 3},     -- roughness, metallic, emissive
	{"VertexColor", "byte", 4},         -- color
}

local empty = {1, 0, 1, 1}
function f:create(mesh)
	for i = 1, #mesh.vertices do
		local vertex = mesh.vertices[i] or empty
		local normal = mesh.normals[i] or empty
		local color = mesh.colors[i] or empty
		
		mesh.mesh:setVertex(i,
			vertex[1], vertex[2], vertex[3], 1,
			normal[1]*0.5+0.5, normal[2]*0.5+0.5, normal[3]*0.5+0.5, 0.0,
			roughness, metallic, emission,
			color[1], color[2], color[3], color[4]
		)
	end
end

return f