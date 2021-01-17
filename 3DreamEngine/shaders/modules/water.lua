local sh = { }

sh.type = "module"

sh.shadow = false

function sh:init(dream)
	
end

function sh:constructDefines(dream)
	return [[
	extern float time;
	
	extern float waterSpeed;
	extern float waterScale;
	extern float waterHeight;
	
	extern float foamScale;
	extern float foamWidth;
	extern float foamDisortion;
	extern float foamMode;
	
	extern float causticsScale;
	extern vec3 causticsColor;
	
	extern Image tex_foam;
	extern Image tex_caustics;
	extern vec2 material_foam;
	]]
end

function sh:constructPixel(dream)
	return [[
	{
	vec2 waterFlow = time * VaryingTexCoord.xy * (1.0 - foamMode);
	
	vec2 waterUV1 = vec2(0.0, time * waterSpeed) + waterFlow;
	vec2 waterUV2 = vec2(time * waterSpeed, 0.0) + waterFlow;
	
	vec3 waterNormal = (
		Texel(tex_normal, (vertexPos.xz + waterUV1) * waterScale).rgb - vec3(0.5) +
		Texel(tex_normal, (vertexPos.xz + waterUV2) * waterScale * 0.66).rgb - vec3(0.5)
	) * vec3(1.0, 1.0, waterHeight);
	normal = normalize(TBN * (waterNormal));
	
#ifdef REFRACTIONS_ENABLED
	vec2 uv = vertexPos.xz + waterFlow + waterNormal.xy * foamDisortion;
	vec2 uvw = uv * waterScale;
	vec2 uvf = uv * foamScale;
	
	//color
	vec4 c_water = Texel(tex_albedo, uvw);
	vec4 c_foam = Texel(tex_foam, uvf);
	
	//material
	vec3 m_water = Texel(tex_material, uvw).xyz * color_material;
	vec3 m_foam = vec3(material_foam, 1.0);
	
	float foamDepth = Texel(tex_depth, love_PixelCoord.xy * screenScale).r;
	
	//blend foam
	float mixValue;
	if (foamMode > 0.5) {
		mixValue = VaryingTexCoord.x;
	} else {
		mixValue = clamp(1.0 - (foamDepth - depth) * foamWidth, 0.0, 1.0) * c_foam.a;
	}
	
	//mix
	albedo.rgb = mix(c_water.rgb, c_foam.rgb, mixValue) * color_albedo.rgb;
	albedo.a = (c_water.a * (1.0 - mixValue) + mixValue) * color_albedo.a;
	
	//caustics
	if (dot(normalRaw, viewVec) > 0.0) {
		vec3 causticsPos = vertexPos + viewVec * (foamDepth - depth);
		caustics = (
			Texel(tex_caustics, (causticsPos.xz + waterUV1) * causticsScale).rgb +
			Texel(tex_caustics, (causticsPos.xz + waterUV2) * causticsScale).rgb
		) * causticsColor * 0.5;
		
		material = mix(m_water, m_foam, mixValue);
	}
#endif
	}
	]]
end

function sh:perShader(dream, shaderObject)
	local shader = shaderObject.shader
	shader:send("time", love.timer.getTime())
end

function sh:perMaterial(dream, shaderObject, material)
	assert(material.alpha, "water shader modules requires alpha pass set to true in material")
	assert(material.tex_normal, "water shader modules requires a normal texture")
	assert(material.tex_caustics, "water shader modules requires a caustics texture")
	assert(material.material_foam, "water shader modules requires a material_foam vec2")
	
	local shader = shaderObject.shader
	
	checkAndSendCached(shaderObject, "waterScale", material.waterScale or 1 / 64)
	checkAndSendCached(shaderObject, "waterSpeed", material.waterSpeed or 1)
	checkAndSendCached(shaderObject, "waterHeight", 1 / (material.waterHeight or 4))
	
	if hasUniform(shaderObject, "foamWidth") then
		checkAndSendCached(shaderObject, "material_foam", {material.material_foam[1], material.material_foam[2]})
		checkAndSendCached(shaderObject, "tex_foam", dream:getTexture(material.tex_foam) or dream.textures.default)
		checkAndSendCached(shaderObject, "tex_caustics", dream:getTexture(material.tex_caustics) or dream.textures.default)
		
		checkAndSendCached(shaderObject, "foamMode", material.foamMode and 1 or 0)
		
		checkAndSendCached(shaderObject, "foamScale", material.foamScale or 1 / 8)
		checkAndSendCached(shaderObject, "foamWidth", 1 / (material.foamWidth or 0.5))
		checkAndSendCached(shaderObject, "foamDisortion", material.foamDisortion or 0.5)
		
		checkAndSendCached(shaderObject, "causticsColor", dream.sun_color)
		checkAndSendCached(shaderObject, "causticsScale", material.causticsScale or 1 / 16)
	end
end

function sh:perTask(dream, shaderObject, subObj, task)
	
end

return sh