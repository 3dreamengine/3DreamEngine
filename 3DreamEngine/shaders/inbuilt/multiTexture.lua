local dream = _3DreamEngine

local sh = { }

sh.type = "pixel"

sh.meshFormat = "textured"

function sh:getId(mat, shadow)
	if shadow then
		return (mat.discard and 1 or 0)
	else
		return (mat.normalTexture and 1 or 0) * 2 ^ 1 + (mat.emissionTexture and 1 or 0) * 2 ^ 2 + (mat.discard and not mat.dither and 1 or 0) * 2 ^ 3 + (mat.dither and 1 or 0) * 2 ^ 4
	end
end

function sh:initMesh(mesh)
	if not mesh:getMesh("uv2Mesh") then
		assert(mesh.colors, "To use the multiTetxure shader the color buffer should contain the blending factor.")
		mesh.uv2Mesh = love.graphics.newMesh({
			{ "VertexBlend", "float", 1 },
			{ "VertexTexCoord2", "float", 2 },
		}, #mesh.colors, "triangles", "static")
		
		--create mesh
		local scale = mesh.texCoords2 and 1.0 or (mesh.multiTextureUV2Scale or 1.0)
		for d, c in ipairs(mesh.colors) do
			local uv = (mesh.texCoords2 or mesh.texCoords)[d]
			mesh.uv2Mesh:setVertex(d, c[mesh.multiTextureColorChannel or 1], uv[1] * scale, uv[2] * scale)
		end
	end
	
	mesh:getMesh():attachAttribute("VertexBlend", mesh:getMesh("uv2Mesh"))
	mesh:getMesh():attachAttribute("VertexTexCoord2", mesh:getMesh("uv2Mesh"))
end

function sh:buildDefines(mat, shadow)
	return [[
		]] .. (mat.normalTexture and "#define NORMAL_TEXTURE\n" or "") .. [[
		]] .. (mat.normalTexture and "#define TANGENT\n" or "") .. [[
		
		]] .. (mat.emissionTexture and "#define EMISSION_TEXTURE\n" or "") .. [[
		]] .. (mat.materialTexture and "#define MATERIAL_TEXTURE\n" or "") .. [[
		
		]] .. ((not shadow and (mat.discard and not mat.dither) or shadow and mat.discard) and "#define DISCARD\n" or "") .. [[
		]] .. ((not shadow and mat.dither) and "#define DITHER\n" or "") .. [[
		
		#ifdef PIXEL
		extern Image blendTexture;
		extern float multiTextureBlendScale;
		
		extern Image albedoTexture1;
		extern Image albedoTexture2;
		extern vec4 albedoColor1;
		extern vec4 albedoColor2;
		
		#ifdef MATERIAL_TEXTURE
		extern Image materialTexture1;
		extern Image materialTexture2;
		#endif
		extern vec2 materialColor1;
		extern vec2 materialColor2;
		
		#ifdef NORMAL_TEXTURE
		extern Image normalTexture1;
		extern Image normalTexture2;
		#endif
		
		#ifdef EMISSION_TEXTURE
		extern Image emissionTexture1;
		extern Image emissionTexture2;
		#endif
		extern vec3 emissionColor1;
		extern vec3 emissionColor2;
		
		#endif
		
		varying vec2 VaryingTexCoord2;
		varying float VaryingBlend;
		
		#ifdef VERTEX
		attribute vec2 VertexTexCoord2;
		attribute float VertexBlend;
		#endif
	]]
end

function sh:buildPixel(mat)
	return [[
	//blending
	float blend = clamp(VaryingBlend * 2.0 - 0.5 + Texel(blendTexture, VaryingTexCoord.xy * multiTextureBlendScale).r * 0.5, 0.0, 1.0);
	
	//color
	vec4 c = mix(
		gammaCorrectedTexel(albedoTexture1, VaryingTexCoord.xy) * albedoColor1,
		gammaCorrectedTexel(albedoTexture2, VaryingTexCoord2.xy) * albedoColor2,
		blend
	);
	albedo = c.rgb;
	alpha = c.a;
	
#ifdef DISCARD
	if (alpha < 0.5) {
		discard;
	}
#endif

#ifdef DITHER
	if (alpha < fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73)) {
		discard;
	}
#endif

#ifndef ALPHA_PASS
	alpha = 1.0;
#endif
	
	//material
#ifdef MATERIAL_TEXTURE
	vec3 material = mix(
		Texel(materialTexture1, VaryingTexCoord.xy).xyz * vec3(materialColor1.xy, 1.0),
		Texel(materialTexture2, VaryingTexCoord2.xy).xyz * vec3(materialColor2.xy, 1.0),
		blend
	);
	
	metallic = material.x;
	roughness = material.y;
	ao = material.z;
#else
	metallic = mix(materialColor1.x, materialColor2.x, blend);
	roughness = mix(materialColor1.y, materialColor2.y, blend);
#endif
	
	//emission
#ifdef EMISSION_TEXTURE
	emission = mix(
		gammaCorrectedTexel(emissionTexture1, VaryingTexCoord.xy).rgb * emissionColor1,
		gammaCorrectedTexel(emissionTexture2, VaryingTexCoord2.xy).rgb * emissionColor2,
		blend
	);
#else
	emission = mix(
		albedoColor1.rgb * emissionColor1,
		albedoColor2.rgb * emissionColor2,
		blend
	);
#endif

	//normal
#ifdef NORMAL_TEXTURE
	normal = mix(
		Texel(normalTexture1, VaryingTexCoord.xy).xyz,
		Texel(normalTexture2, VaryingTexCoord2.xy).xyz,
		blend
	) * 2.0 - 1.0;
	normal = normalize(TBN * normal);
#else
	normal = normalize(varyingNormal);
#endif
	]]
end

function sh:buildVertex(mat)
	return [[
	VaryingTexCoord2 = VertexTexCoord2;
	VaryingBlend = VertexBlend;
	]]
end

function sh:perShader(shaderObject)

end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	local material2 = material.material2
	assert(material2, "materials with multiTexture shader requires a field 'material2' with a second material")
	
	shader:send("albedoTexture1", dream:getImage(material.albedoTexture) or tex.default)
	shader:send("albedoTexture2", dream:getImage(material2.albedoTexture) or tex.default)
	shader:send("albedoColor1", material.color)
	shader:send("albedoColor2", material2.color)
	
	shader:send("blendTexture", dream:getImage(material.blendTexture) or tex.default)
	shader:send("multiTextureBlendScale", material.multiTextureBlendScale or 3.7)
	
	if shader:hasUniform("materialTexture1") then
		shader:send("materialTexture1", dream:getImage(material.materialTexture) or tex.default)
		shader:send("materialTexture2", dream:getImage(material2.materialTexture) or tex.default)
	end
	shader:send("materialColor1", { material.metallic, material.roughness })
	shader:send("materialColor2", { material2.metallic, material2.roughness })
	
	if shader:hasUniform("normalTexture1") then
		shader:send("normalTexture1", dream:getImage(material.normalTexture) or tex.defaultNormal)
		shader:send("normalTexture2", dream:getImage(material2.normalTexture) or tex.defaultNormal)
	end
	
	if shader:hasUniform("emissionTexture1") then
		shader:send("emissionTexture1", dream:getImage(material.emissionTexture) or tex.default)
		shader:send("emissionTexture2", dream:getImage(material2.emissionTexture) or tex.default)
	end
	
	shader:send("emissionColor1", material.emission)
	shader:send("emissionColor2", material2.emission)
end

function sh:perTask(shaderObject, task)

end

return sh