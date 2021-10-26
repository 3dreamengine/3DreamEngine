local sh = { }

sh.type = "pixel"

sh.meshType = "textured"

function sh:getId(dream, mat, shadow)
	if shadow then
		return (mat.discard and 1 or 0)
	else
		return (mat.tex_normal and 1 or 0) * 2^1 + (mat.tex_emission and 1 or 0) * 2^2 + (mat.discard and not mat.dither and 1 or 0) * 2^3 + (mat.dither and 1 or 0) * 2^4
	end
end

function sh:initObject(dream, obj)
	if obj.mesh then
		if not obj.uv2Mesh and not obj.meshes then
			assert(obj.colors, "To use the multiTetxure module at least a second UV map for the mask texture is required.")
			obj.uv2Mesh = love.graphics.newMesh({
				{"VertexBlend", "float", 1},
				{"VertexTexCoord_2", "float", 2},
			}, #obj.colors, "triangles", "static")
			
			--create mesh
			local scale = obj.texCoords2 and 1.0 or (obj.multiTextureUV2Scale or 1.0)
			for d,c in ipairs(obj.colors) do
				local uv = (obj.texCoords2 or obj.texCoords)[d]
				obj.uv2Mesh:setVertex(d, c[obj.multiTextureColorChannel or 1], uv[1] * scale, uv[2] * scale)
			end
		end
		
		if obj.uv2Mesh then
			obj:getMesh("mesh"):attachAttribute("VertexBlend", obj:getMesh("uv2Mesh"))
			obj:getMesh("mesh"):attachAttribute("VertexTexCoord_2", obj:getMesh("uv2Mesh"))
		end
	end
end

function sh:buildDefines(dream, mat, shadow)
	return [[
		]] .. (mat.tex_normal and "#define TEX_NORMAL\n" or "") .. [[
		]] .. (mat.tex_normal and "#define TANGENT\n" or "") .. [[
		
		]] .. (mat.tex_emission and "#define TEX_EMISSION\n" or "") .. [[
		]] .. (mat.tex_material and "#define TEX_MATERIAL\n" or "") .. [[
		
		]] .. ((not shadow and (mat.discard and not mat.dither) or shadow and mat.discard) and "#define DISCARD\n" or "") .. [[
		]] .. ((not shadow and mat.dither) and "#define DITHER\n" or "") .. [[
		
		#ifdef PIXEL
		extern Image tex_blend;
		extern float multiTextureBlendScale;
		
		extern Image tex_albedo_1;
		extern Image tex_albedo_2;
		extern vec4 color_albedo_1;
		extern vec4 color_albedo_2;
		
		#ifdef TEX_MATERIAL
		extern Image tex_material_1;
		extern Image tex_material_2;
		#endif
		extern vec2 color_material_1;
		extern vec2 color_material_2;
		
		#ifdef TEX_NORMAL
		extern Image tex_normal_1;
		extern Image tex_normal_2;
		#endif
		
		#ifdef TEX_EMISSION
		extern Image tex_emission_1;
		extern Image tex_emission_2;
		#endif
		extern vec3 color_emission_1;
		extern vec3 color_emission_2;
		
		#endif
		
		varying vec2 VaryingTexCoord_2;
		varying float VaryingBlend;
		
		#ifdef VERTEX
		attribute vec2 VertexTexCoord_2;
		attribute float VertexBlend;
		#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
	//blending
	float blend = clamp(VaryingBlend * 2.0 - 0.5 + Texel(tex_blend, VaryingTexCoord.xy * multiTextureBlendScale).r * 0.5, 0.0, 1.0);
	
	//color
	vec4 c = mix(
		Texel(tex_albedo_1, VaryingTexCoord.xy) * color_albedo_1,
		Texel(tex_albedo_2, VaryingTexCoord_2.xy) * color_albedo_2,
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
#ifdef TEX_MATERIAL
	vec3 material = mix(
		Texel(tex_material_1, VaryingTexCoord.xy).xyz * vec3(color_material_1.xy, 1.0),
		Texel(tex_material_2, VaryingTexCoord_2.xy).xyz * vec3(color_material_2.xy, 1.0),
		blend
	);
	
	roughness = material.x;
	metallic = material.y;
	ao = material.z;
#else
	roughness = mix(color_material_1.x, color_material_2.x, blend);
	metallic = mix(color_material_1.y, color_material_2.y, blend);
#endif
	
	//emission
#ifdef TEX_EMISSION
	emission = mix(
		Texel(tex_emission_1, VaryingTexCoord.xy).rgb * color_emission_1,
		Texel(tex_emission_2, VaryingTexCoord_2.xy).rgb * color_emission_2,
		blend
	);
#else
	emission = mix(
		color_albedo_1.rgb * color_emission_1,
		color_albedo_2.rgb * color_emission_2,
		blend
	);
#endif

	//normal
#ifdef TEX_NORMAL
	normal = mix(
		Texel(tex_normal_1, VaryingTexCoord.xy).xyz,
		Texel(tex_normal_2, VaryingTexCoord_2.xy).xyz,
		blend
	) * 2.0 - 1.0;
	normal = normalize(TBN * normal);
#else
	normal = normalize(VaryingNormal);
#endif
	]]
end

function sh:buildVertex(dream, mat)
	return [[
	VaryingTexCoord_2 = VertexTexCoord_2;
	VaryingBlend = VertexBlend;
	]]
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	local material_2 = material.material_2
	assert(material_2, "materials with multiTexture shader requires a field 'material_2' with a second material")
	
	shader:send("tex_albedo_1", dream:getImage(material.tex_albedo) or tex.default)
	shader:send("tex_albedo_2", dream:getImage(material_2.tex_albedo) or tex.default)
	shader:send("color_albedo_1", material.color)
	shader:send("color_albedo_2", material_2.color)
	
	shader:send("tex_blend", dream:getImage(material.tex_blend) or tex.default)
	shader:send("multiTextureBlendScale", material.multiTextureBlendScale or 3.7)
	
	if shader:hasUniform("tex_material_1") then
		shader:send("tex_material_1", dream:getImage(material.tex_material) or tex.default)
		shader:send("tex_material_2", dream:getImage(material_2.tex_material) or tex.default)
	end
	shader:send("color_material_1", {material.roughness, material.metallic})
	shader:send("color_material_2", {material_2.roughness, material_2.metallic})
	
	if shader:hasUniform("tex_normal_1") then
		shader:send("tex_normal_1", dream:getImage(material.tex_normal) or tex.default_normal)
		shader:send("tex_normal_2", dream:getImage(material_2.tex_normal) or tex.default_normal)
	end
	
	if shader:hasUniform("tex_emission_1") then
		shader:send("tex_emission_1", dream:getImage(material.tex_emission) or tex.default)
		shader:send("tex_emission_2", dream:getImage(material_2.tex_emission) or tex.default)
	end
	
	shader:send("color_emission_1", material.emission)
	shader:send("color_emission_2", material_2.emission)
end

function sh:perTask(dream, shaderObject, task)

end

return sh