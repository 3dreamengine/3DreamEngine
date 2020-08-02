local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)
	if dream.shadow_smooth then
		return [[
		//modified version of https://learnopengl.com/Advanced-Lighting/Shadows/Point-Shadows
		vec3 sampleOffsetDirections[20] = vec3[] (
		   vec3( 1,  1,  1), vec3( 1, -1,  1), vec3(-1, -1,  1), vec3(-1,  1,  1), 
		   vec3( 1,  1, -1), vec3( 1, -1, -1), vec3(-1, -1, -1), vec3(-1,  1, -1),
		   vec3( 1,  1,  0), vec3( 1, -1,  0), vec3(-1, -1,  0), vec3(-1,  1,  0),
		   vec3( 1,  0,  1), vec3(-1,  0,  1), vec3( 1,  0, -1), vec3(-1,  0, -1),
		   vec3( 0,  1,  1), vec3( 0, -1,  1), vec3( 0, -1, -1), vec3( 0,  1, -1)
		);
		
		float sampleShadowPoint(vec3 lightVec, samplerCube tex) {
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
		]]
	else
		return [[
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