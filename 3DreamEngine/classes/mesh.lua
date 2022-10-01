local lib = _3DreamEngine

function lib:newMesh(name, material, meshType)
	local o = {
		name = name,
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
		
		boundingBox = self:newEmptyBoundingBox(),
		
		meshType = meshType or (material.pixelShader or self.defaultPixelShader).meshType,
		
		renderVisibility = true,
		shadowVisibility = true,
		
		instancesCount = 0,
	}
	
	return setmetatable(o, self.meta.mesh)
end

local class = {
	link = {"clone", "shader", "mesh"},
	
	setterGetter = {
		instancesCount = "number",
		renderVisibility = "boolean",
		shadowVisibility = "boolean",
		farVisibility = "boolean",
	}
}

function class:setName(name)
	self.name = name
end
function class:getName()
	return self.name
end

function class:tostring()
	local tags = { }
	
	--vertex count
	if self.mesh and self.mesh.getVertexCount then
		table.insert(tags, self.mesh:getVertexCount() .. " vertices")
	end
	
	--lod
	local min, max = self:getLOD()
	if min then
		table.insert(tags, math.floor(min) .. "-" .. math.floor(max))
	end
	
	--visibility
	if not self.renderVisibility and not self.shadowVisibility then
		table.insert(tags, "invisible")
	elseif not self.shadowVisibility then
		table.insert(tags, "no shadows")
	elseif not self.renderVisibility then
		table.insert(tags, "shadow caster")
	end
	
	--tags
	for d,s in pairs(self.tags) do
		table.insert(tags, tostring(d))
	end
	
	if #tags > 0 then
		return self.name .. " (" .. table.concat(tags, ", ") .. ")"
	else
		return self.name
	end
end

function class:updateBoundingBox()
	if self.instanceMesh or not self.vertices then
		return
	end
	
	self.boundingBox = lib:newEmptyBoundingBox()
	self.boundingBox:setInitialized(true)
	
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

local meshTypeWarning
function class:initShaders()
	--pixel
	local ps = self.material.pixelShader or self.pixelShader or lib.defaultPixelShader
	if ps.initMesh then
		ps:initMesh(lib, self)
	end
	
	--vertex
	local vs = self.material.vertexShader or self.vertexShader or lib.defaultVertexShader
	if vs.initMesh then
		vs:initMesh(lib, self)
	end
	
	--world
	local ws = self.material.worldShader or self.worldShader or lib.defaultWorldShader
	if ws.initMesh then
		ws:initMesh(lib, self)
	end
	
	--recreate mesh
	if self.mesh and not meshTypeWarning and (ps.meshType ~= self.meshType or vs.meshType ~= self.meshType or ws.meshType ~= self.meshType) then
		meshTypeWarning = true
		print("WARNING: Required and given mesh type do not match. Either set a default shader before loading the object or provide a shader in the material file.")
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

function class:applyTransform(transform)
	--normal transformation
	local subm = transform:subm()
	
	for i = 1, #self.vertices do
		--transform vertices
		self.vertices[i] = transform * vec3(self.vertices[i])
		
		--transform normals
		self.normals[i] = subm * vec3(self.normals[i])
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
	assert(skeleton.transforms, "No pose has been applied to skeleton!")
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
	
	for _,f in ipairs(self.faces) do
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

--creates a render-able mesh
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

function class:createInstances(count)
	self.originalBoundingBox = self.boundingBox:clone()
	
	--create mesh containing the transforms
	self.instanceMesh = love.graphics.newMesh({
		{"InstanceRotation0", "float", 3},
		{"InstanceRotation1", "float", 3},
		{"InstanceRotation2", "float", 3},
		{"InstancePosition", "float", 3},
	}, count)

	self.instancesCount = 0
end

function class:addInstance(rotation, position, index)
	if not index then
		self.instancesCount = self.instancesCount + 1
		index = self.instancesCount
		assert(index <= self.instanceMesh:getVertexCount(), "Instance mesh too small!")
	end
	self.instanceMesh:setVertex(index, {
		rotation[1], rotation[2], rotation[3],
		rotation[4], rotation[5], rotation[6],
		rotation[7], rotation[8], rotation[9],
		position[1], position[2], position[3]
	})
	self.boundingBox = self.boundingBox:merge(lib:newBoundingBox(
		rotation * self.originalBoundingBox.first + position,
		rotation * self.originalBoundingBox.second + position
	))
end

