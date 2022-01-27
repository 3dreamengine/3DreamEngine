local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream)
	return [[
		#define DISTANCE_FACTOR 10.0f
		
		float sampleShadowSun2(Image tex, vec2 shadowUV, float depth, float bias, bool staticShadow, bool smoothShadows) {
			float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
			float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
			if (oy > 1.1) oy = 0.0;
			float ss_texelSize = 1.0 / love_ScreenSize.x;
			float sharpness = 4.0;
			
			depth -= 0.001;
			
			if (staticShadow) {
				if (smoothShadows) {
					float sampleDepth = texture(tex, shadowUV).x;
					return clamp(exp(sharpness * (sampleDepth - depth * DISTANCE_FACTOR)), 0.0, 1.0);
				} else {
					float r0 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).x;
					float r1 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).x;
					float r2 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).x;
					float r3 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).x;
					
					return (
						r0 > depth ? 0.25 : 0.0 +
						r1 > depth ? 0.25 : 0.0 +
						r2 > depth ? 0.25 : 0.0 +
						r3 > depth ? 0.25 : 0.0
					);
				}
			} else {
				if (smoothShadows) {
					float sampleDepth = texture(tex, shadowUV).x;
					float sh = clamp(exp(sharpness * (sampleDepth - depth * DISTANCE_FACTOR)), 0.0, 1.0);
					
					float r0 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).y;
					float r1 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).y;
					float r2 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).y;
					float r3 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).y;
					
					depth -= bias;
					return sh * (
						(r0 > depth ? 0.25 : 0.0) +
						(r1 > depth ? 0.25 : 0.0) +
						(r2 > depth ? 0.25 : 0.0) +
						(r3 > depth ? 0.25 : 0.0)
					);
				} else {
					vec2 r0 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).xy;
					vec2 r1 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).xy;
					vec2 r2 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).xy;
					vec2 r3 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).xy;
					
					depth -= bias;
					return (
						(min(r0.x, r0.y) > depth ? 0.25 : 0.0) +
						(min(r1.x, r1.y) > depth ? 0.25 : 0.0) +
						(min(r2.x, r2.y) > depth ? 0.25 : 0.0) +
						(min(r3.x, r3.y) > depth ? 0.25 : 0.0)
					);
				}
			}
		}
		
		float sampleShadowSun(vec3 VertexPos, vec3 pos, mat4 proj_1, mat4 proj_2, mat4 proj_3, Image tex_1, Image tex_2, Image tex_3, float factor, float shadowDistance, float fade, bool staticShadow, bool smoothShadows, float bias) {
			float dist = distance(VertexPos, pos) * shadowDistance;
			
			float f2 = factor * factor;
			float v1 = clamp((1.0 - dist) * fade * f2, 0.0, 1.0);
			float v2 = clamp((factor - dist) * fade * factor, 0.0, 1.0) - v1;
			float v3 = clamp((f2 - dist) * fade, 0.0, 1.0) - v2 - v1;
			
			float v = 1.0 - v1 - v2 - v3;
			if (v1 > 0.0) {
				vec3 uvs = (proj_1 * vec4(VertexPos, 1.0)).xyz;
				v += v1 * sampleShadowSun2(tex_1, uvs.xy * 0.5 + 0.5, uvs.z, bias, staticShadow, smoothShadows);
			}
			if (v2 > 0.0) {
				vec3 uvs = (proj_2 * vec4(VertexPos, 1.0)).xyz;
				v += v2 * sampleShadowSun2(tex_2, uvs.xy * 0.5 + 0.5, uvs.z, bias, staticShadow, smoothShadows);
			}
			if (v3 > 0.0) {
				vec3 uvs = (proj_3 * vec4(VertexPos, 1.0)).xyz;
				v += v3 * sampleShadowSun2(tex_3, uvs.xy * 0.5 + 0.5, uvs.z, bias, staticShadow, smoothShadows);
			}
			return v;
		}
	]]
end

function sh:constructDefines(dream, ID)
	return ([[
		extern float ss_factor_#ID#;
		extern float ss_distance_#ID#;
		extern float ss_fade_#ID#;
		extern bool ss_staticShadow_#ID#;
		extern bool ss_smooth_#ID#;
		
		extern vec3 ss_pos_#ID#;
		
		extern mat4 ss_proj_1_#ID#;
		extern mat4 ss_proj_2_#ID#;
		extern mat4 ss_proj_3_#ID#;
		
		extern Image ss_tex_1_#ID#;
		extern Image ss_tex_2_#ID#;
		extern Image ss_tex_3_#ID#;
		
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
		float bias = mix(4.0, 0.0, dot(normal, ss_vec_#ID#)) / love_ScreenSize.x;
		float shadow = sampleShadowSun(VertexPos, ss_pos_#ID#, ss_proj_1_#ID#, ss_proj_2_#ID#, ss_proj_3_#ID#, ss_tex_1_#ID#, ss_tex_2_#ID#, ss_tex_3_#ID#, ss_factor_#ID#, ss_distance_#ID#, ss_fade_#ID#, ss_staticShadow_#ID#, ss_smooth_#ID#, bias);
		
		if (shadow > 0.0) {
			vec3 lightColor = ss_color_#ID# * shadow;
			
			light += getLight(lightColor, viewVec, ss_vec_#ID#, normal, fragmentNormal, albedo, roughness, metallic);
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
		float bias = 8.0 / love_ScreenSize.x;
		float shadow = sampleShadowSun(VertexPos, ss_pos_#ID#, ss_proj_1_#ID#, ss_proj_2_#ID#, ss_proj_3_#ID#, ss_tex_1_#ID#, ss_tex_2_#ID#, ss_tex_3_#ID#, ss_factor_#ID#, ss_distance_#ID#, ss_fade_#ID#, ss_staticShadow_#ID#, ss_smooth_#ID#, bias);
		
		light += ss_color_#ID# * shadow;
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(dream, shaderObject)
	
end

function sh:sendUniforms(dream, shaderObject, light, ID)
	local shader = shaderObject.shader
	
	if light.shadow.canvases and light.shadow.canvases[3] then
		shader:send("ss_factor_" .. ID, light.shadow.cascadeFactor)
		shader:send("ss_fade_" .. ID, 4 / light.shadow.cascadeFactor / light.shadow.cascadeFactor)
		shader:send("ss_distance_" .. ID, 2 / light.shadow.cascadeDistance)
		
		shader:send("ss_staticShadow_" .. ID, light.shadow.static and true or false)
		shader:send("ss_smooth_" .. ID, light.shadow.smooth and true or false)
		
		shader:send("ss_pos_" .. ID, light.shadow.cams[1].pos)
		
		shader:send("ss_proj_1_" .. ID, light.shadow.cams[1].transformProj)
		shader:send("ss_proj_2_" .. ID, light.shadow.cams[2].transformProj)
		shader:send("ss_proj_3_" .. ID, light.shadow.cams[3].transformProj)
		
		shader:send("ss_tex_1_" .. ID, light.shadow.canvases[1])
		shader:send("ss_tex_2_" .. ID, light.shadow.canvases[2])
		shader:send("ss_tex_3_" .. ID, light.shadow.canvases[3])
		
		shader:send("ss_color_" .. ID,  {(light.color * light.brightness):unpack()})
		
		if shader:hasUniform("ss_vec_" .. ID) then
			shader:send("ss_vec_" .. ID, {light.direction:unpack()})
		end
	else
		shader:send("ss_color_" .. ID, {0, 0, 0})
	end
end

return sh