local sh = { }

sh.type = "pixel"

sh.meshType = "simple"

function sh:getId(dream, mat, shadow)
	if shadow then
		return (mat.discard and 1 or 0)
	else
		return (mat.discard and not mat.dither and 1 or 0) * 2^0 + (mat.dither and 1 or 0) * 2^1
	end
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
	
#ifdef DISCARD
	if (alpha < 0.5) {
		discard;
	}
#endif

#ifdef DITHER
	if (alpha < fract(love_PixelCoord.x * 0.37 + love_PixelCoord.y * 73.73 + depth * 3.73)) {
		discard;
	}
#endif
	
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