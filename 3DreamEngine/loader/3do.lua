--[[
#3do - 3Dream Object file (3DreamEngine specific)
blazing fast mesh loading using pre-calculated meshes and multi-threading
--]]

return function(self, obj, path)
	--load header
	local file = love.filesystem.newFile(path, "r")
	local typ = file:read(4)
	
	--check if up to date
	if typ ~= "3DO1" then
		print("3DO file " .. path .. " seems to be outdated and will be skipped")
		return true
	end
	
	do
		print("3DOs are currently disabled until compatibility has been restored")
		return true
	end
	
	local compressed = file:read(4)
	local headerLength = file:read(8)
	local headerData = file:read(tonumber(headerLength))
	
	local dataOffset = 16 + headerLength
	local compressed = compressed:sub(1, 3)
	
	obj.objects = table.load(love.data.decompress("string", compressed:sub(1, 3), headerData))
	
	--relink materials
	for d,s in pairs(obj.objects) do
		s.material = obj.materials[s.material] or self.materialLibrary[s.material]
	end
	
	--insert in loader
	table.insert(self.jobs, obj)
	for d, o in pairs(obj.objects) do
		self.channel_jobs_priority:push({"3do", #self.jobs, d, path, dataOffset + o.meshDataIndex, o.meshDataSize, compressed})
	end
end