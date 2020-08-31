local sh = { }

sh.type = "base"

sh.meshType = "textured"
sh.splitMaterials = true
sh.requireTangents = true

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
	if info.tex_normal then
		code[#code+1] = "#define TEX_NORMAL"
		code[#code+1] = "varying mat3 TNB;"
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
		vec3 normal = normalize(TNB * normalize(Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
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
	]]
end

function sh:constructPixelPost(dream, info)
	return [[
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
	
	//final ambient color with reflection
	//approximate the specular part with brdf lookup table
	vec3 ref = reflection(reflectVec, roughness);
	vec2 brdf = Texel(brdfLUT, vec2(cosTheta, roughness)).rg;
	vec3 specular = ref * (F * brdf.x + vec3(brdf.y));
	
	vec3 col = (kD * diffuse + specular) * ao;
	
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
		vec3 B = cross(N, T);
		
		TNB = mat3(T, B, N);
	#else
		normalV = normalTransform * (VertexNormal*2.0-1.0);
	#endif
	
	//color
	VaryingColor = color_albedo * ConstantColor;
	]]
end

function sh:constructLightFunction(dream, info)
	return [[
	//part of the 3DreamEngine by Luke100000
	//PBR lighting shader, expects metallness + roughness workflow

	const float pi = 3.14159265359;
	const float ipi = 0.31830988618;

	float DistributionGGX(vec3 normal, vec3 halfView, float roughness) {
		float a = pow(roughness, 4.0);
		
		float NdotH = max(dot(normal, halfView), 0.0);
		float NdotH2 = NdotH * NdotH;
		
		float denom = NdotH2 * (a - 1.0) + 1.0;
		denom = pi * denom * denom;
		
		return a / max(denom, 0.01);
	}

	float GeometrySchlickGGX(float NdotV, float roughness) {
		float r = roughness + 1.0;
		float k = (r * r) * 0.125;
		float denom = NdotV * (1.0 - k) + k;
		return NdotV / denom;
	}

	float GeometrySmith(vec3 normal, vec3 view, vec3 light, float roughness) {
		float NdotV = max(dot(normal, view), 0.0);
		float NdotL = max(dot(normal, light), 0.0);
		float ggx2 = GeometrySchlickGGX(NdotV, roughness);
		float ggx1 = GeometrySchlickGGX(NdotL, roughness);
		return ggx1 * ggx2;
	}

	vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float roughness, float metallic) {
		//reflectance
		vec3 F0 = mix(vec3(0.04), albedo, metallic);
		
		vec3 halfVec = normalize(viewVec + lightVec);
		
		float NDF = DistributionGGX(normal, halfVec, roughness);   
		float G = GeometrySmith(normal, viewVec, lightVec, roughness);
		
		//fresnel
		float cosTheta = clamp(dot(halfVec, viewVec), 0.0, 1.0);
		vec3 fresnel = F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
		
		//specular
		vec3 nominator = NDF * G * fresnel;
		float denominator = 4.0 * max(dot(normal, viewVec), 0.0) * max(dot(normal, lightVec), 0.0) + 0.001;
		vec3 specular = nominator / denominator;
		
		//energy conservation
		vec3 kD = (vec3(1.0) - fresnel) * (1.0 - metallic);
		
		float lightAngle = max(dot(lightVec, normal), 0.0);
		return (kD * albedo * ipi + specular) * lightColor * lightAngle;
	}
	]]
end

function sh:getLightSignature(dream)
	return "albedo.rgb, roughness, metallic"
end

function sh:perShader(dream, shader, info)
	shader:send("brdfLUT", dream.textures:get("brdfLUT"))
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