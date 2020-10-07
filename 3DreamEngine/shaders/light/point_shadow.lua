local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)
	return [[
	//modified version of https://learnopengl.com/Advanced-Lighting/Shadows/Point-Shadows
	vec3 sampleOffsetDirections[20] = vec3[] (
	   vec3( 1,  1,  1), vec3( 1, -1,  1), vec3(-1, -1,  1), vec3(-1,  1,  1), 
	   vec3( 1,  1, -1), vec3( 1, -1, -1), vec3(-1, -1, -1), vec3(-1,  1, -1),
	   vec3( 1,  1,  0), vec3( 1, -1,  0), vec3(-1, -1,  0), vec3(-1,  1,  0),
	   vec3( 1,  0,  1), vec3(-1,  0,  1), vec3( 1,  0, -1), vec3(-1,  0, -1),
	   vec3( 0,  1,  1), vec3( 0, -1,  1), vec3( 0, -1, -1), vec3( 0,  1, -1)
	);
	
	float sampleShadowPointSmooth(vec3 lightVec, samplerCube tex) {
		//bias
		float depth = length(lightVec);
		float bias = 0.01 + depth * 0.01;
		depth -= bias;
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		float shadow = 0.0;
		float diskRadius = 0.01 * depth;
		for (int i = 0; i < 20; ++i) {
			if (texture(tex, n + sampleOffsetDirections[i] * diskRadius).r > depth) {
				shadow += 0.05;
			}
		}
		return shadow;
	}
	
	float sampleShadowPoint(vec3 lightVec, samplerCube tex) {
		//bias
		float depth = length(lightVec);
		float bias = 0.01 + depth * 0.01;
		depth -= bias;
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		//fetch
		return texture(tex, n).r > depth ? 1.0 : 0.0;
	}
	]]
end

function sh:constructDefines(dream, info, ID)
	return ([[
		extern samplerCube tex_shadow_#ID#;
		extern bool smooth_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream, info)

end

function sh:constructPixel(dream, info, ID)
	return ([[
		vec3 lightVec = lightPos[#ID#] - vertexPos;
		float shadow;
		if (smooth_#ID#) {
			shadow = sampleShadowPointSmooth(lightVec, tex_shadow_#ID#);
		} else {
			shadow = sampleShadowPoint(lightVec, tex_shadow_#ID#);
		}
		if (shadow > 0.0) {
			float distance = length(lightVec);
			float power = 1.0 / (0.1 + distance * distance);
			light += getLight(lightColor[#ID#] * shadow * power, viewVec, normalize(lightVec), normal, albedo.rgb, material.x, material.y);
		}
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shader, info)
	
end

function sh:sendUniforms(dream, shader, info, light, ID)
	if light.shadow.canvas then
		shader:send("smooth_" .. ID, light.smooth)
		shader:send("tex_shadow_" .. ID, light.shadow.canvas)
	else
		return true
	end
end

return sh