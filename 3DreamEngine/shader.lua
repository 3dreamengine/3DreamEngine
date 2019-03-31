--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
shader.lua - contains the shaders
--]]

local lib = _3DreamEngine

--default shader
lib.shader = love.graphics.newShader([[
    varying float depth;
	
	#ifdef PIXEL
	void effect() {
		love_Canvases[0] = VaryingColor;
		love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
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
		vec4 pos = (vertex_position * transform);
		
		vec3 normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
		float dotSunNormal = dot(sun, normal);
		float angle = max(0, dotSunNormal);
		
		vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
		float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexTexCoord.a * 4.0 - VertexTexCoord.a * 2.0) * VertexTexCoord.a * 2.0;
		
		float power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a) * 1.0;
		
		VaryingColor = VertexColor * (ambient + sunColor * power);
		
		if (angle > -100.0) {
			//VaryingColor = vec4(normal*0.5+0.5, 1.0);
		}
		
		vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
		depth = vPos.z;
		return vPos + vec4(0, 0, 0.75, 0);
    }
    #endif
]])

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
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float AOv = 0.6 + Texel(AO, tc).r * 0.4;
		float depth = min(1.0, Texel(depth, tc).r * fog);
		return (Texel(texture, tc) * vec4(AOv, AOv, AOv, 1.0)) * (1.0-depth) + vec4(0.5, 0.5, 0.5, 1.0) * depth;
	}
]])

--AO shader
function lib.loadShader(self)
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

	local t = love.graphics.newImage(lib.pathToNoiseTex)
	t:setWrap("repeat", "repeat")
	lib.AO:send("noise", t)

	local f = { }
	for i = 1, lib.AO_quality do
		f[#f+1] = {(math.random()-0.5) * 32 / love.graphics.getWidth(), (math.random()-0.5) * 32 / love.graphics.getHeight(), (math.random()-0.5) * 0.25}
	end
	lib.AO:send("samples", unpack(f))
end