---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

local f = lib:newMeshFormat({
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexMaterial", "float", 3 }, -- roughness, metallic, emissive
	{ "VertexColor", "byte", 4 }, -- color
})

local empty = vec4(1, 0, 1, 1)
function f:create(mesh)
	local identifier = self:getCStruct()
	local byteData = love.data.newByteData(ffi.sizeof(identifier) * mesh.vertices:getSize())
	local vertices = ffi.cast(identifier .. "*", byteData:getFFIPointer())
	
	for i = 1, mesh.vertices:getSize() do
		local vertex = mesh.vertices:getOrDefault(i, empty)
		local normal = mesh.normals:getOrDefault(i, empty)
		local color = mesh.colors:getOrDefault(i, empty)
		local roughness = mesh.roughnesses:getOrDefault(i, 0.5)
		local metallics = mesh.metallics:getOrDefault(i, 0)
		local emission = mesh.emissions:getOrDefault(i, empty)
		
		local v = vertices[i - 1]
		
		v.VertexPositionX = vertex.x
		v.VertexPositionY = vertex.y
		v.VertexPositionZ = vertex.z
		v.VertexPositionW = 1
		
		v.VertexNormalX = normal.x * 127 + 127
		v.VertexNormalY = normal.y * 127 + 127
		v.VertexNormalZ = normal.z * 127 + 127
		v.VertexNormalW = 0
		
		v.VertexMaterialX = roughness
		v.VertexMaterialY = metallics
		v.VertexMaterialZ = emission.x * 0.299 + emission.y * 0.587 + emission.z * 0.114
		
		v.colorX = color.x * 127 + 127
		v.colorY = color.y * 127 + 127
		v.colorZ = color.z * 127 + 127
		v.colorW = color.w * 127 + 127
	end
	
	return byteData
end

return f