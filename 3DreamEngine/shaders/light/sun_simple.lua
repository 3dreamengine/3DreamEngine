local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)

end

function sh:constructDefines(dream, ID)
	return ([[
		extern vec3 sun_simple_vec_#ID#;
		extern vec3 sun_simple_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		light += getLight(sun_simple_color_#ID#, viewVec, sun_simple_vec_#ID#, normal, albedo, roughness, metallic);
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		light += sun_simple_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader
	
	shader:send("sun_simple_color_" .. ID,  light.color * light.brightness)
	if shader:hasUniform("sun_simple_vec_" .. ID) then
		shader:send("sun_simple_vec_" .. ID, light.direction)
	end
end

return sh