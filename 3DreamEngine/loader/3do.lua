--[[
#3do - 3Dream Object file (3DreamEngine specific)
blazing fast mesh loading using pre-calculated meshes and multi-threading
--]]

return function(self, obj, path)
	--load header
	local file = love.filesystem.newFile(path, "r")
	local typ = file:read(4)
	
	--check if up to date
	if typ ~= "3DO" .. self.version_3DO then
		print("3DO file " .. path .. " seems to be outdated and will be skipped")
		file:close()
		return true
	end
	
	--unused 4 bytes
	local _ = file:read(4)
	
	--header
	local l1, l2, l3, l4 = string.byte(file:read(4), 1, 4)
	local headerLength = l1 + l2 * 256 + l3 * 256^2 + l4 * 256^3
	local headerData = file:read(headerLength)
	
	--object lua data
	local header = self.packTable.unpack(love.data.decompress("string", "lz4", headerData))
	table.merge(obj, header)
	
	--additional mesh data
	local meshData = { }
	if obj.dataStringsLengths then
		for d,s in ipairs(obj.dataStringsLengths) do
			local dat = love.data.decompress("string", "lz4", file:read(s))
			meshData[d] = love.data.newByteData(dat)
		end
	end
	obj.dataStringsLengths = nil
	
	--mesh creation and 3DO exporting makes no longer sense
	obj.args.particleSystems = false
	obj.args.export3do = false
	for _,s in pairs(obj.objects) do
		s.args.particleSystems = false
		s.args.export3do = false
	end
	
	obj:decode(meshData)
	
	file:close()
end