local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowPointDynamic(vec3 lightVec, samplerCube tex) {
		float depth = length(lightVec);
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		//fetch
		//todo remove magic number 3.0
		vec2 r = textureLod(tex, n, 0.0).xy;
		float sharpness = 0.1;
		return clamp(exp(sharpness * (min(r.x, r.y) - depth * 40.0)), 0.0, 1.0);
	}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern samplerCube point_shadow_dynamic_tex_#ID#;
		extern vec3 point_shadow_dynamic_pos_#ID#;
		extern vec3 point_shadow_dynamic_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		vec3 lightVec = point_shadow_dynamic_pos_#ID# - VertexPos;
		
		float shadow = sampleShadowPointDynamic(lightVec, point_shadow_dynamic_tex_#ID#);
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = 1.0 / (distance * distance);
			vec3 lightColor = point_shadow_dynamic_color_#ID# * shadow * power;
			lightVec = normalize(lightVec);
			
			light += getLight(lightColor, viewVec, lightVec, normal, fragmentNormal, albedo, roughness, metallic);
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		vec3 lightVec = point_shadow_dynamic_pos_#ID# - VertexPos;
		
		float shadow = sampleShadowPointDynamic(lightVec, point_shadow_dynamic_tex_#ID#);
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = 1.0 / (distance * distance);
			light += point_shadow_dynamic_color_#ID# * shadow * power;
		}
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader or shaderObject
	
	if light.shadow.canvas then
		shader:send("point_shadow_dynamic_tex_" .. ID, light.shadow.canvas)
		shader:send("point_shadow_dynamic_color_" .. ID, {(light.color * light.brightness):unpack()})
		shader:send("point_shadow_dynamic_pos_" .. ID, {light.pos:unpack()})
	else
		shader:send("point_shadow_dynamic_color_" .. ID, {0, 0, 0})
	end
end

return sh