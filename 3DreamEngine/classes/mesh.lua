---@type Dream
local lib = _3DreamEngine
local mat3, mat4 = lib.mat3, lib.mat4

local ffi = require("ffi")

---Creates a new empty mesh
---@param material DreamMaterial
---@return DreamMesh
function lib:newMesh(material)
	---@type DreamMesh
	local mesh = { }
	
	mesh.name = "unnamed"
	mesh.material = material
	mesh.boundingSphere = self:newBoundingSphere()
	
	---@type MeshDrawMode
	mesh.meshDrawMode = "triangles"
	
	---@type DreamMesh
	mesh.mesh = false
	
	---@type DreamSkeleton
	mesh.skeleton = false
	
	---@type boolean @ visible in render pass
	mesh.renderVisibility = true
	
	---@type boolean @ visible in shadow pass
	mesh.shadowVisibility = true
	
	return setmetatable(mesh, self.meta.mesh)
end

---@alias MeshDrawMode "fan"|"strip"|"triangles"|"points"

---@class DreamMesh : DreamClonable, DreamHasShaders, DreamIsNamed
local class = {
	links = { "clonable", "hasShaders", "named", "mesh" },
}

class.isMesh = true

---Sets the meshes material
---@param material DreamMaterial
function class:setMaterial(material)
	self.material = material
end

---@return DreamMaterial
function class:getMaterial()
	return self.material
end

---@param visibility boolean
function class:setVisible(visibility)
	self:setRenderVisibility(visibility)
	self:setShadowVisibility(visibility)
end

---@param visibility boolean
function class:setRenderVisibility(visibility)
	self.renderVisibility = visibility
end
function class:getRenderVisibility()
	return self.renderVisibility
end

---@param visibility boolean
function class:setShadowVisibility(visibility)
	self.shadowVisibility = visibility
end
function class:getShadowVisibility()
	return self.shadowVisibility
end

---@param skeleton DreamSkeleton
function class:setSkeleton(skeleton)
	self.skeleton = skeleton
end
function class:getSkeleton()
	return self.skeleton
end

function class:getPixelShader()
	return self.material.pixelShader or self.pixelShader or lib.defaultPixelShader
end

function class:getVertexShader()
	return self.material.vertexShader or self.vertexShader or lib.defaultVertexShader
end

function class:getWorldShader()
	return self.material.worldShader or self.worldShader or lib.defaultWorldShader
end

