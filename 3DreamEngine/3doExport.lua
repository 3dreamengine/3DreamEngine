--[[
#part of the 3DreamEngine by Luke100000
3doExport.lua - 3do file exporter
--]]

local lib = _3DreamEngine

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

function lib:export3do(obj)
	local compressed = "lz4"
	local compressedLevel = 9
	local dataStrings = { }
	local dataIndex = 0
	local meshCache = { }
	
	local header = {
		["args"] = obj.args,
		["path"] = obj.path,
		["dir"] = obj.dir,
		["name"] = obj.name,
		["boundingBox"] = obj.boundingBox,
		["materials"] = obj.materials,
		["lights"] = obj.lights,
		["positions"] = obj.positions,
		["transform"] = obj.transform,
		["collisions"] = obj.collisions,
		["animations"] = obj.animations,
		["animationLengths"] = obj.animationLengths,
		["joints"] = obj.joints,
		["skeleton"] = obj.skeleton,
		["linked"] = obj.linked,
		["objects"] = { },
	}
	
	for d,o in pairs(obj.objects) do
		local h = {
			["name"] = o.name,
			["shaderType"] = o.shaderType,
			["meshType"] = o.meshType,
			["material"] = o.material.name,
			["boundingBox"] = table.copyPrimitive(o.boundingBox),
			["transform"] = o.transform,
			["joints"] = o.joints,
			["linked"] = o.linked,
		}
		
		--additional data
		if not o.linked then
			h["weights"] = o.weights
			h["jointIDs"] = o.jointIDs
		end
		
		--extended data
		if obj.args.export3doVertices and not o.linked then
			h["vertices"] = o.vertices
			h["edges"] = o.edges
			h["faces"] = o.faces
		end
		
		header.objects[d] = h
		
		if o.mesh and not o.linked then
			if meshCache[o.mesh] then
				h.vertexCount = meshCache[o.mesh].vertexCount
				h.vertexMap = meshCache[o.mesh].vertexMap
				h.vertexFormat = meshCache[o.mesh].vertexFormat
				h.meshDataIndex = meshCache[o.mesh].meshDataIndex
				h.meshDataSize = meshCache[o.mesh].meshDataSize
			else
				meshCache[o.mesh] = h
				local f = o.mesh:getVertexFormat()
				h.vertexCount = o.mesh:getVertexCount()
				h.vertexMap = o.mesh:getVertexMap()
				h.vertexFormat = f
				
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
				self.ffi.cdef(str)
				
				--byte data
				local byteData = love.data.newByteData(o.mesh:getVertexCount() * self.ffi.sizeof("mesh_vertex_" .. hash))
				local meshData = self.ffi.cast("mesh_vertex_" .. hash .. "*", byteData:getPointer())
				
				--fill data
				for i = 1, o.mesh:getVertexCount() do
					local v = {o.mesh:getVertex(i)}
					for i2 = 1, attrCount do
						meshData[i-1]["x" .. i2] = (types[i2] == "byte" and math.floor(v[i2]*255) or v[i2])
					end
				end
				
				--convert to string and store
				local c = love.data.compress("string", compressed, byteData:getString(), compressedLevel)
				dataStrings[#dataStrings+1] = c
				h.meshDataIndex = dataIndex
				h.meshDataSize = #c
				dataIndex = dataIndex + h.meshDataSize
			end
		end
	end
	
	--export
	local headerData = love.data.compress("string", compressed, packTable.pack(header), compressedLevel)
	local final = "3DO2" .. compressed .. " " .. love.data.pack("string", "J", #headerData) .. headerData .. table.concat(dataStrings, "")
	love.filesystem.createDirectory(obj.dir)
	love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
end