local sh = { }

sh.type = "pixel"

sh.meshType = "material"

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
		attribute float VertexMaterial;
		extern Image tex_lookup;
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
	normal = normalize(VaryingNormal);
	]]
end

function sh:buildVertex(dream, mat)
	return [[
	//get color
	VaryingColor = Texel(tex_lookup, vec2(VertexMaterial, 0.0));
	
	//extract material
	VaryingMaterial = Texel(tex_lookup, vec2(VertexMaterial, 1.0)).rgb;
	]]
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	local shader = shaderObject.shader
	shader:send("tex_lookup", dream:getImage(material.tex_lookup) or dream.textures.default)
end

function sh:perTask(dream, shaderObject, task)

end

return sh