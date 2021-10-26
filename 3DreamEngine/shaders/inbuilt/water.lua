local sh = { }

sh.type = "pixel"

sh.meshType = "textured"

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
	
	return [[
		]] .. (mat.tex_normal and "#define TEX_NORMAL\n" or "") .. [[
		]] .. (mat.tex_normal and "#define TANGENT\n" or "") .. [[
		
		]] .. (mat.tex_emission and "#define TEX_EMISSION\n" or "") .. [[
		]] .. (mat.tex_material and "#define TEX_MATERIAL\n" or "") .. [[
		
		#define TANGENT
		
		//#ifdef PIXEL
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
		
		extern Image tex_noise;
		
		extern float time;
		
		//water
		extern float waterSpeed;
		extern float waterScale;
		extern float waterHeight;
		extern float surfaceDistortion;
		
		extern float foamScale;
		extern float foamSpeed;
		
		extern vec3 liquid_albedo;
		extern float liquid_alpha;
		extern vec3 liquid_emission;
		extern float liquid_roughness;
		extern float liquid_metallic;
		
		//#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
	//two moving UV coords for the wave normal
	vec2 waterUV = VaryingTexCoord.xy + VertexPos.xz;
	vec2 waterUV1 = waterUV + vec2(0.0, time * waterSpeed);
	vec2 waterUV2 = waterUV + vec2(time * waterSpeed, 0.0);
	
	//wave normal
	vec3 waterNormal = (
		Texel(tex_normal, waterUV1 * waterScale).rgb - vec3(0.5) +
		(Texel(tex_normal, waterUV2 * waterScale * 2.7).rgb - vec3(0.5)) * 0.5
	);
	normal = normalize(TBN * waterNormal * vec3(1.0, waterHeight, 1.0));
	
	//disorted final uvs
	vec2 uvd = VertexPos.xz + waterNormal.xz * surfaceDistortion;
	vec2 uvw = uvd * foamScale;
	
	//foam
	float waterDepth = Texel(tex_depth, love_PixelCoord.xy / love_ScreenSize.xy).r - depth;
	
	//two moving UV coords for the wave normal
	vec2 foamUV = VaryingTexCoord.xy + uvd;
	vec2 foamUV0 = foamUV + vec2(0.0, time * foamSpeed);
	vec2 foamUV1 = foamUV + vec2(time * foamSpeed, 0.0);
	
	float d0 = Texel(tex_noise, foamUV0).r;
	float d1 = Texel(tex_noise, foamUV1).b;
	float foamDensity = d0 + d1;
	float density = clamp(foamDensity - waterDepth * 4.0, 0.0, 1.0);
	
	//color
	vec4 c = Texel(tex_albedo, uvw) * color_albedo;
	albedo = mix(liquid_albedo, c.rgb, density);
	alpha = mix(clamp(liquid_alpha, 0.0, 1.0), c.a, density);
	
	//material
#ifdef TEX_MATERIAL
	vec3 material = Texel(tex_material, uvw).xyz;
	roughness = mix(liquid_roughness, material.x * color_material.x, density);
	metallic = mix(liquid_metallic, material.y * color_material.y, density);
	ao = material.z;
#else
	roughness = mix(liquid_roughness, color_material.x, density);
	metallic = mix(liquid_metallic, color_material.y, density);
#endif
	
	//emission
	#ifdef TEX_EMISSION
		emission = mix(liquid_emission, Texel(tex_emission, uvw).rgb * color_emission, density);
	#else
		emission = mix(liquid_emission, color_albedo.rgb * color_emission, density);
	#endif
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
	
	shader:send("tex_noise", dream.textures.foam)
	
	shader:send("color_emission", material.emission)
	
	shader:send("waterScale", material.waterScale or 1 / 16)
	shader:send("waterSpeed", material.waterSpeed or 1)
	shader:send("waterHeight", 1 / (material.waterHeight or 2))
	shader:send("surfaceDistortion", material.surfaceDistortion or 1.0)
	
	shader:send("foamScale", material.foamScale or 1 / 8)
	shader:send("foamSpeed", material.foamSpeed or 0.1)
	
	shader:send("liquid_albedo", material.liquid_albedo or {0.5, 0.75, 1.0})
	shader:send("liquid_alpha", material.liquid_alpha or 0.2)
	shader:send("liquid_emission", material.liquid_emission or {0.0, 0.0, 0.0})
	shader:send("liquid_roughness", material.liquid_roughness or 0.0)
	shader:send("liquid_metallic", material.liquid_metallic or 1.0)
end

function sh:perTask(dream, shaderObject, task)

end

return sh