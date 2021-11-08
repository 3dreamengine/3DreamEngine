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


--apply joints to mesh data directly
function class:applyBones(skeleton)
	if self.joints then
		--make a copy of vertices
		if not self.verticesOld then
			self.verticesOld = self.vertices
			self.normalsOld = self.normals
			self.vertices = { }
			self.normals = { }
		end
		
		--apply joint transforms
		for i,v in ipairs(self.verticesOld) do
			local m = self:getJointMat(skeleton, i)
			self.vertices[i] = m * vec3(v)
			self.normals[i] = m:subm() * vec3(self.normalsOld[i])
		end
	end
end

--returns the final joint transformation based on vertex weights
function class:getJointMat(skeleton, i)
	assert(skeleton.transforms, "No pose has bene applied to skeleton!")
	local m = mat4()
	for jointNr = 1, #self.joints[i] do
		m = m + skeleton.transforms[ self.joints[i][jointNr] ] * self.weights[i][jointNr]
	end
	return m
end

--add tangents buffer
local empty = {0, 0, 0}
function class:calcTangents()
	self.tangents = { }
	for i = 1, #self.vertices do
		self.tangents[i] = {0, 0, 0, 0}
	end
	
	for i,f in ipairs(self.faces) do
		--vertices
		local v1 = self.vertices[f[1]] or empty
		local v2 = self.vertices[f[2]] or empty
		local v3 = self.vertices[f[3]] or empty
		
		--tex coords
		local uv1 = self.texCoords[f[1]] or empty
		local uv2 = self.texCoords[f[2]] or empty
		local uv3 = self.texCoords[f[3]] or empty
		
		local tangent = { }
		
		local edge1 = {v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]}
		local edge2 = {v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]}
		local edge1uv = {uv2[1] - uv1[1], uv2[2] - uv1[2]}
		local edge2uv = {uv3[1] - uv1[1], uv3[2] - uv1[2]}
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			--handle clockwise-uvs
			local clockwise = mat3(uv1[1], uv1[2], 1, uv2[1], uv2[2], 1, uv3[1], uv3[2], 1):det() > 0
			
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
			end
			
			--sum up tangents to smooth across shared vertices
			for i = 1, 3 do
				self.tangents[f[i]][1] = self.tangents[f[i]][1] + tangent[1]
				self.tangents[f[i]][2] = self.tangents[f[i]][2] + tangent[2]
				self.tangents[f[i]][3] = self.tangents[f[i]][3] + tangent[3]
				self.tangents[f[i]][4] = self.tangents[f[i]][4] + (clockwise and 1 or 0)
			end
		end
	end
	
	--normalize
	for i,f in ipairs(self.tangents) do
		local l = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
		f[1] = f[1] / l
		f[2] = f[2] / l
		f[3] = f[3] / l
	end	
	
	--complete smoothing step
	for i,f in ipairs(self.tangents) do
		local n = self.normals[i]
		
		--Gram-Schmidt orthogonalization
		local dot = (f[1] * n[1] + f[2] * n[2] + f[3] * n[3])
		f[1] = f[1] - n[1] * dot
		f[2] = f[2] - n[2] * dot
		f[3] = f[3] - n[3] * dot
		
		local l = math.sqrt(f[1]^2 + f[2]^2 + f[3]^2)
		f[1] = f[1] / l
		f[2] = f[2] / l
		f[3] = f[3] / l
	end
end

--creates a renderable mesh
function class:create()
	assert(self.faces, "face array is required")
	
	--set up vertex map
	local vertexMap = { }
	for d,f in ipairs(self.faces) do
		table.insert(vertexMap, f[1])
		table.insert(vertexMap, f[2])
		table.insert(vertexMap, f[3])
	end
	
	--create mesh
	local meshFormat = lib.meshFormats[self.meshType]
	local meshLayout = meshFormat.meshLayout
	self.mesh = love.graphics.newMesh(meshLayout, #self.vertices, "triangles", "static")
	
	--vertex map
	self.mesh:setVertexMap(vertexMap)
	
	--fill vertices
	meshFormat:create(self)
end

return class