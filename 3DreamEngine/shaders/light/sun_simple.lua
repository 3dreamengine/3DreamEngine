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
		light += getLight(sun_simple_color_#ID#, viewVec, sun_simple_vec_#ID#, normal, albedo.rgb, material.x, material.y);
		
		//backface light
		if (translucent > 0.0) {
			light += getLight(sun_simple_color_#ID#, viewVec, sun_simple_vec_#ID#, reflect(normal, normalRaw), albedo.rgb, material.x, material.y) * translucent;
		}
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
	
	shader:send("sun_simple_color_" .. ID,  {light.r * light.brightness, light.g * light.brightness, light.b * light.brightness})
	if shader:hasUniform("sun_simple_vec_" .. ID) then
		shader:send("sun_simple_vec_" .. ID, {vec3(light.x, light.y, light.z):normalize():unpack()})
	end
end

return sh