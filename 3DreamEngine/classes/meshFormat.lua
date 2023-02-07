---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---newMesh
---@return DreamMeshFormat
function lib:newMeshFormat(meshLayout)
	local f = {
		meshLayout = meshLayout
	}
	
	return setmetatable(f, self.meta.meshFormat)
end

---@class DreamMeshFormat
local class = {
	links = { "meshFormat" },
}

---Converts the intermediate buffer representation into drawable love2d meshes
---@param mesh DreamMesh
function class:create(mesh)
	error("Not implemented")
end

local cachedStructs = { }
function lib:getCStruct()
	--give a unique hash for the structs name
	local md5 = love.data.hash("md5", lib.packTable.pack(self.meshLayout))
	local hash = love.data.encode("string", "hex", md5)
	
	--build a C struct to make sure data match
	if not cachedStructs[hash] then
		local types = { }
		local str = "typedef struct {" .. "\n"
		for _, format in ipairs(self.meshLayout) do
			if format[2] == "float" then
				str = str .. "float "
			elseif format[2] == "byte" then
				str = str .. "unsigned char "
			else
				error("unknown data type " .. format[2])
			end
			
			for i = 1, format[3] do
				table.insert(types, format[2])
				str = str .. "x" .. attrCount .. (i == format[3] and ";" or ", ")
			end
			str = str .. "\n"
		end
		str = str .. "} mesh_vertex_" .. hash .. ";"
		ffi.cdef(str)
		cachedStructs[hash] = types
	end
	
	return hash, cachedStructs[hash]
end

return class