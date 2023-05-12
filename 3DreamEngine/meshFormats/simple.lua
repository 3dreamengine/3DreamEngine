---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

local f = lib:newMeshFormat({
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexMaterial", "byte", 4 }, -- roughness, metallic, emissive
	{ "VertexColor", "byte", 4 }, -- color
})

local empty = lib.vec4(1, 0, 1, 1)
function f:create(mesh)
	local identifier = self:getCStruct()
	local byteData = love.data.newByteData(ffi.sizeof(identifier) * mesh.vertices:getSize())
	local vertices = ffi.cast(identifier .. "*", byteData:getFFIPointer())
	
	for i = 1, mesh.vertices:getSize() do
		local vertex = mesh:getOrCreateBuffer("vertices"):getOrDefault(i, empty)
		local normal = mesh:getOrCreateBuffer("normals"):getOrDefault(i, empty)
		local color = mesh:getOrCreateBuffer("colors"):getOrDefault(i, empty)
		local roughness = mesh:getOrCreateBuffer("roughnesses"):getOrDefault(i, 0.5)
		local metallics = mesh:getOrCreateBuffer("metallics"):getOrDefault(i, 0)
		local emission = mesh:getOrCreateBuffer("emissions"):getOrDefault(i, empty)
		
		local v = vertices[i - 1]
		
		v.VertexPositionX = vertex.x
		v.VertexPositionY = vertex.y
		v.VertexPositionZ = vertex.z
		v.VertexPositionW = 1
		
		v.VertexNormalX = normal.x * 127.5 + 127.5
		v.VertexNormalY = normal.y * 127.5 + 127.5
		v.VertexNormalZ = normal.z * 127.5 + 127.5
		v.VertexNormalW = 0
		
		v.VertexMaterialX = roughness * 255
		v.VertexMaterialY = metallics * 255
		v.VertexMaterialZ = (emission.x * 0.299 + emission.y * 0.587 + emission.z * 0.114) * 255
		
		v.VertexColorX = color.x * 255
		v.VertexColorY = color.y * 255
		v.VertexColorZ = color.z * 255
		v.VertexColorW = color.w * 255
	end
	
	return byteData
end

return f