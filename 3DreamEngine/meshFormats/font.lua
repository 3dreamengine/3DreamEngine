---@type Dream
local lib = _3DreamEngine

local f = lib:newMeshFormat({
	{ "VertexPosition", "float", 4 }, -- x, y, z
	{ "VertexTexCoord", "float", 2 }, -- UV
	{ "VertexNormal", "byte", 4 }, -- normal
	{ "VertexMaterial", "byte", 4 }, -- roughness, metallic, emissive
	{ "VertexColor", "byte", 4 }, -- color
})

function f:create(mesh)
	error("Not implemented, use the font mesh builder.")
end

return f