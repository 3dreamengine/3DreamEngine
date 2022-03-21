local sh = { }

sh.type = "world"

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:buildDefines(dream, mat, shadow)
	if shadow then
		return ""
	else
		return [[
		vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float roughness, float metallic) {
			vec3 lightDir = normalize(lightVec);
			float diffuse = clamp(dot(normal, lightDir), 0.0, 1.0) * (1.0 - metallic * 0.9);
			
			vec3 H = normalize(lightDir - normalize(viewVec));
			float NdotH = clamp(dot(normal, H), 0.0, 1.0);
			float highlight = pow(1.0 - roughness, 2.0) * 256.0 + 0.0001;
			float specular = pow(NdotH, highlight) * (1.0 - roughness);
			
			return (albedo * diffuse + specular) * lightColor;
		}
	]]
	end
end

function sh:buildPixel(dream, mat, shadow)
	if shadow then
		return ""
	else
		return [[
		//reflections
		vec3 reflectVec = reflect(viewVec, normal); 
		vec3 ref = reflection(reflectVec, roughness);
		
		//final color
		vec3 F0 = mix(vec3(0.08), albedo.rgb, metallic);
		color = F0 * ref * ao + emission;
		
		//lighting
		color += light;
		]]
	end
end

function sh:buildVertex(dream, mat)
	return ""
end

function sh:perShader(dream, shaderObject)
	
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)
	
end

return sh