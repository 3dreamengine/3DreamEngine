---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---newMesh
---@return DreamMeshFormat
function lib:newMeshFormat(meshLayout)
	local f = {
		meshLayout = meshLayout,
		attributes = { }
	}
	
	for _, format in ipairs(meshLayout) do
		f.attributes[format[1]] = true
	end
	
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
function class:getCStruct()
	--give a unique hash for the structs name
	local md5 = love.data.hash("md5", lib.packTable.pack(self.meshLayout))
	local identifier = "mesh_vertex_" .. love.data.encode("string", "hex", md5)
	
	--build a C struct to make sure data match
	local vars = { "X", "Y", "Z", "W" }
	if not cachedStructs[identifier] then
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
				str = str .. format[1] .. (format[3] == 1 and " " or vars[i]) .. (i == format[3] and ";" or ", ")
			end
			str = str .. "\n"
		end
		str = str .. "} " .. identifier .. ";"
		ffi.cdef(str)
		cachedStructs[identifier] = types
	end
	
	return identifier, cachedStructs[identifier]
end

return class