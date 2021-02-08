local sh = { }

sh.type = "module"

sh.shadow = false

function sh:init(dream)
	
end

function sh:constructDefines(dream, info)
	assert(info.material.alpha, "water shader modules requires alpha pass set to true in material")
	assert(info.material.tex_normal, "water shader modules requires a normal texture")
	assert(info.material.tex_caustics, "water shader modules requires a caustics texture")
	
	return [[
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
	]]
end

function sh:constructPixel(dream)
	return [[
	{
	//two moving UV coords for the wave normal
	vec2 waterUV1 = VaryingTexCoord.xy + vec2(0.0, time * waterSpeed);
	vec2 waterUV2 = VaryingTexCoord.xy + vec2(time * waterSpeed, 0.0);
	
	//wave normal
	vec3 waterNormal = (
		Texel(tex_normal, (vertexPos.xz + waterUV1) * waterScale).rgb - vec3(0.5) +
		Texel(tex_normal, (vertexPos.xz + waterUV2) * waterScale * 0.66).rgb - vec3(0.5)
	) * vec3(1.0, 1.0, waterHeight);
	normal = normalize(TBN * (waterNormal));
	
	//disorted final uvs
	vec2 uvw = (VaryingTexCoord.xy + waterNormal.xy * surfaceDistortion) * waterScale;
	
	//color
	albedo = Texel(tex_albedo, uvw) * color_albedo;
	
	//material
	material = Texel(tex_material, uvw).xyz * color_material;
	
	//caustics
	if (dot(normalRaw, viewVec) > 0.0) {
#ifdef REFRACTIONS_ENABLED
		float waterDepth = depth - Texel(tex_depth, love_PixelCoord.xy * screenScale).r;
		vec3 causticsPos = viewVec * waterDepth;
#else
		vec3 causticsPos = viewVec;
#endif
		caustics = (
			Texel(tex_caustics, (causticsPos.xz + waterUV1) * causticsScale).rgb +
			Texel(tex_caustics, (causticsPos.xz + waterUV2) * causticsScale).rgb
		) * causticsColor * (1.0 - albedo.a);
	}
	}
	]]
end

function sh:constructVertexPost(dream)
	return [[
	{
		VaryingTexCoord.xy = vertexPos.xz + time * VertexTexCoord.xy;
	}
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("time", love.timer.getTime())
end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	
	checkAndSendCached(shaderObject, "waterScale", material.waterScale or 1 / 64)
	checkAndSendCached(shaderObject, "waterSpeed", material.waterSpeed or 1)
	checkAndSendCached(shaderObject, "waterHeight", 1 / (material.waterHeight or 4))
	checkAndSendCached(shaderObject, "surfaceDistortion", material.surfaceDistortion or 0.75)
	
	checkAndSendCached(shaderObject, "tex_caustics", dream:getImage(material.tex_caustics) or dream.textures.default)
	
	checkAndSendCached(shaderObject, "causticsColor", dream.sun_color)
	checkAndSendCached(shaderObject, "causticsScale", material.causticsScale or 1 / 32)
end

function sh:perTask(dream, shaderObject, subObj, task)

end

return sh