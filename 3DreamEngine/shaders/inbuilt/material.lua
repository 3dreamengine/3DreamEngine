local sh = { }

sh.type = "pixel"

sh.meshType = "material"

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat, shadow)
	return [[
		varying vec3 VaryingMaterial;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute float VertexMaterial;
		extern Image lookupTexture;
		#endif
	]]
end

function sh:buildPixel(dream, mat)
	return [[
	//color
	albedo = VaryingColor.rgb;
	alpha = VaryingColor.a;
	
	//material
	roughness = VaryingMaterial.x;
	metallic = VaryingMaterial.y;
	emission = VaryingColor.rgb * VaryingMaterial.z;
	
	//normal
	normal = normalize(varyingNormal);
	]]
end

function sh:buildVertex(dream, mat)
	return [[
	//get color
	VaryingColor = gammaCorrectedTexel(lookupTexture, vec2(VertexMaterial, 0.0));
	
	//extract material
	VaryingMaterial = Texel(lookupTexture, vec2(VertexMaterial, 1.0)).rgb;
	]]
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	shader:send("lookupTexture", dream:getImage(material.lookupTexture) or dream.textures.default)
end

function sh:perTask(dream, shaderObject, task)

end

return sh