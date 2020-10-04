local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)

end

function sh:constructDefines(dream, info, ID)
	
end

function sh:constructPixelGlobal(dream, info)

end

function sh:constructPixel(dream, info, ID)
	return ([[
		vec3 lightVec = normalize(lightPos[#ID#]);
		light += getLight(lightColor[#ID#], viewVec, lightVec, normal, albedo.rgb, material.x, material.y);
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shader, info)
	
end

function sh:sendUniforms(dream, shader, info, light, ID)
	
end

return sh