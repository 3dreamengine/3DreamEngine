local lib = _3DreamEngine

local sh = { }

sh.type = "pixel"

sh.meshFormat = "material"

function sh:getId(mat, shadow)
	return 0
end

function sh:buildDefines(mat, shadow)
	return [[
		varying vec3 VaryingMaterial;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute float VertexMaterial;
		extern Image lookupTexture;
		#endif
	]]
end

function sh:buildPixel(mat)
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

function sh:buildVertex(mat)
	return [[
	//get color
	VaryingColor = gammaCorrectedTexel(lookupTexture, vec2(VertexMaterial, 0.0));
	
	//extract material
	VaryingMaterial = Texel(lookupTexture, vec2(VertexMaterial, 1.0)).rgb;
	]]
end

function sh:perShader(shaderObject)

end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	shader:send("lookupTexture", lib:getImage(material.lookupTexture) or lib.textures.default)
end

function sh:perTask(shaderObject, task)

end

return sh