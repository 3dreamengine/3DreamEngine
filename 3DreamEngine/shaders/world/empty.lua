local sh = { }

sh.type = "world"

function sh:getPixelId(dream, mat, shadow)
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
	local shader = shaderObject.shader
	
	if shader:hasUniform("brdfLUT") then
		dream.initTextures:PBR()
		shader:send("brdfLUT", dream.textures.brdfLUT)
	end
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)
	
end

return sh