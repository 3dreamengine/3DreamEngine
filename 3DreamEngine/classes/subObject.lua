local lib = _3DreamEngine

local function removePostfix(t)
	local v = t:match("(.*)%.[^.]+")
	return v or t
end

function lib:newLinkedObject(original)
	return setmetatable({ }, {__index = original})
end

function lib:newSubObject(name, obj, mat)
	--guess shaderType if not specified based on textures used
	local shaderType = obj.args.shaderType
	if not shaderType then
		if lib.defaultShaderType then
			shaderType = lib.defaultShaderType
		else
			shaderType = "simple"
			
			if mat and (mat.tex_albedo or mat.tex_normal) then
				shaderType = "Phong"
			end
		end
	end
	
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
		extras = { },
		faces = { },
		
		loaded = true,
		boundingBox = self:newBoundaryBox(),
		
		shaderType = shaderType,
		meshType = obj.args.meshType or self.shaderLibrary.base[shaderType].meshType,
	}
	
	return setmetatable(o, self.meta.subObject)
end

return {
	link = {"clone", "shader", "visibility", "subObject"},
	
	isLoaded = function(self)
		return self.loaded
	end,
	
	request = function(self)
		if not self.loaded and self.meshDataIndex then
			self.obj.loadRequests = self.obj.loadRequests or { }
			
			local index = self.obj.DO_dataOffset + self.meshDataIndex
			if not self.obj.loadRequests[index] then
				self.obj.loadRequests[index] = true
				lib:addResourceJob("3do", self.obj, true, self.obj.DO_path, index, self.meshDataSize, self.obj.DO_compressed)
				return true
			else
				return false
			end
		end
	end,
	
	wait = function(self)
		while not self:isLoaded() do
			local worked = lib:update()
			if not worked then
				love.timer.sleep(10/1000)
			end
		end
	end,
	
	setName = function(self, name)
		assert(type(name) == "string", "name has to be a string")
		self.name = removePostfix(name)
	end,
	getName = function(self)
		return name
	end,
	
	updateBoundingBox = function(self)
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
	
	--clean most primary buffers
	cleanup = function(self, lite)
		if not lite then
			self.vertices = nil
			self.faces = nil
			self.normals = nil
		end
		
		self.texCoords = nil
		self.colors = nil
		self.materials = nil
		self.extras = nil
		self.tangents = nil
	end,
}