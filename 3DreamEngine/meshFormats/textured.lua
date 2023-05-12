---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

local f = lib:newMeshFormat({
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexTexCoord", "float", 2 }, -- UV
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexTangent", "byte", 4 }, -- normal tangent
})

local empty = lib.vec4(1, 0, 1, 1)
function f:create(mesh)
	mesh:recalculateTangents()
	
	local identifier = self:getCStruct()
	local byteData = love.data.newByteData(ffi.sizeof(identifier) * mesh.vertices:getSize())
	local vertices = ffi.cast(identifier .. "*", byteData:getFFIPointer())
	
	for i = 1, mesh.vertices:getSize() do
		local vertex = mesh:getOrCreateBuffer("vertices"):getOrDefault(i, empty)
		local normal = mesh:getOrCreateBuffer("normals"):getOrDefault(i, empty)
		local texCoord = mesh:getOrCreateBuffer("texCoords"):getOrDefault(i, empty)
		local tangent = mesh:getOrCreateBuffer("tangents"):getOrDefault(i, empty)
		
		local v = vertices[i - 1]
		
		v.VertexPositionX = vertex.x
		v.VertexPositionY = vertex.y
		v.VertexPositionZ = vertex.z
		v.VertexPositionW = 1
		
		v.VertexTexCoordX = texCoord.x
		v.VertexTexCoordY = texCoord.y
		
		v.VertexNormalX = normal.x * 127.5 + 127.5
		v.VertexNormalY = normal.y * 127.5 + 127.5
		v.VertexNormalZ = normal.z * 127.5 + 127.5
		v.VertexNormalW = 0
		
		v.VertexTangentX = tangent.x * 127.5 + 127.5
		v.VertexTangentY = tangent.y * 127.5 + 127.5
		v.VertexTangentZ = tangent.z * 127.5 + 127.5
		v.VertexTangentW = 0
	end
	
	return byteData
end

return f