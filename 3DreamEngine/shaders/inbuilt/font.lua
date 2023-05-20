local dream = _3DreamEngine

local sh = { }

sh.type = "pixel"

sh.meshFormat = "font"

function sh:buildDefines(mat, shadow)
	return [[
		#ifdef PIXEL
		uniform Image albedoTexture;
		uniform vec2 albedoTextureSize;
		uniform vec4 albedoColor;
		uniform vec2 materialColor;
		uniform vec3 emissionColor;
		uniform vec3 emissionFactor;
		#endif
	
		varying vec3 VaryingMaterial;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute vec4 VertexMaterial;
		#endif
	]]
end

function sh:buildPixel(mat)
	return [[
	//color
	vec4 c = gammaCorrectedTexel(albedoTexture, VaryingTexCoord.xy * albedoTextureSize) * albedoColor * VaryingColor;
	albedo = c.rgb;
	alpha = c.a;
	
	//material
	roughness = VaryingMaterial.x;
	metallic = VaryingMaterial.y;
	emission = c.rgb * VaryingMaterial.z * emissionFactor + emissionColor;
	]]
end

function sh:buildVertex(mat)
	return [[
	VaryingMaterial = VertexMaterial.xyz;
	]]
end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	
	local t = dream:getImage(material.albedoTexture) or dream.textures.default
	shader:send("albedoTexture", t)
	shader:send("albedoTextureSize", { 1 / t:getWidth(), 1 / t:getHeight() })
	shader:send("albedoColor", material.color)
	
	shader:send("emissionColor", material.emission)
	shader:send("emissionFactor", material.emissionFactor)
end

return sh