--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
shader.lua - contains the shaders
--]]

local lib = _3DreamEngine

--blur, 7-Kernel, only red channel
lib.blur = love.graphics.newShader([[
	extern vec2 size;
	extern float hstep;
	extern float vstep;

	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float o = Texel(texture, tc).r;
		float sum = o * 0.383103;
		
		sum += Texel(texture, tc - vec2(3.0*hstep, 3.0*vstep) * size).r * 0.00598;
		sum += Texel(texture, tc - vec2(2.0*hstep, 2.0*vstep) * size).r * 0.060626;
		sum += Texel(texture, tc - vec2(1.0*hstep, 1.0*vstep) * size).r * 0.241843;
		
		sum += Texel(texture, tc + vec2(1.0*hstep, tc.y + 1.0*vstep) * size).r * 0.241843;
		sum += Texel(texture, tc + vec2(2.0*hstep, tc.y + 2.0*vstep) * size).r * 0.060626;
		sum += Texel(texture, tc + vec2(3.0*hstep, tc.y + 3.0*vstep) * size).r * 0.00598;
		
		return vec4(sum);
	}
]])

--combines AO, applies distance fog
lib.post = love.graphics.newShader([[
	extern Image depth;
	extern Image AO;
	extern float fog;
	extern float strength;
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float AOv = (1.0 - strength) + Texel(AO, tc).r * strength;
		float depth = min(1.0, Texel(depth, tc).r * fog);
		return (Texel(texture, tc) * vec4(AOv, AOv, AOv, 1.0)) + vec4(0.5) * depth;
	}
]])

