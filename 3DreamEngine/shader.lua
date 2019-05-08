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

	lib.AO = love.graphics.newShader([[
		extern vec2 size;
		extern vec3 samples[]] .. self.AO_quality .. [[];
		int sampleCount = ]] .. self.AO_quality .. [[;
		
		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
			float sum = 0.0;
			
			float z = Texel(texture, tc).r;
			if (z >= 250.0) {
				return vec4(1.0);
			}
			
			for (int i = 0; i < sampleCount; i++) {
				float r = Texel(texture, tc + samples[i].xy / (0.3+z*0.05)).r;
				
				//samples differences (but clamps it)
				if (r < 250.0) {
					sum += clamp((z-r), -0.25, 0.5) * samples[i].z;
				}
			}
			
			sum = pow(1.0 - sum / float(sampleCount) * (1.0/sqrt(z+1.0)) * 16.0, 2.0);
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
end

lib.shaderCloud = love.graphics.newShader([[
	varying float dist;
	
	#ifdef PIXEL
	extern float density;
	extern float time;
	
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float v = (Texel(texture, VaryingTexCoord.xy * 0.5 + vec2(time + dist*0.01, dist*0.01)).r + Texel(texture, VaryingTexCoord.xy * 0.5 + vec2(dist*0.01, time + dist*0.01)).r) * 0.5;
		float threshold = 1.0 - (density - abs(dist)*density);
		return vec4(1.0, 1.0, 1.0, min(1.0, 1.0 * max(0.0, v - threshold) / threshold));
	}
	#endif
	
	#ifdef VERTEX
	extern mat4 transform;
	extern mat4 cam;
	
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
		dist = vertex_position.y;
		return cam * (vertex_position * transform);
	}
	#endif
]])

lib.shaderSkyNight = love.graphics.newShader([[
	#ifdef PIXEL
	extern float time;
	extern Image night;
	extern vec4 color;
	vec4 effect(vec4 c, Image day, vec2 tc, vec2 sc) {
		return mix(Texel(day, tc), Texel(night, tc), time) * color;
	}
	#endif
	
	#ifdef VERTEX
	extern mat4 cam;
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
		return cam * vertex_position;
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
		return cam * vertex_position;
	}
	#endif
]])

function lib.getShaderInfo(self, typ, variant, normal, specular, lightings)
	variant = variant or "default"
	local name = "shader_" .. typ .. (self.AO_enabled and "_AO" or "") .. (self.reflections_enabled and "_reflections" or "") .. "_" .. variant .. (normal and "_normal" or "") .. (specular and "_specular" or "") .. "_" .. (lightings or 0)
	
	if not self["info_" .. name] then
		self["info_" .. name] = {
			name = name,
			typ = typ,
			variant = variant,
			normal = normal,
			specular = specular,
			lighting_max = lightings,
		}
	end
	
	return self["info_" .. name]
end

