local lib = _3DreamEngine

---@return DreamObject | DreamClonable | DreamTransformable | DreamHasShaders
function lib:newLinkedObject(original, source)
	return setmetatable({
		linked = source
	}, { __index = original })
end

---@return DreamObject | DreamClonable | DreamTransformable | DreamHasShaders
function lib:newObject(name)
	return setmetatable({
		objects = { },
		meshes = { },
		collisionMeshes = { },
		raytraceMeshes = { },
		positions = { },
		lights = { },
		reflections = { },
		animations = { },
		links = { },
		args = { },
		tags = { },
		
		name = name,
		
		mainSkeleton = false,
		
		boundingBox = self:newEmptyBoundingBox(),
		
		loaded = true,
	}, self.meta.object)
end

---@class DreamObject
---@field objects DreamObject[]
---@field meshes DreamMesh[]
---@field positions DreamPosition[]
---@field lights DreamLight[]
---@field collisionMeshes DreamCollisionMesh[]
---@field raytraceMeshes DreamRaytraceMesh[]
---@field reflections DreamReflection[]
---@field animations DreamAnimation[]
local class = {
	links = { "clone", "transform", "shader", "object" },
}

local function count(t)
	local c = 0
	for _, _ in pairs(t) do
		c = c + 1
	end
	return c
end

local function copy(t)
	local n = { }
	for d, s in pairs(t) do
		if type(s) == "table" and type(s.clone) == "function" then
			n[d] = s:clone()
		else
			n[d] = s
		end
	end
	return setmetatable(n, getmetatable(t))
end

function class:newInstance()
	return setmetatable({}, { __index = self })
end

function class:clone()
	local n = copy(self)
	for _, key in ipairs({ "objects", "meshes" }) do
		self[key] = copy(self[key])
	end
	return setmetatable(n, getmetatable(self))
end

---The main skeleton is usually the one used by all meshes, but may be nil or unused
---@return DreamSkeleton
function class:getMainSkeleton()
	return self.mainSkeleton
end

---Range in which this object should be rendered
---@param min number
---@param max number
function class:setLOD(min, max)
	self.LOD_min = min
	self.LOD_max = max
end

function class:getLOD()
	return self.LOD_min, self.LOD_max
end

function class:updateBoundingBox()
	for _, s in pairs(self.meshes) do
		if not s.boundingBox.initialized then
			s:updateBoundingBox()
		end
	end
	
	for _, s in pairs(self.objects) do
		if not s.boundingBox.initialized then
			s:updateBoundingBox()
		end
	end
	
	--calculate total bounding box
	self.boundingBox = lib:newEmptyBoundingBox()
	self.boundingBox:setInitialized(true)
	for _, s in pairs(self.objects) do
		local sz = vec3(s.boundingBox.size, s.boundingBox.size, s.boundingBox.size)
		
		self.boundingBox.first = s.boundingBox.first:min(self.boundingBox.first - sz)
		self.boundingBox.second = s.boundingBox.second:max(self.boundingBox.second + sz)
		self.boundingBox.center = (self.boundingBox.second + self.boundingBox.first) / 2
	end
	
	for _, s in pairs(self.objects) do
		local o = s.boundingBox.center - self.boundingBox.center
		self.boundingBox.size = math.max(self.boundingBox.size, s.boundingBox.size + o:lengthSquared())
	end
end

function class:clearMeshes()
	for _, s in pairs(self.objects) do
		s:clearMeshes(s)
	end
	for _, s in pairs(self.meshes) do
		s:clearMesh(s)
	end
end

function class:cleanup()
	for _, s in pairs(self.objects) do
		s:cleanup(s)
	end
	for _, s in pairs(self.meshes) do
		s:cleanup(s)
	end
end

function class:preload(force)
	for _, s in pairs(self.objects) do
		s:preload(force)
	end
	for _, s in pairs(self.meshes) do
		s:preload(force)
	end
end

---Converts all meshes to physics meshes
function class:meshesToCollisionMeshes()
	for id, mesh in pairs(self.meshes) do
		for idx, m in ipairs(mesh:separate()) do
			self.collisionMeshes[id .. "_" .. idx] = lib:getPhysicsData(m)
		end
	end
	self.meshes = { }
end

