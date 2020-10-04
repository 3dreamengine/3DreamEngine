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
	do
		print("3DO export WIP")
		return
	end
	local compressed = "lz4"
	local compressedLevel = 9
	local meshHeaderData = { }
	local meshDataStrings = { }
	local meshDataIndex = 0
	for d,o in pairs(obj.objects) do
		if o.mesh then
			local f = o.mesh:getVertexFormat()
			meshHeaderData[d] = copy(o, {[o.material or false] = true, [o.final or false] = true, [o.faces or false] = true, [o.mesh or false] = true})
			
			meshHeaderData[d].vertexCount = o.mesh:getVertexCount()
			meshHeaderData[d].vertexMap = o.mesh:getVertexMap()
			meshHeaderData[d].vertexFormat = f
			meshHeaderData[d].material = o.material.name
			
			local hash = love.data.encode("string", "hex", love.data.hash("md5", table.save(f)))
			local str = "typedef struct {" .. "\n"
			local count = 0
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
					count = count + 1
					types[count] = ff[2]
					str = str .. "x" .. count .. (i == ff[3] and ";" or ", ")
				end
				str = str .. "\n"
			end
			str = str .. "} mesh_vertex_" .. hash .. ";"
			--print(str)
			
			--byte data
			self.ffi.cdef(str)
			local byteData = love.data.newByteData(o.mesh:getVertexCount() * self.ffi.sizeof("mesh_vertex_" .. hash))
			local meshData = self.ffi.cast("mesh_vertex_" .. hash .. "*", byteData:getPointer())
			
			--fill data
			for i = 1, o.mesh:getVertexCount() do
				local v = {o.mesh:getVertex(i)}
				for i2 = 1, count do
					meshData[i-1]["x" .. i2] = (types[i2] == "byte" and math.floor(v[i2]*255) or v[i2])
				end
			end
			
			--convert to string and store
			meshDataStrings[#meshDataStrings+1] = love.data.compress("string", compressed, byteData:getString(), compressedLevel)
			meshHeaderData[d].meshDataIndex = meshDataIndex
			meshHeaderData[d].meshDataSize = #meshDataStrings[#meshDataStrings]
			meshDataIndex = meshDataIndex + meshHeaderData[d].meshDataSize
		end
	end
	
	--export
	local headerData = love.data.compress("string", compressed, table.save(meshHeaderData), compressedLevel)
	local final = "3DO1" .. compressed .. " " .. string.format("%08d", #headerData) .. headerData .. table.concat(meshDataStrings, "")
	love.filesystem.createDirectory(obj.dir)
	love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
end