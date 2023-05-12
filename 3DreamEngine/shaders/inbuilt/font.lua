local dream = _3DreamEngine

local sh = { }

sh.type = "pixel"

sh.meshFormat = "font"

function sh:getId(mat, shadow)
	return 0
end

function sh:buildDefines(mat, shadow)
	return [[
		#ifdef PIXEL
		uniform Image albedoTexture;
		uniform vec2 albedoTextureSize;
		//todo
		uniform vec4 albedoColor;
		uniform vec2 materialColor;
		uniform vec3 emissionColor;
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
	vec4 c = gammaCorrectedTexel(albedoTexture, VaryingTexCoord.xy * albedoTextureSize) * VaryingColor;
	albedo = c.rgb;
	alpha = c.a;
	
	//material
	roughness = VaryingMaterial.x;
	metallic = VaryingMaterial.y;
	emission = VaryingColor.rgb * VaryingMaterial.z; //todo why
	]]
end

function sh:buildVertex(mat)
	return [[
	VaryingMaterial = VertexMaterial.xyz;
	]]
end

function sh:perShader(shaderObject)

end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	
	local t = dream:getImage(material.albedoTexture) or dream.textures.default
	shader:send("albedoTexture", t)
	shader:send("albedoTextureSize", { 1 / t:getWidth(), 1 / t:getHeight() })
	
	--todo readd albedo, material and emission. Also find a way to fix emission on materials supporting per vertex emissions. For font and simple
end

function sh:perTask(shaderObject, task)

end

return sh