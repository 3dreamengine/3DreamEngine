local sh = { }

sh.type = "pixel"

sh.meshFormat = "simple"

function sh:getId(mat, shadow)
	return 0
end

function sh:buildDefines(mat, shadow)
	return [[
		varying vec3 VaryingMaterial;
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute vec3 VertexMaterial;
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
	VaryingMaterial = VertexMaterial;
	]]
end

function sh:perShader(shaderObject)

end

function sh:perMaterial(shaderObject, material)
	
end

function sh:perTask(shaderObject, task)
	
end

return sh