local function getAllMeshes(object, list)
	if not object.LOD_max or object.LOD_max >= math.huge then
		for _, o in pairs(object.objects) do
			getAllMeshes(o, list)
		end
		for _, m in pairs(object.meshes) do
			if m.vertices then
				table.insert(list, m)
			end
		end
	end
end

---Get all child meshes, recursively
function class:getAllMeshes()
	local list = { }
	getAllMeshes(self, list)
	return list
end

---Merge all meshes, recursively, of an object and concatenate all buffer together
--It uses a material of one random mesh and therefore requires only identical materials
--It returns a new object with only one mesh named merged
function class:merge()
	--apply the current transform
	local appliedSource = self:clone()
	appliedSource:applyTransform()
	
	--get valid meshes
	local meshes = appliedSource:getAllMeshes()
	local sourceMesh = meshes[next(meshes)]
	local mesh = lib:newMesh("merged", sourceMesh.material)
	
	assert(sourceMesh.vertices, "At least the vertex buffer is required.")
	
	--look for the max size
	local size = 0
	local faces = 0
	for _, source in pairs(meshes) do
		size = size + source.vertices:getSize()
		faces = faces + source.faces:getSize()
	end
	
	--check which buffers are necessary
	local found = { }
	for name, buffer in pairs(sourceMesh) do
		if type(buffer) == "table" and (buffer.class == "buffer" or buffer.class == "dynamicBuffer") then
			if name ~= "faces" then
				table.insert(found, name)
				mesh[name] = lib:newBuffer(buffer:getType(), buffer:getDataType(), size)
			end
		end
	end
	
	--merge buffers
	local startIndices = { }
	local index = 0
	for d, source in ipairs(meshes) do
		startIndices[d] = index
		
		for _, name in ipairs(found) do
			mesh[name]:copyFrom(source[name], index)
		end
		
		index = index + source.vertices:getSize()
	end
	
	--merge faces
	mesh.faces = lib:newBuffer("vec3", "float", faces)
	local faceId = 0
	for d, m in ipairs(meshes) do
		local i = startIndices[d]
		for _, face in m.faces:ipairs() do
			faceId = faceId + 1
			mesh.faces:set(faceId, { face.x + i, face.y + i, face.z + i })
		end
	end
	
	local final = lib:newObject(self.name)
	
	final.meshes = { merged = mesh }
	
	--todo the bounding box should remain unchanged?
	local t = love.timer.getTime()
	final:updateBoundingBox()
	print(love.timer.getTime() - t, "bb")
	
	return final
end

---Apply the current transformation to the meshes
function class:applyTransform()
	for _, o in pairs(self.objects) do
		o:setTransform(self:getTransform() * o:getTransform())
		o:applyTransform()
	end
	for _, mesh in pairs(self.meshes) do
		mesh:applyTransform(self:getTransform())
	end
	self:resetTransform()
end

---Apply joints to mesh data directly
---@param skeleton DreamSkeleton @ optional
function class:applyBones(skeleton)
	for _, m in pairs(self.meshes) do
		m:applyBones(skeleton)
	end
	
	--also apply to children
	for _, o in pairs(self.objects) do
		o:applyBones(skeleton)
	end
end

---Create all render-able meshes
function class:createMeshes()
	if not self.linked then
		for _, mesh in pairs(self.meshes) do
			mesh:getMesh()
		end
		
		for _, o in pairs(self.objects) do
			o:createMeshes()
		end
	end
end

---@param visibility boolean
function class:setVisible(visibility)
	self:setRenderVisibility(visibility)
	self:setShadowVisibility(visibility)
end

---@param visibility boolean
function class:setRenderVisibility(visibility)
	for _, s in pairs(self.objects) do
		s:setRenderVisibility(visibility)
	end
	for _, s in pairs(self.meshes) do
		s:setRenderVisibility(visibility)
	end
end

---@param visibility boolean
function class:setShadowVisibility(visibility)
	for _, s in pairs(self.objects) do
		s:setShadowVisibility(visibility)
	end
	for _, s in pairs(self.meshes) do
		s:setShadowVisibility(visibility)
	end
end

---Set whether the outer layers of the sun cascade shadow should render this object
---@param visibility boolean
function class:setFarVisibility(visibility)
	for _, s in pairs(self.objects) do
		s:setFarVisibility(visibility)
	end
	for _, s in pairs(self.meshes) do
		s:setFarVisibility(visibility)
	end
