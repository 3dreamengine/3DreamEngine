local sh = { }

sh.type = "pixel"

sh.meshType = "simple"

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat, shadow)
	return [[
		varying vec3 VaryingMaterial;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute vec3 VertexMaterial;
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
	VaryingMaterial = VertexMaterial;
	]]
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)
	
end

return sh