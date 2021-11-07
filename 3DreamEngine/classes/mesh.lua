local lib = _3DreamEngine

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

function lib:newMesh(name, material, meshType)
	assert(meshType, "mesh type required")
	local o = {
		name = removePostfix(name),
		material = material,
		tags = { },
		
		--common data arrays
		vertices = { },
		normals = { },
		texCoords = { },
		colors = { },
		roughnesses = { },
		metallics = { },
		emissions = { },
		faces = { },
		
		boundingBox = self:newBoundaryBox(),
		
		meshType = meshType,
	}
	
	return setmetatable(o, self.meta.mesh)
end

local class = {
	link = {"clone", "transform", "shader", "visibility", "mesh"},
}

function class:setName(name)
	assert(type(name) == "string", "name has to be a string")
	self.name = removePostfix(name)
end
function class:getName()
	return name
end

function class:updateBoundingBox()
	if self.instanceMesh then
		return
	end
	
	self.boundingBox = lib:newBoundaryBox(true)
	
	--get aabb
	for i,v in ipairs(self.vertices) do
		local pos = vec3(v)
		self.boundingBox.first = self.boundingBox.first:min(pos)
		self.boundingBox.second = self.boundingBox.second:max(pos)
	end
	self.boundingBox.center = (self.boundingBox.second + self.boundingBox.first) / 2
	
	--get size
	local max = 0
	local c = self.boundingBox.center
	for i,v in ipairs(self.vertices) do
		local pos = vec3(v) - c
		max = math.max(max, pos:lengthSquared())
	end
	self.boundingBox.size = math.max(math.sqrt(max), self.boundingBox.size)
end

function class:initShaders()
	--pixel
	local ps = self.material.pixelShader or self.pixelShader or lib.defaultPixelShader
	if ps.initMesh then
		ps:initMesh(lib, self)
	end
	
	--vertex
	local ps = self.material.vertexShader or self.vertexShader or lib.defaultVertexShader
	if ps.initMesh then
		ps:initMesh(lib, self)
	end
	
	--world
	local ps = self.material.worldShader or self.worldShader or lib.defaultWorldShader
	if ps.initMesh then
		ps:initMesh(lib, self)
	end
	
	self.shadersInitialized = true
end

--clean most primary buffers
function class:cleanup()
	if not self.tags.raytrace then
		self.vertices = nil
		self.faces = nil
		self.normals = nil
		
		self.joints = nil
		self.weights = nil
	end
	
	self.texCoords = nil
	self.colors = nil
	self.extras = nil
	self.tangents = nil
	
	for i = 1, 10 do
		self["texCoords_" .. i] = nil
		self["colors_" .. i] = nil
	end
end

function class:preload(force)
	if self.preloaded then
		return
	else
		self.preloaded = true
	end
	
	--preload material
	self.material:preload(force)
	
	--load meshes
	if self.meshes then
		if self.meshes then
			for _, name in ipairs(self.meshes) do
				self:getMesh(name)
			end
		end
	end
end

function class:getMesh(name)
	local mesh = self[name]
	if type(mesh) == "userdata" then
		return mesh
	elseif mesh then
		if mesh.mesh then
			--cached
			self[name] = mesh.mesh
			return mesh.mesh
		else
			--load
			local newMesh = love.graphics.newMesh(mesh.vertexFormat, mesh.vertexCount, "triangles", "static")
			
			if mesh.vertexMap then
				newMesh:setVertexMap(mesh.vertexMap, "uint32")
			end
			newMesh:setVertices(mesh.vertices)
			
			--cache it for later, in case it is a shared mesh
			for d,s in pairs(mesh) do
				mesh[d] = nil
			end
			mesh.mesh = newMesh
			
			self[name] = newMesh
			return newMesh
		end
	end
end

return class