--[[
#3do - 3Dream Object file (3DreamEngine specific)
blazing fast mesh loading using pre-calculated meshes and multi-threading
--]]

_3DreamEngine.loader["3do"] = function(self, obj, path)
	--load header
	local file = love.filesystem.newFile(path, "r")
	local typ = file:read(4)
	local compressed = file:read(4)
	local headerLength = file:read(8)
	local headerData = file:read(tonumber(headerLength))
	
	obj.loaded = false
	
	obj.dataOffset = 16 + headerLength
	obj.compressed = compressed:sub(1, 3)
	
	obj.objects = table.load(love.data.decompress("string", compressed:sub(1, 3), headerData))
	
	table.insert(self.resourceLoader.jobs, obj)
end