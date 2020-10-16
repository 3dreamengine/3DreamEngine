local lib = _3DreamEngine

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
		
		shaderType = shaderType,
		meshType = obj.args.meshType or self.shaderLibrary.base[shaderType].meshType,
	}
	
	return setmetatable(o, self.meta.subObject)
end

return {
	link = {"clone", "transform", "shader", "visibility"},
}