function class:addInstances(instances)
	self:createInstances(#instances)
	self.instanceMesh:setVertices(instances)
	self.instancesCount = #instances
end

--separates by loose parts and returns a list of new meshes
function class:separate()
	--initilize group indices
	local groupIndices = { }
	for d,s in ipairs(self.vertices) do
		groupIndices[s] = d
	end
	
	--group vertices via floodfill
	local active
	local found = true
	while found do
		found = false
		for _,face in ipairs(self.faces) do
			local a = self.vertices[face[1]]
			local b = self.vertices[face[2]]
			local c = self.vertices[face[3]]
			
			local ga = groupIndices[a]
			local gb = groupIndices[b]
			local gc = groupIndices[c]
			
			local min = math.min(ga, gb, gc)
			local max = math.max(ga, gb, gc)
			
			if min ~= max then
				groupIndices[a] = min
				groupIndices[b] = min
				groupIndices[c] = min
				found = true
			end
		end
	end
	
	--get a set of remaining lists
	local active = { }
	for _,face in ipairs(self.faces) do
		local a = self.vertices[face[1]]
		local ga = groupIndices[a]
		active[ga] = true
	end
	
	--split into groups
	local meshes = { }
	local ID = 0
	for group,_ in pairs(active) do
		ID = ID + 1
		meshes[ID] = self:clone()
		meshes[ID].faces = { }
		for _,face in ipairs(self.faces) do
			local a = self.vertices[face[1]]
			if groupIndices[a] == group then
				table.insert(meshes[ID].faces, face)
			end
		end
	end
	
	return meshes
end

function class:setLOD(min, max)
	self.LOD_min = min
	self.LOD_max = max
end
function class:getLOD()
	return self.LOD_min, self.LOD_max
end

function class:setVisible(b)
	self:setRenderVisibility(b)
	self:setShadowVisibility(b)
end

local cached = { }

function class:encode(meshCache, dataStrings)
	local ffi = require("ffi")
	
	local data = {
		["name"] = self.name,
		["meshType"] = self.meshType,
		["tags"] = self.tags,
		
		["boundingBox"] = self.boundingBox,
		
		["LOD_min"] = self.LOD_min,
		["LOD_max"] = self.LOD_max,
		
		["renderVisibility"] = self.renderVisibility,
		["shadowVisibility"] = self.shadowVisibility,
		["farVisibility"] = self.farVisibility,
	}
	
	--save the material id if its registered or the entire material
	if self.material.library then
		data["material"] = self.material.name
	else
		data["material"] = self.material
	end
	
	--export buffer data
	data["weights"] = self.weights
	data["joints"] = self.joints
	data["jointNames"] = self.jointNames
	data["inverseBindMatrices"] = self.inverseBindMatrices
	data["vertices"] = self.vertices
	data["normals"] = self.normals
	data["faces"] = self.faces
	
	--look for meshes
	for name, mesh in pairs(self) do
		if type(mesh) == "userdata" and mesh:typeOf("Mesh") then
			if meshCache[mesh] then
				data[name] = meshCache[mesh]
			else
				local m = { }
				meshCache[mesh] = m
				data[name] = m
				
				--store general data
				local f = mesh:getVertexFormat()
				m.vertexCount = mesh:getVertexCount()
				m.vertexFormat = f
				
				--store vertexMap
				local map = mesh:getVertexMap()
				if map then
					local vertexMapData = love.data.newByteData(#map * 4)
					local vertexMap = ffi.cast("uint32_t*", vertexMapData:getPointer())
					for d,s in ipairs(map) do
						vertexMap[d-1] = s-1
					end
					
					--compress and store vertex map
					local c = love.data.compress("string", "lz4", vertexMapData:getString(), -1)
					table.insert(dataStrings, c)
					m.vertexMap = #dataStrings
				end
				
				--give a unique hash for the vertex format
				local md5 = love.data.hash("md5", packTable.pack(f))
				local hash = love.data.encode("string", "hex", md5)
				
				--build a C struct to make sure data match
				local attrCount = 0
				local types = { }
				if cached[hash] then
					attrCount = cached[hash].attrCount
					types = cached[hash].types
				else
					local str = "typedef struct {" .. "\n"
					for _,ff in ipairs(f) do
						if ff[2] == "float" then
							str = str .. "float "
						elseif ff[2] == "byte" then
							str = str .. "unsigned char "
						else
							error("unknown data type " .. ff[2])
						end
						
						for i = 1, ff[3] do
							attrCount = attrCount + 1
							types[attrCount] = ff[2]
							str = str .. "x" .. attrCount .. (i == ff[3] and ";" or ", ")
						end
						str = str .. "\n"
					end
					str = str .. "} mesh_vertex_" .. hash .. ";"
					ffi.cdef(str)
					
					cached[hash] = {
						attrCount = attrCount,
						types = types,
					}
				end
				
				--byte data
				local byteData = love.data.newByteData(mesh:getVertexCount() * ffi.sizeof("mesh_vertex_" .. hash))
				local meshData = ffi.cast("mesh_vertex_" .. hash .. "*", byteData:getPointer())
				
				--fill data
				for i = 1, mesh:getVertexCount() do
					local v = {mesh:getVertex(i)}
					for i2 = 1, attrCount do
						meshData[i-1]["x" .. i2] = (types[i2] == "byte" and math.floor(v[i2]*255) or v[i2])
					end
				end
				
				--convert to string and store
				local c = love.data.compress("string", "lz4", byteData:getString(), 9)
				table.insert(dataStrings, c)
				m.vertices = #dataStrings
			end
		end
	end
	
	return data
end

function class:decode(meshData)
	setmetatable(self.boundingBox, lib.meta.boundingBox)
	self.boundingBox:decode()
	
	--look for meshes and link
	for _,s in pairs(self) do
		if type(s) == "table" and type(s.vertices) == "number" then
			s.vertexMap = s.vertexMap and meshData[s.vertexMap]
			s.vertices = meshData[s.vertices]
		end
	end
	
	--restore matrices
	if self.inverseBindMatrices then
		for i,v in ipairs(self.inverseBindMatrices) do
			self.inverseBindMatrices[i] = mat4(v)
		end
	end
	
	--relink materials
	local mat = type(self.material) == "table" and self.material or lib.materialLibrary[self.material]
	if mat then
		self.material = setmetatable(mat, lib.meta.material)
	else
		error("material " .. tostring(self.material) .. " required by object " .. tostring(self.name) .. " does not exist!")
	end
end

return class