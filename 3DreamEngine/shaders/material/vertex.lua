local sh = { }

sh.type = "material"

sh.meshType = "textured"
sh.splitMaterials = true
sh.requireTangents = true

function sh:getPixelId(dream, mat)
	return 0
end

function sh:getVertexId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat)
	return ""
end

function sh:buildPixel(dream, mat)
	return ""
end

function sh:buildVertex(dream, mat)
	return ""
end

function sh:perShader(dream, shaderObject)
	
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)

end

return sh