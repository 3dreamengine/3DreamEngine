local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
	return [[
	#define DISTANCE_FACTOR 10.0f
	
	float sampleShadowPoint(vec3 lightVec, samplerCube tex, bool staticShadow, bool smoothShadows) {
		float max_distance = 0.5;
		float mipmap_count = 3.0;
		float sharpness = 1.0;
		
		float depth = length(lightVec);
		float bias = depth * 0.01 + 0.01;
		
		//direction
		vec3 n = -lightVec * vec3(1.0, -1.0, 1.0);
		
		//fetch
		float mm = min(mipmap_count, depth * max_distance);
		if (staticShadow) {
			if (smoothShadows) {
				float sampleDepth = textureLod(tex, n, mm).x;
				return clamp(exp(sharpness * (sampleDepth / DISTANCE_FACTOR - depth)), 0.0, 1.0);
			} else {
				float r = textureLod(tex, n, 0.0).x;
				return r + bias > depth ? 1.0 : 0.0;
			}
		} else {
			if (smoothShadows) {
				float sampleDepth = textureLod(tex, n, mm).x;
				return (
					clamp(exp(sharpness * (sampleDepth / DISTANCE_FACTOR - depth)), 0.0, 1.0) *
					(textureLod(tex, n, 0.0).y + bias > depth ? 1.0 : 0.0)
				);
			} else {
				vec2 r = textureLod(tex, n, 0.0).xy;
				return min(r.x, r.y) + bias > depth ? 1.0 : 0.0;
			}
		}
	}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern samplerCube ps_tex_#ID#;
		extern vec3 ps_pos_#ID#;
		extern vec3 ps_color_#ID#;
		extern bool ps_static_#ID#;
		extern bool ps_smooth_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		vec3 lightVec = ps_pos_#ID# - VertexPos;
		
		float shadow = sampleShadowPoint(lightVec, ps_tex_#ID#, ps_static_#ID#, ps_smooth_#ID#);
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = 1.0 / (distance * distance);
			vec3 lightColor = ps_color_#ID# * shadow * power;
			lightVec = normalize(lightVec);
			
			light += getLight(lightColor, viewVec, lightVec, normal, fragmentNormal, albedo, roughness, metallic);
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		vec3 lightVec = ps_pos_#ID# - VertexPos;
		
		float shadow = sampleShadowPoint(lightVec, ps_tex_#ID#, ps_static_#ID#, ps_smooth_#ID#);
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = 1.0 / (distance * distance);
			light += ps_color_#ID# * shadow * power;
		}
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader or shaderObject
	
	if light.shadow.canvas then
		shader:send("ps_tex_" .. ID, light.shadow.canvas)
		shader:send("ps_color_" .. ID, {(light.color * light.brightness):unpack()})
		shader:send("ps_pos_" .. ID, {light.pos:unpack()})
		
		shader:send("ps_static_" .. ID, light.shadow.static and true or false)
		shader:send("ps_smooth_" .. ID, light.shadow.smooth and true or false)
	else
		shader:send("ps_color_" .. ID, {0, 0, 0})
	end
end

return sh