local sh = { }

sh.type = "base"

sh.meshType = "textured"
sh.splitMaterials = true
sh.requireTangents = true

function sh:getTypeID(dream, mat)
	return (mat.tex_normal and 0 or 1) + (mat.tex_emission and 0 or 2)
end

function sh:constructDefines(dream, mat)
	local code = { }
	if mat.tex_normal then
		code[#code+1] = "#define TEX_NORMAL"
		code[#code+1] = "varying mat3 TBN;"
	end
	if mat.tex_emission then
		code[#code+1] = "#define TEX_EMISSION"
	end
	
	code[#code+1] = [[
		extern vec4 color_albedo;
		
		#ifdef PIXEL
		extern Image tex_albedo;
		extern Image tex_material;
		extern vec3 color_material;
		extern Image tex_emission;
		extern vec3 color_emission;
		extern Image tex_normal;
		#endif
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute vec3 VertexNormal;
		attribute vec4 VertexTangent;
		#endif
	]]
	
	return table.concat(code, "\n")
end

function sh:constructPixelPre(dream, mat)
	return [[
	vec4 albedo = Texel(tex_albedo, VaryingTexCoord.xy) * VaryingColor;
	]]
end

function sh:constructPixel(dream, mat)
	return [[
	//transform normal to world space
	#ifdef TEX_NORMAL
		vec3 normal = normalize(TBN * (Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
	#else
		vec3 normal = normalRaw;
	#endif
	
	//fetch material data
	vec3 material = Texel(tex_material, VaryingTexCoord.xy).rgb * color_material;
	
	//emission
	#ifdef TEX_EMISSION
		vec3 emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
	#else
		vec3 emission = color_emission;
	#endif
	]]
end

function sh:constructPixelPost(dream, mat)
	return [[
	vec3 reflectVec = reflect(-viewVec, normal); 
	
	//ambient component
	vec3 diffuse = reflection(normal, 1.0);
	
	//final ambient color and reflection
	vec3 ref = reflection(reflectVec, 1.0 - material.x);
	col += (diffuse + ref * material.y) * albedo.rgb * material.z;
	
	//emission
	col += emission;
	]]
end

function sh:constructVertex(dream, mat)
	return [[
	//transform from tangential space into world space
#ifdef INSTANCES
	mat3 normalTransform = mat3(transforms[love_InstanceID]);
#else
	mat3 normalTransform = mat3(transform);
#endif
	
	//raw normal vector without normal map;
	normalRawV = normalTransform * (VertexNormal - 0.5);
	
	#ifdef TEX_NORMAL
		vec3 T = normalize(normalTransform * (VertexTangent.xyz - 0.5));
		vec3 N = normalize(normalRawV);
		
		vec3 B;
		if (VertexTangent.w > 0.5) {
			B = cross(T, N);
		} else {
			B = cross(N, T);
		}
		
		TBN = mat3(T, B, N);
	#endif
	
	//color
	VaryingColor = color_albedo * ConstantColor;
	]]
end

function sh:constructLightFunction(dream, mat)
	return [[
	//the PBR model is darker than the Phong shading, to use the same light intensities the Phong shading will be adapted
	const float adaptToPBR = 0.25;

	vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float specular, float glossiness) {
		#ifdef TRANSLUCENT_ENABLED
			if (dot(normal, lightVec) < 0.0) {
				lightVec = -lightVec;
				lightColor *= translucent;
			}
		#endif
		
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
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	shader:send("tex_albedo", dream:getTexture(material.tex_albedo) or tex.default)
	shader:send("color_albedo", material.color)
	
	shader:send("tex_material", dream:getTexture(material.tex_material) or tex.default)
	shader:send("color_material", {material.glossiness, material.specular, 1.0})
	
	if shader:hasUniform("tex_normal") then
		shader:send("tex_normal", dream:getTexture(material.tex_normal) or tex.default_normal)
	end
	
	if material.tex_emission then
		shader:send("tex_emission", dream:getTexture(material.tex_emission) or tex.default)
	end
	if shader:hasUniform("color_emission") then
		shader:send("color_emission", material.emission)
	end
end

function sh:perTask(dream, shaderObject, task)

end

return sh