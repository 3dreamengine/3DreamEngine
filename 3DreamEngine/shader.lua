--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
shader.lua - contains the shaders
--]]

local lib = _3DreamEngine

--blur
lib.blur = love.graphics.newShader([[
	extern vec2 size;
	extern float hstep;
	extern float vstep;

	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		vec4 sum = vec4(0.0);
		
		sum += Texel(texture, tc - vec2(4.0*hstep, 4.0*vstep) * size) * 0.0162162162;
		sum += Texel(texture, tc - vec2(3.0*hstep, 3.0*vstep) * size) * 0.0540540541;
		sum += Texel(texture, tc - vec2(2.0*hstep, 2.0*vstep) * size) * 0.1216216216;
		sum += Texel(texture, tc - vec2(1.0*hstep, 1.0*vstep) * size) * 0.1945945946;
		
		sum += Texel(texture, tc) * 0.2270270270;
		
		sum += Texel(texture, tc + vec2(1.0*hstep, tc.y + 1.0*vstep) * size) * 0.1945945946;
		sum += Texel(texture, tc + vec2(2.0*hstep, tc.y + 2.0*vstep) * size) * 0.1216216216;
		sum += Texel(texture, tc + vec2(3.0*hstep, tc.y + 3.0*vstep) * size) * 0.0540540541;
		sum += Texel(texture, tc + vec2(4.0*hstep, tc.y + 4.0*vstep) * size) * 0.0162162162;
		
		return sum;
	}
]])

lib.post = love.graphics.newShader([[
	extern Image depth;
	extern Image AO;
	extern float fog;
	extern float strength;
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float AOv = 0.6 + Texel(AO, tc).r * strength;
		float depth = min(1.0, Texel(depth, tc).r * fog);
		return (Texel(texture, tc) * vec4(AOv, AOv, AOv, 1.0)) * (1.0-depth) + vec4(0.5, 0.5, 0.5, 1.0) * depth;
	}
]])

