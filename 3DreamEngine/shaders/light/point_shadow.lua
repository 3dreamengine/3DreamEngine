local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)
	return [[
	float sampleShadowPoint(vec3 lightVec, samplerCube tex) {
		//bias
		float depth = length(lightVec);
		float bias = 0.01 + depth * 0.01;
		depth -= bias;
		
		//fetch
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		return texture(tex, n).r > depth ? 1.0 : 0.0;
	}
	]]
end

function sh:constructDefines(dream, info, ID)
	return ([[
		extern samplerCube tex_shadow_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixel(dream, info, ID, lightSignature)
	return ([[
		vec3 lightVec = lightPos[#ID#] - vertexPos;
		float shadow = sampleShadowPoint(lightVec, tex_shadow_#ID#);
		if (shadow > 0.0) {
			float distance = length(lightVec);
			float power = 1.0 / (0.1 + distance * distance);
			light += getLight(lightColor[#ID#] * shadow * power, viewVec, normalize(lightVec), normal, #lightSignature#);
		}
	]]):gsub("#ID#", ID):gsub("#lightSignature#", lightSignature)
end

function sh:sendGlobalUniforms(dream, shader, info)
	
end

function sh:sendUniforms(dream, shader, info, light, ID)
	if light.shadow.canvas then
		shader:send("tex_shadow_" .. ID, light.shadow.canvas)
	else
		return true
	end
end

return sh