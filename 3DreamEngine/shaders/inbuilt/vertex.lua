local sh = { }

sh.type = "vertex"

function sh:getId(mat, shadow)
	return 0
end

function sh:buildDefines(mat)
	return ""
end

function sh:buildPixel(mat)
	return ""
end

function sh:buildVertex(mat)
	return [[
	vertexPos = (transform * vec4(vertexPos, 1.0)).xyz;
	]]
end

function sh:perShader(shaderObject)

end

function sh:perMaterial(shaderObject, material)
	
end

function sh:perTask(shaderObject, task)

end

return sh