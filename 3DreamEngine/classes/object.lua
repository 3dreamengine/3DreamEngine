local lib = _3DreamEngine

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

function lib:newLinkedObject(original, source)
	return setmetatable({
		linked = source
	}, {__index = original})
end

function lib:newObject(name)
	return setmetatable({
		objects = { },
		meshes = { },
		positions = { },
		lights = { },
		physics = { },
		reflections = { },
		animations = { },
		args = { },
		
		name = name,
		
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
	for d,s in pairs(self.meshes) do
		s:initShaders()
	end
end

function class:cleanup()
	for d,s in pairs(self.objects) do
		s:cleanup(s)
	end
	for d,s in pairs(self.meshes) do
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
			printf("%s at %s", p.name, p.position)
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
			if not o.mesh then
				o:create()
			end
		end
		
		for d,o in pairs(self.objects) do
			o:createMeshes()
		end
	end
end

function class:encode(meshCache, dataStrings)
	local data = {
		["objects"] = { },
		["meshes"] = { },
		["positions"] = self.positions,
		["lights"] = self.lights,
		["physics"] = self.physics,
		["reflections"] = self.reflections,
		["args"] = self.args,
		
		["name"] = self.name,
		
		["boundingBox"] = self.boundingBox,
		
		["transform"] = self.transform,
		
		["animations"] = self.animations,
		["skeleton"] = self.skeleton,
		
		["linkedObjects"] = self.linkedObjects,
		
		["LOD_min"] = self.LOD_min,
		["LOD_max"] = self.LOD_max,
	}

	--save objects
	for d,o in pairs(self.objects) do
		if not o.linked then
			data.objects[d] = o:encode(meshCache, dataStrings)
		end
	end

	--encode everything else
	for _,v in ipairs({"meshes"}) do
		data[v] = { }
		for d,s in pairs(self[v]) do
			data[v][d] = s:encode(meshCache, dataStrings)
		end
	end

	return data
end

function class:decode(meshData)
	--recreate transform
	if self.transform then
		self.transform = mat4(self.transform)
	end
	
	--recreate vecs and mats
	lib:decodeBoundaryBox(self.boundingBox)
	
	--recreate objects
	for d,s in pairs(self.objects) do
		self.objects[d] = table.merge(lib:newObject(s.name), s)
		self.objects[d]:decode(meshData)
	end
	
	--decode meshes
	for d,s in pairs(self.meshes) do
		setmetatable(s, lib.meta.mesh)
		s:decode(meshData)
	end
	
	--recreate linked data
	if self.linkedObjects then
		for _,s in ipairs(self.linkedObjects) do
			if s.transform then
				s.transform = mat4(s.transform)
			end
		end
	end
	
	--recreate lights
	for d,s in pairs(self.lights) do
		setmetatable(s, lib.meta.light)
		s:decode()
	end
	
	--decode reflections
	for d,s in pairs(self.reflections) do
		setmetatable(s, lib.meta.reflection)
		s:decode()
	end
	
	--recreate skeleton data
	if self.skeleton then
		self.skeleton = lib:newSkeleton(self.skeleton.bones)
	end
	
	--decode animations
	for d,s in pairs(self.animations) do
		setmetatable(s, lib.meta.animation)
		s:decode()
	end
	
	--decode physics
	for d,s in pairs(self.physics) do
		setmetatable(s, lib.meta.collider)
		s:decode()
	end
	
	--recreate positions
	for d,s in pairs(self.positions) do
		s.position = vec3(s.position)
	end
end

return class