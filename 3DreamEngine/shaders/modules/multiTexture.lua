local sh = { }

sh.type = "module"

function sh:init(dream)
	
end

function sh:constructDefines(dream)
	return [[
	extern Image tex_albedo_2;
	extern vec4 color_albedo_2;
	
	extern Image tex_normal_2;
	
	extern Image tex_material_2;
	extern vec3 color_material_2;

	extern Image tex_emission_2;
	extern vec3 color_emission_2;
	
	extern Image tex_mask;
	extern Image tex_blend;
	
	extern float uv2Scale;
	
	varying vec2 VaryingTexCoord2;
	
	#ifdef VERTEX
		attribute vec2 VertexTexCoord2;
	#endif
	]]
end

function sh:constructPixel(dream, mat)
	return [[
	float mask = Texel(tex_mask, VaryingTexCoord2.xy).r;
	float blend = Texel(tex_blend, VaryingTexCoord2.xy * 64.0).r;
	mask = clamp((mask*3.0 - 1.0 + blend), 0.0, 1.0);
	
	vec2 uv2 = VaryingTexCoord.xy * uv2Scale;
	
	albedo = mix(albedo, Texel(tex_albedo_2, uv2) * color_albedo_2, mask);
	
	material = mix(material, Texel(tex_material_2, uv2).xyz * color_material_2, mask);
	
	#ifdef TEX_NORMAL
		vec3 normal_2 = normalize(TBN * (Texel(tex_normal_2, uv2).rgb - 0.5));
		normal = mix(normal, normal_2, mask);
	#endif
	
	#ifdef TEX_EMISSION
		emission = mix(emission, Texel(tex_emission_2, uv2).rgb * color_emission_2, mask);
	#else
		emission = mix(emission, color_emission_2, mask);
	#endif
	]]
end

function sh:constructVertexPost(dream)
	return [[
	VaryingTexCoord2 = VertexTexCoord2;
	]]
end

function sh:perShader(dream, shaderObject)
	
end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
end

function sh:perTask(dream, shaderObject, subObj, task)
	local shader = shaderObject.shader
	
	--initial prepare bone data
	if not subObj.uv2Mesh then
		assert(subObj.texCoords_2, "To use the multiTetxure module at least a second UV map for the mask texture is required.")
		subObj.uv2Mesh = love.graphics.newMesh({{"VertexTexCoord2", "float", 2}}, #subObj.texCoords_2, "triangles", "static")
		
		--create mesh
		for d,uv in ipairs(subObj.texCoords_2) do
			subObj.uv2Mesh:setVertex(d, uv[1], uv[2])
		end
		
		--clear buffers
		if subObj.obj.args.cleanup then
			subObj.texCoords_2 = nil
		end
		
		subObj.mesh:attachAttribute("VertexTexCoord2", subObj.uv2Mesh)
	end
	
	local material = subObj.material_2
	assert(material, "set subObject.material_2 to a material")
	assert(subObj.tex_mask, "material.tex_mask required")
	assert(subObj.tex_blend, "material.tex_blend required")
	
	shader:send("tex_mask", dream:getTexture(subObj.tex_mask) or dream.textures.default)
	shader:send("tex_blend", dream:getTexture(subObj.tex_blend) or dream.textures.default)
	
	shader:send("uv2Scale", subObj.multiTexture_uv2Scale or 1.0)
	
	shader:send("tex_albedo_2", dream:getTexture(material.tex_albedo) or dream.textures.default)
	shader:send("color_albedo_2", material.color)
	
	shader:send("tex_material_2", dream:getTexture(material.tex_material) or dream.textures.default)
	shader:send("color_material_2", {material.roughness, material.metallic, 1.0})
	
	if material.tex_emission then
		shader:send("tex_emission_2", dream:getTexture(material.tex_emission) or tex.default)
	end
	if shader:hasUniform("color_emission") then
		shader:send("color_emission_2", material.emission)
	end
	
	if shader:hasUniform("tex_normal_2") then
		shader:send("tex_normal_2", dream:getTexture(material.tex_normal) or dream.textures.default_normal)
	end
end

return sh