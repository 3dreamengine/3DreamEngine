//part of the 3DreamEngine by Luke100000
//shader.glsl - the main vertex and fragment shader

#ifdef OPENGL_ES
	highp mat3 transpose_optional(mat3 inMatrix) {
		vec3 i0 = inMatrix[0];
		vec3 i1 = inMatrix[1];
		vec3 i2 = inMatrix[2];
		
		highp mat3 outMatrix = mat3(
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

varying vec3 normalV;

//lighting
#ifdef LIGHTING
	//light pos and color (r, g, b and distance meter)
	extern highp vec3 lightPos[lightCount];
	extern highp vec4 lightColor[lightCount];
#endif

//transformations
#ifdef SHADOWS_ENABLED
	extern highp mat4 transformProjShadow; //projective transformation for shadows
#endif

extern highp mat4 transformProj;        //projective transformation
extern highp mat4 transform;            //model transformation

//ambient
extern mediump vec3 ambient;            //ambient sun color

//viewer
extern highp vec3 viewPos;              //position of viewer in world space
varying highp vec3 posV;                //vertex position for pixel shader

//shadows
#ifdef SHADOWS_ENABLED
	varying highp vec4 vPosShadow;      //projected vertex position on shadow map
#endif

varying highp mat3 objToTangentSpace;



#ifdef PIXEL

//shadows
#ifdef SHADOWS_ENABLED
	extern Image tex_shadow;
#endif

//normal texture
#ifdef TEX_NORMAL
#ifdef ARRAY_IMAGE
	extern ArrayImage tex_normal;      //normal texture
#else
	extern Image tex_normal;           //normal texture
#endif
#endif

//specular/reflection texture
#ifdef TEX_SPECULAR
#ifdef ARRAY_IMAGE
	extern ArrayImage tex_specular;    //specular texture
#else
	extern Image tex_specular;         //specular texture
#endif
#else
//or use a global value if not texture is specified
//for flat shading this value is stored per vertex
#ifndef FLAT_SHADING
	extern float specular;
#endif
#endif

//emission texture
#ifdef TEX_EMISSION
#ifdef ARRAY_IMAGE
	extern ArrayImage tex_emission;  //emission texture
#else
	extern Image tex_emission;  //emission texture
#endif
#endif

//for flat shading and textured emission, this value works as a multiplier
//for textured non-emission-texture shader this is the global value
extern float emission;

//texture used to simulate reflections
#ifdef REFLECTIONS_DAY
extern Image background_day;    //background day texture

//an optional texture for night, blending done automatically
#ifdef REFLECTIONS_NIGHT
	extern Image background_night;  //background night texture
	extern mediump vec4 background_color;   //background color
	extern float background_time;   //background day/night factor
#endif
#endif

//diffuse color texture
#ifndef FLAT_SHADING
#ifdef ARRAY_IMAGE
	uniform ArrayImage MainTex;      //diffuse texture
#else
	uniform Image MainTex;      //diffuse texture
#endif
#endif

//if writing on the depth buffer is enabled, rendering only works for non-alpha textures
//glass therefore does not require the threshold
extern float alphaThreshold;

void effect() {
//get specular level, either from the texture, the vertex on flat shading or the fallback global value
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

//get the normal vector, either from the texture or the varying vector from the fragment shader
#ifdef TEX_NORMAL
#ifdef ARRAY_IMAGE
	vec3 normal = (Texel(tex_normal, VaryingTexCoord.xyz).rgb * 2.0 - 1.0);
#else
	vec3 normal = (Texel(tex_normal, VaryingTexCoord.xy).rgb * 2.0 - 1.0);
#endif
#else
	vec3 normal = normalV;
#endif
	
	//base light
	mediump vec3 lighting = ambient;

	//point source lightings
#ifdef LIGHTING
	highp vec3 viewVec = normalize(viewPos - posV) * objToTangentSpace;
	
	//lighting
	float NdotL;
	float NdotH;
	for (int i = 0; i < lightCount; i++) {
		highp vec3 lightVec = normalize(lightPos[i] - posV) * objToTangentSpace;
		
		NdotL = clamp(dot(normal, lightVec), 0.0, 1.0);
		NdotH = clamp(dot(normal, normalize(viewVec + lightVec)), 0.0, 1.0);
		
		NdotH = pow(max(0.0, (NdotH - spec) / (1.0 - spec)), 2.0) * spec * 2.0;
		lighting += (NdotH + NdotL) * lightColor[i].rgb / (0.01 + lightColor[i].a * length(lightPos[i] - posV));
	}
#endif
	
	//diffuse color, either
#ifdef FLAT_SHADING
	//flat shading
	mediump vec4 col = vec4(VaryingColor.rgb * lighting, VaryingColor.a);
#else
	//textured
#ifdef ARRAY_IMAGE
	mediump vec4 diffuse = Texel(MainTex, VaryingTexCoord.xyz);
#else
	mediump vec4 diffuse = Texel(MainTex, VaryingTexCoord.xy);
#endif

	//apply light
	mediump vec4 col = vec4(diffuse.rgb * lighting, diffuse.a);
#endif
	
	//emission
#ifdef TEX_EMISSION

	//textured
#ifdef ARRAY_IMAGE
	vec4 e = Texel(tex_emission, VaryingTexCoord.xyz);
#else
	vec4 e = Texel(tex_emission, VaryingTexCoord.xy);
#endif
	col += vec4(e.rgb * e.a * emission, e.a);
	
#else

	//flat shading or diffuse color
#ifdef FLAT_SHADING
	col += VaryingColor * emission;
#else
	col += diffuse * emission;
#endif

#endif
	
	//reflections
#ifdef REFLECTIONS_DAY
	//get reflected normal
#ifdef FLAT_SHADING
	highp vec3 n = normalize(normalV - normalize(posV-viewPos)).xyz;
#elif defined TEX_NORMAL
	highp vec3 n = normalize(normalV + normal*transpose(objToTangentSpace)*0.25 - normalize(posV-viewPos)).xyz;
#else
	highp vec3 n = normalize(normalV - normalize(posV-viewPos)).xyz;
#endif

	//get UV coord
	float u = atan(n.x, n.z) * 0.1591549430919 + 0.5;
	float v = n.y * 0.5 + 0.5;
	mediump vec2 uv = 1.0 - vec2(u, v);
	
	//get (optional blend) the color of the sky/background
#ifdef REFLECTIONS_NIGHT
	mediump vec4 dayNight = mix(Texel(background_day, uv), Texel(background_night, uv), background_time) * background_color;
#else
	mediump vec4 dayNight = Texel(background_day, uv);
#endif
	
	//apply reflection
	dayNight.a = col.a;
	col = mix(col, dayNight, spec);
#endif
	
	//discard of below alpha threshold
	if (col.a < alphaThreshold) {
		discard;
	}
	
	//apply shadow
#ifdef SHADOWS_ENABLED
	vec2 shadowUV = vPosShadow.xy / vPosShadow.z;
	float shadowDepth = Texel(tex_shadow, shadowUV * 0.5 + 0.5).r;
	if (shadowDepth + 0.75 / 128.0 < vPosShadow.z) {
		col *= vec4(0.25, 0.25, 0.25, 1.0);
	}
#endif
	
	//pass color to canvas
	love_Canvases[0] = col;
	
	//pass depth
#ifdef AO_ENABLED
	if (alphaThreshold < 1.0) {
		love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
	} else {
		love_Canvases[1] = vec4(255.0, 0.0, 0.0, 1.0);
	}
#endif

	//pass overflow of final color to the HDR canvas
#ifdef BLOOM_ENABLED
#ifdef AO_ENABLED
	love_Canvases[2] = (col - vec4(1.0, 1.0, 1.0, 0.0)) * vec4(0.125, 0.125, 0.125, 1.0);
#else
	love_Canvases[1] = (col - vec4(1.0, 1.0, 1.0, 0.0)) * vec4(0.125, 0.125, 0.125, 1.0);
#endif
#endif

}//end effetcs()
#endif


#ifdef VERTEX

//optional data for the wind shader
#ifdef VARIANT_WIND
	extern float wind;
	extern float shader_wind_strength;
	extern float shader_wind_scale;
#endif

//additional vertex attributes
#ifndef FLAT_SHADING
	attribute highp vec3 VertexNormal;
#ifdef TEX_NORMAL
	attribute highp vec3 VertexTangent;
	attribute highp vec3 VertexBitangent;
#endif
#endif

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	//calculate vertex position
#ifdef VARIANT_WIND
	//where vertex_position.a is used for the waving strength
	highp vec4 pos = (
		vec4(vertex_position.xyz, 1.0)
		+ vec4((cos(vertex_position.x*0.25*shader_wind_scale + wind) + cos((vertex_position.z*4.0+vertex_position.y)*shader_wind_scale + wind*2.0)) * vertex_position.a * shader_wind_strength, 0.0, 0.0, 0.0)
	) * transform;
#else
	highp vec4 pos = vertex_position * transform;
#endif
	
	//transform into tangential space
#ifdef LIGHTING

//use open gl special transpose
#ifdef OPENGL_ES

#ifdef FLAT_SHADING
	objToTangentSpace = transpose_optional(mat3(transform));
#elif defined TEX_NORMAL
	objToTangentSpace = transpose_optional(mat3(transform)) * mat3(VertexTangent*2.0-1.0, VertexBitangent*2.0-1.0, VertexNormal*2.0-1.0);
#else
	objToTangentSpace = transpose(mat3(transform));
#endif

#else

#ifdef FLAT_SHADING
	objToTangentSpace = transpose(mat3(transform));
#elif defined TEX_NORMAL
	objToTangentSpace = transpose(mat3(transform)) * mat3(VertexTangent*2.0-1.0, VertexBitangent*2.0-1.0, VertexNormal*2.0-1.0);
#else
	objToTangentSpace = transpose(mat3(transform));
#endif

#endif

#endif
	
	//pass raw vertex position to fragment shader
	posV = pos.xyz;
	
	//projective transform for the shadow
#ifdef SHADOWS_ENABLED
	vPosShadow = transformProjShadow * pos;
#endif
	
	//projective transform for the vertex
	highp vec4 vPos = transformProj * pos;
	
	//extract normal vector used for reflections, for flat shading lighting too
#ifdef FLAT_SHADING
	normalV = VertexTexCoord.xyz*2.0-1.0;
#else
	normalV = VertexNormal*2.0-1.0;
#endif
	
	//extract and pass depth
#ifdef AO_ENABLED
	depth = vPos.z;
#endif
	
	return vPos;
} //end of position()
#endif