---@private
function class:tostring()
	local tags = { }
	
	--vertex count
	local m = self:getMesh()
	if m and m.getVertexCount then
		table.insert(tags, m:getVertexCount() .. " vertices")
	end
	
	--vertex count
	if self.skeleton then
		table.insert(tags, "skeleton")
	end
	
	--visibility
	if not self.renderVisibility and not self.shadowVisibility then
		table.insert(tags, "invisible")
	elseif not self.shadowVisibility then
		table.insert(tags, "no shadows")
	elseif not self.renderVisibility then
		table.insert(tags, "shadow caster")
	end
	
	return self.name .. (#tags > 0 and (" (" .. table.concat(tags, ", ") .. ")") or "")
end

---@private
function class:getFarthestVertex(from)
	local best = from
	local bestDistance = 0
	for i = 1, self.vertices:getSize() do
		local point = self.vertices:getVector(i)
		local dist = (point - from):lengthSquared()
		if dist > bestDistance then
			bestDistance = dist
			best = point
		end
	end
	return best
end

---Updates the bounding sphere based on mesh data
function class:updateBoundingSphere()
	if not self.vertices then
		return
	end
	
	--Ritter's bounding sphere
	--pick a random point
	local x = self.vertices:getVector(1)
	
	--find the farthest point
	local y = self:getFarthestVertex(x)
	
	--find the farthest point from y
	local z = self:getFarthestVertex(y)
	
	--the initial guess is in the middle of those two points
	local center = (y + z) / 2
	local size = (y - z):length() / 2
	
	--now include all other points
	local size2 = size ^ 2
	for i = 1, self.vertices:getSize() do
		local pos = self.vertices:getVector(i)
		local diff = pos - center
		local dist = diff:lengthSquared()
		if dist > size2 then
			dist = math.sqrt(dist)
			size = (size + dist) / 2
			center = (size * center + (dist - size) * pos) / dist
			size2 = size ^ 2
		end
	end
	
	self.boundingSphere = lib:newBoundingSphere(center, size)
end

--Clean most primary buffers
function class:cleanup()
	for i, v in pairs(self) do
		if type(v) == "table" and v.link and v.link.buffer then
			self[i] = nil
		end
	end
end

---Load textures and similar
---@param force boolean @ Bypass threaded loading and immediately load things
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

---Deletes the mesh, will regenerate next time needed
function class:clearMesh()
	self.mesh = nil
end

---Get a mesh, load automatically if required
---@param name string @ optional, default "mesh"
function class:getMesh(name)
	name = name or "mesh"
	if name == "mesh" and not self.mesh then
		self:create()
	end
	
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
			local newMesh = love.graphics.newMesh(mesh.vertexFormat, mesh.vertexCount, self.meshDrawMode, "static")
			
			if mesh.vertexMap then
				newMesh:setVertexMap(mesh.vertexMap, "uint32")
			end
			newMesh:setVertices(mesh.vertices)
			
			--cache it for later, in case it is a shared mesh
			for key, _ in pairs(mesh) do
				mesh[key] = nil
			end
			mesh.mesh = newMesh
			
			self[name] = newMesh
			return newMesh
		end
	end
end

---Apply a transformation matrix to all vertices
---@param transform DreamMat4
function class:applyTransform(transform)
	if self.vertices then
		local oldVertices = self.vertices
		local oldNormals = self.normals
		self.vertices = lib:newBufferLike(self.vertices)
		self.normals = lib:newBufferLike(self.normals)
		local subm = transform:subm()
		for i = 1, self.vertices:getSize() do
			self.vertices:set(i, transform * oldVertices:getVector(i))
			self.normals:set(i, subm * oldNormals:getVector(i))
		end
	end
end

---Apply joints to mesh data directly
---@param skeleton DreamSkeleton @ optional
function class:applyBones(skeleton)
	skeleton = skeleton or self.skeleton
	
	if self.joints then
		--make a copy of vertices
		if not self.oldVertices then
			self.oldVertices = self.vertices
			self.oldNormals = self.normals
			self.vertices = lib:newBufferLike(self.vertices)
			self.normals = lib:newBufferLike(self.normals)
		end
		
		--apply joint transforms
		for i = 1, self.vertices:getSize() do
			local transform = self:getJointMatrix(skeleton, i)
			self.vertices:set(i, transform * self.oldVertices:getVector(i))
			self.normals:set(i, transform:subm() * self.oldNormals:getVector(i))
		end
	end
end

---Returns the final joint transformation based on vertex weights
---@param skeleton DreamSkeleton
---@param jointIndex number
---@return DreamMat4
function class:getJointMatrix(skeleton, jointIndex)
	assert(skeleton.transforms, "No pose has been applied to skeleton!")
	local m = mat4()
	for jointNr = 1, #self.joints[jointIndex] do
		m = m + skeleton.transforms[self.joints[jointIndex][jointNr]] * self.weights[jointIndex][jointNr]
	end
	return m
end

local empty = { 0, 0 }
function class:recalculateTangents()
	self.tangents = lib:newBuffer("vec4", "float", self.vertices:getSize())
	
	for _, f in self.faces:ipairs() do
		--vertices
		local v1 = self.vertices:get(f.x)
		local v2 = self.vertices:get(f.y)
		local v3 = self.vertices:get(f.z)
		
		--tex coords
		local uv1 = self.texCoords:getOrDefault(f.x, empty)
		local uv2 = self.texCoords:getOrDefault(f.y, empty)
		local uv3 = self.texCoords:getOrDefault(f.z, empty)
		
		local tangent = { }
		
		local edge1 = { v2.x - v1.x, v2.y - v1.y, v2.z - v1.z }
		local edge2 = { v3.x - v1.x, v3.y - v1.y, v3.z - v1.z }
		local edge1uv = { uv2.x - uv1.x, uv2.y - uv1.y }
		local edge2uv = { uv3.x - uv1.x, uv3.y - uv1.y }
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			--handle clockwise-uvs
			local clockwise = mat3(uv1.x, uv1.y, 1, uv2.x, uv2.y, 1, uv3.x, uv3.y, 1):det() > 0
			
			tangent.x = (edge1[1] * edge2uv[2] - edge2[1] * edge1uv[2]) / cp
			tangent.y = (edge1[2] * edge2uv[2] - edge2[2] * edge1uv[2]) / cp
			tangent.z = (edge1[3] * edge2uv[2] - edge2[3] * edge1uv[2]) / cp
			
			--sum up tangents to smooth across shared vertices
			for _, key in ipairs({ "x", "y", "z" }) do
				local t = self.tangents:get(f[key])
				t.x = t.x + tangent.x
				t.y = t.y + tangent.y
				t.z = t.z + tangent.z
				t.w = clockwise and 1 or 0
			end
		end
	end
	
	for i = 1, self.tangents:getSize() do
		--normalize
		local t = self.tangents:get(i)
		local l = math.sqrt(t.x ^ 2 + t.y ^ 2 + t.z ^ 2)
		t.x = t.x / l
		t.y = t.y / l
		t.z = t.z / l
		
		--complete smoothing step
		local n = self.normals:get(i)
		
		--Gram-Schmidt orthogonality
		local dot = (t.x * n.x + t.y * n.y + t.z * n.z)
		t.x = t.x - n.x * dot
		t.y = t.y - n.y * dot
		t.z = t.z - n.z * dot
		
		--normalize
		l = math.sqrt(t.x ^ 2 + t.y ^ 2 + t.z ^ 2)
		t.x = t.x / l
		t.y = t.y / l
		t.z = t.z / l
	end
end

function class:createVertexMap()
	local vertexMapByteData = love.data.newByteData(ffi.sizeof("uint32_t") * self.faces:getSize() * 3)
	local indices = ffi.cast("uint32_t*", vertexMapByteData:getFFIPointer())
	for i = 1, self.faces:getSize() do
		local f = self.faces:get(i)
		indices[i * 3 - 3] = f.x - 1
		indices[i * 3 - 2] = f.y - 1
		indices[i * 3 - 1] = f.z - 1
	end
	return vertexMapByteData
end

---Returns the required mesh format set by the current pixel shader
---@return DreamMeshFormat
function class:getMeshFormat()
	return lib.meshFormats[self:getPixelShader().meshFormat]
end

---Makes this mesh render-able
function class:create()
	assert(self.meshDrawMode ~= "triangles" or self.faces, "Face array is required")
	
	--create mesh
	local meshFormat = self:getMeshFormat()
	local byteData = meshFormat:create(self)
	self.mesh = love.graphics.newMesh(meshFormat.vertexFormat, byteData, self.meshDrawMode, "static")
	
	--vertex map
	self.mesh:setVertexMap(self:createVertexMap(), "uint32")
	
	--initialize pixel shader
	local pixelShader = self:getPixelShader()
	if pixelShader.initMesh then
		pixelShader:initMesh(self)
	end
	
	--initialize vertex shader
	local vertexShader = self:getVertexShader()
	if vertexShader.initMesh then
		vertexShader:initMesh(self)
	end
	
	--initialize world shader
	local worldShader = self:getWorldShader()
	if worldShader.initMesh then
		worldShader:initMesh(self)
	end
end

local function vertexHash(v)
	return tostring(v.x) .. tostring(v.y) .. tostring(v.z)
end

---Separates by loose parts and returns a list of new meshes
---@return DreamMesh[]
function class:separate()
	--initialize group indices
	local groupIndices = { }
	for i = 1, self.vertices:getSize() do
		local v = self.vertices:get(i)
		groupIndices[vertexHash(v)] = i
	end
	
	--group vertices via floodfill
	local found = true
	while found do
		found = false
		for _, face in self.faces:ipairs() do
			local a = vertexHash(self.vertices:get(face.x))
			local b = vertexHash(self.vertices:get(face.y))
			local c = vertexHash(self.vertices:get(face.z))
			
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
	for _, face in self.faces:ipairs() do
		local a = vertexHash(self.vertices:get(face.x))
		local ga = groupIndices[a]
		active[ga] = true
	end
	
	--split into groups
	local meshes = { }
	local ID = 0
	for group, _ in pairs(active) do
		ID = ID + 1
		meshes[ID] = self:clone()
		meshes[ID].faces = lib:newDynamicBuffer()
		for _, face in self.faces:ipairs() do
			local a = vertexHash(self.vertices:get(face.x))
			if groupIndices[a] == group then
				meshes[ID].faces:append(face)
			end
		end
	end
	
	return meshes
end

---Sets the current meshDrawMode, rarely makes sense to set manually
---@param meshDrawMode MeshDrawMode
function class:setMeshDrawMode(meshDrawMode)
	self.meshDrawMode = meshDrawMode
end

---Gets the current meshDrawMode
---@return MeshDrawMode
function class:getMeshDrawMode()
	return self.meshDrawMode
end

---Gets or creates an dynamic, typeless buffer
---@param name string @ name of buffer
function class:getOrCreateBuffer(name)
	if not self[name] then
		self[name] = lib:newDynamicBuffer()
	end
	return self[name]
end

---@private
function class:encode(meshCache, dataStrings)
	local data = {
		["name"] = self.name,
		["meshFormat"] = self.meshFormat,
		
		["boundingSphere"] = self.boundingSphere,
		
		["renderVisibility"] = self.renderVisibility,
		["shadowVisibility"] = self.shadowVisibility,
	}
	
	--save the material id if its registered or the entire material
	if self.material.library then
		data["material"] = self.material.name
	else
		data["material"] = self.material
	end
	
	--export buffer data
	data["joints"] = self.joints
	data["weights"] = self.weights
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
					for d, s in ipairs(map) do
						vertexMap[d - 1] = s - 1
					end
					
					--compress and store vertex map
					local c = love.data.compress("string", "lz4", vertexMapData:getString(), -1)
					table.insert(dataStrings, c)
					m.vertexMap = #dataStrings
				end
				
				local identifier, types = lib:newMeshFormat(f):getCStruct()
				
				--byte data
				local byteData = love.data.newByteData(mesh:getVertexCount() * ffi.sizeof(identifier))
				local meshData = ffi.cast(identifier .. "*", byteData:getPointer())
				
				--fill data
				for i = 1, mesh:getVertexCount() do
					local v = { mesh:getVertex(i) }
					for index, type in ipairs(types) do
						--todo why, just use love2d mesh as a wrapper
						meshData[i - 1]["x" .. index] = (type == "byte" and math.floor(v[index] * 255) or v[index])
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

---@private
function class:decode(meshData)
	setmetatable(self.boundingSphere, lib.meta.boundingSphere)
	self.boundingSphere:decode()
	
	--look for meshes and link
	for _, s in pairs(self) do
		if type(s) == "table" and type(s.vertices) == "number" then
			s.vertexMap = s.vertexMap and meshData[s.vertexMap]
			s.vertices = meshData[s.vertices]
		end
	end
	
	--restore matrices
	if self.inverseBindMatrices then
		for i, v in ipairs(self.inverseBindMatrices) do
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