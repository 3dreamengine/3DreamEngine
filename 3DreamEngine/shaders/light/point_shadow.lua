local sh = { }

sh.func = "sampleShadowPoint"

function sh:constructDefinesGlobal(dream)
	return [[
	float sampleShadowPoint(vec3 lightVec, samplerCube tex) {
		float depth = length(lightVec);
		float bias = depth * 0.01 + 0.01;
		
		//direction
		vec3 n = normalize(-lightVec * vec3(1.0, -1.0, 1.0));
		
		//fetch
		float r = texture(tex, n).x;
		return r + bias > depth ? 1.0 : 0.0;
	}
	]]
end

function sh:constructDefines(ID)
	return ([[
	extern samplerCube ps_tex_#ID#;
	extern vec3 ps_pos_#ID#;
	extern vec3 ps_color_#ID#;
	extern float ps_attenuation_#ID#;
	]]):gsub("#ID#", ID)
end

function sh:constructPixelGlobal(dream)

end

function sh:constructPixelBasicGlobal(dream)

end

function sh:constructPixel(ID)
	return ([[
		vec3 lightVec = ps_pos_#ID# - vertexPos;
		
		float shadow = ]] .. self.func .. [[(lightVec, ps_tex_#ID#); //hee
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = pow(distance, ps_attenuation_#ID#);
			vec3 lightColor = ps_color_#ID# * shadow * power;
			lightVec = normalize(lightVec);
			
			light += getLight(lightColor, viewVec, lightVec, normal, albedo, roughness, metallic);
		}
	]]):gsub("#ID#", ID)
end

function sh:constructPixelBasic(ID)
	return ([[
		vec3 lightVec = ps_pos_#ID# - vertexPos;
		
		float shadow = ]] .. self.func .. [[(lightVec, ps_tex_#ID#);
		
		if (shadow > 0.0) {
			float distance = length(lightVec) + 1.0;
			float power = pow(distance, ps_attenuation_#ID#);
			light += ps_color_#ID# * shadow * power;
		}
	]]):gsub("#ID#", ID)
end

function sh:sendGlobalUniforms(shaderObject)
	
end

function sh:sendUniforms(shaderObject, light, ID)
	local shader = shaderObject.shader or shaderObject
	
	if light.shadow.canvas then
		shader:send("ps_tex_" .. ID, light.shadow.canvas)
		shader:send("ps_color_" .. ID, light.color * light.brightness)
		shader:send("ps_pos_" .. ID, light.position)
		shader:send("ps_attenuation_" .. ID, -light.attenuation)
	else
		shader:send("ps_color_" .. ID, {0, 0, 0})
	end
end

return sh