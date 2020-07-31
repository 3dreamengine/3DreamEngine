local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)

end

function sh:constructDefines(dream, info, ID)
	
end

function sh:constructPixel(dream, info, ID, lightSignature)
	return ([[
		vec3 lightVecRaw = lightPos[#ID#] - vertexPos;
		vec3 lightVec = normalize(lightVecRaw);
		float distance = length(lightVecRaw);
		float power = 1.0 / (0.1 + distance * distance);
		light += getLight(lightColor[#ID#] * power, viewVec, lightVec, normal, #lightSignature#);
	]]):gsub("#ID#", ID):gsub("#lightSignature#", lightSignature)
end

function sh:sendGlobalUniforms(dream, shader, info)
	
end

function sh:sendUniforms(dream, shader, info, light, ID)
	
end

return sh