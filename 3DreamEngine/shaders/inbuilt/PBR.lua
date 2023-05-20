local dream = _3DreamEngine

local sh = { }

sh.type = "world"

function sh:buildDefines(mat, shadow)
	if shadow then
		return ""
	else
		return [[
			#ifdef PIXEL
			uniform Image brdfLUT;
			
			uniform float ior;
			
			//PBR lighting
			const float pi = 3.14159265359;
			const float ipi = 0.31830988618;
			
			float DistributionGGX(vec3 normal, vec3 halfView, float roughness) {
				float a = pow(roughness, 4.0);
				
				#ifdef IS_PARTICLE
					return a / pi;
				#else
					float NdotH = max(dot(normal, halfView), 0.0);
					float NdotH2 = NdotH * NdotH;
					
					float denom = NdotH2 * (a - 1.0) + 1.0;
					denom = pi * denom * denom;
					
					return a / max(denom, 0.01);
				#endif
			}
			
			float GeometrySchlickGGX(float NdotV, float roughness) {
				float r = roughness + 1.0;
				float k = (r * r) * 0.125;
				float denom = NdotV * (1.0 - k) + k;
				return NdotV / denom;
			}
			
			float GeometrySmith(vec3 normal, vec3 view, vec3 light, float roughness) {
				#ifdef IS_PARTICLE
					return pow(GeometrySchlickGGX(1.0, roughness), 2.0);
				#else
					float NdotV = max(dot(normal, view), 0.0);
					float NdotL = max(dot(normal, light), 0.0);
					float ggx2 = GeometrySchlickGGX(NdotV, roughness);
					float ggx1 = GeometrySchlickGGX(NdotL, roughness);
					return ggx1 * ggx2;
				#endif
			}
			
			vec3 getLight(vec3 lightColor, vec3 viewVec, vec3 lightVec, vec3 normal, vec3 albedo, float roughness, float metallic) {
				#ifdef IS_PARTICLE
					normal = normalize(lightVec);
					viewVec = -normalize(lightVec);
				#endif
				
				vec3 vec = -viewVec;
				
				//backface
				#ifdef TRANSLUCENCY
					if (dot(normal, lightVec) < 0.0) {
						lightVec = normalize(reflect(lightVec, normal));
						lightColor *= translucency;
					}
				#endif
				
				//reflectance
				vec3 F0 = mix(vec3(0.04), albedo, metallic);
				
				vec3 halfVec = normalize(vec + lightVec);
				
				float NDF = DistributionGGX(normal, halfVec, roughness);   
				float G = GeometrySmith(normal, vec, lightVec, roughness);
				
				//fresnel
				vec3 fresnel;
				#ifdef IS_PARTICLE
					fresnel = F0;
				#else
					float cosTheta = clamp(dot(halfVec, vec), 0.0, 1.0);
					fresnel = F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
				#endif
				
				//specular
				vec3 nominator = NDF * G * fresnel;
				#ifdef IS_PARTICLE
					// The result of a 45° view and light angle
					float denominator = 1.0;
				#else
					float denominator = 4.0 * max(dot(normal, vec), 0.0) * max(dot(normal, lightVec), 0.0) + 0.001;
				#endif
				vec3 specular = nominator / denominator;
				
				//energy conservation
				vec3 kD = (vec3(1.0) - fresnel) * (1.0 - metallic);
				
				#ifdef IS_PARTICLE
					float lightAngle = 1.0;
				#else
					float lightAngle = max(dot(lightVec, normal), 0.0);
				#endif
				
				return (kD * albedo * ipi + specular) * lightColor * lightAngle;
			}
			#endif
		]]
	end
end

function sh:buildPixel(mat, shadow)
	if shadow then
		return ""
	else
		return [[
		float cosTheta = -dot(normal, viewVec);
		
		//PBR model data
		vec3 reflectVec = reflect(viewVec, normal); 
		cosTheta = clamp(cosTheta, 0.0, 1.0);
		vec3 F0 = mix(vec3(0.04), albedo.rgb, metallic);
		
		//fresnel
		vec3 F = F0 + (vec3(1.0) - F0) * pow(1.0 - cosTheta, 5.0);
		
		//specular and diffuse component
		vec3 kS = F;
		vec3 kD = (1.0 - kS) * (1.0 - metallic);
		
		//use the reflection texture as irradiance map approximation
		vec3 diffuse = reflection(normal, 1.0) * albedo.rgb;
		
		//final ambient color with reflection
		//approximate the specular part with brdf lookup table
		vec3 ref = reflection(reflectVec, roughness);
		vec2 brdf = Texel(brdfLUT, vec2(cosTheta, roughness)).rg;
		vec3 specular = ref * (F * brdf.x + vec3(brdf.y));
		
		//final color
		color = (kD * diffuse + specular) * ao + emission;
		
		//lighting
		color += light;
		]]
	end
end

function sh:buildVertex(mat)
	return ""
end

function sh:perShader(shaderObject)
	local shader = shaderObject.shader
	
	if shader:hasUniform("brdfLUT") then
		dream.initTextures:PBR()
		shader:send("brdfLUT", dream.textures.brdfLUT)
	end
end

function sh:perMaterial(shaderObject, material)
	local shader = shaderObject.shader
	
	if shader:hasUniform("ior") then
		shader:send("ior", 1 / material.ior)
	end
end

function sh:perTask(shaderObject, task)
	
end

return sh