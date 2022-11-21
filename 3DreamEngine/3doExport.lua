--[[
#part of the 3DreamEngine by Luke100000
3doExport.lua - 3do file exporter
--]]

local lib = _3DreamEngine

function lib:export3do(obj)
	local meshCache = { }
	local dataStrings = { }
	
	--encode
	local data = obj:encode(meshCache, dataStrings)
	
	--save the length of each data segment
	data.dataStringsLengths = { }
	for _, s in pairs(dataStrings) do
		table.insert(data.dataStringsLengths, #s)
	end
	
	--export
	local headerData = love.data.compress("string", "lz4", lib.packTable.pack(data), 9)
	local headerLength = #headerData
	local l1 = math.floor(headerLength) % 256
	local l2 = math.floor(headerLength / 256) % 256
	local l3 = math.floor(headerLength / 256 ^ 2) % 256
	local l4 = math.floor(headerLength / 256 ^ 3) % 256
	local final = "3DO" .. lib.version_3DO .. "    " .. string.char(l1, l2, l3, l4) .. headerData .. table.concat(dataStrings, "")
	love.filesystem.createDirectory(obj.dir)
	love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
end