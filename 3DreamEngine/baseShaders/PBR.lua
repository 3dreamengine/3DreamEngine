local sh = { }

function sh:getShaderInfoID(dream, mat, shaderType, reflection)
	return ((reflection or dream.sky_enabled) and 0 or 1) + (mat.tex_normal and 0 or 2) + (mat.tex_emission and 0 or 4)
end

function sh:getShaderInfo(dream, mat, shaderType, reflection)
	return {
		tex_normal = mat.tex_normal ~= nil,
		tex_emission = mat.tex_emission ~= nil,
		
		shaderType = shaderType,
		vertexShader = vertexShader,
		reflection = reflection or dream.sky_enabled,
	}
end

function sh:constructDefines(dream, info)
	local code = { }
	if info.tex_normal then
		code[#code+1] = "#define TEX_NORMAL"
		code[#code+1] = "varying mat3 objToWorldSpace;"
	else
		code[#code+1] = "varying vec3 normalV;"
	end
	if info.tex_emission then
		code[#code+1] = "#define TEX_EMISSION"
	end
	
	code[#code+1] = [[
		extern vec4 color_albedo;
		
		#ifdef PIXEL
		extern Image brdfLUT;
		
		extern Image tex_albedo;
		extern Image tex_combined;
		extern vec3 color_combined;
		extern Image tex_emission;
		extern vec3 color_emission;
		extern Image tex_normal;
		#endif
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute highp vec3 VertexNormal;
		attribute highp vec3 VertexTangent;
		attribute highp vec3 VertexBiTangent;
		#endif
	]]
	
	return table.concat(code, "\n")
end

function sh:constructPixelPre(dream, info)
	return [[
	vec4 albedo = Texel(tex_albedo, VaryingTexCoord.xy) * VaryingColor;
	float alpha = albedo.a;
	]]
end

function sh:constructPixel(dream, info)
	return [[
	//transform normal to world space
	#ifdef TEX_NORMAL
		vec3 normal = normalize(objToWorldSpace * normalize(Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
	#else
		vec3 normal = normalize(normalV);
	#endif
	
	//fetch material data
	vec3 rma = Texel(tex_combined, VaryingTexCoord.xy).rgb * color_combined;
	float roughness = rma.r;
	float metallic = rma.g;
	float ao = rma.b;
	
	//emission
	#ifdef TEX_EMISSION
		vec3 emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
	#else
		vec3 emission = color_emission;
	#endif
	
	//PBR model data
	vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 reflectVec = reflect(-viewVec, normal); 
	float cosTheta = clamp(dot(normal, viewVec), 0.0, 1.0);
	vec3 F0 = mix(vec3(0.04), albedo.rgb, metallic);
	
	//fresnel
    vec3 F = F0 + (vec3(1.0) - F0) * pow(1.0 - cosTheta, 5.0);
    
	//specular and diffuse component
    vec3 kS = F;
    vec3 kD = (1.0 - kS) * (1.0 - metallic);
    
	//use the reflection texture as irradiance map approximation
    vec3 diffuse = reflection(normal, 1.0) * albedo.rgb;
	
	//final ambient color, screen space reflection disables reflections
	#ifdef SSR_ENABLED
		vec3 col = (kD * diffuse) * ao;
	#else
		//approximate the specular part with brdf lookup table
		vec3 ref = reflection(reflectVec, roughness);
		vec2 brdf = Texel(brdfLUT, vec2(cosTheta, roughness)).rg;
		vec3 specular = ref * (F * brdf.x + vec3(brdf.y));
		
		vec3 col = (kD * diffuse + specular) * ao;
	#endif
	
	//emission
	col += emission;
	]]
end

function sh:constructVertex(dream, info)
	return [[
	//transform from tangential space into world space
	mat3 normalTransform = mat3(transform);
	#ifdef TEX_NORMAL
		vec3 T = normalize(normalTransform * (VertexTangent*2.0-1.0));
		vec3 N = normalize(normalTransform * (VertexNormal*2.0-1.0));
		vec3 B = normalize(normalTransform * (VertexBiTangent*2.0-1.0));
		
		objToWorldSpace = mat3(T, B, N);
	#else
		normalV = normalTransform * (VertexNormal*2.0-1.0);
	#endif
	
	//color
	VaryingColor = color_albedo * ConstantColor;
	]]
end

function sh:getLightSignature(dream)
	return "albedo.rgb, roughness, metallic"
end

function sh:perShader(dream, shader, info)
	shader:send("brdfLUT", dream.textures.brdfLUT)
end

function sh:perMaterial(dream, shader, info, material)
	local tex = dream.textures
	
	shader:send("tex_albedo", dream:getTexture(material.tex_albedo) or tex.default)
	shader:send("color_albedo", (material.tex_albedo and {1.0, 1.0, 1.0, 1.0} or material.color and {material.color[1], material.color[2], material.color[3], material.color[4] or 1.0} or {1.0, 1.0, 1.0, 1.0}))
	
	shader:send("tex_combined", dream:getTexture(material.tex_combined) or tex.default)
	shader:send("color_combined", {material.tex_roughness and 1.0 or material.roughness or 0.5, material.tex_metallic and 1.0 or material.metallic or 0.5, 1.0})
	
	if info.tex_normal then
		shader:send("tex_normal", dream:getTexture(material.tex_normal) or tex.default_normal)
	end
	
	if info.tex_emission then
		shader:send("tex_emission", dream:getTexture(material.tex_emission) or tex.default)
	end
	shader:send("color_emission", material.emission or (info.tex_emission and {5.0, 5.0, 5.0}) or {0.0, 0.0, 0.0})
end

function sh:perObject(dream, shader, info, task)

end

return sh