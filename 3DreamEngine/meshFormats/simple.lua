local f = { }

f.meshLayout = {
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexMaterial", "float", 3 }, -- roughness, metallic, emissive
	{ "VertexColor", "byte", 4 }, -- color
}

local empty = vec4(1, 0, 1, 1)
function f:create(mesh)
	for i = 1, mesh.vertices:getSize() do
		local vertex = mesh.vertices:getOrDefault(i, empty)
		local normal = mesh.normals:getOrDefault(i, empty)
		local color = mesh.colors:getOrDefault(i, empty)
		local emission = mesh.emissions:getOrDefault(i, empty)
		
		mesh.mesh:setVertex(i,
				vertex.x, vertex.y, vertex.z, 1,
				normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 0.0,
				mesh.roughnesses[i] or 0.5, mesh.metallics[i] or 0, emission.x * 0.299 + emission.y * 0.587 + emission.z * 0.114,
				color.x, color.y, color.z, color.w
		)
	end
end

return f