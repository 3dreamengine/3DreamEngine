---@type Dream
local lib = _3DreamEngine

local vec3, mat4 = lib.vec3, lib.mat4

--todo linked objects are basically just instances, and should be instances for the sake of recursive instancing
---@deprecated
---@return DreamObject
function lib:newLinkedObject(original, source)
	return setmetatable({
		linked = source
	}, { __index = original })
end

---Create an empty object
---@return DreamObject
function lib:newObject()
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
		
		name = "unnamed",
		
		mainSkeleton = false,
		
		loaded = true,
	}, self.meta.object)
end

---@class DreamObject : DreamClonable, DreamTransformable, DreamHasShaders, DreamIsNamed
---@field public objects DreamObject[]
---@field public meshes DreamMesh[]
---@field public positions DreamPosition[]
---@field public lights DreamLight[]
---@field public collisionMeshes DreamCollisionMesh[]
---@field public raytraceMeshes DreamRaytraceMesh[]
---@field public reflections DreamReflection[]
---@field public animations DreamAnimation[]
local class = {
	links = { "clonable", "transformable", "hasShaders", "named", "object" },
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

---Creates an recursive instance, objects can now be transformed individually, all other changes remain synced
---Much faster than a full copy
---@return DreamObject
function class:instance()
	local instance = setmetatable({}, { __index = self })
	instance.objects = { }
	for i, v in pairs(self.objects) do
		instance.objects[i] = v:instance()
	end
	return instance
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

function class:updateBoundingSphere()
	--update bounding sphere of meshes
	for _, s in pairs(self.meshes) do
		if not s.boundingSphere:isInitialized() then
			s:updateBoundingSphere()
		end
	end
	
	--update bounding spheres of objects
	for _, s in pairs(self.objects) do
		s:updateBoundingSphere()
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

local function getAllMeshes(object, list, transform)
	if not object.LOD_max or object.LOD_max >= math.huge then
		for _, o in pairs(object.objects) do
			getAllMeshes(o, list, o:getTransform() * transform)
		end
		for _, mesh in pairs(object.meshes) do
			if mesh.vertices then
				table.insert(list, { mesh, transform })
			end
		end
	end
end

---Get all pairs of (DreamMesh, mat4 transform), recursively, as a flat array
function class:getAllMeshes()
	local list = { }
	getAllMeshes(self, list, mat4:getIdentity())
	return list
end

---Merge all meshes, recursively, of an object
---It uses a material of one random mesh and therefore requires only identical materials
---It returns a new object with only one mesh named "merged"
function class:merge()
	local meshes = self:getAllMeshes()
	
	assert(#meshes > 0, "Object has no meshes")
	
	--get size beforehand to avoid resizes
	local mesh = lib:newMeshBuilder(meshes[1][1].material)
	local vertexSize = 0
	local vertexMapSize = 0
	for _, pair in ipairs(meshes) do
		vertexSize = vertexSize + pair[1].vertices:getSize()
		vertexMapSize = vertexMapSize + pair[1].faces:getSize() * 3
	end
	mesh:resizeVertex(vertexSize)
	mesh:resizeIndices(vertexMapSize)
	
	--add the meshes
	for _, pair in ipairs(meshes) do
		mesh:addMesh(unpack(pair))
	end
	
	--create object
	local merged = lib:newObject()
	merged.meshes["merged"] = mesh
	return merged
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

---A object has no material, therefore this call will forward this to all Meshes
---@param material DreamMaterial
function class:setMaterial(material)
	for _, s in pairs(self.objects) do
		s:setMaterial(material)
	end
	for _, s in pairs(self.meshes) do
		s:setMaterial(material)
	end
end

---@private
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

---@private
function class:decode(meshData)
	--recreate transform
	if self.transform then
		self.transform = mat4(self.transform)
	end
	
	--recreate objects
	for d, s in pairs(self.objects) do
		self.objects[d] = table.merge(lib:newObject(), s)
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

---@private
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

---Exports this object in the custom, compact and fast 3DO format
---@deprecated @ broken
function class:export3do()
	--todo optional return string as well as raw mesh byte data array for memory efficient inter-thread communication
	local meshCache = { }
	local dataStrings = { }
	
	--encode
	local data = self:encode(meshCache, dataStrings)
	
	--save the length of each data segment
	data.dataStringsLengths = { }
	for _, s in pairs(dataStrings) do
		table.insert(data.dataStringsLengths, #s)
	end
	
	--export
	local headerData = love.data.compress("string", "lz4", lib.packTable.pack(data), 9)
	local headerLength = #headerData
	local l1 = math.floor(headerLength) % 256
	local l2 = math.floor(headerLength / 256) % 256
	local l3 = math.floor(headerLength / 256 ^ 2) % 256
	local l4 = math.floor(headerLength / 256 ^ 3) % 256
	local final = "3DO" .. lib.version_3DO .. "    " .. string.char(l1, l2, l3, l4) .. headerData .. table.concat(dataStrings, "")
	love.filesystem.createDirectory(self.dir)
	love.filesystem.write(self.dir .. "/" .. self.name .. ".3do", final)
end

return class