lib.shaders = { }
function lib.loadShader(self)
	local fragments = { }
	
	fragments.sun_flat = [[
		//sun
		float dotSunNormal = dot(sun, normal);
		float angle = max(0, dotSunNormal);
		vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
		float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexTexCoord.a * 4.0 - VertexTexCoord.a * 2.0) * VertexTexCoord.a * 2.0;
		float power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a) * 1.0;
		
		VaryingColor = ConstantColor * vec4((VertexColor.rgb + vec3(power*0.2)) * (ambient + sunColor * power), VertexColor.a);
	]]
	
	fragments.sun = [[
		//sun
		float dotSunNormal = dot(sun, normal);
		float angle = max(0, dotSunNormal);
		vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
		float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexColor.a * 4.0 - VertexColor.a * 2.0) * VertexColor.a * 2.0;
		float power = (angle * (1.0 - VertexColor.a * 0.5) + reflectionAngle * VertexColor.a) * 1.0;
		
		VaryingColor = ConstantColor * vec4((ambient + sunColor * power), 1.0);
	]]
	
	--flat per pixel shading, lighting
	lib.shaders.flat_light_pixel = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
		
		varying vec4 colorRaw;
		varying vec4 pos;
		extern vec3 camV;
		varying vec3 normal;
		varying float specular;
		
		#ifdef PIXEL
		extern vec3 lightPos[]].. self.lighting_max .. [[];
		extern vec4 lightColor[]].. self.lighting_max .. [[];
		int lightCount = ]] .. self.lighting_max .. [[;
		
		void effect() {
			vec4 col = VaryingColor;
			for (int i = 0; i < lightCount; i++) {
				if (lightColor[i].a > 0.0) {
					vec3 diff = lightPos[i]-pos.xyz;
					float dotLightNormal = dot(normalize(diff), normal);
					float angle = max(0, dotLightNormal);
					float power = ((1.0 - specular) * angle + specular * angle*angle) / (pow(length(diff), 2)+1.0);
					
					col += vec4(colorRaw.rgb * lightColor[i].rgb * power, max(0, (angle-0.75)*4.0) * power);
				} else {
					break;
				}
			}
			
			love_Canvases[0] = col;
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			pos = (vertex_position * transform);
			normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun_flat) .. [[
			
			colorRaw = VertexColor;
			specular = VertexTexCoord.a;
			
			vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
			]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
			return vPos + vec4(0, 0, 0.75, 0);
		}
		#endif
	]])
	
	--flat shading, lightning
	lib.shaders.flat_light = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
		
		]] .. (self.AO_enabled and [[
		#ifdef PIXEL
		void effect() {
			love_Canvases[0] = VaryingColor;
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		]] or "") .. [[
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern vec3 camV;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		extern vec3 lightPos[]].. self.lighting_max .. [[];
		extern vec4 lightColor[]].. self.lighting_max .. [[];
		int lightCount = ]] .. self.lighting_max .. [[;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			vec4 pos = (vertex_position * transform);
			vec3 normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun_flat) .. [[
			
			for (int i = 0; i < lightCount; i++) {
				if (lightColor[i].a > 0.0) {
					float specular = VertexTexCoord.a;
					vec3 diff = lightPos[i]-pos.xyz;
					float dotLightNormal = dot(normalize(diff), normal);
					float angle = max(0, dotLightNormal);
					float power = ((1.0 - specular) * angle + specular * angle*angle) / (pow(length(diff), 2)+1.0);
					
					VaryingColor += vec4((VertexColor.rgb + vec3(power*0.2)) * lightColor[i].rgb * power, max(0, (angle-0.75)*4.0) * power);
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
	
	--flat shading
	lib.shaders.flat = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
		
		]] .. (self.AO_enabled and [[
		#ifdef PIXEL
		void effect() {
			love_Canvases[0] = VaryingColor;
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		]] or "") .. [[
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern vec3 camV;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		extern vec3 lightPos[]].. self.lighting_max .. [[];
		extern vec4 lightColor[]].. self.lighting_max .. [[];
		int lightCount = ]] .. self.lighting_max .. [[;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			vec4 pos = (vertex_position * transform);
			vec3 normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun_flat) .. [[
			
			vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
			]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
			return vPos + vec4(0, 0, 0.75, 0);
		}
		#endif
	]])
	
	--textured, per pixel lighting, specular map
	lib.shaders.textured_light_pixel_spec = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
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
					vec3 diff = lightPos[i]-pos.xyz;
					float dotLightNormal = dot(normalize(diff), normal);
					float angle = max(0, dotLightNormal);
					float power = ((1.0 - specular) * angle + specular * angle*angle) / (pow(length(diff), 2)+1.0);
					
					col += vec4(lightColor[i].rgb * power, max(0, (angle-0.75)*4.0) * power);
				} else {
					break;
				}
			}
			
			love_Canvases[0] = col * Texel(MainTex, VaryingTexCoord.xy);
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern vec3 camV;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			pos = (vertex_position * transform);
			normal = (VertexColor.rgb - vec3(0.5)) * 2.0 * rotate;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun) .. [[
			
			vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
			]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
			return vPos + vec4(0, 0, 0.75, 0);
		}
		#endif
	]])
	
	--textured, per pixel lighting
	lib.shaders.textured_light_pixel = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
		varying vec4 pos;
		varying vec3 normal;
		varying float specular;
		
		#ifdef PIXEL
		uniform Image MainTex;
		
		extern vec3 lightPos[]].. self.lighting_max .. [[];
		extern vec4 lightColor[]].. self.lighting_max .. [[];
		int lightCount = ]] .. self.lighting_max .. [[;
		
		void effect() {
			vec4 col = VaryingColor;
			for (int i = 0; i < lightCount; i++) {
				if (lightColor[i].a > 0.0) {
					vec3 diff = lightPos[i]-pos.xyz;
					float dotLightNormal = dot(normalize(diff), normal);
					float angle = max(0, dotLightNormal);
					float power = ((1.0 - specular) * angle + specular * angle*angle) / (pow(length(diff), 2)+1.0);
					
					col += vec4(lightColor[i].rgb * power, max(0, (angle-0.75)*4.0) * power);
				} else {
					break;
				}
			}
			
			love_Canvases[0] = col * Texel(MainTex, VaryingTexCoord.xy);
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern vec3 camV;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			pos = (vertex_position * transform);
			normal = (VertexColor.rgb - vec3(0.5)) * 2.0 * rotate;
			specular = VertexColor.a;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun) .. [[
			
			vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
			]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
			return vPos + vec4(0, 0, 0.75, 0);
		}
		#endif
	]])
	
	--textured, lighting
	lib.shaders.textured_light = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
		
		#ifdef PIXEL
		uniform Image MainTex;
		void effect() {
			love_Canvases[0] = VaryingColor * Texel(MainTex, VaryingTexCoord.xy);
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern vec3 camV;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		extern vec3 lightPos[]].. self.lighting_max .. [[];
		extern vec4 lightColor[]].. self.lighting_max .. [[];
		int lightCount = ]] .. self.lighting_max .. [[;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			vec4 pos = (vertex_position * transform);
			vec3 normal = (VertexColor.rgb - vec3(0.5)) * 2.0 * rotate;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun) .. [[
			
			for (int i = 0; i < lightCount; i++) {
				if (lightColor[i].a > 0.0) {
					float specular = VertexColor.a;
					vec3 diff = lightPos[i]-pos.xyz;
					float dotLightNormal = dot(normalize(diff), normal);
					float angle = max(0, dotLightNormal);
					float power = ((1.0 - specular) * angle + specular * angle*angle) / (pow(length(diff), 2)+1.0);
					
					VaryingColor += vec4(lightColor[i].rgb * power, max(0, (angle-0.75)*4.0) * power);
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
	
	--textured
	lib.shaders.textured = love.graphics.newShader([[
		]] .. (self.AO_enabled and "varying float depth;" or "") .. [[
		]] .. (self.reflections_enabled and "varying vec3 normalCam;" or "") .. [[
		
		#ifdef PIXEL
		uniform Image MainTex;
		void effect() {
			love_Canvases[0] = VaryingColor * Texel(MainTex, VaryingTexCoord.xy);
			]] .. (self.AO_enabled and "love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);" or "") .. [[
			]] .. (self.reflections_enabled and "love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);" or "") .. [[
		}
		#endif
		
		#ifdef VERTEX
		]] .. (self.reflections_enabled and "extern mat3 cam3;" or "") .. [[
		extern mat4 cam;
		extern vec3 camV;
		extern mat4 transform;
		extern vec3 sun;
		extern vec3 sunColor;
		extern vec3 ambient;
		extern mat3 rotate;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			vec4 pos = (vertex_position * transform);
			vec3 normal = (VertexColor.rgb - vec3(0.5)) * 2.0 * rotate;
			]] .. (self.reflections_enabled and "normalCam = normal * cam3;;" or "") .. [[
			
			]] .. (fragments.sun) .. [[
			
			vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
			]] .. (self.AO_enabled and "depth = vPos.z;" or "") .. [[
			return vPos + vec4(0, 0, 0.75, 0);
		}
		#endif
	]])
	
	lib.AO = love.graphics.newShader([[		extern vec2 size;
		extern vec3 samples[]] .. self.AO_quality .. [[];
		int sampleCount = ]] .. self.AO_quality .. [[;
		
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
			float sum = 0.0;
			
			float z = Texel(texture, tc).r;
			if (z >= 255.0) {
				return vec4(1.0);
			}
			
			for (int i = 0; i < sampleCount; i++) {
				float r = Texel(texture, tc + samples[i].xy / (0.3+z*0.05)).r;
				
				//samples differences (but clamps it)
				sum += clamp(z-r, -0.5, 0.5) * samples[i].z;
			}
			
			sum = pow(1.0 - sum / float(sampleCount) * 8.0, 2);
			return vec4(sum, sum, sum, 1.0);
		}
	]])

	local f = { }
	for i = 1, lib.AO_quality do
		local r = i/lib.AO_quality * math.pi * 2
		local d = (0.5 + i % 4) / 4
		local range = 16
		f[#f+1] = {math.cos(r)*d*range / love.graphics.getWidth(), math.sin(r)*d*range / love.graphics.getHeight(), (1-d)^2}
	end
	lib.AO:send("samples", unpack(f))
	
	lib.shaderCloud = love.graphics.newShader([[
		varying float dist;
		
		#ifdef PIXEL
		extern float density;
		extern float time;
		
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
			float v = (Texel(texture, VaryingTexCoord.xy * 0.5 + vec2(time + dist*0.01, dist*0.01)).r + Texel(texture, VaryingTexCoord.xy * 0.5 + vec2(dist*0.01, time + dist*0.01)).r) * 0.5;
			float threshold = 1.0 - (density - abs(dist)*density);
			return vec4(1.0, 1.0, 1.0, min(1.0, 1.0 * max(0, v - threshold) / threshold));
		}
		#endif
		
		#ifdef VERTEX
		extern mat4 transform;
		extern mat4 cam;
		
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			dist = vertex_position.y;
			return cam * (vertex_position * transform) * vec4(1, -1, 1, 1);
		}
		#endif
	]])
	
	lib.shaderSkyNight = love.graphics.newShader([[
		#ifdef PIXEL
		extern float time;
		extern Image night;
		extern vec4 color;
		vec4 effect(vec4 c, Image day, vec2 tc, vec2 sc) {
			return (Texel(day, tc) * time + Texel(night, tc) * (1.0-time)) * color;
		}
		#endif
		
		#ifdef VERTEX
		extern mat4 cam;
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			return cam * vertex_position * vec4(1, -1, 1, 1);
		}
		#endif
	]])
	
	lib.shaderSky = love.graphics.newShader([[
		#ifdef PIXEL
		extern vec4 color;
		vec4 effect(vec4 c, Image day, vec2 tc, vec2 sc) {
			return Texel(day, tc) * color;
		}
		#endif
		
		#ifdef VERTEX
		extern mat4 cam;
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			return cam * vertex_position * vec4(1, -1, 1, 1);
		}
		#endif
	]])
end