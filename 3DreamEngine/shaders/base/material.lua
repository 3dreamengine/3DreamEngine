local sh = { }

sh.type = "base"

sh.meshType = "material"

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
		varying vec3 material;
		
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
	]]
end

function sh:constructPixel(dream, info)
	return [[
	vec3 normal = normalRaw;
	]]
end

function sh:constructPixelPost(dream, info)
	return [[
	vec3 reflectVec = reflect(-viewVec, normal); 
	vec3 diffuse = reflection(normal, 1.0);
	
	vec3 ref = reflection(reflectVec, 1.0 - material.x);
	vec3 col = (diffuse + ref * material.y) * albedo.rgb + material.z * albedo.rgb;
	]]
end

function sh:constructVertex(dream, info)
	return [[
	//extract normal vector
	normalRawV = mat3(transform) * VertexTexCoord.xyz;
	
	//get color
	VaryingColor = Texel(tex_lookup, vec2(VertexMaterial, 0.0)) * ConstantColor;
	
	//extract material
	material = Texel(tex_lookup, vec2(VertexMaterial, 1.0)).rgb;
	]]
end

function sh:constructLightFunction(dream, info)
	return [[
	//the PBR model is darker than the Phong shading, the use the same light intensities the Phong shading will be adapted
	const float adaptToPBR = 0.25;

	vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float specular, float glossiness) {
		float lambertian = max(dot(lightVec, normal), 0.0);
		float spec = 0.0;
		
		if (lambertian > 0.0) {
			vec3 halfDir = normalize(lightVec + viewVec);
			float specAngle = max(dot(halfDir, normal), 0.0);
			spec = specular * pow(specAngle, 1.0 + glossiness * 256.0);
		}
		
		return albedo * lightColor * (lambertian + spec) * adaptToPBR;
	}
	]]
end

function sh:perShader(dream, shader, info)
	
end

function sh:perMaterial(dream, shader, info, material)
	shader:send("tex_lookup", dream:getTexture(material.tex_lookup) or dream.textures.default)
end

function sh:perObject(dream, hader, info, task)

end

return sh