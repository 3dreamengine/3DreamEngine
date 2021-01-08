local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
	return [[
		extern float factor;
		extern float shadowDistance;
		extern float texelSize;
		
		vec2 sampleOffset[17] = vec2[] (
			vec2(2, -1),
			vec2(3, 0),
			vec2(2, 1),
			vec2(1, -2),
			vec2(1, 0),
			vec2(1, 2),
			vec2(0, -3),
			vec2(0, -1),
			vec2(0, 0),
			vec2(0, 1),
			vec2(0, 3),
			vec2(-1, -2),
			vec2(-1, 0),
			vec2(-1, 2),
			vec2(-2, -1),
			vec2(-3, 0),
			vec2(-2, 1)
		);
		
		float sampleShadowSun2Smooth(Image tex, vec2 shadowUV, float depth) {
			float shadow = 0.0;
			for (int i = 0; i < 17; ++i) {
				vec2 r = texture(tex, shadowUV + sampleOffset[i] * texelSize).xy;
				shadow += (min(r.x, r.y) > depth ? 0.0588235 : 0.0);
			}
			return shadow;
		}
		
		float sampleShadowSunSmooth(vec3 vertexPos, mat4 sun_shadow_proj_1, mat4 sun_shadow_proj_2, mat4 sun_shadow_proj_3, Image sun_shadow_tex_1, Image sun_shadow_tex_2, Image sun_shadow_tex_3, vec3 bias) {
			float dist = distance(vertexPos, viewPos) * shadowDistance;
			if (dist < 1.0) {
				vec3 vertexPosShadow = (sun_shadow_proj_1 * vec4(vertexPos + bias, 1.0)).xyz;
				return sampleShadowSun2Smooth(sun_shadow_tex_1, vertexPosShadow.xy * 0.5 + 0.5, vertexPosShadow.z);
			} else if (dist < factor) {
				vec3 vertexPosShadow = (sun_shadow_proj_2 * vec4(vertexPos + bias * factor, 1.0)).xyz;
				return sampleShadowSun2Smooth(sun_shadow_tex_2, vertexPosShadow.xy * 0.5 + 0.5, vertexPosShadow.z);
			} else {
				vec3 vertexPosShadow = (sun_shadow_proj_3 * vec4(vertexPos + bias * factor * factor, 1.0)).xyz;
				float f = clamp(factor * factor - dist, 0.0, 1.0);
				return mix(1.0, sampleShadowSun2Smooth(sun_shadow_tex_3, vertexPosShadow.xy * 0.5 + 0.5, vertexPosShadow.z), f);
			}
		}
		
		float sampleShadowSun2(Image tex, vec2 shadowUV, float depth) {
			float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
			float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
			if (oy > 1.1) oy = 0.0;
			
			vec2 r1 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * texelSize).xy;
			vec2 r2 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * texelSize).xy;
			vec2 r3 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * texelSize).xy;
			vec2 r4 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * texelSize).xy;
			
			return
				(min(r1.x, r1.y) > depth ? 0.25 : 0.0) +
				(min(r2.x, r2.y) > depth ? 0.25 : 0.0) +
				(min(r3.x, r3.y) > depth ? 0.25 : 0.0) +
				(min(r4.x, r4.y) > depth ? 0.25 : 0.0);
		}
		
		float sampleShadowSun(vec3 vertexPos, mat4 sun_shadow_proj_1, mat4 sun_shadow_proj_2, mat4 sun_shadow_proj_3, Image sun_shadow_tex_1, Image sun_shadow_tex_2, Image sun_shadow_tex_3, vec3 bias) {
			float dist = distance(vertexPos, viewPos) * shadowDistance;
			if (dist < 1.0) {
				vec3 vertexPosShadow = (sun_shadow_proj_1 * vec4(vertexPos + bias, 1.0)).xyz;
				return sampleShadowSun2(sun_shadow_tex_1, vertexPosShadow.xy * 0.5 + 0.5, vertexPosShadow.z);
			} else if (dist < factor) {
				vec3 vertexPosShadow = (sun_shadow_proj_2 * vec4(vertexPos + bias * factor, 1.0)).xyz;
				return sampleShadowSun2(sun_shadow_tex_2, vertexPosShadow.xy * 0.5 + 0.5, vertexPosShadow.z);
			} else {
				vec3 vertexPosShadow = (sun_shadow_proj_3 * vec4(vertexPos + bias * factor * factor, 1.0)).xyz;
				float f = clamp(factor * factor - dist, 0.0, 1.0);
				return mix(1.0, sampleShadowSun2(sun_shadow_tex_3, vertexPosShadow.xy * 0.5 + 0.5, vertexPosShadow.z), f);
			}
		}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern mat4 sun_shadow_proj_1_#ID#;
		extern mat4 sun_shadow_proj_2_#ID#;
		extern mat4 sun_shadow_proj_3_#ID#;
		
		extern Image sun_shadow_tex_1_#ID#;
		extern Image sun_shadow_tex_2_#ID#;
		extern Image sun_shadow_tex_3_#ID#;
		
		extern bool sun_shadow_smooth_#ID#;
		extern vec3 sun_shadow_vec_#ID#;
		extern vec3 sun_shadow_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		float shadow;
		vec3 bias = normal * mix(32.0, 8.0, dot(normal, sun_shadow_vec_#ID#)) * texelSize;
		
		if (sun_shadow_smooth_#ID#) {
			shadow = sampleShadowSunSmooth(vertexPos, sun_shadow_proj_1_#ID#, sun_shadow_proj_2_#ID#, sun_shadow_proj_3_#ID#, sun_shadow_tex_1_#ID#, sun_shadow_tex_2_#ID#, sun_shadow_tex_3_#ID#, bias);
		} else {
			shadow = sampleShadowSun(vertexPos, sun_shadow_proj_1_#ID#, sun_shadow_proj_2_#ID#, sun_shadow_proj_3_#ID#, sun_shadow_tex_1_#ID#, sun_shadow_tex_2_#ID#, sun_shadow_tex_3_#ID#, bias);
		}
		
		if (shadow > 0.0) {
			vec3 lightColor = sun_shadow_color_#ID# * shadow;
			
			light += getLight(lightColor, viewVec, sun_shadow_vec_#ID#, normal, albedo.rgb, material.x, material.y);
			
			//backface light
			#ifdef TRANSLUCENT_ENABLED
				light += getLight(lightColor, viewVec, sun_shadow_vec_#ID#, reflect(normal, normalRaw), albedo.rgb, material.x, material.y) * translucent;
			#endif
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		float shadow;
		if (sun_shadow_smooth_#ID#) {
			shadow = sampleShadowSunSmooth(vertexPos, sun_shadow_proj_1_#ID#, sun_shadow_proj_2_#ID#, sun_shadow_proj_3_#ID#, sun_shadow_tex_1_#ID#, sun_shadow_tex_2_#ID#, sun_shadow_tex_3_#ID#, 0.001);
		} else {
			shadow = sampleShadowSun(vertexPos, sun_shadow_proj_1_#ID#, sun_shadow_proj_2_#ID#, sun_shadow_proj_3_#ID#, sun_shadow_tex_1_#ID#, sun_shadow_tex_2_#ID#, sun_shadow_tex_3_#ID#, 0.001);
		}
		
		light += sun_shadow_color_#ID# * shadow;
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	local shader = shaderObject.shader
	
	shader:send("factor", dream.shadow_factor)
	shader:send("shadowDistance", 2 / dream.shadow_distance)
	shader:send("texelSize", 1.0 / dream.shadow_resolution)
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader
	
	if light.shadow.canvases and light.shadow.canvases[3] then
		shader:send("sun_shadow_proj_1_" .. ID, light.shadow.cams[1].transformProj)
		shader:send("sun_shadow_proj_2_" .. ID, light.shadow.cams[2].transformProj)
		shader:send("sun_shadow_proj_3_" .. ID, light.shadow.cams[3].transformProj)
		
		shader:send("sun_shadow_tex_1_" .. ID, light.shadow.canvases[1])
		shader:send("sun_shadow_tex_2_" .. ID, light.shadow.canvases[2])
		shader:send("sun_shadow_tex_3_" .. ID, light.shadow.canvases[3])
		
		if light.smooth == nil then
			shader:send("sun_shadow_smooth_" .. ID, dream.shadow_smooth)
		else
			shader:send("sun_shadow_smooth_" .. ID, light.smooth)
		end
		
		shader:send("sun_shadow_color_" .. ID,  {light.r * light.brightness, light.g * light.brightness, light.b * light.brightness})
		
		if shader:hasUniform("sun_shadow_vec_" .. ID) then
			shader:send("sun_shadow_vec_" .. ID, {vec3(light.x, light.y, light.z):normalize():unpack()})
		end
	else
		shader:send("sun_shadow_color_" .. ID, {0, 0, 0})
	end
end

return sh