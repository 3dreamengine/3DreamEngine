---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---Creates a new mesh format
---@param vertexFormat table @ A vertex format as specified in https://love2d.org/wiki/love.graphics.newMesh
---@return DreamMeshFormat
function lib:newMeshFormat(vertexFormat)
	local f = {
		vertexFormat = vertexFormat,
		attributes = { }
	}
	
	for _, format in ipairs(vertexFormat) do
		f.attributes[format[1]] = true
	end
	
	return setmetatable(f, self.meta.meshFormat)
end

---Mesh formats contain the code required to populate the final render-able mesh and should overwrite the `create` methods. Use cases for custom mesh formats are additional attributes. Special shaders are required to make use of custom mesh formats. See https://github.com/3dreamengine/3DreamEngine/tree/master/3DreamEngine/meshFormats for inbuilt formats.
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
	local md5 = love.data.hash("md5", lib.packTable.pack(self.vertexFormat))
	local identifier = "mesh_vertex_" .. love.data.encode("string", "hex", md5)
	
	--build a C struct to make sure data match
	local vars = { "X", "Y", "Z", "W" }
	if not cachedStructs[identifier] then
		local types = { }
		local str = "typedef struct {" .. "\n"
		for _, format in ipairs(self.vertexFormat) do
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