local sh = { }

sh.type = "light"

function sh:constructDefinesGlobal(dream, info)
	return [[
		extern float factor;
		extern float shadowDistance;
		extern float texelSize;
		
		float sampleShadowSun2(sampler2DShadow tex, vec3 shadowUV) {
			float ox = float(fract(love_PixelCoord.x * 0.5) > 0.25);
			float oy = float(fract(love_PixelCoord.y * 0.5) > 0.25) + ox;
			if (oy > 1.1) oy = 0.0;
			
			return (
				texture(tex, shadowUV + vec3(-1.5 + ox, 0.5 + oy, 0.0) * texelSize) +
				texture(tex, shadowUV + vec3(0.5 + ox, 0.5 + oy, 0.0) * texelSize) +
				texture(tex, shadowUV + vec3(-1.5 + ox, -1.5 + oy, 0.0) * texelSize) +
				texture(tex, shadowUV + vec3(0.5 + ox, -1.5 + oy, 0.0) * texelSize)
			) * 0.25;
		}
		
		float sampleShadowSun(vec3 vertexPos, mat4 transformProjShadow_1, mat4 transformProjShadow_2, mat4 transformProjShadow_3, sampler2DShadow tex_shadow_1, sampler2DShadow tex_shadow_2, sampler2DShadow tex_shadow_3) {
			float bias = 0.0005;
			vec4 vertexPosShadow;
			vec3 shadowUV;
			float dist = distance(vertexPos, viewPos) * shadowDistance;
			
			if (dist < 1.0) {
				vertexPosShadow = transformProjShadow_1 * vec4(vertexPos.xyz, 1.0);
				shadowUV = vertexPosShadow.xyz - vec3(0.0, 0.0, bias);
				return sampleShadowSun2(tex_shadow_1, shadowUV * 0.5 + 0.5);
			} else if (dist < factor) {
				vertexPosShadow = transformProjShadow_2 * vec4(vertexPos.xyz, 1.0);
				shadowUV = vertexPosShadow.xyz - vec3(0.0, 0.0, bias * factor);
				return sampleShadowSun2(tex_shadow_2, shadowUV * 0.5 + 0.5);
			} else {
				vertexPosShadow = transformProjShadow_3 * vec4(vertexPos.xyz, 1.0);
				shadowUV = vertexPosShadow.xyz - vec3(0.0, 0.0, bias * factor * factor);
				return sampleShadowSun2(tex_shadow_3, shadowUV * 0.5 + 0.5);
			}
		}
	]]
end

function sh:constructDefines(dream, info, ID)
	return ([[
		extern highp mat4 transformProjShadow_1_#ID#;
		extern highp mat4 transformProjShadow_2_#ID#;
		extern highp mat4 transformProjShadow_3_#ID#;
		extern sampler2DShadow tex_shadow_1_#ID#;
		extern sampler2DShadow tex_shadow_2_#ID#;
		extern sampler2DShadow tex_shadow_3_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixel(dream, info, ID, lightSignature)
	return ([[
		float shadow = sampleShadowSun(vertexPos, transformProjShadow_1_#ID#, transformProjShadow_2_#ID#, transformProjShadow_3_#ID#, tex_shadow_1_#ID#, tex_shadow_2_#ID#, tex_shadow_3_#ID#);
		if (shadow > 0.0) {
			vec3 lightVec = normalize(lightPos[#ID#]);
			light += getLight(lightColor[#ID#], viewVec, lightVec, normal, #lightSignature#);
		}
	]]):gsub("#ID#", ID):gsub("#lightSignature#", lightSignature)
end

function sh:sendGlobalUniforms(dream, shader, info)
	shader:send("factor", dream.shadow_factor)
	shader:send("shadowDistance", 2 / dream.shadow_distance)
	shader:send("texelSize", 1.0 / dream.shadow_resolution)
end

function sh:sendUniforms(dream, shader, info, light, ID)
	if light.shadow.canvases and light.shadow.canvases[3] then
		shader:send("transformProjShadow_1_" .. ID, light.shadow.transformation_1)
		shader:send("transformProjShadow_2_" .. ID, light.shadow.transformation_2)
		shader:send("transformProjShadow_3_" .. ID, light.shadow.transformation_3)
		shader:send("tex_shadow_1_" .. ID, light.shadow.canvases[1])
		shader:send("tex_shadow_2_" .. ID, light.shadow.canvases[2])
		shader:send("tex_shadow_3_" .. ID, light.shadow.canvases[3])
	else
		return
	end
end

return sh