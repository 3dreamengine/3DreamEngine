local sh = { }

sh.type = "pixel"

sh.meshType = "textured"

function sh:getId(dream, mat, shadow)
	if shadow then
		return 0
	else
		return (mat.normalTexture and 1 or 0) * 2^1 + (mat.emissionTexture and 1 or 0) * 2^2
	end
end

function sh:buildDefines(dream, mat, shadow)
	return [[
		]] .. (mat.normalTexture and "#define NORMAL_TEXTURE\n" or "") .. [[
		]] .. (mat.normalTexture and "#define TANGENT\n" or "") .. [[
		
		]] .. (mat.emissionTexture and "#define EMISSION_TEXTURE\n" or "") .. [[
		]] .. (mat.materialTexture and "#define MATERIAL_TEXTURE\n" or "") .. [[
		
		#ifdef PIXEL
		extern Image albedoTexture;
		extern vec4 albedoColor;
		
		#ifdef MATERIAL_TEXTURE
		extern Image materialTexture;
		#endif
		extern vec2 materialColor;
		
		#ifdef NORMAL_TEXTURE
		extern Image normalTexture;
		#endif
		
		#ifdef EMISSION_TEXTURE
		extern Image emissionTexture;
		#endif
		extern vec3 emissionColor;
		
		#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
	//color
	vec4 c = gammaCorrectedTexel(albedoTexture, VaryingTexCoord.xy) * albedoColor;
	albedo = c.rgb;
	alpha = c.a;
	
	//material
#ifdef MATERIAL_TEXTURE
	vec3 material = Texel(materialTexture, VaryingTexCoord.xy).xyz;
	roughness = material.x * materialColor.x;
	metallic = material.y * materialColor.y;
	ao = material.z;
#else
	roughness = materialColor.x;
	metallic = materialColor.y;
#endif
	
	//emission
#ifdef EMISSION_TEXTURE
	emission = gammaCorrectedTexel(emissionTexture, VaryingTexCoord.xy).rgb * emissionColor;
#else
	emission = albedoColor.rgb * emissionColor;
#endif

	//normal
#ifdef NORMAL_TEXTURE
	normal = Texel(normalTexture, VaryingTexCoord.xy).xyz * vec3(2.0) - vec3(1.0);
	normal = normalize(TBN * normal);
#else
	normal = normalize(varyingNormal);
#endif
	]]
end

function sh:buildVertex(dream, mat)
	return ""
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	shader:send("albedoTexture", dream:getImage(material.albedoTexture) or tex.default)
	shader:send("albedoColor", material.color)
	
	if shader:hasUniform("materialTexture") then
		shader:send("materialTexture", dream:getImage(material.materialTexture) or tex.default)
	end
	shader:send("materialColor", {material.roughness, material.metallic})
	
	if shader:hasUniform("normalTexture") then
		shader:send("normalTexture", dream:getImage(material.normalTexture) or tex.defaultNormal)
	end
	
	if shader:hasUniform("emissionTexture") then
		shader:send("emissionTexture", dream:getImage(material.emissionTexture) or tex.default)
	end
	
	shader:send("emissionColor", material.emission)
end

function sh:perTask(dream, shaderObject, task)

end

return sh