lib.render = love.graphics.getRendererInfo( )
function lib.getShader(self, typ, variant, normal, specular, lightings)
	local info = self:getShaderInfo(typ, variant, normal, specular, lightings)
	
	--flat shading does not have textures
	if typ == "flat" then
		normal = false
		specular = false
	end
	
	if not self[info.name] then
		self[info.name] = info
		local code = 
			--defines
			(typ == "flat" and "#define FLAT_SHADING\n" or "") ..
			(normal and "#define TEX_NORMAL\n" or "") ..
			(specular and "#define TEX_SPECULAR\n" or "") ..
			(self.AO_enabled and "#define AO_ENABLED\n" or "") ..
			(self.reflections_enabled and "#define REFLECTIONS_ENABLED\n" or "") ..
			(variant == "wind" and "#define VARIANT_WIND\n" or "") ..
			(lightings > 0 and "#define LIGHTING\n" or "") ..
			(self.render == "OpenGL ES" and "#define OPENGL_ES\n" or "") ..
			
			[[

#ifdef OPENGL_ES
mat3 transpose(mat3 inMatrix) {
	vec3 i0 = inMatrix[0];
	vec3 i1 = inMatrix[1];
	vec3 i2 = inMatrix[2];
	
    mat3 outMatrix = mat3(
		vec3(i0.x, i1.x, i2.x),
		vec3(i0.y, i1.y, i2.y),
		vec3(i0.z, i1.z, i2.z)
	);
	
	return outMatrix;
}
#endif

//required for secondary depth buffer and AO
#ifdef AO_ENABLED
varying float depth;
#endif

//lighting
#ifdef LIGHTING
const int lightCount = ]] .. lightings .. [[;

//light pos and color (r, g, b and distance meter)
extern vec3 lightPos[lightCount];
extern vec4 lightColor[lightCount];
varying vec3 lightVec[lightCount];
varying vec3 lightVecHalf[lightCount];
#endif

//transformations
extern mat4 transformProj;   //projective transformation
extern mat4 transform;       //model transformation

//ambient
extern vec3 ambient;     //ambient sun color

//viewer
extern vec3 viewPos;     //position of viewer in world space
varying vec3 viewVec;    //vector from viewer to vertex
varying vec3 posV;       //vertex position for pixel shader

#ifdef PIXEL

#ifdef TEX_SPECULAR
extern Image tex_specular;  //specular texture
#endif

#ifdef TEX_NORMAL
extern Image tex_normal;    //normal texture
#endif

#ifndef FLAT_SHADING
uniform Image MainTex;      //diffuse texture
#endif

extern float alphaThreshold;

void effect() {
	#ifdef TEX_SPECULAR
	float specular = Texel(tex_specular, VaryingTexCoord.xy).r * 0.9;
	#else
		#ifdef FLAT_SHADING
		float specular = VaryingTexCoord.a;
		#else
		float specular = 0.5;
		#endif
	#endif
	
	#ifdef TEX_NORMAL
	vec3 normal = (Texel(tex_normal, VaryingTexCoord.xy).rgb * 2.0 - 1.0);
	#else
	#ifdef FLAT_SHADING
	vec3 normal = VaryingTexCoord.xyz;
	#else
	vec3 normal = vec3(0, 0, 1.0);
	#endif
	#endif
	
	vec3 lighting = ambient;
	
	#ifdef LIGHTING
	//lighting
	float NdotL;
	float NdotH;
	for (int i = 0; i < lightCount; i++) {
		NdotL = clamp(dot(normal, lightVec[i]), 0.0, 1.0);
		NdotH = clamp(dot(normal, lightVecHalf[i]), 0.0, 1.0);
		
		NdotH = pow(max(0.0, (NdotH - specular) / (1.0 - specular)), 2) * specular * 2.0;
		lighting += (NdotH + NdotL) * lightColor[i].rgb / (0.01 + lightColor[i].a * length(lightPos[i] - posV));
	}
	#endif
	
	//final color
	#ifdef FLAT_SHADING
	vec4 col = vec4(VaryingColor.rgb * lighting, VaryingColor.a);
	#else
	vec4 diffuse = Texel(MainTex, VaryingTexCoord.xy);
	vec4 col = vec4(diffuse.rgb * lighting, diffuse.a);
	#endif
	
	if (col.a < alphaThreshold) {
		discard;
	}
	
	love_Canvases[0] = col;
	
	#ifdef AO_ENABLED
	love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
	#endif
	
	#ifdef REFLECTIONS_ENABLED
	love_Canvases[2] = vec4(normalCam*0.5 + vec3(0.5), 1.0);
	#endif
}
#endif


#ifdef VERTEX

#ifdef VARIANT_WIND
extern float wind;
#endif

//additional vertex attributes
attribute vec3 VertexNormal;
attribute vec3 VertexTangent;
attribute vec3 VertexBitangent;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	//calculate vertex position
	#ifdef VARIANT_WIND
	//where vertex_position.a is used for the waving strength
	vec4 pos = (
			vec4(vertex_position.xyz, 1.0)
			+ vec4((cos(vertex_position.x*0.25+wind) + cos(vertex_position.z*4.0+vertex_position.y+wind*2.0)) * vertex_position.a, 0.0, 0.0, 0.0)
		) * transform;
	#else
	vec4 pos = vertex_position * transform;
	#endif
	
	//transform into tangential space
	#ifdef FLAT_SHADING
	mat3 objToTangentSpace = transpose(mat3(transform));
	#else
	mat3 objToTangentSpace = transpose(mat3(transform)) * mat3(VertexTangent, VertexBitangent, VertexNormal);
	#endif
	
	//view vector
	viewVec = normalize(viewPos - pos.xyz) * objToTangentSpace;
	
	#ifdef LIGHTING
		//lighting
		for (int i = 0; i < lightCount; i++) {
			lightVec[i] = normalize(lightPos[i] - pos.xyz) * objToTangentSpace;
			
			//light-view vector
			lightVecHalf[i] = normalize(viewVec + lightVec[i]);
		}
	#endif
	
	posV = pos.xyz;
	
	//projective transform and depth extracting
	vec4 vPos = transformProj * pos + vec4(0.0, 0.0, 0.75, 0.0);
	
	#ifdef AO_ENABLED
	depth = vPos.z;
	#endif
	
	return vPos;
}
#endif]]
		
		--debug
		--love.filesystem.write(info.name .. ".glsl", code)
		
		self[info.name].shader = love.graphics.newShader(code)
	end
	
	return self[info.name]
end