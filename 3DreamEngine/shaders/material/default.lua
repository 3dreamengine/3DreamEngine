local sh = { }

--todo
sh.type = "material"

sh.meshType = "textured"
sh.splitMaterials = true
sh.requireTangents = true

function sh:getPixelId(dream, mat)
	return (mat.tex_normal and 1 or 0)^1 + (mat.tex_emission and 1 or 0)^2
end

--todo
function sh:getVertexId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat)
	return [[
		varying mat3 TBN;
		
		]] .. (mat.tex_normal and "#define TEX_NORMAL\n" or "") .. [[
		]] .. (mat.tex_emission and "#define TEX_EMISSION\n" or "") .. [[
		]] .. (mat.tex_material and "#define TEX_MATERIAL\n" or "") .. [[
		
		#ifdef PIXEL
		extern Image tex_albedo;
		extern vec4 color_albedo;
		
		#ifdef TEX_MATERIAL
		extern Image tex_material;
		#else
		extern vec2 color_material;
		#endif
		
		#ifdef TEX_NORMAL
		extern Image tex_normal;
		#endif
		
		#ifdef TEX_EMISSION
		extern Image tex_emission;
		#endif
		extern vec3 color_emission;
		
		#endif
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute vec3 VertexNormal;
		attribute vec4 VertexTangent;
		#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
	//color
	vec4 c = Texel(tex_albedo, VaryingTexCoord.xy) * color_albedo;
	albedo = c.rgb;
	alpha = c.a;
	
	//material
#ifdef TEX_MATERIAL
	vec3 material = Texel(tex_material, VaryingTexCoord.xy).xyz;
	roughness = material.x;
	metallic = material.y;
	ao = material.z;
#else
	roughness = color_material.x;
	metallic = color_material.y;
#endif
	
	//emission
#ifdef TEX_EMISSION
	emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
#else
	emission = color * color_emission;
#endif

	//normal
#ifdef TEX_NORMAL
	vec3 normal = Texel(tex_normal, VaryingTexCoord.xy) * vec2(2.0) - vec2(1.0);
	normal = normalize(TBN * normal);
#else
	normal = normalize(vertexNormal);
#endif
	]]
end

function sh:buildVertex(dream, mat)
	return [[
	vertexPos = (transform * vec4(VertexPosition.xyz, 1.0)).rgb;
	]]
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	shader:send("tex_albedo", dream:getImage(material.tex_albedo) or tex.default)
	shader:send("color_albedo", material.color)
	
	if shader:hasUniform("tex_material") then
		shader:send("tex_material", dream:getImage(material.tex_material) or tex.default)
	else
		shader:send("color_material", {material.roughness, material.metallic})
	end
	
	if shader:hasUniform("tex_normal") then
		shader:send("tex_normal", dream:getImage(material.tex_normal) or tex.default_normal)
	end
	
	if material.tex_emission then
		shader:send("tex_emission", dream:getImage(material.tex_emission) or tex.default)
	end
	
	--shader:send("color_emission", material.emission)
end

function sh:perTask(dream, shaderObject, task)

end

return sh