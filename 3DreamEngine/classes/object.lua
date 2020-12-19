local lib = _3DreamEngine

function lib:newObject(path)
	--get name and dir
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
		return string.format("%s: %d objects, %d collisions, %d physics, %d lights", self.name, count(self.objects), count(self.collisions), count(self.physics), count(self.lights))
	end,
	
	print = function(self)
		print(self)
		
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
		
		for _,group in ipairs(groups) do
			print("  " .. group)
			local width = 32
			print("      #m tags" .. string.rep(" ", width-4) .. "LOD     D S R")
			
			local found = { }
			local hash = { }
			for d,s in pairs(self.objects) do
				if s.name == group then
					local n = s.materialGroup or d
					if not hash[n] then
						found[#found+1] = {d, n}
					end
					hash[n] = (hash[n] or 0) + 1
				end
			end
			
			for _,d in ipairs(found) do
				local s = self.objects[d[1]]
				local tags = { }
				for d,s in pairs(s.tags) do
					tags[#tags+1] = d
				end
				
				local tags = table.concat(tags, ", "):sub(1, width)
				local min, max = s:getLOD()
				local lod = max and (min .. " - " .. max) or ""
				local a, b, c = s:getVisibility()
				print("    " .. string.format("% 3d ", hash[d[2]]) .. tags .. string.rep(" ", width - #tags) .. lod .. string.rep(" ", 8 - #lod) .. (a and "X" or " ") .. " " .. (b and "X" or " ") .. " " .. (c and "X" or " "))
			end
		end
	end
}