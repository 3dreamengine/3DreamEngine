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
	
	local dataOffset = 16 + headerLength
	local compressed = compressed:sub(1, 3)
	
	obj.objects = table.load(love.data.decompress("string", compressed:sub(1, 3), headerData))
	
	--relink materials
	obj.materials = { }
	for d,s in pairs(obj.objects) do
		obj.materials[s.material.name] = s.material
	end
	
	--insert in loader
	table.insert(self.resourceLoader.jobs, obj)
	for d, o in pairs(obj.objects) do
		self.resourceLoader.channel_jobs_priority:push({"3do", #self.resourceLoader.jobs, d, path, dataOffset + o.meshDataIndex, o.meshDataSize, compressed})
	end
end