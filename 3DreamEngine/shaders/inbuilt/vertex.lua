local sh = { }

sh.type = "vertex"

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat)
	return ""
end

function sh:buildPixel(dream, mat)
	return ""
end

function sh:buildVertex(dream, mat)
	return [[
	vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
	]]
end

function sh:perShader(dream, shaderObject)

end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)

end

return sh