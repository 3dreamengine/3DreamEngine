local sh = { }

sh.type = "light"

sh.func = "sampleShadowSun"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowSun2(Image tex, vec2 shadowUV, float depth) {
		float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
		float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
		if (oy > 1.1) oy = 0.0;
		float ss_texelSize = 1.0 / love_ScreenSize.x;
		
		float r0 = texture(tex, shadowUV + vec2(-1.5 + ox, 0.5 + oy) * ss_texelSize).x;
		float r1 = texture(tex, shadowUV + vec2(0.5 + ox, 0.5 + oy) * ss_texelSize).x;
		float r2 = texture(tex, shadowUV + vec2(-1.5 + ox, -1.5 + oy) * ss_texelSize).x;
		float r3 = texture(tex, shadowUV + vec2(0.5 + ox, -1.5 + oy) * ss_texelSize).x;
		
		return (r0 > depth ? 0.25 : 0.0) +
			(r1 > depth ? 0.25 : 0.0) +
			(r2 > depth ? 0.25 : 0.0) +
			(r3 > depth ? 0.25 : 0.0)
		;
	}
	]] .. self:constructDefinesGlobalCommon(dream)
end

function sh:constructDefinesGlobalCommon(dream)
	return [[
	float ]] .. self.func .. [[(vec3 vertexPos, vec3 pos, mat4 proj1, mat4 proj2, mat4 proj3, Image tex1, Image tex2, Image tex3, float factor, float shadowDistance, float fade, float bias) {
		float dist = distance(vertexPos, pos) * shadowDistance;
		
		float f2 = factor * factor;
		float v1 = clamp((1.0 - dist) * fade * f2, 0.0, 1.0);
		float v2 = clamp((factor - dist) * fade * factor, 0.0, 1.0) - v1;
		float v3 = clamp((f2 - dist) * fade, 0.0, 1.0) - v2 - v1;
		
		float v = 1.0 - v1 - v2 - v3;
		if (v1 > 0.0) {
			vec3 uvs = (proj1 * vec4(vertexPos, 1.0)).xyz;
			v += v1 * ]] .. self.func ..[[2(tex1, uvs.xy * 0.5 + 0.5, uvs.z - bias);
		}
		if (v2 > 0.0) {
			vec3 uvs = (proj2 * vec4(vertexPos, 1.0)).xyz;
			v += v2 * ]] .. self.func ..[[2(tex2, uvs.xy * 0.5 + 0.5, uvs.z - bias * factor);
		}
		if (v3 > 0.0) {
			vec3 uvs = (proj3 * vec4(vertexPos, 1.0)).xyz;
			v += v3 * ]] .. self.func ..[[2(tex3, uvs.xy * 0.5 + 0.5, uvs.z - bias * f2);
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
	
	extern vec3 ss_pos_#ID#;
	
	extern mat4 ss_proj1_#ID#;
	extern mat4 ss_proj2_#ID#;
	extern mat4 ss_proj3_#ID#;
	
	extern Image ss_tex1_#ID#;
	extern Image ss_tex2_#ID#;
	extern Image ss_tex3_#ID#;
	
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
	float bias = mix(1.0, 0.01, dot(normal, ss_vec_#ID#)) / 512.0;
	float shadow = ]] .. self.func .. [[(vertexPos, ss_pos_#ID#, ss_proj1_#ID#, ss_proj2_#ID#, ss_proj3_#ID#, ss_tex1_#ID#, ss_tex2_#ID#, ss_tex3_#ID#, ss_factor_#ID#, ss_distance_#ID#, ss_fade_#ID#, bias);
	
	if (shadow > 0.0) {
		vec3 lightColor = ss_color_#ID# * shadow;
		
		light += getLight(lightColor, viewVec, ss_vec_#ID#, normal, albedo, roughness, metallic);
	}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(dream, ID)
	return ([[
	float bias = 1.0 / 512.0;
	float shadow = ]] .. self.func .. [[(vertexPos, ss_pos_#ID#, ss_proj1_#ID#, ss_proj2_#ID#, ss_proj3_#ID#, ss_tex1_#ID#, ss_tex2_#ID#, ss_tex3_#ID#, ss_factor_#ID#, ss_distance_#ID#, ss_fade_#ID#, bias);
	
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
		
		shader:send("ss_pos_" .. ID, light.shadow.cams[1].pos)
		
		shader:send("ss_proj1_" .. ID, light.shadow.cams[1].transformProj)
		shader:send("ss_proj2_" .. ID, light.shadow.cams[2].transformProj)
		shader:send("ss_proj3_" .. ID, light.shadow.cams[3].transformProj)
		
		shader:send("ss_tex1_" .. ID, light.shadow.canvases[1])
		shader:send("ss_tex2_" .. ID, light.shadow.canvases[2])
		shader:send("ss_tex3_" .. ID, light.shadow.canvases[3])
		
		shader:send("ss_color_" .. ID, light.color * light.brightness)
		
		if shader:hasUniform("ss_vec_" .. ID) then
			shader:send("ss_vec_" .. ID, light.direction)
		end
	else
		shader:send("ss_color_" .. ID, {0, 0, 0})
	end
end

return sh