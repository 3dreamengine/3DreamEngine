local lib = _3DreamEngine

function lib:newLinkedObject(original)
	local meta = {
		__index = function(o, key)
			return rawget(o.linkedObject, key) or lib.meta.subObject.__index[key]
		end
	}
	return setmetatable({linkedObject = original}, meta)
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
		name = name,
		material = mat,
		obj = obj,
		
		--common data arrays
		vertices = { },
		normals = { },
		texCoords = { },
		colors = { },
		materials = { },
		extras = { },
		faces = { },
		edges = { },
		
		loaded = true,
		
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
		if not self.loaded then
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
}