local f = { }

f.meshLayout = {
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexMaterial", "float", 1 }, -- material
}

local empty = { 1, 0, 1, 1 }
function f:create(mesh)
	for i = 1, mesh.vertices:getSize() do
		local vertex = mesh.vertices:getOrDefault(i, empty)
		local normal = mesh.normals:getOrDefault(i, empty)
		local texCoord = mesh.texCoords:getOrDefault(i, empty)
		
		mesh.mesh:setVertex(i,
				vertex[1], vertex[2], vertex[3], 1,
				normal[1] * 0.5 + 0.5, normal[2] * 0.5 + 0.5, normal[3] * 0.5 + 0.5, 0.0,
				texCoord[1] --todo not really standard, use 2D and multi texture
		)
	end
end

return f