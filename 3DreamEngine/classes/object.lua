local lib = _3DreamEngine

function lib:newObject(path)
	--get name and dir
	path = path or "unknown"
	local n = self:split(path, "/")
	local name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	return setmetatable({
		materials = {
			None = self:newMaterial()
		},
		objects = { },
		positions = { },
		lights = { },
		args = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		loaded = true,
	}, self.meta.object)
end

return {
	link = {"clone", "transform", "shader", "visibility", "object"},
	
	isLoaded = function(self)
		for d,s in pairs(self.objects) do
			if not s:isLoaded() then
				return false
			end
		end
		return true
	end,
	
	request = function(self)
		for d,s in pairs(self.objects) do
			s:request()
		end
	end,
	
	wait = function(self)
		while not self:isLoaded() do
			local worked = lib:update()
			if not worked then
				love.timer.sleep(10/1000)
			end
		end
	end,
	
	tostring = function(self)
		local function count(t)
			local c = 0
			for d,s in pairs(t) do
				c = c + 1
			end
			return c
		end
		return string.format("%s: %d objects, %d collisions, %d physics, %d lights", self.name, count(self.objects), count(self.collisions or { }), count(self.physics or { }), count(self.lights))
	end,
	
	withName = function(self, name)
		local o = { }
		for d,s in pairs(self.objects) do
			if s.name == name then
				o[d] = s
			end
		end
		return o
	end,
	
	print = function(self)
		--general innformation
		print(self)
		
		--group objects by their name
		print("objects")
		local groups = { }
		local hash = { }
		for d,s in pairs(self.objects) do
			if not hash[s.name] then
				hash[s.name] = true
				groups[#groups+1] = s.name
			end
		end
		table.sort(groups)
		
		--print objects
		for _,group in ipairs(groups) do
			--header
			print("  " .. group)
			local width = 32
			print("       # tags" .. string.rep(" ", width-4) .. "LOD     D S R  Vertexcount")
			
			--group together materials and particle meshes
			local found = { }
			local count = { }
			local vertices = { }
			for d,s in pairs(self.objects) do
				if s.name == group then
					local n = s.group or d
					if not count[n] then
						found[#found+1] = {d, n}
					end
					count[n] = (count[n] or 0) + 1
					if s.mesh then
						vertices[n] = (vertices[n] or 0) + s.mesh:getVertexCount()
					end
				end
			end
			
			for _,d in ipairs(found) do
				local s = self.objects[d[1]]
				local tags = { }
				for d,s in pairs(s.tags) do
					tags[#tags+1] = d
				end
				
				if s.linked then
					table.insert(tags, 1, "L")
				end
				
				local tags = table.concat(tags, ", "):sub(1, width)
				local min, max = s:getLOD()
				local lod = max and (min .. " - " .. max) or ""
				local a, b, c = s:getVisibility()
				local visibility = (a and "X" or " ") .. " " .. (b and "X" or " ") .. " " .. (c and "X" or " ")
				
				print(string.format("     % 3d %s%s%s%s%s %d", count[d[2]], tags, string.rep(" ", width - #tags), lod, string.rep(" ", 8 - #lod), visibility, vertices[d[2]] or 0))
			end
		end
		
		--collisions
		print("collisions")
		local count = { }
		for d,s in pairs(self.collisions or { }) do
			count[s.name] = (count[s.name] or 0) + 1
		end
		for d,s in pairs(count) do
			print("", s, d)
		end
		
		--physics
		print("physics")
		local count = { }
		for d,s in pairs(self.physics or { }) do
			count[s.name] = (count[s.name] or 0) + 1
		end
		for d,s in pairs(count) do
			print("", s, d)
		end
		
		--physics
		print("lights")
		for d,s in pairs(self.lights) do
			print("", s.name, s.brightness)
		end
	end
}