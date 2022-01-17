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
		animations = { },
		args = { },
		
		path = path, --absolute path to object
		name = name, --name of object
		dir = dir, --dir containing the object
		
		boundingBox = self:newBoundaryBox(),
		
		loaded = true,
	}, self.meta.object)
end

local class = {
	link = {"clone", "transform", "shader", "visibility", "object"},
}
 
function class:tostring()
	local function count(t)
		local c = 0
		for d,s in pairs(t) do
			c = c + 1
		end
		return c
	end
	return string.format("%s: %d objects, %d meshes, %d physics, %d lights", self.name, count(self.objects), count(self.meshes), count(self.physics or { }), count(self.lights))
end

function class:updateBoundingBox()
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
end

function class:initShaders()
	for d,s in pairs(self.objects) do
		s:initShaders()
	end
end

function class:cleanup()
	for d,s in pairs(self.objects) do
		s:cleanup(s)
	end
end

function class:preload(force)
	for d,s in pairs(self.objects) do
		s:preload(force)
	end
	for d,s in pairs(self.meshes) do
		s:preload(force)
	end
end

function class:copySkeleton(o)
	assert(o.skeleton, "object has no skeletons")
	self.sekelton = o.skeleton
end

function class:meshesToPhysics()
	for id,mesh in pairs(self.meshes) do
		for idx,m in ipairs(lib:separateMesh(mesh)) do
			self.physics[id .. "_" .. idx] = lib:getPhysicsData(m)
		end
	end
	self.meshes = { }
end

--create and apply pose (wrapper)
function class:setPose(animation, time)
	assert(self.skeleton, "object requires a skeleton")
	local p = self:getPose(animation, time)
	self:applyPose(p)
end

--apply the pose to the skeleton (wrapper)
function class:applyPose(pose)
	assert(self.skeleton, "object requires a skeleton")
	self.skeleton:applyPose(pose)
end

--apply joints to mesh data directly
function class:applyBones(skeleton)
	for _,m in pairs(self.meshes) do
		m:applyBones(self.skeleton or skeleton)
	end
	
	--also apply to children
	for _,o in pairs(self.objects) do
		o:applyBones(self.skeleton or skeleton)
	end
end

local tree = { }

local function printf(str, ...)
	table.insert(tree, {text = string.format(tostring(str), ...)})
end

local function push(str, ...)
	printf(str, ...)
	tree[#tree].children = {parent = tree}
	tree = tree[#tree].children
end

local function pop()
	tree = tree.parent
end

local function printNode(node, tabs)
	tabs = tabs or ""
	for d,s in ipairs(node) do
		print(tabs .. (d == #node and "└─" or "├─") .. s.text)
		
		if s.children then
			printNode(s.children, tabs .. (d == #node and "  " or "│ "))
		end
	end
	tree = { }
end

function class:print()
	local width = 48
	
	--general innformation
	if self.linked then
		push(self.name .. " (linked)")
	else
		push(self.name)
	end
	
	if self.linked then
		pop()
		return
	end
	
	--print objects
	if next(self.meshes) then
		push("meshes")
		for _,m in pairs(self.meshes) do
			printf(m)
		end
		pop()
	end
	
	--physics
	if next(self.physics) then
		push("physics")
		for d,s in pairs(self.physics or { }) do
			printf("%s", s.name)
		end
		pop()
	end
	
	--lights
	if next(self.lights) then
		push("lights")
		for _,l in pairs(self.lights) do
			printf(l)
		end
		pop()
	end
	
	--positions
	if next(self.positions) then
		push("positions")
		for _,p in pairs(self.positions) do
			printf("%s at (%.3f, %.3f, %.3f)", p.name, p.x, p.y, p.z)
		end
		pop()
	end
	
	--skeleton
	if self.skeleton then
		local function p(s)
			for i,v in pairs(s) do
				push(v.name)
				if v.children then
					p(v.children)
				end
				pop()
			end
		end
		push("skeleton")
		p(self.skeleton.bones)
		pop()
	end
	
	--animations
	if next(self.animations) then
		push("animations")
		for d,s in pairs(self.animations) do
			printf("%s: %.1f sec", d, s.length)
		end
		pop()
	end
	
	--print objects
	if next(self.objects) then
		push("objects")
		for _,o in pairs(self.objects) do
			o:print()
		end
		pop()
	end
	
	pop()
	
	--print result
	if not tree.parent then
		printNode(tree)
		tree = { }
	end
end

--create meshes
function class:createMeshes()
	if not self.linked then
		for d,o in pairs(self.meshes) do
			o:create()
		end
		
		for d,o in pairs(self.objects) do
			o:createMeshes()
		end
	end
end

return class