local sh = { }

sh.type = "module"

sh.shadow = false

function sh:init(dream)
	
end

function sh:initObject(dream, obj)
	--initial prepare bone data
	if not obj.foamMesh and not obj.meshes then
		assert(obj.colors and #obj.colors > 0, "water with foam required red channel of color buffer")
		obj.foamMesh = love.graphics.newMesh({{"VertexFoam", "float", 1}}, #obj.colors, "triangles", "static")
		
		--create mesh
		for d,s in ipairs(obj.colors) do
			obj.foamMesh:setVertex(d, s[1])
		end
	end
	
	if obj.foamMesh then
		obj.mesh:attachAttribute("VertexFoam", obj.foamMesh)
	end
end

function sh:constructDefines(dream, info)
	assert(info.material.alpha, "water shader modules requires alpha pass set to true in material")
	assert(info.material.tex_normal, "water shader modules requires a normal texture")
	assert(info.material.tex_caustics, "water shader modules requires a caustics texture")
	assert(info.material.material_foam, "water shader modules requires a material_foam vec2")
	
	return [[
	extern float time;
	
	//water
	extern float waterSpeed;
	extern float waterScale;
	extern float waterHeight;
	extern float surfaceDistortion;
	
	//foam
	extern float foamScale;
	extern float foamWidth;
	extern float foamDistortion;
	extern Image tex_foam;
	extern vec2 material_foam;
	
	//caustics
	extern Image tex_caustics;
	extern float causticsScale;
	extern vec3 causticsColor;
	
	#ifdef VERTEX
	attribute float VertexFoam;
	#endif
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
	vec2 uvf = (VaryingTexCoord.xy + waterNormal.xy * foamDistortion) * foamScale;
	
	//color
	vec4 c_water = Texel(tex_albedo, uvw);
	vec4 c_foam = Texel(tex_foam, uvf);
	
	//material
	vec3 m_water = Texel(tex_material, uvw).xyz * color_material;
	vec3 m_foam = vec3(material_foam, 1.0);
	
	//blend foam
	albedo.rgb = mix(c_water.rgb, c_foam.rgb, VaryingTexCoord.z) * color_albedo.rgb;
	albedo.a = (c_water.a * (1.0 - VaryingTexCoord.z) + VaryingTexCoord.z) * color_albedo.a;
	material = mix(m_water, m_foam, VaryingTexCoord.z);
	
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
		VaryingTexCoord.z = VertexFoam;
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
	
	checkAndSendCached(shaderObject, "material_foam", {material.material_foam[1], material.material_foam[2]})
	checkAndSendCached(shaderObject, "tex_foam", dream:getTexture(material.tex_foam) or dream.textures.default)
	checkAndSendCached(shaderObject, "tex_caustics", dream:getTexture(material.tex_caustics) or dream.textures.default)
	
	checkAndSendCached(shaderObject, "foamScale", material.foamScale or 1 / 8)
	checkAndSendCached(shaderObject, "foamWidth", 1 / (material.foamWidth or 0.5))
	checkAndSendCached(shaderObject, "foamDistortion", material.foamDistortion or 0.5)
	
	checkAndSendCached(shaderObject, "causticsColor", dream.sun_color)
	checkAndSendCached(shaderObject, "causticsScale", material.causticsScale or 1 / 32)
end

function sh:perTask(dream, shaderObject, subObj, task)

end

return sh