function lib.loadShader(self)
	if self.flat then
		if self.lighting_enabled then
			if self.pixelPerfect then
				--flat per pixel shading, lightning
				lib.shader = love.graphics.newShader([[
					]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
					
					varying vec4 colorRaw;
					varying vec4 pos;
					varying vec3 normal;
					varying float reflectionAngle;
					varying float specular;
					
					#ifdef PIXEL
					extern vec3 lightPos[]].. self.lighting_max .. [[];
					extern vec4 lightColor[]].. self.lighting_max .. [[];
					int lightCount = ]] .. self.lighting_max .. [[;
					
					void effect() {
						vec4 col = VaryingColor;
						for (int i = 0; i < lightCount; i++) {
							if (lightColor[i].a > 0.0) {
								//sun
								vec3 diff = lightPos[i]-pos.xyz;
								float dotLightNormal = dot(normalize(diff), normal);
								float angle = max(0, dotLightNormal);
								vec3 reflection = normalize(diff - 2 * dotLightNormal * normal);
								float power = (angle * (1.0 - specular * 0.5) + reflectionAngle * specular) / length(diff);
								
								col += colorRaw * lightColor[i] * power;
							} else {
								break;
							}
						}
						
						love_Canvases[0] = col;
						]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
					}
					#endif
					
					#ifdef VERTEX
					extern mat4 cam;
					extern vec3 camV;
					extern mat4 transform;
					extern vec3 sun;
					extern vec4 sunColor;
					extern vec4 ambient;
					extern mat3 rotate;
					
					vec4 position(mat4 transform_projection, vec4 vertex_position) {
						pos = (vertex_position * transform);
						normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
						
						//sun
						float dotSunNormal = dot(sun, normal);
						float angle = max(0, dotSunNormal);
						vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
						reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexTexCoord.a * 4.0 - VertexTexCoord.a * 2.0) * VertexTexCoord.a * 2.0;
						float power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a);
						
						colorRaw = VertexColor;
						VaryingColor = ConstantColor * (VertexColor + vec4(power*0.2)) * (ambient + sunColor * power);
						specular = VertexTexCoord.a;
						
						vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
						]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
						return vPos + vec4(0, 0, 0.75, 0);
					}
					#endif
				]])
			else
				--flat shading, lightning
				lib.shader = love.graphics.newShader([[
					]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
					
					]] .. (self.AO_enabled and [[
					#ifdef PIXEL
					void effect() {
						love_Canvases[0] = VaryingColor;
						love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
					}
					#endif
					]] or "") .. [[
					
					#ifdef VERTEX
					extern mat4 cam;
					extern vec3 camV;
					extern mat4 transform;
					extern vec3 sun;
					extern vec4 sunColor;
					extern vec4 ambient;
					extern mat3 rotate;
					
					extern vec3 lightPos[]].. self.lighting_max .. [[];
					extern vec4 lightColor[]].. self.lighting_max .. [[];
					int lightCount = ]] .. self.lighting_max .. [[;
					
					vec4 position(mat4 transform_projection, vec4 vertex_position) {
						vec4 pos = (vertex_position * transform);
						vec3 normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
						
						//sun
						float dotSunNormal = dot(sun, normal);
						float angle = max(0, dotSunNormal);
						vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
						float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexTexCoord.a * 4.0 - VertexTexCoord.a * 2.0) * VertexTexCoord.a * 2.0;
						float power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a) * 1.0;
						
						VaryingColor = ConstantColor * (VertexColor + vec4(power*0.2)) * (ambient + sunColor * power);
						
						for (int i = 0; i < lightCount; i++) {
							if (lightColor[i].a > 0.0) {
								//sun
								vec3 diff = lightPos[i]-pos.xyz;
								dotSunNormal = dot(normalize(diff), normal);
								angle = max(0, dotSunNormal);
								reflection = normalize(sun - 2 * dotSunNormal * normal);
								power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a) / length(diff);
								
								VaryingColor += (VertexColor + vec4(power*0.2)) * lightColor[i] * power;
							} else {
								break;
							}
						}
						
						vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
						]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
						return vPos + vec4(0, 0, 0.75, 0);
					}
					#endif
				]])
			end
		else
			--flat shading
			lib.shader = love.graphics.newShader([[
				]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
				
				]] .. (self.AO_enabled and [[
				#ifdef PIXEL
				void effect() {
					love_Canvases[0] = VaryingColor;
					love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
				}
				#endif
				]] or "") .. [[
				
				#ifdef VERTEX
				extern mat4 cam;
				extern vec3 camV;
				extern mat4 transform;
				extern vec3 sun;
				extern vec4 sunColor;
				extern vec4 ambient;
				extern mat3 rotate;
				
				extern vec3 lightPos[]].. self.lighting_max .. [[];
				extern vec4 lightColor[]].. self.lighting_max .. [[];
				int lightCount = ]] .. self.lighting_max .. [[;
				
				vec4 position(mat4 transform_projection, vec4 vertex_position) {
					vec4 pos = (vertex_position * transform);
					
					vec3 normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
					float dotSunNormal = dot(sun, normal);
					float angle = max(0, dotSunNormal);
					
					vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
					float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexTexCoord.a * 4.0 - VertexTexCoord.a * 2.0) * VertexTexCoord.a * 2.0;
					
					float power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a) * 1.0;
					
					VaryingColor = ConstantColor * VertexColor * (ambient + sunColor * power);
					
					vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
					]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
					return vPos + vec4(0, 0, 0.75, 0);
				}
				#endif
			]])
		end
	else
		if self.pixelPerfect then
			--textured, per pixel lighting, specular map
			lib.shader = love.graphics.newShader([[
				]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
				
				varying vec4 pos;
				varying vec3 normal;
				varying float reflectionAngle;
				
				#ifdef PIXEL
				extern Image tex_spec;
				uniform Image MainTex;
				
				extern vec3 lightPos[]].. self.lighting_max .. [[];
				extern vec4 lightColor[]].. self.lighting_max .. [[];
				int lightCount = ]] .. self.lighting_max .. [[;
				
				void effect() {
					float specular = Texel(tex_spec, VaryingTexCoord.xy).r;
					
					vec4 col = VaryingColor;
					for (int i = 0; i < lightCount; i++) {
						if (lightColor[i].a > 0.0) {
							//sun
							vec3 diff = lightPos[i]-pos.xyz;
							float dotLightNormal = dot(normalize(diff), normal);
							float angle = max(0, dotLightNormal);
							vec3 reflection = normalize(diff - 2 * dotLightNormal * normal);
							float power = (angle * (1.0 - specular * 0.5) + reflectionAngle * specular) / length(diff);
							
							col += lightColor[i] * power;
						} else {
							break;
						}
					}
					
					love_Canvases[0] = col * Texel(MainTex, VaryingTexCoord.xy);
					]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
				}
				#endif
				
				#ifdef VERTEX
				extern mat4 cam;
				extern vec3 camV;
				extern mat4 transform;
				extern vec3 sun;
				extern vec4 sunColor;
				extern vec4 ambient;
				extern mat3 rotate;
				
				vec4 position(mat4 transform_projection, vec4 vertex_position) {
					pos = (vertex_position * transform);
					normal = (VertexColor.rgb - vec3(0.5)) * 2.0 * rotate;
					
					//sun
					float dotSunNormal = dot(sun, normal);
					float angle = max(0, dotSunNormal);
					vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
					reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexColor.a * 4.0 - VertexColor.a * 2.0) * VertexColor.a * 2.0;
					float power = (angle * (1.0 - VertexColor.a * 0.5) + reflectionAngle * VertexColor.a) * 1.0;
					
					VaryingColor = ConstantColor * (ambient + sunColor * power);
					
					vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
					]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
					return vPos + vec4(0, 0, 0.75, 0);
				}
				#endif
			]])
		else
			--textured, lighting
			lib.shader = love.graphics.newShader([[
				]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
				
				#ifdef PIXEL
				uniform Image MainTex;
				void effect() {
					love_Canvases[0] = VaryingColor * Texel(MainTex, VaryingTexCoord.xy);
					]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
				}
				#endif
				
				#ifdef VERTEX
				extern mat4 cam;
				extern vec3 camV;
				extern mat4 transform;
				extern vec3 sun;
				extern vec4 sunColor;
				extern vec4 ambient;
				extern mat3 rotate;
				
				extern vec3 lightPos[]].. self.lighting_max .. [[];
				extern vec4 lightColor[]].. self.lighting_max .. [[];
				int lightCount = ]] .. self.lighting_max .. [[;
				
				vec4 position(mat4 transform_projection, vec4 vertex_position) {
					vec4 pos = (vertex_position * transform);
					vec3 normal = (VertexColor.rgb - vec3(0.5)) * 2.0 * rotate;
					
					//sun
					float dotSunNormal = dot(sun, normal);
					float angle = max(0, dotSunNormal);
					vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
					float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexColor.a * 4.0 - VertexColor.a * 2.0) * VertexColor.a * 2.0;
					float power = (angle * (1.0 - VertexColor.a * 0.5) + reflectionAngle * VertexColor.a) * 1.0;
					
					VaryingColor = ConstantColor * (ambient + sunColor * power);
					
					for (int i = 0; i < lightCount; i++) {
						if (lightColor[i].a > 0.0) {
							//sun
							vec3 diff = lightPos[i]-pos.xyz;
							dotSunNormal = dot(normalize(diff), normal);
							angle = max(0, dotSunNormal);
							reflection = normalize(diff - 2 * dotSunNormal * normal);
							power = (angle * (1.0 - VertexColor.a * 0.5) + reflectionAngle * VertexColor.a) / length(diff);
							
							VaryingColor += lightColor[i] * power;
						} else {
							break;
						}
					}
					
					vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
					]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
					return vPos + vec4(0, 0, 0.75, 0);
				}
				#endif
			]])
		end
	end

	lib.AO = love.graphics.newShader([[
		extern vec2 size;
		extern vec3 samples[]] .. self.AO_quality .. [[];
		extern Image noise;
		extern vec2 noiseOffset;
		int sampleCount = ]] .. self.AO_quality .. [[;
		
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
			float sum = 0;
			
			float z = Texel(texture, tc).r;
			vec2 offset = (Texel(noise, tc * 64.0 + noiseOffset).xy - vec2(0.5)) * 0.01;
			for (int i = 0; i < sampleCount; i++) {
				float r = Texel(texture, tc + samples[i].xy / (0.25+z*0.05) + offset).r;
				if (z - r > samples[i].z) {
					sum ++;
				}
			}
			
			sum = 1.0 - min(1, sum / sampleCount * 2.0 - 1.0);
			return vec4(sum, sum, sum, 1.0);
		}
	]])

	local t = love.graphics.newImage(self.root .. "/noise.png")
	t:setWrap("repeat", "repeat")
	lib.AO:send("noise", t)

	local f = { }
	for i = 1, lib.AO_quality do
		f[#f+1] = {(math.random()-0.5) * 32 / love.graphics.getWidth(), (math.random()-0.5) * 32 / love.graphics.getHeight(), (math.random()-0.5) * 0.25}
	end
	lib.AO:send("samples", unpack(f))
end