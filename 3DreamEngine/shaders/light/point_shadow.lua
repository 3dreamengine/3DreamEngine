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
		extern samplerCube point_shadow_tex_#ID#;
		extern bool point_shadow_smooth_#ID#;
		extern vec3 point_shadow_pos_#ID#;
		extern vec3 point_shadow_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream, info)

end

function sh:constructPixelBasicGlobal(dream, info)

end

function sh:constructPixel(dream, info, ID)
	return ([[
		vec3 lightVec = point_shadow_pos_#ID# - vertexPos;
		
		float shadow;
		if (point_shadow_smooth_#ID#) {
			shadow = sampleShadowPointSmooth(lightVec, point_shadow_tex_#ID#);
		} else {
			shadow = sampleShadowPoint(lightVec, point_shadow_tex_#ID#);
		}
		
		if (shadow > 0.0) {
			float distance = length(lightVec);
			float power = 1.0 / (0.1 + distance * distance);
			vec3 lightColor = point_shadow_color_#ID# * shadow * power;
			vec3 nLightVec = normalize(lightVec);
			
			light += getLight(lightColor, viewVec, nLightVec, normal, albedo.rgb, material.x, material.y);
			
			//backface light
			if (translucent > 0.0) {
				light += getLight(lightColor, viewVec, nLightVec, reflect(normal, normalRaw), albedo.rgb, material.x, material.y) * translucent;
			}
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, info, ID)
	return ([[
		vec3 lightVec = point_shadow_pos_#ID# - vertexPos;
		
		float shadow;
		if (point_shadow_smooth_#ID#) {
			shadow = sampleShadowPointSmooth(lightVec, point_shadow_tex_#ID#);
		} else {
			shadow = sampleShadowPoint(lightVec, point_shadow_tex_#ID#);
		}
		
		if (shadow > 0.0) {
			float distance = length(lightVec);
			float power = 1.0 / (0.1 + distance * distance);
			light += point_shadow_color_#ID# * shadow * power;
		}
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shader, info)
	
end

function sh:sendUniforms(dream, shader, info, light, ID)
	if light.shadow.canvas then
		if light.smooth == nil then
			shader:send("point_shadow_smooth_" .. ID, dream.shadow_smooth)
		else
			shader:send("point_shadow_smooth_" .. ID, light.smooth)
		end
		shader:send("point_shadow_tex_" .. ID, light.shadow.canvas)
		shader:send("point_shadow_color_" .. ID, {light.r * light.brightness, light.g * light.brightness, light.b * light.brightness})
		shader:send("point_shadow_pos_" .. ID, {light.x, light.y, light.z})
	else
		shader:send("point_shadow_color_" .. ID, {0, 0, 0})
	end
end

return sh