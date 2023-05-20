local sh = { }

sh.type = "pixel"

sh.meshFormat = "simple"

function sh:buildDefines(mat, shadow)
	return [[
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
	albedo = VaryingColor.rgb;
	alpha = VaryingColor.a;
	
	//material
	roughness = VaryingMaterial.x;
	metallic = VaryingMaterial.y;
	emission = VaryingColor.rgb * VaryingMaterial.z;
	]]
end

function sh:buildVertex(mat)
	return [[
	VaryingMaterial = VertexMaterial.xyz;
	]]
end

return sh