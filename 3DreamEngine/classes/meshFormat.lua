---@type Dream
local lib = _3DreamEngine

---newMesh
---@return DreamMeshFormat
function lib:newMeshFormat()
	local f = {
		meshFormat = {}
	}
	
	return setmetatable(f, self.meta.meshFormat)
end

---@class DreamMeshFormat
local class = {
	links = { "meshFormat" },
}

function class:create(mesh)
	error("Not implemented")
end

return class