end

function class:encode(meshCache, dataStrings)
	local data = {
		["objects"] = { },
		["meshes"] = { },
		["positions"] = self.positions,
		["lights"] = self.lights,
		["collisionMeshes"] = self.collisionMeshes,
		["reflections"] = self.reflections,
		["links"] = self.links,
		["args"] = self.args,
		
		["name"] = self.name,
		
		["boundingBox"] = self.boundingBox,
		
		["transform"] = self.transform,
		
		["animations"] = self.animations,
		
		["LOD_min"] = self.LOD_min,
		["LOD_max"] = self.LOD_max,
	}
	
	--save objects
	for d, o in pairs(self.objects) do
		if not o.linked then
			data.objects[d] = o:encode(meshCache, dataStrings)
		end
	end
	
	--encode everything else
	for _, v in ipairs({ "meshes" }) do
		data[v] = { }
		for d, s in pairs(self[v]) do
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
	self.boundingBox:decode()
	
	--recreate objects
	for d, s in pairs(self.objects) do
		self.objects[d] = table.merge(lib:newObject(s.name), s)
		self.objects[d]:decode(meshData)
	end
	
	--decode meshes
	for _, s in pairs(self.meshes) do
		setmetatable(s, lib.meta.mesh)
		s:decode(meshData)
	end
	
	--recreate linked data
	for _, s in ipairs(self.links) do
		if s.transform then
			s.transform = mat4(s.transform)
		end
	end
	
	--recreate lights
	for _, s in pairs(self.lights) do
		setmetatable(s, lib.meta.light)
		s:decode()
	end
	
	--decode reflections
	for _, s in pairs(self.reflections) do
		setmetatable(s, lib.meta.reflection)
		s:decode()
	end
	
	--decode animations
	for _, s in pairs(self.animations) do
		setmetatable(s, lib.meta.animation)
		s:decode()
	end
	
	--decode physics
	for _, s in pairs(self.collisionMeshes) do
		setmetatable(s, lib.meta.collisionMesh)
		s:decode()
	end
	
	--recreate positions
	for _, s in pairs(self.positions) do
		s.position = vec3(s.position)
	end
end

local tree = { }

local function printf(str, ...)
	table.insert(tree, { text = string.format(tostring(str), ...) })
end

local function push(str, ...)
	printf(str, ...)
	tree[#tree].children = { parent = tree }
	tree = tree[#tree].children
end

local function pop()
	tree = tree.parent
end

local function printNode(node, tabs)
	tabs = tabs or ""
	for d, s in ipairs(node) do
		print(tabs .. (d == #node and "└─" or "├─") .. s.text)
		
		if s.children then
			printNode(s.children, tabs .. (d == #node and "  " or "│ "))
		end
	end
	tree = { }
end

---Print a detailed summary of this object
function class:print()
	--general information
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
		for _, m in pairs(self.meshes) do
			printf(m)
		end
		pop()
	end
	
	--physics
	if next(self.collisionMeshes) then
		push("physics")
		for _, s in pairs(self.collisionMeshes or { }) do
			printf("%s", s.name)
		end
		pop()
	end
	
	--lights
	if next(self.lights) then
		push("lights")
		for _, l in pairs(self.lights) do
			printf(l)
		end
		pop()
	end
	
	--positions
	if next(self.positions) then
		push("positions")
		for _, p in pairs(self.positions) do
			printf("%s at %s", p.name, p.position)
		end
		pop()
	end
	
	--animations
	if next(self.animations) then
		push("animations")
		for d, s in pairs(self.animations) do
			printf("%s: %.1f sec", d, s.length)
		end
		pop()
	end
	
	--print objects
	if next(self.objects) then
		push("objects")
		for _, o in pairs(self.objects) do
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

function class:tostring()
	local tags = { }
	
	--lod
	local min, max = self:getLOD()
	if min then
		table.insert(tags, math.floor(min) .. "-" .. math.floor(max))
	end
	
	--tags
	for tag, _ in pairs(self.tags) do
		table.insert(tags, tostring(tag))
	end
	return string.format("%s: %d objects, %d meshes, %d physics, %d lights%s%s", self.name, count(self.objects), count(self.meshes), count(self.collisionMeshes or { }), count(self.lights), #tags > 0 and ", " or "", table.concat(tags, ", "))
end

return class