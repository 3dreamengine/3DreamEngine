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
			
			if mat.tex_albedo or mat.tex_normal then
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
		LOD_center = vec3(0, 0, 0),
		boundingBox = self:newBoundaryBox(),
		
		shaderType = shaderType,
		meshType = obj.args.meshType or self.shaderLibrary.base[shaderType].meshType,
	}
	
	return setmetatable(o, self.meta.subObject)
end

return {
	link = {"clone", "transform", "shader", "visibility", "subObject"},
	
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
	end
}