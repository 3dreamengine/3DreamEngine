local f = { }

f.meshLayout = {
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexTexCoord", "float", 2 }, -- UV
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexTangent", "byte", 4 }, -- normal tangent
}

local empty = vec4(1, 0, 1, 1)
function f:create(mesh)
	mesh:recalculateTangents()
	
	for i = 1, mesh.vertices:getSize() do
		local vertex = mesh.vertices:getOrDefault(i, empty)
		local normal = mesh.normals:getOrDefault(i, empty)
		local texCoord = mesh.texCoords:getOrDefault(i, empty)
		local tangent = mesh.tangents:getOrDefault(i, empty)
		
		mesh.mesh:setVertex(i,
				vertex.x, vertex.y, vertex.z, 1,
				texCoord.x, texCoord.y,
				normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5, 0.0,
				tangent.x * 0.5 + 0.5, tangent.y * 0.5 + 0.5, tangent.z * 0.5 + 0.5, tangent.w or 0.0
		)
	end
end

return f