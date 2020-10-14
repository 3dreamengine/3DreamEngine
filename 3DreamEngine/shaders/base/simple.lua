local sh = { }

sh.type = "base"

sh.meshType = "simple"

function sh:getTypeID(dream, mat)
	return (mat.tex_normal and 0 or 1) + (mat.tex_emission and 0 or 2)
end

function sh:constructDefines(dream, mat)
	local code = { }
	code[#code+1] = [[
		varying vec3 material;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute vec3 VertexMaterial;
		#endif
	]]
	
	return table.concat(code, "\n")
end

function sh:constructPixelPre(dream, mat)
	return [[
	vec4 albedo = VaryingColor;
	]]
end

function sh:constructPixel(dream, mat)
	return [[
	vec3 normal = normalRaw;
	]]
end

function sh:constructPixelPost(dream, mat)
	return [[
	vec3 reflectVec = reflect(-viewVec, normal); 
	vec3 diffuse = reflection(normal, 1.0);
	
	vec3 ref = reflection(reflectVec, 1.0 - material.x);
	col += (diffuse + ref * material.y) * albedo.rgb + material.z * albedo.rgb;
	]]
end

function sh:constructVertex(dream, mat)
	return [[
	//extract normal vector
	normalRawV = mat3(transform) * VertexTexCoord.xyz;
	
	//extract material
	material = VertexMaterial;
	]]
end

function sh:constructLightFunction(dream, mat)
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

function sh:perShader(dream, shaderObject)
	
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)

end

return sh