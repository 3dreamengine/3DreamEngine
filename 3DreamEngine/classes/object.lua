local lib = _3DreamEngine

function lib:newLinkedObject(original, source)
	return setmetatable({
		linked = source
	}, {__index = original})
end

function lib:newObject(path)
	--get name and dir
	path = path or "unknown"
	local n = string.split(path, "/")
	local name = n[#n] or path
	local dir = #n > 1 and table.concat(n, "/", 1, #n-1) or ""
	
	return setmetatable({
		materials = {
			None = self:newMaterial()
		},
		objects = { },
		meshes = { },
		positions = { },
		lights = { },
		physics = { },
		reflections = { },
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
	
	updateBoundingBox = function(self)
		for d,s in pairs(self.meshes) do
			if not s.boundingBox.initialized then
				s:updateBoundingBox()
			end
		end
		
		for d,s in pairs(self.objects) do
			if not s.boundingBox.initialized then
				s:updateBoundingBox()
			end
		end
		
		--calculate total bounding box
		self.boundingBox = lib:newBoundaryBox(true)
		for d,s in pairs(self.objects) do
			local sz = vec3(s.boundingBox.size, s.boundingBox.size, s.boundingBox.size)
			
			self.boundingBox.first = s.boundingBox.first:min(self.boundingBox.first - sz)
			self.boundingBox.second = s.boundingBox.second:max(self.boundingBox.second + sz)
			self.boundingBox.center = (self.boundingBox.second + self.boundingBox.first) / 2
		end
		
		for d,s in pairs(self.objects) do
			local o = s.boundingBox.center - self.boundingBox.center
			self.boundingBox.size = math.max(self.boundingBox.size, s.boundingBox.size + o:lengthSquared())
		end
	end,
	
	initShaders = function(self)
		for d,s in pairs(self.objects) do
			s:initShaders()
		end
	end,
	
	cleanup = function(self)
		for d,s in pairs(self.objects) do
			s:cleanup(s)
		end
	end,
	
	preload = function(self, force)
		--preload meshes
		for d,s in pairs(self.objects) do
			s:preload(force)
		end
	end,
	
	copySkeleton = function(self, o)
		assert(o.skeleton, "skeleton does not exist")
		self.sekelton = o.skeleton
	end,
	
	copyAnimations = function(self, o)
		assert(o.animations, "animation does not exist")
		self.animations = o.animations
		self.animationLengths = o.animationLengths
	end,
	
	generatePhysics = function(self)
		self.physics = { }
		for d,s in pairs(self.objects) do
			self.physics[d] = lib:getPhysicsData(s)
		end
	end,
	
	print = function(self, tabs)
		tabs = tabs or 0
		local indent = string.rep("  ", tabs + 1)
		local indent2 = string.rep("  ", tabs + 2)
		
		--general innformation
		print(string.rep("  ", tabs) .. self.name)
		
		--print objects
		local width = 32
		if next(self.meshes) then
			print(indent .. "meshes")
			print(indent2 .. "name " .. string.rep(" ", width-9) .. "tags LOD     R S  vertexcount")
		end
		
		--group together similar meshes
		local found = { }
		for _,m in pairs(self.meshes) do
			--to array
			local tags = { }
			for d,s in pairs(m.tags) do
				table.insert(tags, tostring(d))
			end
			
			--data to display
			local tags = table.concat(tags, ", "):sub(1, width)
			local min, max = m:getLOD()
			local lod = max and (min .. " - " .. max) or ""
			local visibility = (m.renderVisibility ~= false and "X" or " ") .. " " .. (m.shadowVisibility ~= false and "X" or " ")
			
			--final string
			local vertexCount = (m.mesh and m.mesh.getVertexCount and m.mesh:getVertexCount() or "")
			local str = m.name .. string.rep(" ", width - #tags - #m.name) .. tags .. lod .. string.rep(" ", 8 - #lod) .. visibility .. "  " .. vertexCount
			
			--merge meshes
			print(indent2 .. str)
		end
		
		--physics
		if next(self.physics) then
			print(indent .. "physics")
			local count = { }
			for d,s in pairs(self.physics or { }) do
				print(indent2 .. tostring(s.name))
			end
		end
		
		--lights
		if next(self.lights) then
			print(indent .. "lights")
			for d,s in pairs(self.lights) do
				print(indent2 .. tostring(s.name) .. "  " .. s.brightness)
			end
		end
		
		--positions
		if next(self.positions) then
			print(indent .. "positions")
			for d,s in pairs(self.positions) do
				print(indent2 .. tostring(s.name) .. string.format("  %f, %f, %f", s.x, s.y, s.z))
			end
		end
		
		--print objects
		if next(self.objects) then
			print(indent .. "objects")
			for _,o in pairs(self.objects) do
				o:print(tabs + 2)
			end
		end
	end
}