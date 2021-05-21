local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
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
		float bias = depth * 0.01 + 0.01;
		depth -= bias;
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		float shadow = 0.0;
		float diskRadius = depth * 0.0125;
		for (int i = 0; i < 20; ++i) {
			vec2 f = texture(tex, n + sampleOffsetDirections[i] * diskRadius).xy;
			if (min(f.x, f.y) > depth) {
				shadow += 0.05;
			}
		}
		return shadow;
	}
	
	float sampleShadowPoint(vec3 lightVec, samplerCube tex) {
		//bias
		float depth = length(lightVec);
		float bias = depth * 0.01 + 0.01;
		depth -= bias;
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		//fetch
		vec2 f = texture(tex, n).xy;
		return min(f.x, f.y) > depth ? 1.0 : 0.0;
	}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern samplerCube point_shadow_tex_#ID#;
		extern bool point_shadow_smooth_#ID#;
		extern vec3 point_shadow_pos_#ID#;
		extern vec3 point_shadow_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		vec3 lightVec = point_shadow_pos_#ID# - vertexPos;
		
		float shadow;
		if (point_shadow_smooth_#ID#) {
			shadow = sampleShadowPointSmooth(lightVec, point_shadow_tex_#ID#);
		} else {
			shadow = sampleShadowPoint(lightVec, point_shadow_tex_#ID#);
		}
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = 1.0 / (distance * distance);
			vec3 lightColor = point_shadow_color_#ID# * shadow * power;
			lightVec = normalize(lightVec);
			
			light += getLight(lightColor, viewVec, lightVec, normal, fragmentNormal, albedo, roughness, metallic);
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		vec3 lightVec = point_shadow_pos_#ID# - vertexPos;
		
		float shadow;
		if (point_shadow_smooth_#ID#) {
			shadow = sampleShadowPointSmooth(lightVec, point_shadow_tex_#ID#);
		} else {
			shadow = sampleShadowPoint(lightVec, point_shadow_tex_#ID#);
		}
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = 1.0 / (distance * distance);
			light += point_shadow_color_#ID# * shadow * power;
		}
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader or shaderObject
	
	if light.shadow.canvas then
		if light.smooth == nil then
			shader:send("point_shadow_smooth_" .. ID, dream.shadow_smooth)
		else
			shader:send("point_shadow_smooth_" .. ID, light.smooth)
		end
		shader:send("point_shadow_tex_" .. ID, light.shadow.canvas)
		shader:send("point_shadow_color_" .. ID, {(light.color * light.brightness):unpack()})
		shader:send("point_shadow_pos_" .. ID, {light.pos:unpack()})
	else
		shader:send("point_shadow_color_" .. ID, {0, 0, 0})
	end
end

return sh