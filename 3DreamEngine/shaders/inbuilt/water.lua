local dream = _3DreamEngine

local sh = { }

sh.type = "pixel"

sh.meshFormat = "textured"

function sh:getId(mat, shadow)
	if shadow then
		return 0
	else
		return (mat.normalTexture and 1 or 0) * 2^1 + (mat.emissionTexture and 1 or 0) * 2^2
	end
end

function sh:buildDefines(mat, shadow)
	assert(mat.alpha, "water shader requires alpha pass set to true")
	assert(mat.normalTexture, "water shader requires a normal texture for wave movement")
	
	return [[
		]] .. (mat.normalTexture and "#define NORMAL_TEXTURE\n" or "") .. [[
		]] .. (mat.normalTexture and "#define TANGENT\n" or "") .. [[
		
		]] .. (mat.emissionTexture and "#define EMISSION_TEXTURE\n" or "") .. [[
		]] .. (mat.materialTexture and "#define MATERIAL_TEXTURE\n" or "") .. [[
		
		#define TANGENT
		
		//#ifdef PIXEL
		extern Image albedoTexture;
		extern vec4 albedoColor;
		
		#ifdef MATERIAL_TEXTURE
		extern Image materialTexture;
		#endif
		extern vec2 materialColor;
		
		extern Image normalTexture;
		
		#ifdef EMISSION_TEXTURE
		extern Image emissionTexture;
		#endif
		extern vec3 emissionColor;
		
		extern Image noiseTexture;
		
		extern float time;
		
		//water
		extern float waterSpeed;
		extern float waterScale;
		extern float waterHeight;
		extern float surfaceDistortion;
		
		extern float foamScale;
		extern float foamSpeed;
		
		extern vec3 liquidAlbedo;
		extern float liquidAlpha;
		extern vec3 liquidEmission;
		extern float liquidRoughness;
		extern float liquidMetallic;
		
		//#endif
	]]
end

function sh:buildPixel(mat)
	return [[
	//two moving UV coords for the wave normal
	vec2 waterUV = VaryingTexCoord.xy + vertexPos.xz;
	vec2 waterUV1 = waterUV + vec2(0.0, time * waterSpeed);
	vec2 waterUV2 = waterUV + vec2(time * waterSpeed, 0.0);
	
	//wave normal
	vec3 waterNormal = (
		Texel(normalTexture, waterUV1 * waterScale).rgb - vec3(0.5) +
		(Texel(normalTexture, waterUV2 * waterScale * 2.7).rgb - vec3(0.5)) * 0.5
	);
	normal = normalize(TBN * waterNormal * vec3(1.0, waterHeight, 1.0));
	
	//distorted final uvs
	vec2 uvd = vertexPos.xz + waterNormal.xz * surfaceDistortion;
	vec2 uvw = uvd * foamScale;
	
	//foam
#ifdef DEPTH_AVAILABLE
	float waterDepth = Texel(depthTexture, love_PixelCoord.xy / love_ScreenSize.xy).r - depth;
#else
	float waterDepth = 1.0f;;
#endif
	
	//two moving UV coords for the wave normal
	vec2 foamUV = VaryingTexCoord.xy + uvd;
	vec2 foamUV0 = foamUV + vec2(0.0, time * foamSpeed);
	vec2 foamUV1 = foamUV + vec2(time * foamSpeed, 0.0);
	
	float d0 = Texel(noiseTexture, foamUV0).r;
	float d1 = Texel(noiseTexture, foamUV1).b;
	float foamDensity = d0 + d1;
	float density = clamp(foamDensity - waterDepth * 4.0, 0.0, 1.0);
	
	//color
	vec4 c = gammaCorrectedTexel(albedoTexture, uvw) * albedoColor;
	albedo = mix(liquidAlbedo, c.rgb, density);
	alpha = mix(clamp(liquidAlpha, 0.0, 1.0), c.a, density);
	
	//material
#ifdef MATERIAL_TEXTURE
	vec3 material = Texel(materialTexture, uvw).xyz;
	metallic = mix(liquidMetallic, material.x * materialColor.x, density);
	roughness = mix(liquidRoughness, material.y * materialColor.y, density);
	ao = material.z;
#else
	metallic = mix(liquidMetallic, materialColor.x, density);
	roughness = mix(liquidRoughness, materialColor.y, density);
#endif
	
	//emission
	#ifdef EMISSION_TEXTURE
		emission = mix(liquidEmission, gammaCorrectedTexel(emissionTexture, uvw).rgb * emissionColor, density);
	#else
		emission = mix(liquidEmission, albedoColor.rgb * emissionColor, density);
	#endif
	]]
end

function sh:buildVertex(mat)
	return ""
end

function sh:perShader(shaderObject)
	local shader = shaderObject.shader
	shader:send("time", love.timer.getTime())
end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	shader:send("albedoTexture", dream:getImage(material.albedoTexture) or tex.default)
	shader:send("albedoColor", material.color)
	
	if shader:hasUniform("materialTexture") then
		shader:send("materialTexture", dream:getImage(material.materialTexture) or tex.default)
	end
	shader:send("materialColor", {material.metallic, material.roughness})
	
	shader:send("normalTexture", dream:getImage(material.normalTexture) or tex.defaultNormal)
	
	if shader:hasUniform("emissionTexture") then
		shader:send("emissionTexture", dream:getImage(material.emissionTexture) or tex.default)
	end
	
	shader:send("noiseTexture", dream.textures.foam)
	
	shader:send("emissionColor", material.emission)
	
	shader:send("waterScale", material.waterScale or (1 / 16))
	shader:send("waterSpeed", material.waterSpeed or 1)
	shader:send("waterHeight", 1 / (material.waterHeight or 2))
	shader:send("surfaceDistortion", material.surfaceDistortion or 1.0)
	
	shader:send("foamScale", material.foamScale or (1 / 8))
	shader:send("foamSpeed", material.foamSpeed or 0.1)
	
	shader:send("liquidAlbedo", material.liquidAlbedo or {0.5, 0.75, 1.0})
	shader:send("liquidAlpha", material.liquidAlpha or 0.2)
	shader:send("liquidEmission", material.liquidEmission or {0.0, 0.0, 0.0})
	shader:send("liquidRoughness", material.liquidRoughness or 0.0)
	shader:send("liquidMetallic", material.liquidMetallic or 1.0)
end

function sh:perTask(shaderObject, task)

end

return sh