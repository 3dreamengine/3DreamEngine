--[[
#part of the 3DreamEngine by Luke100000
3doExport.lua - 3do file exporter
--]]

local lib = _3DreamEngine
local ffi = require("ffi")

local function copy(first_table, skip)
	local second_table = { }
	for k,v in pairs(first_table) do
		if type(v) == "table" then
			if not skip[v] then
				second_table[k] = copy(v, skip)
			end
		else
			second_table[k] = v
		end
	end
	return second_table
end

local function saveObject(obj, meshCache, dataStrings)
	local header = {
		["materials"] = obj.materials,
		["objects"] = { },
		["meshes"] = { },
		["positions"] = obj.positions,
		["lights"] = obj.lights,
		["physics"] = obj.physics,
		["reflections"] = obj.reflections,
		["args"] = obj.args,
		
		["path"] = obj.path,
		["dir"] = obj.dir,
		["name"] = obj.name,
		
		["boundingBox"] = obj.boundingBox,
		
		["transform"] = obj.transform,
		
		["animations"] = obj.animations,
		["animationLengths"] = obj.animationLengths,
		["skeleton"] = obj.skeleton,
		
		["linkedObjects"] = obj.linkedObjects,
		
		["LOD_min"] = obj.LOD_min,
		["LOD_max"] = obj.LOD_max,
		
		["visible"] = obj.visible,
	}
	
	--save objects
	for d,o in pairs(obj.objects) do
		if not o.linked then
			header.objects[d] = saveObject(o, meshCache, dataStrings)
		end
	end
	
	--save meshes
	for d,o in pairs(obj.meshes) do
		local h = {
			["name"] = o.name,
			["meshType"] = o.meshType,
			["tags"] = o.tags,
			
			["LOD_min"] = obj.LOD_min,
			["LOD_max"] = obj.LOD_max,
			
			["visible"] = o.visible,
			["renderVisibility"] = o.renderVisibility,
			["shadowVisibility"] = o.shadowVisibility,
			["farVisibility"] = o.farVisibility,
		}
		
		--save the material id if its registered or the entire material
		if o.material.library then
			h["material"] = o.material.name
		else
			h["material"] = o.material
		end
		
		--export buffer data
		h["weights"] = o.weights
		h["joints"] = o.joints
		h["jointIDs"] = o.jointIDs
		h["vertices"] = o.vertices
		h["normals"] = o.normals
		h["faces"] = o.faces
		
		header.meshes[d] = h
		
		--look for meshes
		for name, mesh in pairs(o) do
			if type(mesh) == "userdata" and mesh:typeOf("Mesh") then
				if meshCache[mesh] then
					h[name] = meshCache[mesh]
				else
					local m = { }
					meshCache[mesh] = m
					h[name] = m
					
					--store general data
					local f = mesh:getVertexFormat()
					m.vertexCount = mesh:getVertexCount()
					m.vertexFormat = f
					
					--store vertexMap
					local map = mesh:getVertexMap()
					if map then
						local vertexMapData = love.data.newByteData(m.vertexCount * 4)
						local vertexMap = ffi.cast("uint32_t*", vertexMapData:getPointer())
						for d,s in ipairs(map) do
							vertexMap[d-1] = s-1
						end
						
						--compress and store vertex map
						local c = love.data.compress("string", "lz4", vertexMapData:getString(), compressedLevel)
						table.insert(dataStrings, c)
						m.vertexMap = #dataStrings
					end
					
					--give a unique hash for the vertex format
					local md5 = love.data.hash("md5", packTable.pack(f))
					local hash = love.data.encode("string", "hex", md5)
					
					--build a C struct to make sure data match
					local str = "typedef struct {" .. "\n"
					local attrCount = 0
					local types = { }
					for _,ff in ipairs(f) do
						if ff[2] == "float" then
							str = str .. "float "
						elseif ff[2] == "byte" then
							str = str .. "unsigned char "
						else
							error("unknown data type " .. ff[2])
						end
						
						for i = 1, ff[3] do
							attrCount = attrCount + 1
							types[attrCount] = ff[2]
							str = str .. "x" .. attrCount .. (i == ff[3] and ";" or ", ")
						end
						str = str .. "\n"
					end
					str = str .. "} mesh_vertex_" .. hash .. ";"
					ffi.cdef(str)
					
					--byte data
					local byteData = love.data.newByteData(mesh:getVertexCount() * ffi.sizeof("mesh_vertex_" .. hash))
					local meshData = ffi.cast("mesh_vertex_" .. hash .. "*", byteData:getPointer())
					
					--fill data
					for i = 1, mesh:getVertexCount() do
						local v = {mesh:getVertex(i)}
						for i2 = 1, attrCount do
							meshData[i-1]["x" .. i2] = (types[i2] == "byte" and math.floor(v[i2]*255) or v[i2])
						end
					end
					
					--convert to string and store
					local c = love.data.compress("string", "lz4", byteData:getString(), compressedLevel)
					table.insert(dataStrings, c)
					m.vertices = #dataStrings
				end
			end
		end
	end
	
	return header
end

function lib:export3do(obj)
	local compressedLevel = 9
	local meshCache = { }
	local dataStrings = { }
	
	--save
	header = saveObject(obj, meshCache, dataStrings)
	
	--save the length of each data segment
	header.dataStringsLengths = { }
	for d,s in pairs(dataStrings) do
		table.insert(header.dataStringsLengths, #s)
	end
	
	--export
	local headerData = love.data.compress("string", "lz4", packTable.pack(header), compressedLevel)
	local final = "3DO5    " .. love.data.pack("string", "L", #headerData) .. headerData .. table.concat(dataStrings, "")
	love.filesystem.createDirectory(obj.dir)
	love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
end