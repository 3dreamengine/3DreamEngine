local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)

end

function sh:constructDefines(dream, info, ID)
	
end

function sh:constructPixel(dream, info, ID, lightSignature)
	return ([[
		vec3 lightVec = normalize(lightPos[#ID#]);
		light += getLight(lightColor[#ID#], viewVec, lightVec, normal, #lightSignature#);
	]]):gsub("#ID#", ID):gsub("#lightSignature#", lightSignature)
end

function sh:sendGlobalUniforms(dream, shader, info)
	
end

function sh:sendUniforms(dream, shader, info, light, ID)
	
end

return sh