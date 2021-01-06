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
		groups = { },
		positions = { },
		lights = { },
		physics = { },
		args = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		boundingBox = self:newBoundaryBox(),
		
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
		return string.format("%s: %d objects, %d physics, %d lights", self.name, count(self.objects), count(self.physics or { }), count(self.lights))
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
	
	updateGroups = function(self)
		self.groups = { }
		for d,o in pairs(self.objects) do
			if not self.groups[o.name] then
				self.groups[o.name] = lib:newGroup()
				self.groups[o.name].transform = o.transform
				self.groups[o.name].linked = o.linked
			end
			self.groups[o.name]:add(o)
		end
		
		for d,s in ipairs(self.groups) do
			s:updateBoundingBox()
		end
	end,
	
	print = function(self)
		--general innformation
		print(self)
		
		--print objects
		for name,group in pairs(self.groups) do
			--header
			print("  " .. name)
			local width = 32
			print("       # tags" .. string.rep(" ", width-4) .. "LOD     D S R  Vertexcount")
			
			--group together similar objects
			local found = { }
			for _,s in ipairs(group.objects) do
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
				
				local str = string.format("%s%s%s%s%s", tags, string.rep(" ", width - #tags), lod, string.rep(" ", 8 - #lod), visibility)
				found[str] = found[str] or {0, 0}
				found[str][1] = found[str][1] + 1
				found[str][2] = found[str][2] + (s.mesh and s.mesh:getVertexCount() or 0)
			end
			
			for str, count in pairs(found) do
				print(string.format("     % 3d %s %d", count[1], str, count[2]))
			end
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