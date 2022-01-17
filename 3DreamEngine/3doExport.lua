--[[
#part of the 3DreamEngine by Luke100000
3doExport.lua - 3do file exporter
--]]

local lib = _3DreamEngine
local ffi = require("ffi")

function lib:export3do(obj)
	local meshCache = { }
	local dataStrings = { }
	
	--encode
	local data = obj:encode(meshCache, dataStrings)
	
	--save the length of each data segment
	data.dataStringsLengths = { }
	for d,s in pairs(dataStrings) do
		table.insert(data.dataStringsLengths, #s)
	end
	
	--export
	local headerData = love.data.compress("string", "lz4", packTable.pack(data), 9)
	local final = "3DO5    " .. love.data.pack("string", "L", #headerData) .. headerData .. table.concat(dataStrings, "")
	love.filesystem.createDirectory(obj.dir)
	love.filesystem.write(obj.dir .. "/" .. obj.name .. ".3do", final)
end