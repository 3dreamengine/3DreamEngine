local sh = { }

sh.type = "pixel"

sh.meshType = "textured"
sh.splitMaterials = true

function sh:getId(dream, mat, shadow)
	if shadow then
		return 0
	else
		return (mat.tex_normal and 1 or 0) * 2^1 + (mat.tex_emission and 1 or 0) * 2^2
	end
end

function sh:buildDefines(dream, mat, shadow)
	assert(mat.alpha, "water shader requires alpha pass set to true")
	assert(mat.tex_normal, "water shader requires a normal texture for wave movement")
	assert(mat.tex_caustics, "water shader requires a caustics texture")
	
	return [[
		]] .. (mat.tex_normal and "#define TEX_NORMAL\n" or "") .. [[
		]] .. (mat.tex_normal and "#define TANGENT\n" or "") .. [[
		
		]] .. (mat.tex_emission and "#define TEX_EMISSION\n" or "") .. [[
		]] .. (mat.tex_material and "#define TEX_MATERIAL\n" or "") .. [[
		
		#define TANGENT
		
		#ifdef PIXEL
		extern Image tex_albedo;
		extern vec4 color_albedo;
		
		#ifdef TEX_MATERIAL
		extern Image tex_material;
		#endif
		extern vec2 color_material;
		
		extern Image tex_normal;
		
		#ifdef TEX_EMISSION
		extern Image tex_emission;
		#endif
		extern vec3 color_emission;
		
		extern float time;
		
		//water
		extern float waterSpeed;
		extern float waterScale;
		extern float waterHeight;
		extern float surfaceDistortion;
		
		//caustics
		extern Image tex_caustics;
		extern float causticsScale;
		extern vec3 causticsColor;
		
		#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[	
	//emission
#ifdef TEX_EMISSION
	emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
#else
	emission = color_albedo.rgb * color_emission;
#endif

	//two moving UV coords for the wave normal
	vec2 waterUV1 = VaryingTexCoord.xy + vec2(0.0, time * waterSpeed);
	vec2 waterUV2 = VaryingTexCoord.xy + vec2(time * waterSpeed, 0.0);
	
	//wave normal
	vec3 waterNormal = (
		Texel(tex_normal, (VertexPos.xz + waterUV1) * waterScale).rgb - vec3(0.5) +
		Texel(tex_normal, (VertexPos.xz + waterUV2) * waterScale * 0.66).rgb - vec3(0.5)
	) * vec3(1.0, 1.0, waterHeight);
	normal = normalize(TBN * (waterNormal));
	
	//disorted final uvs
	vec2 uvw = (VaryingTexCoord.xy + waterNormal.xy * surfaceDistortion) * waterScale;
	
	
	//color
	vec4 c = Texel(tex_albedo, uvw) * color_albedo;
	albedo = c.rgb;
	alpha = c.a;
	
	
	//material
#ifdef TEX_MATERIAL
	vec3 material = Texel(tex_material, uvw).xyz;
	roughness = material.x * color_material.x;
	metallic = material.y * color_material.y;
	ao = material.z;
#else
	roughness = color_material.x;
	metallic = color_material.y;
#endif
	
	
	//caustics
	if (dot(fragmentNormal, viewVec) > 0.0) {
#ifdef DEPTH_AVAILABLE
		float waterDepth = depth - Texel(tex_depth, love_PixelCoord.xy / love_ScreenSize.xy).r;
		vec3 causticsPos = viewVec * waterDepth;
#else
		vec3 causticsPos = viewVec;
#endif
		vec3 caustics = (
			Texel(tex_caustics, (causticsPos.xz + waterUV1) * causticsScale).rgb +
			Texel(tex_caustics, (causticsPos.xz + waterUV2) * causticsScale).rgb
		) * causticsColor * (1.0 - alpha);
	}
	]]
end

function sh:buildVertex(dream, mat)
	return ""
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("time", love.timer.getTime())
end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	
	local tex = dream.textures
	
	shader:send("tex_albedo", dream:getImage(material.tex_albedo) or tex.default)
	shader:send("color_albedo", material.color)
	
	if shader:hasUniform("tex_material") then
		shader:send("tex_material", dream:getImage(material.tex_material) or tex.default)
	end
	shader:send("color_material", {material.roughness, material.metallic})
	
	shader:send("tex_normal", dream:getImage(material.tex_normal) or tex.default_normal)
	
	if shader:hasUniform("tex_emission") then
		shader:send("tex_emission", dream:getImage(material.tex_emission) or tex.default)
	end
	
	shader:send("color_emission", material.emission)
	
	shader:send("waterScale", material.waterScale or 1 / 64)
	shader:send("waterSpeed", material.waterSpeed or 1)
	shader:send("waterHeight", 1 / (material.waterHeight or 4))
	shader:send("surfaceDistortion", material.surfaceDistortion or 0.75)
	
	--shader:send("tex_caustics", dream:getImage(material.tex_caustics) or dream.textures.default)
	
	--shader:send("causticsColor", dream.sun_color)
	--shader:send("causticsScale", material.causticsScale or 1 / 32)
end

function sh:perTask(dream, shaderObject, task)

end

return sh