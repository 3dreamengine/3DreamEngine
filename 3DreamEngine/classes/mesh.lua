local lib = _3DreamEngine

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

function lib:newLinkedObject(original)
	return setmetatable({ }, {__index = original})
end

function lib:newMesh(name, obj, mat)
	local o = {
		name = removePostfix(name),
		material = mat,
		obj = obj,
		tags = { },
		
		--common data arrays
		vertices = { },
		normals = { },
		texCoords = { },
		colors = { },
		materials = { },
		faces = { },
		
		boundingBox = self:newBoundaryBox(),
		
		meshType = obj.args.meshType,
	}
	
	return setmetatable(o, self.meta.mesh)
end

return {
	link = {"clone", "shader", "visibility", "mesh"},
	
	setName = function(self, name)
		assert(type(name) == "string", "name has to be a string")
		self.name = removePostfix(name)
	end,
	getName = function(self)
		return name
	end,
	
	updateBoundingBox = function(self)
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
	end,
	
	initShaders = function(self)
		--pixel
		local ps = self.material.pixelShader or self.pixelShader or lib.defaultPixelShader
		if ps.initObject then
			ps:initObject(lib, self)
		end
		
		--vertex
		local ps = self.material.vertexShader or self.vertexShader or lib.defaultVertexShader
		if ps.initObject then
			ps:initObject(lib, self)
		end
		
		--world
		local ps = self.material.worldShader or self.worldShader or lib.defaultWorldShader
		if ps.initObject then
			ps:initObject(lib, self)
		end
		
		self.shadersInitialized = true
	end,
	
	--clean most primary buffers
	cleanup = function(self)
		if not self.tags.raytrace then
			self.vertices = nil
			self.faces = nil
			self.normals = nil
			
			self.joints = nil
			self.weights = nil
		end
		
		self.texCoords = nil
		self.colors = nil
		self.materials = nil
		self.extras = nil
		self.tangents = nil
		
		for i = 1, 10 do
			self["texCoords_" .. i] = nil
			self["colors_" .. i] = nil
		end
	end,
	
	preload = function(self, force)
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
	end,
	
	getMesh = function(self, name)
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
					--newMesh:setVertexMap(mesh.vertexMap, "uint32")
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
	end,
}