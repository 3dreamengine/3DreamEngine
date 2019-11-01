--[[
#part of the 3DreamEngine by Luke100000
shader.lua - contains the shaders
--]]

local lib = _3DreamEngine

if not love.graphics then
	return
end

if _DEBUGMODE then
	love.graphics.newShader_old = love.graphics.newShader
	function love.graphics.newShader(pixel, vertex)
		local status, err = love.graphics.validateShader(_RENDERER == "OpenGL ES", pixel, vertex)
		if not status then
			print()
			print("-----------------")
			print("SHADER ERROR")
			print(err)
			print(debug.traceback())
			print("-----------------")
			print()
		end
		return love.graphics.newShader_old(pixel, vertex)
	end
end

--blur, 7-Kernel, only red channel
lib.blur = love.graphics.newShader([[
	extern mediump vec2 size;
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
		return ((Texel(texture, tc) * vec4(AOv, AOv, AOv, 1.0)) + vec4(0.5) * depth) * color;
	}
]])

--applies bloom
lib.bloom = love.graphics.newShader([[
	extern float strength;
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		return Texel(texture, tc) * vec4(strength, strength, strength, 1.0);
	}
]])

lib.shaders = { }
function lib.loadShader(self)
	lib.shaderParticle = love.graphics.newShader(
		(self.bloom_enabled and  "#define BLOOM_ENABLED" or "") .. [[
		
		#ifdef PIXEL
		uniform Image MainTex;
		extern float emission;
		extern Image tex_emission;
		
		void effect()
		{
			love_Canvases[0] = Texel(MainTex, VaryingTexCoord.xy) * VaryingColor;
			#ifdef BLOOM_ENABLED
				love_Canvases[1] = Texel(tex_emission, VaryingTexCoord.xy) * emission;
			#endif
		}
		#endif
		
		#ifdef VERTEX
		extern float depth;
		extern mat4 cam;
		vec4 position(mat4 transform_projection, vec4 vertex_position) {
			return vec4((transform_projection * vertex_position).xy, depth, 1.0);
		}
		#endif
	]])

	lib.AO = love.graphics.newShader([[
		extern mediump vec2 size;
		extern mediump vec3 samples[]] .. self.AO_quality .. [[];
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
		return vec4(1.0, 1.0, 1.0, min(1.0, 1.0 * max(0.0, v - threshold) / threshold)) * color;
	}
	#endif
	
	#ifdef VERTEX
	extern mat4 cam;
	
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
		dist = vertex_position.y;
		return cam * vertex_position;
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

--store all shaders
function lib.clearShaders()
	lib.shaders = { }
	for _,flat in ipairs({true, false}) do
		lib.shaders[flat] = { }
		for _,variant in ipairs({"default", "wind"}) do
			lib.shaders[flat][variant] = { }
			for _,normal in ipairs({true, false}) do
				lib.shaders[flat][variant][normal] = { }
				for _,specular in ipairs({true, false}) do
					lib.shaders[flat][variant][normal][specular] = { }
					for _,emission in ipairs({true, false}) do
						lib.shaders[flat][variant][normal][specular][emission] = { }
						for _,arrayImage in ipairs({true, false}) do
							lib.shaders[flat][variant][normal][specular][emission][arrayImage] = { }
							for _,reflections_day in ipairs({true, false}) do
								lib.shaders[flat][variant][normal][specular][emission][arrayImage][reflections_day] = { }
								for _,reflections_night in ipairs({true, false}) do
									lib.shaders[flat][variant][normal][specular][emission][arrayImage][reflections_day][reflections_night] = {
										flat = flat,
										variant = variant,
										normal = normal,
										specular = specular,
										emission = emission,
										arrayImage = arrayImage,
										reflections_day = reflections_day,
										reflections_night = reflections_night,
										shaders = { },
									}
								end
							end
						end
					end
				end
			end
		end
	end
end

--returns a fitting shader for the current material and meshtype
function lib.getShaderInfo(self, mat, meshType, obj)
	return lib.shaders[meshType == "flat" and true or false][mat.shader or "default"][(meshType == "textured_normal" or meshType == "textured_array_normal") and mat.tex_normal and true or false][meshType ~= "flat" and mat.tex_specular and true or false][meshType ~= "flat" and mat.tex_emission and true or false][meshType == "textured_array_normal" or meshType == "textured_array"][(obj and obj.reflections_day or mat.reflections_day or mat.reflections and self.sky) and true or false][(obj and obj.reflections_night or mat.reflections_night or mat.reflections and self.night) and true or false]
end

--returns a full shader based on the shaderInfo and lighting count
_RENDERER = love.graphics.getRendererInfo()
function lib.getShader(self, info, lightings)
	if not info.shaders[lightings] then
		local code = 
			--defines
			(info.flat and "#define FLAT_SHADING\n" or "") ..
			(info.normal and "#define TEX_NORMAL\n" or "") ..
			(info.specular and "#define TEX_SPECULAR\n" or "") ..
			(info.emission and "#define TEX_EMISSION\n" or "") ..
			(self.AO_enabled and "#define AO_ENABLED\n" or "") ..
			(self.bloom_enabled and "#define BLOOM_ENABLED\n" or "") ..
			(info.arrayImage and "#define ARRAY_IMAGE\n" or "") ..
			(info.reflections_day and "#define REFLECTIONS_DAY\n" or "") ..
			(info.reflections_night and "#define REFLECTIONS_NIGHT\n" or "") ..
			(info.variant == "wind" and "#define VARIANT_WIND\n" or "") ..
			(lightings > 0 and "#define LIGHTING\n" or "") ..
			[[

]] .. (self.render == "OpenGL ES" and [[
mediump mat3 transpose_optional(mat3 inMatrix) {
	vec3 i0 = inMatrix[0];
	vec3 i1 = inMatrix[1];
	vec3 i2 = inMatrix[2];
	
    mediump mat3 outMatrix = mat3(
		vec3(i0.x, i1.x, i2.x),
		vec3(i0.y, i1.y, i2.y),
		vec3(i0.z, i1.z, i2.z)
	);
	
	return outMatrix;
}
]] or "") .. [[

//required for secondary depth buffer and AO
#ifdef AO_ENABLED
	varying float depth;
#endif

varying vec3 normalV;

//lighting
#ifdef LIGHTING
	const int lightCount = ]] .. lightings .. [[;

	//light pos and color (r, g, b and distance meter)
	extern mediump vec3 lightPos[lightCount];
	extern mediump vec4 lightColor[lightCount];
#endif

//transformations
extern mediump mat4 transformProjShadow; //projective transformation for shadows
extern mediump mat4 transformProj;       //projective transformation
extern mediump mat4 transform;           //model transformation

//ambient
extern mediump vec3 ambient;     //ambient sun color

//viewer
extern mediump vec3 viewPos;     //position of viewer in world space
varying mediump vec3 posV;       //vertex position for pixel shader

varying mediump vec4 vPosShadow; //projected vertex position on shadow map

varying mediump mat3 objToTangentSpace;

#ifdef PIXEL

extern Image tex_shadow;

#ifdef TEX_NORMAL
	#ifdef ARRAY_IMAGE
		extern ArrayImage tex_normal;    //normal texture
	#else
		extern Image tex_normal;    //normal texture
	#endif
#endif

#ifdef TEX_SPECULAR
	#ifdef ARRAY_IMAGE
		extern ArrayImage tex_specular;  //specular texture
	#else
		extern Image tex_specular;  //specular texture
	#endif
#else
	#ifndef FLAT_SHADING
		extern float specular;
	#endif
#endif

#ifdef TEX_EMISSION
	#ifdef ARRAY_IMAGE
		extern ArrayImage tex_emission;  //emission texture
	#else
		extern Image tex_emission;  //emission texture
	#endif
#endif

extern float emission;

#ifdef REFLECTIONS_DAY
	extern Image background_day;    //background day texture
	#ifdef REFLECTIONS_NIGHT
		extern Image background_night;  //background night texture
		extern mediump vec4 background_color;   //background color
		extern float background_time;   //background day/night factor
	#endif
#endif

#ifndef FLAT_SHADING
	#ifdef ARRAY_IMAGE
		uniform ArrayImage MainTex;      //diffuse texture
	#else
		uniform Image MainTex;      //diffuse texture
	#endif
#endif

extern float alphaThreshold;

void effect() {
	#ifdef TEX_SPECULAR
		#ifdef ARRAY_IMAGE
			float spec = Texel(tex_specular, VaryingTexCoord.xyz).r * 0.95;
		#else
			float spec = Texel(tex_specular, VaryingTexCoord.xy).r * 0.95;
		#endif
	#else
		#ifdef FLAT_SHADING
			float spec = VaryingTexCoord.a * 0.95;
		#else
			float spec = specular * 0.95;
		#endif
	#endif
	
	#ifdef TEX_NORMAL
		#ifdef ARRAY_IMAGE
			vec3 normal = (Texel(tex_normal, VaryingTexCoord.xyz).rgb * 2.0 - 1.0);
		#else
			vec3 normal = (Texel(tex_normal, VaryingTexCoord.xy).rgb * 2.0 - 1.0);
		#endif
	#else
		vec3 normal = normalV;
	#endif
	
	mediump vec3 lighting = ambient;
	
	#ifdef LIGHTING
	mediump vec3 viewVec = normalize(viewPos - posV) * objToTangentSpace;
	
	//lighting
	float NdotL;
	float NdotH;
	for (int i = 0; i < lightCount; i++) {
		mediump vec3 lightVec = normalize(lightPos[i] - posV) * objToTangentSpace;
		
		NdotL = clamp(dot(normal, lightVec), 0.0, 1.0);
		NdotH = clamp(dot(normal, normalize(viewVec + lightVec)), 0.0, 1.0);
		
		NdotH = pow(max(0.0, (NdotH - spec) / (1.0 - spec)), 2.0) * spec * 2.0;
		lighting += (NdotH + NdotL) * lightColor[i].rgb / (0.01 + lightColor[i].a * length(lightPos[i] - posV));
	}
	#endif
	
	//final color
	#ifdef FLAT_SHADING
		mediump vec4 col = vec4(VaryingColor.rgb * lighting, VaryingColor.a);
	#else
		#ifdef ARRAY_IMAGE
			mediump vec4 diffuse = Texel(MainTex, VaryingTexCoord.xyz);
		#else
			mediump vec4 diffuse = Texel(MainTex, VaryingTexCoord.xy);
		#endif
		mediump vec4 col = vec4(diffuse.rgb * lighting, diffuse.a);
	#endif
	
	//emission
	#ifdef TEX_EMISSION
		#ifdef ARRAY_IMAGE
			vec4 e = Texel(tex_emission, VaryingTexCoord.xyz);
		#else
			vec4 e = Texel(tex_emission, VaryingTexCoord.xy);
		#endif
		col += vec4(e.rgb * e.a * emission, e.a);
	#else
		if (emission > 0) {
		#ifdef FLAT_SHADING
			col += vec4(VaryingColor.rgb * emission, VaryingColor.a);
		#else
			col += vec4(diffuse.rgb * emission, diffuse.a);
		#endif
		}
	#endif
	
	//reflections
	#ifdef REFLECTIONS_DAY
		#ifdef FLAT_SHADING
			mediump vec3 n = normalize(normalV - normalize(posV-viewPos)).xyz;
		#else
			#ifdef TEX_NORMAL
				mediump vec3 n = normalize(normalV + normal*transpose(objToTangentSpace)*0.25 - normalize(posV-viewPos)).xyz;
			#else
				mediump vec3 n = normalize(normalV - normalize(posV-viewPos)).xyz;
			#endif
		#endif
		float u = atan(n.x, n.z) * 0.1591549430919 + 0.5;
		float v = n.y * 0.5 + 0.5;
		mediump vec2 uv = 1.0 - vec2(u, v);
		
		#ifdef REFLECTIONS_NIGHT
			mediump vec4 dayNight = mix(Texel(background_day, uv), Texel(background_night, uv), background_time) * background_color;
		#else
			mediump vec4 dayNight = Texel(background_day, uv);
		#endif
		dayNight.a = col.a;
		col = mix(col, dayNight, spec);
	#endif
	
	if (col.a < alphaThreshold) {
		discard;
	}
	
	//apply shadow
	vec2 shadowUV = vPosShadow.xy / vPosShadow.z;
	float shadowDepth = Texel(tex_shadow, shadowUV * 0.5 + 0.5).r;
	if (shadowDepth + 1.0 < vPosShadow.z) {
		col *= vec4(0.25, 0.25, 0.25, 1.0);
	}
	
	love_Canvases[0] = col;
	
	#ifdef AO_ENABLED
	if (alphaThreshold < 1.0) {
		love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
	} else {
		love_Canvases[1] = vec4(255.0, 0.0, 0.0, 1.0);
	}
	#endif
	
	#ifdef BLOOM_ENABLED
		#ifdef AO_ENABLED
			love_Canvases[2] = (col - vec4(1.0, 1.0, 1.0, 0.0)) * vec4(0.125, 0.125, 0.125, 1.0);
		#else
			love_Canvases[1] = (col - vec4(1.0, 1.0, 1.0, 0.0)) * vec4(0.125, 0.125, 0.125, 1.0);
		#endif
	#endif
}
#endif


#ifdef VERTEX

#ifdef VARIANT_WIND
	extern float wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
#endif

//additional vertex attributes
#ifndef FLAT_SHADING
	attribute mediump vec3 VertexNormal;
	#ifdef TEX_NORMAL
		attribute mediump vec3 VertexTangent;
		attribute mediump vec3 VertexBitangent;
	#endif
#endif

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	//calculate vertex position
	#ifdef VARIANT_WIND
		//where vertex_position.a is used for the waving strength
		mediump vec4 pos = (
				vec4(vertex_position.xyz, 1.0)
				+ vec4((cos(vertex_position.x*0.25*shader_wind_scale + wind) + cos((vertex_position.z*4.0+vertex_position.y)*shader_wind_scale + wind*2.0)) * vertex_position.a * shader_wind_strength, 0.0, 0.0, 0.0)
			) * transform;
	#else
		mediump vec4 pos = vertex_position * transform;
	#endif
	
	//transform into tangential space
	#ifdef LIGHTING
]] .. (self.render == "OpenGL ES" and [[
		#ifdef FLAT_SHADING
			objToTangentSpace = transpose_optional(mat3(transform));
		#else
			#ifdef TEX_NORMAL
				objToTangentSpace = transpose_optional(mat3(transform)) * mat3(VertexTangent*2.0-1.0, VertexBitangent*2.0-1.0, VertexNormal*2.0-1.0);
			#else
				objToTangentSpace = transpose(mat3(transform));
			#endif
		#endif
]] or [[
		#ifdef FLAT_SHADING
			objToTangentSpace = transpose(mat3(transform));
		#else
			#ifdef TEX_NORMAL
				objToTangentSpace = transpose(mat3(transform)) * mat3(VertexTangent*2.0-1.0, VertexBitangent*2.0-1.0, VertexNormal*2.0-1.0);
			#else
				objToTangentSpace = transpose(mat3(transform));
			#endif
		#endif
]]) .. [[
	#endif
	
	posV = pos.xyz;
	
	
	
	//projective transform for the shadow
	vPosShadow = transformProjShadow * pos;
	
	//projective transform and depth extracting
	mediump vec4 vPos = transformProj * pos;
	
	#ifdef FLAT_SHADING
		normalV = VertexTexCoord.xyz*2.0-1.0;
	#else
		normalV = VertexNormal*2.0-1.0;
	#endif
	
	#ifdef AO_ENABLED
		depth = vPos.z;
	#endif
	
	return vPos;
}
#endif]]
		
		--debug
		if _DEBUGMODE then
			--love.filesystem.write(tostring(info):gsub(":", "") .. ".glsl", code)
		end
		
		info.shaders[lightings] = love.graphics.newShader(code)
	end
	
	info.shader = info.shaders[lightings]
	
	return info
end



--the shadow shader
lib.shaderShadow = love.graphics.newShader([[
	//transformations
	extern mediump mat4 transformProj;   //projective transformation
	extern mediump mat4 transform;       //model transformation
	
	varying float depth;

	#ifdef PIXEL
	void effect() {
		love_Canvases[0] = vec4(depth, 0.0, 0.0, 1.0);
	}
	#endif


	#ifdef VERTEX

	vec4 position(mat4 transform_projection, vec4 vertex_position) {
		//calculate vertex position
		mediump vec4 pos = vec4(vertex_position.xyz, 1.0) * transform;
		
		//projective transform and depth extracting
		mediump vec4 vPos = transformProj * pos;
		
		depth = vPos.z;
		
		return vPos;
	}
	#endif
]])