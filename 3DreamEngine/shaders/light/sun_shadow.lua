local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
	return [[
		extern float ss_factor;
		extern float ss_shadowDistance;
		extern float ss_texelSize;
		extern float ss_fade;
		
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
				float r = texture(tex, shadowUV + sampleOffset[i] * ss_texelSize).x;
				shadow += (r > depth ? 0.0588235 : 0.0);
			}
			return shadow;
		}
		
		float sampleShadowSunSmooth(vec3 vertexPos, vec3 ss_pos, mat4 ss_proj_1, mat4 ss_proj_2, mat4 ss_proj_3, Image ss_tex_1, Image ss_tex_2, Image ss_tex_3, vec3 bias) {
			float dist = distance(vertexPos, ss_pos) * ss_shadowDistance;
			
			float f2 = ss_factor * ss_factor;
			float v1 = clamp((1.0 - dist) * ss_fade * f2, 0.0, 1.0);
			float v2 = clamp((ss_factor - dist) * ss_fade * ss_factor, 0.0, 1.0) - v1;
			float v3 = clamp((f2 - dist) * ss_fade, 0.0, 1.0) - v2 - v1;
			
			float v = 1.0 - v1 - v2 - v3;
			if (v1 > 0.0) {
				vec3 uvs = (ss_proj_1 * vec4(vertexPos + bias, 1.0)).xyz;
				v += v1 * sampleShadowSun2Smooth(ss_tex_1, uvs.xy * 0.5 + 0.5, uvs.z);
			}
			if (v2 > 0.0) {
				vec3 uvs = (ss_proj_2 * vec4(vertexPos + bias * ss_factor, 1.0)).xyz;
				v += v2 * sampleShadowSun2Smooth(ss_tex_2, uvs.xy * 0.5 + 0.5, uvs.z);
			}
			if (v3 > 0.0) {
				vec3 uvs = (ss_proj_3 * vec4(vertexPos + bias * f2, 1.0)).xyz;
				v += v3 * sampleShadowSun2Smooth(ss_tex_3, uvs.xy * 0.5 + 0.5, uvs.z);
			}
			return v;
		}
		
		float sampleShadowSun2(Image tex, vec2 shadowUV, float depth) {
			float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
			float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
			if (oy > 1.1) oy = 0.0;
			
			float r1 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).x;
			float r2 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).x;
			float r3 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).x;
			float r4 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).x;
			
			return
				(r1 > depth ? 0.25 : 0.0) +
				(r2 > depth ? 0.25 : 0.0) +
				(r3 > depth ? 0.25 : 0.0) +
				(r4 > depth ? 0.25 : 0.0);
		}
		
		float sampleShadowSun(vec3 vertexPos, vec3 ss_pos, mat4 ss_proj_1, mat4 ss_proj_2, mat4 ss_proj_3, Image ss_tex_1, Image ss_tex_2, Image ss_tex_3, vec3 bias) {
			float dist = distance(vertexPos, ss_pos) * ss_shadowDistance;
			
			float f2 = ss_factor * ss_factor;
			float v1 = clamp((1.0 - dist) * ss_fade * f2, 0.0, 1.0);
			float v2 = clamp((ss_factor - dist) * ss_fade * ss_factor, 0.0, 1.0) - v1;
			float v3 = clamp((f2 - dist) * ss_fade, 0.0, 1.0) - v2 - v1;
			
			float v = 1.0 - v1 - v2 - v3;
			if (v1 > 0.0) {
				vec3 uvs = (ss_proj_1 * vec4(vertexPos + bias, 1.0)).xyz;
				v += v1 * sampleShadowSun2(ss_tex_1, uvs.xy * 0.5 + 0.5, uvs.z);
			}
			if (v2 > 0.0) {
				vec3 uvs = (ss_proj_2 * vec4(vertexPos + bias * ss_factor, 1.0)).xyz;
				v += v2 * sampleShadowSun2(ss_tex_2, uvs.xy * 0.5 + 0.5, uvs.z);
			}
			if (v3 > 0.0) {
				vec3 uvs = (ss_proj_3 * vec4(vertexPos + bias * f2, 1.0)).xyz;
				v += v3 * sampleShadowSun2(ss_tex_3, uvs.xy * 0.5 + 0.5, uvs.z);
			}
			return v;
		}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern vec3 ss_pos_#ID#;
		
		extern mat4 ss_proj_1_#ID#;
		extern mat4 ss_proj_2_#ID#;
		extern mat4 ss_proj_3_#ID#;
		
		extern Image ss_tex_1_#ID#;
		extern Image ss_tex_2_#ID#;
		extern Image ss_tex_3_#ID#;
		
		extern bool ss_smooth_#ID#;
		extern vec3 ss_vec_#ID#;
		extern vec3 ss_color_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(dream, ID)
	return ([[
		float shadow;
		vec3 bias = normal * mix(32.0, 8.0, dot(normal, ss_vec_#ID#)) * ss_texelSize;
		
		if (ss_smooth_#ID#) {
			shadow = sampleShadowSunSmooth(vertexPos, ss_pos_#ID#, ss_proj_1_#ID#, ss_proj_2_#ID#, ss_proj_3_#ID#, ss_tex_1_#ID#, ss_tex_2_#ID#, ss_tex_3_#ID#, bias);
		} else {
			shadow = sampleShadowSun(vertexPos, ss_pos_#ID#, ss_proj_1_#ID#, ss_proj_2_#ID#, ss_proj_3_#ID#, ss_tex_1_#ID#, ss_tex_2_#ID#, ss_tex_3_#ID#, bias);
		}
		
		if (shadow > 0.0) {
			vec3 lightColor = ss_color_#ID# * shadow;
			
			light += getLight(lightColor, viewVec, ss_vec_#ID#, normal, albedo, roughness, metallic, translucent);
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		float shadow;
		vec3 bias = normalize(vertexPos - viewPos) * 8.0 * ss_texelSize;
		
		if (ss_smooth_#ID#) {
			shadow = sampleShadowSunSmooth(vertexPos, ss_pos_#ID#, ss_proj_1_#ID#, ss_proj_2_#ID#, ss_proj_3_#ID#, ss_tex_1_#ID#, ss_tex_2_#ID#, ss_tex_3_#ID#, bias);
		} else {
			shadow = sampleShadowSun(vertexPos, ss_pos_#ID#, ss_proj_1_#ID#, ss_proj_2_#ID#, ss_proj_3_#ID#, ss_tex_1_#ID#, ss_tex_2_#ID#, ss_tex_3_#ID#, bias);
		}
		
		light += ss_color_#ID# * shadow;
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	local shader = shaderObject.shader
	
	shader:send("ss_factor", dream.shadow_factor)
	shader:send("ss_fade", 4 / dream.shadow_factor / dream.shadow_factor)
	shader:send("ss_shadowDistance", 2 / dream.shadow_distance)
	shader:send("ss_texelSize", 1.0 / dream.shadow_resolution)
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader
	
	if light.shadow.canvases and light.shadow.canvases[3] then
		shader:send("ss_pos_" .. ID, light.shadow.cams[1].pos)
		
		shader:send("ss_proj_1_" .. ID, light.shadow.cams[1].transformProj)
		shader:send("ss_proj_2_" .. ID, light.shadow.cams[2].transformProj)
		shader:send("ss_proj_3_" .. ID, light.shadow.cams[3].transformProj)
		
		shader:send("ss_tex_1_" .. ID, light.shadow.canvases[1])
		shader:send("ss_tex_2_" .. ID, light.shadow.canvases[2])
		shader:send("ss_tex_3_" .. ID, light.shadow.canvases[3])
		
		if light.smooth == nil then
			shader:send("ss_smooth_" .. ID, dream.shadow_smooth)
		else
			shader:send("ss_smooth_" .. ID, light.smooth)
		end
		
		shader:send("ss_color_" .. ID,  {(light.color * light.brightness):unpack()})
		
		if shader:hasUniform("ss_vec_" .. ID) then
			shader:send("ss_vec_" .. ID, {light.direction:unpack()})
		end
	else
		shader:send("ss_color_" .. ID, {0, 0, 0})
	end
end

return sh