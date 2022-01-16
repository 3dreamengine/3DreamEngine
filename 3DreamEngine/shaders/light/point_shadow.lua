local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowPointDynamic(vec3 lightVec, samplerCube tex, float shadowDistanceFactor, bool dynamic) {
		float max_distance = 0.5;
		float mipmap_count = 3.0;
		
		float depth = length(lightVec);
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		//fetch
		float mm = min(mipmap_count, depth * max_distance);
		float sampleDepth;
		if (dynamic) {
			vec2 r = textureLod(tex, n, mm).xy;
			sampleDepth = min(r.x, r.y);
		} else {
			sampleDepth = textureLod(tex, n, mm).x;
		}
		float sharpness = 0.4;
		return clamp(exp(sharpness * (sampleDepth * 40.0 * shadowDistanceFactor - depth * 40.0)), 0.0, 1.0);
	}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern samplerCube point_shadow_tex_#ID#;
		extern vec3 point_shadow_pos_#ID#;
		extern vec3 point_shadow_color_#ID#;
		extern float point_shadow_distanceFactor_#ID#;
		extern bool point_shadow_dynamic_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		vec3 lightVec = point_shadow_pos_#ID# - VertexPos;
		
		float shadow = sampleShadowPointDynamic(lightVec, point_shadow_tex_#ID#, point_shadow_distanceFactor_#ID#, point_shadow_dynamic_#ID#);
		
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
		vec3 lightVec = point_shadow_pos_#ID# - VertexPos;
		
		float shadow = sampleShadowPointDynamic(lightVec, point_shadow_tex_#ID#, point_shadow_distanceFactor_#ID#, point_shadow_dynamic_#ID#);
		
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
		shader:send("point_shadow_tex_" .. ID, light.shadow.canvas)
		shader:send("point_shadow_color_" .. ID, {(light.color * light.brightness):unpack()})
		shader:send("point_shadow_pos_" .. ID, {light.pos:unpack()})
		
		shader:send("point_shadow_distanceFactor_" .. ID, (light.shadow.smoothStatic or light.shadow.smoothDynamic) and 1 / 40 or 1)
		shader:send("point_shadow_dynamic_" .. ID, not light.shadow.static)
	else
		shader:send("point_shadow_color_" .. ID, {0, 0, 0})
	end
end

return sh