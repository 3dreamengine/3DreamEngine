local sh = { }

sh.type = "base"

function sh:getShaderInfoID(dream, mat, shaderType)
	return (mat.tex_normal and 0 or 1) + (mat.tex_emission and 0 or 2)
end

function sh:getShaderInfo(dream, mat, shaderType)
	return {
		tex_normal = mat.tex_normal ~= nil,
		tex_emission = mat.tex_emission ~= nil,
	}
end

function sh:constructDefines(dream, info)
	local code = { }
	code[#code+1] = [[
		varying float specular;
		varying float glossiness;
		varying float emission;
		
		varying vec3 normalVec;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute float VertexMaterial;
		extern Image tex_lookup;
		#endif
	]]
	
	return table.concat(code, "\n")
end

function sh:constructPixelPre(dream, info)
	return [[
	vec4 albedo = VaryingColor;
	float alpha = albedo.a;
	]]
end

function sh:constructPixel(dream, info)
	return [[
	vec3 normal = normalize(normalVec);
	]]
end

function sh:constructPixelPost(dream, info)
	return [[
	highp vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 reflectVec = reflect(-viewVec, normal); 
	vec3 diffuse = reflection(normal, 1.0);
	
	vec3 ref = reflection(reflectVec, 1.0 - glossiness);
	vec3 col = (diffuse + ref * specular) * albedo.rgb;
	
	col += emission * albedo.rgb;
	]]
end

function sh:constructVertex(dream, info)
	return [[
	//extract normal vector
	normalVec = mat3(transform) * VertexTexCoord.xyz;
	
	//get color
	VaryingColor = Texel(tex_lookup, vec2(VertexMaterial, 0.0)) * ConstantColor;
	
	//extract material
	vec3 mat = Texel(tex_lookup, vec2(VertexMaterial, 1.0)).rgb;
	specular = mat.r;
	glossiness = mat.g;
	emission = mat.b;
	]]
end

function sh:getLightSignature(dream)
	return "albedo.rgb, specular, glossiness"
end

function sh:perShader(dream, shader, info)
	
end

function sh:perMaterial(dream, shader, info, material)
	shader:send("tex_lookup", dream:getTexture(material.tex_lookup) or dream.textures.default)
end

function sh:perObject(dream, hader, info, task)

end

return sh